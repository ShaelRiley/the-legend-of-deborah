LOD = LOD or {}
LOD.MagicFX = LOD.MagicFX or {waves = {}}

local FX = LOD.MagicFX
FX.waves = FX.waves or {}
local A=LOD.MagicArea
local beamMaterial=A.Material
local glowMaterial=Material("sprites/light_glow02_add")
local buttonHeld = {}
local wallArmed = {}
local localCastUntil = 0
function FX:ViewModelHidden() return CurTime()<localCastUntil end

local function activePlayer()
    local ply = LocalPlayer()
    return IsValid(ply) and ply:Alive() and ply:GetNW2Bool("LOD_PlayedIdentity", false) and ply or nil
end

local function inputCovered()
    return LOD.UI and LOD.UI.ActivePage or gui.IsGameUIVisible() or gui.IsConsoleVisible()
        or vgui.CursorVisible() or IsValid(vgui.GetKeyboardFocus())
        or (chat and chat.IsTyping and chat.IsTyping())
end
local function requestCast(button)
    net.Start("LOD_MagicCastRequest");net.WriteUInt(button,3);net.SendToServer()
end
local function boundForm(snapshot,button)
    return snapshot and (snapshot.bindings and snapshot.bindings[tostring(button)]
        or button==2 and snapshot.selectedFormId) or nil
end
function FX:WallAimActive()
    local button=self.WallAimButton
    local snapshot=LOD.Spellbook and LOD.Spellbook.Snapshot
    local ply=activePlayer()
    return button and wallArmed[button] and boundForm(snapshot,button)=='wall'
        and ply and not inputCovered() and not (LOD.Equipment and LOD.Equipment:IsActive(ply))
        and button or nil
end
hook.Add("CreateMove", "LOD_MagicPredictedInput", function(cmd)
    local ply=activePlayer()
    local covered=inputCovered()
    local throwable=ply and LOD.Equipment and LOD.Equipment:IsActive(ply)
    local allowed=ply and not covered and not throwable
    local snapshot=LOD.Spellbook and LOD.Spellbook.Snapshot
    local down={[2]=cmd:KeyDown(IN_ATTACK2),[3]=input.IsMouseDown(MOUSE_MIDDLE),
        [4]=input.IsMouseDown(MOUSE_4),[5]=input.IsMouseDown(MOUSE_5)}
    FX.WallAimButton=nil
    for button=2,5 do
        local held=down[button]
        local form=boundForm(snapshot,button)
        -- Covering the game, losing the form, or changing role/life cancels the
        -- gesture. Closing a menu while still holding cannot re-arm it.
        if not allowed or form~='wall' then wallArmed[button]=nil end
        if allowed and held and not buttonHeld[button] then
            if form=='wall' then wallArmed[button]=true
            elseif form then requestCast(button) end
        elseif not held and buttonHeld[button] then
            if allowed and wallArmed[button] and form=='wall' then requestCast(button) end
            wallArmed[button]=nil
        end
        if held and wallArmed[button] then FX.WallAimButton=button end
        buttonHeld[button]=held
    end
    if not throwable or covered then cmd:RemoveKey(IN_ATTACK2) end
    if covered then cmd:RemoveKey(IN_ATTACK) end
end)
hook.Add("PreCleanupMap","LOD_WallAimCancel",function()
    wallArmed={};FX.WallAimButton=nil
end)
-- Consume native bind actions for assigned auxiliary buttons (e.g. +zoom).
hook.Add("PlayerBindPress","LOD_MagicAuxiliaryBindings",function(ply,bind,pressed,code)
    local snapshot=LOD.Spellbook and LOD.Spellbook.Snapshot
    local button=({[MOUSE_MIDDLE]=3,[MOUSE_4]=4,[MOUSE_5]=5})[code]
    if button and snapshot and snapshot.bindings and snapshot.bindings[tostring(button)] then return true end
end)

net.Receive("LOD_MagicShoutFX", function()
    local caster = net.ReadEntity()
    local origin = net.ReadVector()
    local direction = net.ReadVector()
    if direction == vector_origin then return end
    direction = direction:GetNormalized()

    while #FX.waves>=12 do table.remove(FX.waves,1) end
    FX.waves[#FX.waves + 1] = {
        caster = caster,
        origin = origin,
        direction = direction,
        started = CurTime(),
        lifetime = 0.55
    }

    if caster == LocalPlayer() then
        localCastUntil = CurTime() + 0.28
        -- Do not force ACT_VM_PRIMARYATTACK on the active weapon here. Stock HL2
        -- SWEPs can retain/replay that sequence after a Magic cast, producing a
        -- phantom firing animation with no shot. The server-authored player
        -- gesture and force-wave FX carry the cast presentation instead.
        LOD.Audio:Play('cast')
    end
end)

-- Briefly clear the held first-person viewmodel during the cast. We deliberately
-- do not drive a firearm animation sequence; RMB belongs to Magic, not alt-fire.
hook.Add("PreDrawViewModel", "LOD_MagicHideWeaponDuringCast", function()
    if CurTime() < localCastUntil then return true end
end)

local function ringBasis(direction)
    local ang = direction:Angle()
    return ang:Right(), ang:Up()
end

local function drawRing(origin, direction, distance, alpha, width)
    if distance <= 0 then return end
    local right, up = ringBasis(direction)
    local center = origin + direction * distance
    local radius = math.max(18, distance * math.tan(math.rad(30)))
    local segments = 24
    local previous

    A:Disc(center,radius,right,up,Color(155,225,255,math.floor(alpha*.4)))
    render.SetMaterial(beamMaterial)
    for i = 0, segments do
        local theta = (i / segments) * math.pi * 2
        local point = center + right * math.cos(theta) * radius + up * math.sin(theta) * radius
        if previous then
            render.DrawBeam(previous, point, width, 0, 1, Color(155, 225, 255, alpha))
        end
        previous = point
    end

    render.SetMaterial(glowMaterial)
    render.DrawSprite(center, 22 + distance * 0.018, 22 + distance * 0.018,
        Color(190, 235, 255, math.floor(alpha * 0.6)))
end

hook.Add("PostDrawTranslucentRenderables", "LOD_MagicForceShoutWaves", function(depth,skybox)
    if depth or skybox then return end
    local now = CurTime()
    for i = #FX.waves, 1, -1 do
        local wave = FX.waves[i]
        local age = now - wave.started
        local progress = age / wave.lifetime
        if progress >= 1 then
            table.remove(FX.waves, i)
        else
            local fade = math.Clamp(1 - progress, 0, 1)
            local alpha = math.floor(255 * fade)
            local distance = 80 + progress * 980
            drawRing(wave.origin, wave.direction, distance, alpha, 10 * fade + 2)

            local trailing = math.Clamp(progress - 0.14, 0, 1)
            local reduced=GetConVar("lod_reduced_effects")
            if trailing > 0 and not (reduced and reduced:GetBool()) then
                drawRing(wave.origin, wave.direction, 50 + trailing * 900,
                    math.floor(255 * fade), 6 * fade + 1)
            end
        end
    end
end)


local function clearWaves() FX.waves={};localCastUntil=0 end
hook.Add("PostCleanupMap","LOD_MagicShoutCleanup",clearWaves)
hook.Add("ShutDown","LOD_MagicShoutShutdown",clearWaves)
