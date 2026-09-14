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
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(24, 88)
    scroll:SetSize(frame:GetWide()-48, frame:GetTall()-200)
    local content = vgui.Create("DPanel", scroll)
    content:Dock(TOP)
    content:SetTall(460)
    content.Paint = function(_, w)
        draw.SimpleText("EQUIPMENT", "LOD_SheetSubheading", 0, 0, C.red)
        for i, slot in ipairs(E.SlotOrder) do
            local item = E:Equipped(E.Snapshot, slot)
            local def = E:Definition(item)
            draw.SimpleText(E.SlotLabels[slot], "LOD_SheetBody", 0, 26+i*27, C.blue)
            draw.SimpleText(def and (def.name .. " ×" .. item.count) or "Empty", "LOD_SheetBody", w*0.48, 26+i*27, C.ink)
        end
        draw.SimpleText("ITEMS", "LOD_SheetSubheading", 0, 288, C.red)
    end
    local ids = {}
    for id in pairs(E.Snapshot.items) do ids[#ids+1] = id end
    table.sort(ids)
    local y = 320
    for _, id in ipairs(ids) do
        local item = E.Snapshot.items[id]
        local def = E:Definition(item)
        if def then
            local label = vgui.Create("DLabel", content)
            label:SetPos(0,y); label:SetSize(frame:GetWide()-60,48)
            label:SetFont("LOD_SheetSmall"); label:SetTextColor(C.ink)
            label:SetWrap(true); label:SetText(def.name .. " ×" .. item.count .. " — " .. def.description)
            local equipped = E.Snapshot.slots.throwable == id
            local button = vgui.Create("DButton", content)
            button:SetPos(0,y+52); button:SetSize(155,30)
            button:SetText(equipped and "Hold Throwable" or "Equip Throwable")
            button.DoClick = function()
                E:Request(equipped and "activate" or "equip", id, "throwable")
                if equipped then LOD.Spellbook:Close() end
            end
            if equipped then
                local unequip = vgui.Create("DButton", content)
                unequip:SetPos(165,y+52); unequip:SetSize(120,30); unequip:SetText("Unequip")
                unequip.DoClick = function() E:Request("unequip", "", "throwable") end
            end
            y = y + 96
        end
    end
    content:SetTall(math.max(360,y))
end

net.Receive("LOD_EquipmentSnapshot", function()
    local state = net.ReadTable()
    if not istable(state) or not istable(state.items) or not istable(state.slots) then return end
    E.Snapshot = state
    if LOD.Spellbook.EquipmentPage and IsValid(LOD.Spellbook.Frame) then LOD.Spellbook:Open() end
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
