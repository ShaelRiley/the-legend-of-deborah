LOD = LOD or {}
LOD.CrateVisuals = LOD.CrateVisuals or {}
local C = LOD.CrateVisuals

-- Only presentation constants live here. Graph, collision and section palette
-- retain their existing owners. Long face is local Y; normal is local +/-X.
-- Actual canonical cargo VVD bounds (CRATE_HULL_C2.json), not a render-culling box.
C.CargoMins = Vector(-63.051464, -192.100876, -60.343300)
C.CargoMaxs = Vector(64.947823, 195.440399, 67.656700)
C.SafeWidth = 240
C.SafeHeight = 78
C.FitMargin = 0.94
C.SurfaceOffset = 0.8
C.DrawDistance = 1650
C.MaxBrandDraws = 64
C.MaxGratesPerFloor = 1
C.GrateInset = 16
C.GratePitch = 16
C.GrateBarWidth = 3
C.FloorStyle = 'continuous-concrete'
C.GrateStyle = 'solid-collision-steel-grating'

local function finite(v) return type(v)=='number' and v==v and v>-math.huge and v<math.huge end
function C.BrandID(seed)
    return (LOD.Seeds.Derive(tonumber(seed) or 0, 'container-brand:v1') % 256) + 1
end
function C.FitBrand(id)
    local m = LOD.CrateBrandMetadata and LOD.CrateBrandMetadata[id]
    if not m then return nil end
    local b = m.bounds
    local w,h = b[3]-b[1],b[4]-b[2]
    if not finite(w) or not finite(h) or w<=0 or h<=0 then return nil end
    local scale = math.min(C.SafeWidth/w,C.SafeHeight/h)*C.FitMargin
    return {width=w*scale,height=h*scale,u0=b[1]/m.width,v0=b[2]/m.height,
        u1=b[3]/m.width,v1=b[4]/m.height,scale=scale}
end

-- Stable, named cosmetic stream. Only an existing stair's side apron qualifies:
-- both ends of the vertical edge occupy this cell, and the lower floor is solid.
-- No extra entity, opening, rail or traversal link is introduced.
function C.SelectGrates(graph)
    local out, candidates, transitions = {}, {}, {}
    for _,e in ipairs(graph.VerticalEdges or {}) do
        local a,b=e.a,e.b
        local upper = a.z>b.z and a or b
        local lower = a.z>b.z and b or a
        transitions[upper.x..':'..upper.y..':'..upper.z]=true
        if upper.x==lower.x and upper.y==lower.y and upper.z==lower.z+1 then
            candidates[#candidates+1]={upper=upper,lower=lower}
        end
    end
    table.sort(candidates,function(a,b)
        local x,y=a.upper,b.upper
        if x.z~=y.z then return x.z<y.z end
        if x.y~=y.y then return x.y<y.y end
        return x.x<y.x
    end)
    local floors={}
    for _,pair in ipairs(candidates) do
        local u,l=pair.upper,pair.lower
        local uk,lk=u.x..':'..u.y..':'..u.z,l.x..':'..l.y..':'..l.z
        -- A lower stair aperture would allow a stacked vista into a third level.
        if graph.Cells[uk] and graph.Cells[lk] and not transitions[lk]
            and not (graph.WardenVoid and (graph.WardenVoid[uk] or graph.WardenVoid[lk])) then
            floors[u.z]=floors[u.z] or {}
            floors[u.z][#floors[u.z]+1]=uk
        end
    end
    for z,keys in pairs(floors) do
        local index=(LOD.Seeds.Derive(graph.LevelSeed or 0,'crate-grate:v1:'..z)%#keys)+1
        out[keys[index]]=true
    end
    return out
end
