LOD = LOD or {}
LOD.Magic = LOD.Magic or {}

local Magic = LOD.Magic
local RunManager = LOD.RunManager
local Rolls = LOD.CombatRolls
local Pushback = LOD.Pushback

local MAX_MAGIC = 100
local SHOUT_COST = 20
local REGEN_SECONDS = 60
local REGEN_TICK = 0.25
local REGEN_PER_TICK = MAX_MAGIC / (REGEN_SECONDS / REGEN_TICK)
local SHOUT_COOLDOWN = 0.85
local SHOUT_RANGE = 1100
local SHOUT_HALF_ANGLE = 30
local SHOUT_DOT = math.cos(math.rad(SHOUT_HALF_ANGLE))
local SHOUT_PUSH = 336
local SHOUT_PROFILE = {label = "FORCE SHOUT", source = "force shout", count = 1, sides = 6, exploding = 6}
local MAGIC_TIMER = "LOD_MagicRegen"

util.AddNetworkString("LOD_MagicCastRequest")
util.AddNetworkString("LOD_MagicShoutFX")

Magic.Stats = Magic.Stats or {casts = 0, targets = 0, damage = 0}
Magic.NextCast = Magic.NextCast or setmetatable({}, {__mode = "k"})

local GENERIC_SHOUTS = {
    male = {
        "vo/npc/male01/watchout.wav",
        "vo/npc/male01/getdown02.wav",
        "vo/npc/male01/overthere01.wav"
    },
    female = {
        "vo/npc/female01/watchout.wav",
        "vo/npc/female01/getdown02.wav",
        "vo/npc/female01/overthere01.wav"
    }
}

local CHARACTER_SHOUTS = {
    alyx = {pitch = 100, sounds = {
        "vo/npc/alyx/hurt04.wav", "vo/npc/alyx/hurt05.wav", "vo/npc/alyx/hurt06.wav"
    }},
    barney = {pitch = 96, sounds = {
        "vo/npc/barney/ba_pain01.wav", "vo/npc/barney/ba_pain02.wav", "vo/npc/barney/ba_pain03.wav"
    }},
    grigori = {pitch = 90, sounds = {
        "vo/ravenholm/monk_pain01.wav", "vo/ravenholm/monk_pain02.wav", "vo/ravenholm/monk_pain03.wav"
    }},
    breen = {pitch = 88},
    kleiner = {pitch = 108},
    eli = {pitch = 92},
    mossman = {pitch = 102, gender = "female"},
    odessa = {pitch = 95},
    male = {pitch = 100},
    female = {pitch = 105, gender = "female"}
}

local function playerState(ply)
    return RunManager and RunManager.GetPlayerState and RunManager:GetPlayerState(ply) or nil
end

local function characterGender(ps)
    local id = ps and ps.characterId or "male"
    local configured = LOD.Config and LOD.Config.Audio and LOD.Config.Audio.CharacterPain
    local entry = configured and configured[id]
    return entry and entry.gender or (CHARACTER_SHOUTS[id] and CHARACTER_SHOUTS[id].gender) or "male"
end

local function validSound(path)
    return path and file.Exists("sound/" .. path, "GAME")
end

local function chooseShout(ply, ps)
    local id = ps and ps.characterId or "male"
    local spec = CHARACTER_SHOUTS[id] or CHARACTER_SHOUTS.male
    local candidates = spec.sounds or {}
    local serial = (ply.LODMagicShoutSerial or 0) + 1
    ply.LODMagicShoutSerial = serial

    if #candidates > 0 then
        for offset = 0, #candidates - 1 do
            local index = ((serial + offset - 1) % #candidates) + 1
            if validSound(candidates[index]) then
                return candidates[index], spec.pitch or 100
            end
        end
    end

    local fallback = GENERIC_SHOUTS[characterGender(ps)] or GENERIC_SHOUTS.male
    for offset = 0, #fallback - 1 do
        local index = ((serial + offset + (ps and ps.ordinal or 1) - 2) % #fallback) + 1
        if validSound(fallback[index]) then
            return fallback[index], spec.pitch or 100
        end
    end
    return nil, spec.pitch or 100
end

function Magic:_Sync(ply, ps)
    if not IsValid(ply) then return end
    ps = ps or playerState(ply)
    local value = ps and tonumber(ps.magic) or MAX_MAGIC
    value = math.Clamp(value or MAX_MAGIC, 0, MAX_MAGIC)
    if ps then ps.magic = value end
    ply:SetNW2Float("LOD_Magic", value)
    ply:SetNW2Int("LOD_MagicMax", MAX_MAGIC)
end

function Magic:_EnsureState(ply)
    local ps = playerState(ply)
    if not ps then return nil end
    if ps.magic == nil then ps.magic = MAX_MAGIC end
    ps.magic = math.Clamp(tonumber(ps.magic) or MAX_MAGIC, 0, MAX_MAGIC)
    return ps
end

-- Magic is a campaign resource. Wrap admission/sync/apply rather than adding a
-- competing player-state authority to RunManager.
if RunManager and not RunManager.LODMagicWrapped then
    RunManager.LODMagicWrapped = true

    local baseAdmit = RunManager._AdmitIdentity
    function RunManager:_AdmitIdentity(ply)
        local ps = baseAdmit(self, ply)
        if ps and ps.magic == nil then ps.magic = MAX_MAGIC end
        if ps then Magic:_Sync(ply, ps) end
        return ps
    end

    local baseSync = RunManager._SyncPlayerVars
    function RunManager:_SyncPlayerVars(ply)
        baseSync(self, ply)
        Magic:_Sync(ply, self:GetPlayerState(ply))
    end

    local baseApply = RunManager.ApplyPlayerState
    function RunManager:ApplyPlayerState(ply)
        baseApply(self, ply)
        local ps = self:GetPlayerState(ply)
        if ps then
            if ps.magic == nil then ps.magic = MAX_MAGIC end
            Magic:_Sync(ply, ps)
        end
    end
end

local function lineClear(ply, hostile)
    local startPos = ply:GetShootPos()
    local endPos = hostile:WorldSpaceCenter()
    local weapon = ply:GetActiveWeapon()
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        mask = MASK_SOLID,
        filter = function(ent)
            if ent == ply or ent == weapon then return false end
            if IsValid(ent) and ent.LODHostile then return false end
            return true
        end
    })
    return not tr.Hit or tr.Fraction >= 0.995
end

local function rollExploding2d6()
    if not Rolls or not Rolls._RNG or not Rolls._RollExploding then return 2, {1, 1} end
    local rng = Rolls:_RNG("magic:force-shout")
    local total = 0
    local all = {}
    local capped = false
    for die = 1, 2 do
        local amount, values, _, chainCapped = Rolls:_RollExploding(SHOUT_PROFILE, rng)
        total = total + (amount or 0)
        all[#all + 1] = values or {}
        capped = capped or chainCapped == true
    end
    return math.max(2, total), all, capped
end

local function rollDetail(chains)
    local pieces = {}
    for _, chain in ipairs(chains or {}) do pieces[#pieces + 1] = table.concat(chain, ">") end
    return table.concat(pieces, " + ")
end

local function targetList(ply, direction)
    local targets = {}
    local origin = ply:GetShootPos()
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODHostile and not hostile.LODDead and hostile:Health() > 0 then
            local delta = hostile:WorldSpaceCenter() - origin
            local distSqr = delta:LengthSqr()
            if distSqr > 1 and distSqr <= SHOUT_RANGE * SHOUT_RANGE then
                local toTarget = delta:GetNormalized()
                if direction:Dot(toTarget) >= SHOUT_DOT and lineClear(ply, hostile) then
                    targets[#targets + 1] = hostile
                end
            end
        end
    end
    table.sort(targets, function(a, b)
        return origin:DistToSqr(a:WorldSpaceCenter()) < origin:DistToSqr(b:WorldSpaceCenter())
    end)
    return targets
end

function Magic:CastForceShout(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if RunManager and RunManager.IsActivePlayer and not RunManager:IsActivePlayer(ply) then return false end
    local state = RunManager and RunManager.State
    if not state or state.Failed or state.LevelCleared or state.SimulationFrozen then return false end

    local ps = self:_EnsureState(ply)
    if not ps then return false end
    local now = CurTime()
    if now < (self.NextCast[ply] or 0) then return false end
    if ps.magic < SHOUT_COST then
        ply:EmitSound("buttons/button10.wav", 52, 85, 0.45, CHAN_ITEM)
        return false
    end

    local direction = ply:GetAimVector():GetNormalized()
    if direction == vector_origin then return false end

    ps.magic = math.max(0, ps.magic - SHOUT_COST)
    self.NextCast[ply] = now + SHOUT_COOLDOWN
    self:_Sync(ply, ps)

    local shout, pitch = chooseShout(ply, ps)
    if shout then ply:EmitSound(shout, 86, pitch, 1.0, CHAN_VOICE) end
    ply:EmitSound("ambient/energy/weld2.wav", 82, 78, 0.72, CHAN_STATIC)
    if ply.AnimRestartGesture then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE, true)
    end

    local origin = ply:GetShootPos() + direction * 18
    net.Start("LOD_MagicShoutFX")
    net.WriteEntity(ply)
    net.WriteVector(origin)
    net.WriteVector(direction)
    net.Broadcast()

    local targets = targetList(ply, direction)
    for _, hostile in ipairs(targets) do
        if IsValid(hostile) and not hostile.LODDead and hostile:Health() > 0 then
            local total, chains, capped = rollExploding2d6()
            local info = DamageInfo()
            info:SetAttacker(ply)
            info:SetInflictor(ply)
            info:SetDamage(total)
            info:SetDamageType(DMG_SONIC)
            info:SetDamagePosition(hostile:WorldSpaceCenter())
            info:SetDamageForce(vector_origin)
            hostile:TakeDamageInfo(info)

            Magic.Stats.targets = (Magic.Stats.targets or 0) + 1
            Magic.Stats.damage = (Magic.Stats.damage or 0) + total

            if Rolls and Rolls._Send and Rolls._DamageEventText then
                local detail = string.format("[rolls %s%s]", rollDetail(chains), capped and "; chain cap" or "")
                Rolls:_Send(ply, 0, Rolls:_DamageEventText(ply, "2d6!", total, hostile,
                    detail, nil, "Hostile", "force shout"))
            end

            if IsValid(hostile) and not hostile.LODDead and hostile:Health() > 0 and Pushback and Pushback.Apply then
                Pushback:Apply(hostile, {
                    attacker = ply,
                    origin = ply:GetPos(),
                    direction = direction,
                    distance = SHOUT_PUSH,
                    source = "force shout"
                })
            end
        end
    end

    self.Stats.casts = (self.Stats.casts or 0) + 1
    return true
end

net.Receive("LOD_MagicCastRequest", function(_, ply)
    Magic:CastForceShout(ply)
end)

-- RMB belongs to Magic globally in the current build. Strip secondary-fire input
-- server-side as well as client-side so stock weapon alt-fire cannot leak through.
hook.Add("StartCommand", "LOD_MagicSuppressSecondaryFire", function(ply, cmd)
    if IsValid(ply) and ply:Alive() and RunManager and RunManager.IsActivePlayer and RunManager:IsActivePlayer(ply) then
        cmd:RemoveKey(IN_ATTACK2)
    end
end)

timer.Create(MAGIC_TIMER, REGEN_TICK, 0, function()
    if not RunManager or not RunManager.State or RunManager.State.Failed then return end
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:Alive() and RunManager:IsActivePlayer(ply) then
            local ps = Magic:_EnsureState(ply)
            if ps and ps.magic < MAX_MAGIC then
                ps.magic = math.min(MAX_MAGIC, ps.magic + REGEN_PER_TICK)
                Magic:_Sync(ply, ps)
            end
        end
    end
end)

concommand.Add("lod_magic_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local line = string.format("casts=%d targets=%d damage=%d max=%d cost=%d regen=%.2fs range=%d cone=%ddeg push=%d",
        Magic.Stats.casts or 0, Magic.Stats.targets or 0, Magic.Stats.damage or 0,
        MAX_MAGIC, SHOUT_COST, REGEN_SECONDS, SHOUT_RANGE, SHOUT_HALF_ANGLE * 2, SHOUT_PUSH)
    print("[LOD:MAGIC] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
