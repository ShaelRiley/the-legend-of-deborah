-- Arrival boundary uses existing render/NW2 presentation; no collision entity,
-- material replacement, texture allocation or Crate surface mutation.
local tint=Color(240,211,150,220)
local label=Color(255,240,205)
local function centers(p)
    local out={}
    for i=1,math.Clamp(p:GetNW2Int("LOD_EntryCells",0),0,5) do out[i]=p:GetNW2Vector("LOD_EntryCell"..i) end
    return out
end
hook.Add("PostDrawTranslucentRenderables","LOD_EntrySanctuaryBoundary",function(depth,sky)
    if depth or sky then return end
    local p=LocalPlayer();if not IsValid(p) then return end
    local cs=centers(p);if not cs[1] or p:GetPos():DistToSqr(cs[1])>2304^2 then return end
    local half=p:GetNW2Float("LOD_EntryHalf",192)
    for _,c in ipairs(cs) do
        for _,d in ipairs({Vector(1,0,0),Vector(-1,0,0),Vector(0,1,0),Vector(0,-1,0)}) do
            local neighbor=c+d*half*2;local shared=false
            for _,other in ipairs(cs) do if other:DistToSqr(neighbor)<1 then shared=true;break end end
            if not shared then
                local middle=c+d*half+Vector(0,0,4);local along=Vector(-d.y,d.x,0)*half
                render.DrawLine(middle-along,middle+along,tint,false)
            end
        end
    end
end)
hook.Add("HUDPaint","LOD_EntrySanctuaryCaption",function()
    local p=LocalPlayer()
    if not IsValid(p) or not p:Alive() or not p:GetNW2Bool("LOD_EntrySanctuary",false) then return end
    draw.SimpleTextOutlined("SANCTUARY — COMBAT DISABLED IN BOTH DIRECTIONS","DermaDefaultBold",
        ScrW()*.5,ScrH()*.23,label,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
end)
