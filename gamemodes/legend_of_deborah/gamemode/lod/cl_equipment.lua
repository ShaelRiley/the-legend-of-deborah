local E, UI = LOD.Equipment, LOD.UI
local C = UI.Colors
E.Snapshot = {items={}, slots={}}
E.HasSnapshot = false

function E:Request(action, id, slot)
    if LOD.UI.IsMinigameLocked and LOD.UI:IsMinigameLocked() then return false end
    net.Start("LOD_EquipmentRequest")
    net.WriteString(action)
    net.WriteString(id or "")
    net.WriteString(slot or "")
    net.SendToServer()
end

-- Cache on the entity object, never its recyclable EntIndex. Retry a request
-- after entering PVS/reconnecting; records never reroll on inspection.
function E:PickupView(ent)
    if LOD.UI.IsMinigameLocked and LOD.UI:IsMinigameLocked() then return false end
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

-- Pickup comparison is retired. Show the full name, without replacement prompts.
local nameCache
function E:PickupNameLayout(ent,name,width)
    if nameCache and nameCache.entity==ent and nameCache.name==name and nameCache.width==width then return nameCache end
    surface.SetFont("Trebuchet24")
    local lines,line={},""
    for word in name:gmatch("%S+") do
        local nextLine=line=="" and word or line.." "..word
        if line~="" and surface.GetTextSize(nextLine)>width then lines[#lines+1]=line;line=word else line=nextLine end
    end
    if line~="" then lines[#lines+1]=line end
    nameCache={entity=ent,name=name,width=width,lines=lines};return nameCache
end
local target,nextScan=nil,0
hook.Add("HUDPaint","LOD_EquipmentComparison",function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or UI.ActivePage then target=nil;return end
    if CurTime()>=nextScan then
        nextScan=CurTime()+.15
        target=LOD.NearLook:Find(ply,512,function(e) return e:GetClass()=="lod_loot_pickup" end)
    end
    if not IsValid(target) or not LOD.NearLook:Qualifies(ply,target,512) then return end
    local name=target:GetNW2String("LOD_LootName","")
    if name=="" then return end
    local layout=E:PickupNameLayout(target,name,math.min(900,ScrW()-48))
    for i,line in ipairs(layout.lines) do
        draw.SimpleTextOutlined(line,"Trebuchet24",ScrW()*.5,ScrH()*.58+(i-1)*26,
            color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,230))
    end
end)
hook.Add("PreCleanupMap","LOD_EquipmentComparisonCleanup",function() nameCache=nil;target=nil;nextScan=0 end)

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

-- Full carried-item names live on Equipment. Remove the old hook on Lua refresh
-- too, so it cannot remain underneath the relocated character portrait.
hook.Remove("HUDPaint", "LOD_ProceduralWeaponName")

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
    bottle:SetModelScale(def.heldScale or 0.65,0)
    bottle:SetColor(def.heldColor or Color(130,235,160))
    bottle:SetupBones()
    cam.IgnoreZ(true); bottle:DrawModel(); cam.IgnoreZ(false)
end)
hook.Add("ShutDown", "LOD_EquipmentCleanup", function() if IsValid(bottle) then bottle:Remove() end end)
