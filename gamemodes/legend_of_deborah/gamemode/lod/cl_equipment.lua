local E, UI = LOD.Equipment, LOD.UI
local C = UI.Colors
E.Snapshot = {items={}, slots={}}
E.HasSnapshot = false

function E:Request(action, id, slot)
    net.Start("LOD_EquipmentRequest")
    net.WriteString(action)
    net.WriteString(id or "")
    net.WriteString(slot or "")
    net.SendToServer()
end

-- Cache on the entity object, never its recyclable EntIndex. Retry a request
-- after entering PVS/reconnecting; records never reroll on inspection.
function E:PickupView(ent)
    if ent.LODItemView then return ent.LODItemView end
    local now=CurTime()
    if now>=(self.NextInspect or 0) then
        self.NextInspect=now+.5
        net.Start("LOD_EquipmentInspect")
        net.WriteEntity(ent)
        net.SendToServer()
    end
end
net.Receive("LOD_EquipmentInspect",function()
    local ent,item=net.ReadEntity(),net.ReadTable()
    if IsValid(ent) and ent:GetClass()=="lod_loot_pickup" and E:ValidateWearable(item) then
        ent.LODItemView=item
    end
end)

-- One layout, not a growing history of inspected equipment. Item records and
-- received snapshots are replaced atomically; either change invalidates it.
local comparison
local comparisonBackground=Color(20,27,32,235)
local comparisonInk=Color(235,239,245)
function E:ComparisonLayout(ent,item,width)
    if comparison and comparison.entity==ent and comparison.item==item
        and comparison.snapshot==self.Snapshot and comparison.width==width then return comparison end
    comparison=nil
    if not E:ValidateWearable(item) then return end
    local slot,displaced,oldValue=E:Placement(E.Snapshot,item)
    local lines={E:ItemName(item),E:Description(item,true)}
    for _,id in ipairs(displaced) do
        local old=E.Snapshot.items[id]
        lines[#lines+1]="Replaces "..E:ItemName(old)..": "..E:Description(old,true)
    end
    lines[#lines+1]=string.format("Value %g → %g (%+g) — approximate comparison",oldValue,E:Value(item),E:Value(item)-oldValue)
    lines[#lines+1]=#displaced>0 and "E: ACCEPT REPLACEMENT" or "Touch or E: EQUIP"
    surface.SetFont("DermaDefault")
    local wrapped={}
    for _,text in ipairs(lines) do
        local line=""
        for word in text:gmatch("%S+") do
            local nextLine=line=="" and word or line.." "..word
            if surface.GetTextSize(nextLine)>width-24 then wrapped[#wrapped+1]=line;line=word else line=nextLine end
        end
        wrapped[#wrapped+1]=line
    end
    comparison={entity=ent,item=item,snapshot=self.Snapshot,width=width,lines=wrapped,height=#wrapped*18+20}
    return comparison
end

-- World pickup and inventory share the item name/property/value formatter.
hook.Add("HUDPaint","LOD_EquipmentComparison",function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or UI.ActivePage then comparison=nil;return end
    local ent=ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass()~="lod_loot_pickup"
        or ply:GetPos():DistToSqr(ent:GetPos())>128*128 then comparison=nil;return end
    local layout=E:ComparisonLayout(ent,E:PickupView(ent),math.min(900,ScrW()-40))
    if not layout then return end
    local height=layout.height
    local x,y=20,math.max(20,ScrH()-height-70)
    draw.RoundedBox(4,x,y,layout.width,height,comparisonBackground)
    for i,text in ipairs(layout.lines) do draw.SimpleText(text,"DermaDefault",x+12,y+10+(i-1)*18,comparisonInk) end
end)
hook.Add("PreCleanupMap","LOD_EquipmentComparisonCleanup",function() comparison=nil end)

net.Receive("LOD_EquipmentSnapshot", function()
    local state = net.ReadTable()
    if istable(state) and state.equipmentDelta then
        if not E.HasSnapshot then E:Request("snapshot");return end
        local patch, removed=state.state,state.removed
        if not istable(patch) or not istable(patch.items) or not istable(patch.slots) or not istable(removed) then return end
        -- Copy only the item index; immutable rolls can be shared between views.
        -- A fresh snapshot identity also invalidates the comparison layout.
        local items={}
        for id,item in pairs(E.Snapshot.items) do items[id]=item end
        for _,id in ipairs(removed) do items[id]=nil end
        for id,item in pairs(patch.items) do items[id]=item end
        patch.items=items
        state=patch
    end
    if not istable(state) or not istable(state.items) or not istable(state.slots) then return end
    E.Snapshot = state
    E.HasSnapshot = true
    comparison=nil
    if E.RefreshInventory then E:RefreshInventory() end
end)

hook.Add("HUDPaint","LOD_ProceduralWeaponName",function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or UI.ActivePage then return end
    local weapon=ply:GetActiveWeapon()
    if not IsValid(weapon) then return end
    local name=weapon:GetNW2String("LOD_ItemName","")
    if name~="" then draw.SimpleText(name,"DermaDefault",ScrW()*.5,ScrH()-48,Color(235,220,170),TEXT_ALIGN_CENTER) end
end)

hook.Add("HUDPaint", "LOD_ThrowableControls", function()
    local ply = LocalPlayer()
    if not E:IsActive(ply) then return end
    local def = E.Definitions[ply:GetNW2String("LOD_ThrowableItem", "")]
    if not def then return end
    local x,y = ScrW()*0.5, ScrH()*0.78
    UI:HUDText(def.name .. " ×" .. ply:GetNW2Int("LOD_ThrowableCount",0), "HudHintTextLarge", x,y,UI.HUDColor,TEXT_ALIGN_CENTER)
    UI:HUDText(E:Prompt(def), "HudHintTextLarge", x,y+22,UI.HUDColor,TEXT_ALIGN_CENTER)
end)

local bottle
hook.Add("PostDrawTranslucentRenderables", "LOD_HeldPotion", function(_, sky)
    if sky then return end
    local ply = LocalPlayer()
    if not E:IsActive(ply) or ply:ShouldDrawLocalPlayer() then return end
    local def = E.Definitions[ply:GetNW2String("LOD_ThrowableItem", "")]
    if not def then return end
    if not IsValid(bottle) then
        bottle = ClientsideModel(def.model, RENDERGROUP_TRANSLUCENT)
        if not IsValid(bottle) then return end
        bottle:SetNoDraw(true)
    end
    if bottle:GetModel() ~= def.model then bottle:SetModel(def.model) end
    local angles = EyeAngles()
    bottle:SetPos(EyePos()+angles:Forward()*14+angles:Right()*6-angles:Up()*5)
    bottle:SetAngles(Angle(0,angles.y+90,15))
    bottle:SetModelScale(0.65,0)
    bottle:SetColor(Color(130,235,160))
    bottle:SetupBones()
    cam.IgnoreZ(true); bottle:DrawModel(); cam.IgnoreZ(false)
end)
hook.Add("ShutDown", "LOD_EquipmentCleanup", function() if IsValid(bottle) then bottle:Remove() end end)
