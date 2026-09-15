local E, UI = LOD.Equipment, LOD.UI
local C = UI.Colors
E.Snapshot = {items={}, slots={}}

function E:Request(action, id, slot)
    net.Start("LOD_EquipmentRequest")
    net.WriteString(action)
    net.WriteString(id or "")
    net.WriteString(slot or "")
    net.SendToServer()
end

function E:BuildPanel(frame)
    local scroll=vgui.Create("DScrollPanel",frame)
    scroll:SetPos(24,88);scroll:SetSize(frame:GetWide()-48,frame:GetTall()-200)
    local content=vgui.Create("DPanel",scroll)
    content:Dock(TOP);content.Paint=function() end
    local width=frame:GetWide()-84
    local y=0
    local function label(text,font)
        local panel=vgui.Create("DLabel",content)
        panel:SetPos(0,y);panel:SetWide(width);panel:SetFont(font or "LOD_SheetSmall")
        panel:SetTextColor(C.ink);panel:SetWrap(true);panel:SetAutoStretchVertical(true);panel:SetText(text)
        -- Measure wrapped lines now so controls never overlap asynchronous layout.
        surface.SetFont(font or "LOD_SheetSmall")
        local lines,line=1,""
        for word in text:gmatch("%S+") do
            local test=line=="" and word or line.." "..word
            if surface.GetTextSize(test)>width then lines=lines+1;line=word else line=test end
        end
        local _,height=surface.GetTextSize("Ag")
        y=y+lines*height+10
    end
    label("EQUIPMENT", "LOD_SheetSubheading")
    for _,slot in ipairs(E.SlotOrder) do
        local item=E:Equipped(E.Snapshot,slot)
        label(E.SlotLabels[slot]..": "..(item and E:ItemName(item) or "Empty"))
    end
    local _,moves,block=E:Contributions(E.Snapshot)
    label(string.format("Combined Block: %.0f%% (33%% cap)",block*100))
    for _,id in ipairs(E.MoveOrder) do
        local move=E.SpecialMoves[id]
        if moves[id] then label(string.format("%s %s | %d base Magic | %gs cooldown — %s",
            move.name,move.glyphs,move.magicCost,move.cooldown,move.description)) end
    end
    if E.BuildMoveBindings then y=E:BuildMoveBindings(content,y,width) end
    label("OWNED ITEMS", "LOD_SheetSubheading")
    label("Up to 32 equipment records. Unequip unwanted clothing, then Discard to make room. Only your active weapon contributes.")
    local ids={};for id in pairs(E.Snapshot.items) do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids) do
        local item=E.Snapshot.items[id]
        local def=E:Definition(item)
        if def then
            label(E:ItemName(item)..(def.throwable and " ×"..item.count or " | value "..E:Value(item)))
            label(E:Description(item))
            local equippedSlot
            for _,slot in ipairs(E.SlotOrder) do if E.Snapshot.slots[slot]==id then equippedSlot=slot;break end end
            local button=vgui.Create("DButton",content)
            button:SetPos(0,y);button:SetSize(180,30)
            button:SetText(def.weapon and "Select Weapon" or (equippedSlot and (def.throwable and "Hold Throwable" or "Unequip") or "Equip"))
            button.DoClick=function()
                if def.weapon then
                    local weapon=LocalPlayer():GetWeapon(def.weaponClass)
                    if IsValid(weapon) then input.SelectWeapon(weapon);LOD.Spellbook:Close() end
                    return
                end
                if equippedSlot then
                    E:Request(def.throwable and "activate" or "unequip",id,equippedSlot)
                    if def.throwable then LOD.Spellbook:Close() end
                else E:Request("equip",id,E:Placement(E.Snapshot,item)) end
            end
            if def.throwable and equippedSlot then
                local remove=vgui.Create("DButton",content)
                remove:SetPos(190,y);remove:SetSize(120,30);remove:SetText("Unequip")
                remove.DoClick=function() E:Request("unequip",id,equippedSlot) end
            elseif item.definitionId=="ring" then
                local right=vgui.Create("DButton",content)
                right:SetPos(190,y);right:SetSize(140,30);right:SetText("Equip Right Hand")
                right.DoClick=function() E:Request("equip",id,"right_hand") end
            end
            if def.wearable and not equippedSlot then
                local discard=vgui.Create("DButton",content)
                discard:SetPos(340,y);discard:SetSize(100,30);discard:SetText("Discard")
                discard.DoClick=function() E:Request("discard",id,"") end
            end
            y=y+44
        end
    end
    content:SetTall(y+16)
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

-- World pickup and inventory share the item name/property/value formatter.
hook.Add("HUDPaint","LOD_EquipmentComparison",function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or UI.ActivePage then return end
    local trace=ply:GetEyeTrace()
    local ent=trace.Entity
    if not IsValid(ent) or ent:GetClass()~="lod_loot_pickup"
        or ply:GetPos():DistToSqr(ent:GetPos())>128*128 then return end
    local item=E:PickupView(ent)
    if not E:ValidateWearable(item) then return end
    local slot,displaced,oldValue=E:Placement(E.Snapshot,item)
    local lines={E:ItemName(item),E:Description(item,true)}
    for _,id in ipairs(displaced) do
        local old=E.Snapshot.items[id]
        lines[#lines+1]="Replaces "..E:ItemName(old)..": "..E:Description(old,true)
    end
    lines[#lines+1]=string.format("Value %g → %g (%+g) — approximate comparison",oldValue,E:Value(item),E:Value(item)-oldValue)
    lines[#lines+1]=#displaced>0 and "E: ACCEPT REPLACEMENT" or "Touch or E: EQUIP"
    local width=math.min(900,ScrW()-40)
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
    local height=#wrapped*18+20
    local x,y=20,math.max(20,ScrH()-height-70)
    draw.RoundedBox(4,x,y,width,height,Color(20,27,32,235))
    for i,text in ipairs(wrapped) do draw.SimpleText(text,"DermaDefault",x+12,y+10+(i-1)*18,Color(235,239,245)) end
end)

net.Receive("LOD_EquipmentSnapshot", function()
    local state = net.ReadTable()
    if not istable(state) or not istable(state.items) or not istable(state.slots) then return end
    E.Snapshot = state
    if LOD.Spellbook.EquipmentPage and IsValid(LOD.Spellbook.Frame) then LOD.Spellbook:Open() end
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
