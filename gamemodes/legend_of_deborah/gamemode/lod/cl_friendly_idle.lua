-- Living service actors, without NPC weapon activities or a server animation
-- loop. Stock player counterparts retain the face with an unarmed sequence.
LOD.FriendlyIdle = LOD.FriendlyIdle or {}
local I = LOD.FriendlyIdle
I.Version = 'unarmed-service-idle-20261013-2'
local profiles = {
    hermit = {rate = .85, smile = .55, nod = 4, glance = 3, period = 9},
    game_master = {rate = .92, smile = .4, nod = 3, glance = 5, period = 7},
    scavenger = {rate = .65, smile = 0, nod = 1.5, glance = 2, period = 11},
    surveyor = {rate = .78, smile = .12, nod = 2, glance = 9, period = 10}
}
local sequenceNames = {'idle_all_01', 'idle_all_02', 'menu_combine'}
local boneNames = {'Spine2', 'Neck1', 'Head1', 'L_UpperArm', 'L_Forearm', 'L_Hand',
    'R_UpperArm', 'R_Forearm', 'R_Hand'}
local function clearPose(ent, state)
    -- Role changes and Lua refresh must not accumulate our additive offsets.
    local boneCount, flexCount = ent:GetBoneCount(), math.min(96, ent:GetFlexNum())
    for _, bone in pairs(state.bones) do
        if bone < boneCount then ent:ManipulateBoneAngles(bone, angle_zero) end
    end
    for _, ids in pairs(state.flexes) do
        for _, id in ipairs(ids) do if id < flexCount then ent:SetFlexWeight(id, 0) end end
    end
end
local function discover(ent, role, model)
    local previous = ent.LODFriendlyIdle
    if previous then clearPose(ent, previous) end
    local state = {model = model, role = role, version = I.Version, bones = {},
        flexes = {smile = {}, blink = {}, cheek = {}}, nextDetail = 0}
    local id = ent:EntIndex()
    state.phase = (id % 97) * .37
    state.blinkCount = 0
    state.nextBlink = CurTime() + 1 + (id % 7) * .41
    for _, name in ipairs(sequenceNames) do
        local sequence, duration = ent:LookupSequence(name)
        if sequence and sequence >= 0 and duration and duration > 0 then
            state.sequence, state.duration, state.name = sequence, duration, name
            ent:ResetSequence(sequence)
            break
        end
    end
    -- Never guess sequence zero, an activity, or a generic Grigory gun idle.
    -- This property is what base_anim's Lua setter writes. A DModelPanel's
    -- native ClientsideModel does not inherit that scripted-entity method.
    ent.AutomaticFrameAdvance = false
    ent:SetPlaybackRate(0) -- elapsed-time SetCycle below is the sole clock
    for _, name in ipairs(boneNames) do
        local bone = ent:LookupBone('ValveBiped.Bip01_' .. name)
        if bone then state.bones[name] = bone end
    end
    for id = 0, math.min(96, ent:GetFlexNum()) - 1 do
        local name = string.lower(ent:GetFlexName(id) or '')
        local group = (name == 'blink' or name:find('lid_closer', 1, true)) and 'blink'
            or (name:find('smile', 1, true) or name:find('corner_puller', 1, true)) and 'smile'
            or name:find('cheek_raiser', 1, true) and 'cheek'
        if group then state.flexes[group][#state.flexes[group] + 1] = id end
    end
    ent.LODFriendlyIdle = state
    return state
end
local function boneAngle(ent, state, name, p, y, r)
    local bone = state.bones[name]
    if bone then ent:ManipulateBoneAngles(bone, Angle(p, y, r)) end
end
local function flex(ent, state, role, weight)
    for _, id in ipairs(state.flexes[role]) do ent:SetFlexWeight(id, weight) end
end
local function pulse(t, period, width)
    local u = t % period
    return u < width and (.5 - .5 * math.cos(u / width * math.pi * 2)) or 0
end
function I:Apply(ent, role, portrait)
    local profile = profiles[role]
    if not profile or not IsValid(ent) then return false end
    local model = ent:GetModel()
    local state = ent.LODFriendlyIdle
    if not state or state.model ~= model or state.role ~= role or state.version ~= self.Version then
        state = discover(ent, role, model)
    end
    if not state.sequence then return false end
    -- Draw and DrawTranslucent/model-panel passes can paint twice in one frame.
    local frame = FrameNumber()
    if state.frame == frame then return true end
    state.frame = frame
    local now = CurTime()
    if ent:GetSequence() ~= state.sequence then ent:ResetSequence(state.sequence) end
    ent:SetCycle(((now * profile.rate + state.phase) / state.duration) % 1)
    if not portrait and ent:GetPos():DistToSqr(EyePos()) > 1024 * 1024 then return true end
    if now < state.nextDetail then return true end
    local reduced = GetConVar('lod_reduced_effects')
    state.nextDetail = now + (reduced and reduced:GetBool() and .1 or .05)
    local t = now + state.phase
    local invite = pulse(t, profile.period, 3)
    local nod = pulse(t + 2, profile.period + 2, 1.4) * profile.nod
    local breath = math.sin(t * 1.8)
    local glance = math.sin(t * .43) * profile.glance
    boneAngle(ent, state, 'Spine2', .3 * breath, 0, role == 'scavenger' and 2 or .5 * breath)
    boneAngle(ent, state, 'Neck1', 0, glance * .25, 0)
    boneAngle(ent, state, 'Head1', nod, glance, role == 'game_master' and 3 * invite or 0)
    if role == 'scavenger' then
        boneAngle(ent, state, 'R_UpperArm', -8, 12, 18 + breath)
        boneAngle(ent, state, 'R_Forearm', 0, 40, 5)
        boneAngle(ent, state, 'R_Hand', 0, 0, -10)
    else
        -- Modest palm-up movement over the unarmed base, never a gun grip.
        local amount = role == 'surveyor' and invite * .45 or invite
        boneAngle(ent, state, 'L_UpperArm', -8 * amount, -12 * amount, -24 * amount)
        boneAngle(ent, state, 'L_Forearm', 0, -38 * amount, -10 * amount)
        boneAngle(ent, state, 'L_Hand', 0, 0, 20 * amount)
    end
    if now >= state.nextBlink then
        state.blinkStart = now
        state.blinkCount = state.blinkCount + 1
        state.nextBlink = now + 3 + (1 + math.sin(state.phase + state.blinkCount * 2.4)) * 1.2
    end
    local elapsed = state.blinkStart and now - state.blinkStart or 1
    local blink = elapsed < .22 and math.sin(math.max(0, elapsed) / .22 * math.pi) or 0
    flex(ent, state, 'blink', blink)
    flex(ent, state, 'smile', profile.smile * (1 + .12 * invite))
    flex(ent, state, 'cheek', profile.smile * .3)
    return true
end
