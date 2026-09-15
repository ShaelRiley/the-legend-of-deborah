-- Small code-native silhouettes, independent of the placeholder wearable models.
local E=LOD.Equipment
local shapes={
    headwear={{5,20},{7,10},{13,6},{23,7},{26,19},{30,21},{30,24},{3,24},{3,21}},
    vest={{7,5},{12,3},{16,8},{20,3},{25,5},{28,14},{23,16},{23,29},{9,29},{9,16},{4,14}},
    trousers={{8,3},{25,3},{24,29},{18,29},{16,15},{14,29},{8,29}},
    boots={{8,3},{21,3},{20,20},{28,23},{29,29},{6,29},{6,23},{8,19}},
    gloves={{9,27},{5,17},{7,14},{11,18},{11,5},{14,5},{15,14},{16,3},{19,3},{19,14},{21,5},{24,5},{23,15},{26,9},{29,10},{25,24},{21,28}},
    shield={{4,5},{16,2},{28,5},{26,21},{16,30},{6,21}},
    bottle={{12,2},{21,2},{21,6},{19,6},{19,11},{26,17},{26,28},{7,28},{7,17},{14,11},{14,6},{12,6}},
    gun={{2,8},{30,8},{30,15},{18,15},{16,20},{12,20},{10,29},{3,27},{7,15},{2,15}},
    rifle={{2,15},{9,10},{28,10},{28,13},{32,13},{32,16},{20,16},{18,25},{14,25},{15,17},{8,17},{2,22}},
    crowbar={{8,30},{11,30},{22,9},{23,5},{20,2},{16,2},{12,5},{14,7},{18,5},{20,6},{19,9}},
    ring={{16,2},{22,7},{16,12},{10,7}},
    body={{13,1},{19,1},{21,6},{19,11},{25,14},{30,26},{26,28},{21,20},{21,33},{25,51},{20,52},{16,37},{12,52},{7,51},{11,33},{11,20},{6,28},{2,26},{7,14},{13,11},{11,6}}
}
-- surface.DrawPoly accepts convex polygons: triangulate silhouettes once.
local triangles={}
local function cross(a,b,c) return (b[1]-a[1])*(c[2]-a[2])-(b[2]-a[2])*(c[1]-a[1]) end
for name,points in pairs(shapes) do
    local indices,output={},{}
    local area=0
    for i,p in ipairs(points) do local q=points[i%#points+1];area=area+p[1]*q[2]-q[1]*p[2] end
    for i=1,#points do indices[i]=area>0 and i or #points-i+1 end
    while #indices>3 do
        local clipped=false
        for i,index in ipairs(indices) do
            local a,b,c=indices[(i-2)%#indices+1],index,indices[i%#indices+1]
            local clear=cross(points[a],points[b],points[c])>0
            if clear then for _,j in ipairs(indices) do
                if j~=a and j~=b and j~=c and cross(points[a],points[b],points[j])>=0
                    and cross(points[b],points[c],points[j])>=0 and cross(points[c],points[a],points[j])>=0 then clear=false;break end
            end end
            if clear then output[#output+1]={a,b,c};table.remove(indices,i);clipped=true;break end
        end
        assert(clipped,'Invalid equipment icon silhouette: '..name)
    end
    output[#output+1]={indices[1],indices[2],indices[3]};triangles[name]=output
end
local cache,cacheSize={},0
local function polygons(family,x,y,scale)
    local key=family..':'..x..':'..y..':'..scale
    if cache[key] then return cache[key] end
    if cacheSize>=64 then cache={};cacheSize=0 end
    local result={};local points=shapes[family]
    for i,triangle in ipairs(triangles[family]) do
        local poly={}
        for j,index in ipairs(triangle) do local p=points[index];poly[j]={x=x+p[1]*scale,y=y+p[2]*scale} end
        result[i]=poly
    end
    cache[key]=result;cacheSize=cacheSize+1;return result
end
function E:IconFamily(item)
    local id=item and item.definitionId or ''
    if id=='healing_potion' or id=='stink_bomb' then return 'bottle' end
    if id=='weapon_lod_crowbar' then return 'crowbar' end
    if id=='weapon_pistol' or id=='weapon_357' then return 'gun' end
    if self.Definitions[id] and self.Definitions[id].weapon then return 'rifle' end
    return shapes[id] and id or 'shield'
end
function E:DrawItemIcon(item,x,y,size,color,family)
    family=family or self:IconFamily(item)
    local points=shapes[family] or shapes.shield
    local scale=size/(family=='body' and 54 or 34)
    draw.NoTexture();surface.SetDrawColor(color)
    for _,polygon in ipairs(polygons(family,x,y,scale)) do surface.DrawPoly(polygon) end
    if family=='ring' then
        surface.DrawCircle(x+16*scale,y+20*scale,9*scale,color.r,color.g,color.b,color.a)
        surface.DrawCircle(x+16*scale,y+20*scale,6*scale,color.r,color.g,color.b,color.a)
    elseif item and item.definitionId=='healing_potion' then
        surface.SetDrawColor(LOD.UI.Colors.light)
        surface.DrawRect(x+14*scale,y+16*scale,4*scale,10*scale)
        surface.DrawRect(x+11*scale,y+19*scale,10*scale,4*scale)
    elseif item and item.definitionId=='stink_bomb' then
        draw.SimpleText('!','LOD_SheetKey',x+16*scale,y+15*scale,LOD.UI.Colors.light,TEXT_ALIGN_CENTER)
    elseif item and item.definitionId=='weapon_357' then
        surface.DrawCircle(x+16*scale,y+13*scale,4*scale,251,247,233,255)
    end
end
