local E, UI = LOD.Equipment, LOD.UI
local directions={"UP","DOWN","LEFT","RIGHT"}
local primary={KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT}
local defaults={KEY_LBRACKET,KEY_COMMA,KEY_SEMICOLON,KEY_BACKSLASH}
local mirrors={}
for i,id in ipairs(directions) do
    mirrors[i]=CreateClientConVar("lod_special_key_"..string.lower(id),tostring(defaults[i]),true,false,
        "Special Move keyboard mirror: "..id)
end
local held, wasBusy={},true
local function send(token)
    net.Start("LOD_SpecialMoveToken");net.WriteUInt(token,3);net.SendToServer()
end
function E:SpecialInputBusy()
    local ply=LocalPlayer()
    return not IsValid(ply) or not ply:Alive() or self:IsActive(ply)
        or gui.IsGameUIVisible() or gui.IsConsoleVisible() or vgui.CursorVisible()
        or IsValid(vgui.GetKeyboardFocus()) or chat.IsTyping and chat.IsTyping()
        or UI.ActivePage ~= nil
end
-- No joystick/D-pad API feeds this stream. GLua cannot distinguish OS-level
-- keyboard emulation; do not map Steam Input to the Special Move keyboard keys.
hook.Add("Think","LOD_SpecialMoveKeyboard",function()
    local busy=E:SpecialInputBusy()
    if busy and not wasBusy then send(0) end
    local pressed={}
    for i=1,4 do
        local mirror=mirrors[i]:GetInt()
        local down=input.IsKeyDown(primary[i])
        if mirror>=KEY_0 and mirror<=KEY_SCROLLLOCK then down=down or input.IsKeyDown(mirror) end
        if down and not held[i] then pressed[#pressed+1]=i end
        held[i]=down
    end
    if not busy then
        if #pressed==1 then send(pressed[1]) elseif #pressed>1 then send(0) end
    end
    wasBusy=busy
end)

function E:BuildMoveBindings(parent,y,width)
    local heading=vgui.Create("DLabel",parent)
    heading:SetPos(0,y);heading:SetSize(width,24);heading:SetText("Special Moves: arrow keys or rebindable keyboard mirror")
    heading:SetFont("LOD_SheetSmall");heading:SetTextColor(UI.Colors.ink)
    for i,id in ipairs(directions) do
        local binder=vgui.Create("DBinder",parent)
        binder:SetPos((i-1)*width/4,y+28);binder:SetSize(width/4-6,30)
        binder:SetValue(mirrors[i]:GetInt());binder:SetTooltip(id)
        binder.OnChange=function(_,key)
            if key>=KEY_0 and key<=KEY_SCROLLLOCK then RunConsoleCommand("lod_special_key_"..string.lower(id),tostring(key)) end
        end
        local label=vgui.Create("DLabel",parent)
        label:SetPos((i-1)*width/4,y+60);label:SetSize(width/4-6,20);label:SetText(id)
        label:SetTextColor(UI.Colors.ink)
    end
    return y+94
end

local blockUntil=0
net.Receive("LOD_BlockPulse",function() blockUntil=CurTime()+0.16 end)
hook.Add("HUDPaint","LOD_BlockFlash",function()
    local remaining=blockUntil-CurTime()
    if remaining<=0 then return end
    local alpha=remaining/0.16
    surface.SetDrawColor(130,190,235,22*alpha);surface.DrawRect(0,0,ScrW(),ScrH())
    local x,y=ScrW()/2,ScrH()/2
    surface.SetDrawColor(160,215,255,200*alpha)
    surface.DrawLine(x-18,y-16,x+18,y-16);surface.DrawLine(x-18,y-16,x-14,y+12)
    surface.DrawLine(x+18,y-16,x+14,y+12);surface.DrawLine(x-14,y+12,x,y+24);surface.DrawLine(x+14,y+12,x,y+24)
end)
net.Receive("LOD_SpecialMoveFX",function()
    local actor,id=net.ReadEntity(),net.ReadString()
    if not IsValid(actor) or not E.SpecialMoves[id] then return end
    local fx=EffectData();fx:SetOrigin(actor:WorldSpaceCenter());fx:SetScale(1)
    util.Effect(id=="quickstep" and "cball_bounce" or "ManhackSparks",fx)
end)
