LOD = LOD or {}
LOD.CombatAudio = LOD.CombatAudio or {}

local CombatAudio = LOD.CombatAudio

-- Audio is deliberately centralized here rather than scattered through combat,
-- progression, and run-state code. Spatial information (enemy movement/combat)
-- comes from world-positioned sounds; abstract run-state feedback is played on
-- the affected player. Silence between cues is intentional.
local HOSTILE_AUDIO = {
    shambler = {
        footsteps = {
            "npc/zombie/foot1.wav", "npc/zombie/foot2.wav", "npc/zombie/foot3.wav"
        },
        footFallback = {"player/footsteps/concrete1.wav", "player/footsteps/concrete2.wav"},
        footDistance = 52,
        footInterval = 0.38,
        footVolume = 0.78,
        footPitch = 88,
        pain = {
            "npc/zombie/zombie_pain1.wav", "npc/zombie/zombie_pain2.wav",
            "npc/zombie/zombie_pain3.wav", "npc/zombie/zombie_pain4.wav"
        },
        death = {
            "npc/zombie/zombie_die1.wav", "npc/zombie/zombie_die2.wav", "npc/zombie/zombie_die3.wav"
        },
        activation = {
            "npc/zombie/zo_alert10.wav", "npc/zombie/zo_alert20.wav", "npc/zombie/zo_alert30.wav"
        }
    },
    runner = {
        footsteps = {
            "npc/fast_zombie/foot1.wav", "npc/fast_zombie/foot2.wav",
            "npc/fast_zombie/foot3.wav", "npc/fast_zombie/foot4.wav"
        },
        footFallback = {"player/footsteps/concrete3.wav", "player/footsteps/concrete4.wav"},
        footDistance = 70,
        footInterval = 0.22,
        footVolume = 0.82,
        footPitch = 112,
        pain = {
            "npc/fast_zombie/fz_pain1.wav", "npc/fast_zombie/fz_pain2.wav",
            "npc/fast_zombie/fz_pain3.wav"
        },
        death = {
            "npc/fast_zombie/fz_die1.wav", "npc/fast_zombie/fz_die2.wav"
        },
        activation = {
            "npc/fast_zombie/fz_alert_close1.wav", "npc/fast_zombie/fz_scream1.wav"
        }
    },
    soldier = {
        -- Combine gear clacks make the ranged archetype recognizable around a
        -- blind corner without borrowing the organic foot sounds of either zombie.
        footsteps = {
            "npc/combine_soldier/gear1.wav", "npc/combine_soldier/gear2.wav",
            "npc/combine_soldier/gear3.wav", "npc/combine_soldier/gear4.wav",
            "npc/combine_soldier/gear5.wav", "npc/combine_soldier/gear6.wav"
        },
        footFallback = {"player/footsteps/metal1.wav", "player/footsteps/metal2.wav"},
        footDistance = 60,
        footInterval = 0.30,
        footVolume = 0.72,
        footPitch = 98,
        pain = {
            "npc/combine_soldier/pain1.wav", "npc/combine_soldier/pain2.wav", "npc/combine_soldier/pain3.wav"
        },
        death = {
            "npc/combine_soldier/die1.wav", "npc/combine_soldier/die2.wav", "npc/combine_soldier/die3.wav"
        },
        activation = {
            "npc/combine_soldier/gear3.wav", "npc/combine_soldier/gear5.wav"
        }
    }
}

-- Every playable character slot has its own death signature. Named character
-- clips are preferred when mounted; a distinct gender-correct citizen pain clip
-- is the guaranteed fallback so no female model can ever emit a male death voice
-- and no two fallback character slots intentionally share the same sample.
local CHARACTER_DEATH = {
    breen   = {gender = "male", primary = {"vo/citadel/br_ohshit.wav"}, fallback = {"vo/npc/male01/pain01.wav"}, pitch = 94},
    alyx    = {gender = "female", primary = {"vo/npc/alyx/hurt08.wav", "vo/npc/alyx/hurt06.wav"}, fallback = {"vo/npc/female01/pain01.wav"}, pitch = 104},
    barney  = {gender = "male", primary = {"vo/npc/barney/ba_pain03.wav"}, fallback = {"vo/npc/male01/pain02.wav"}, pitch = 100},
    kleiner = {gender = "male", fallback = {"vo/npc/male01/pain03.wav"}, pitch = 106},
    eli     = {gender = "male", fallback = {"vo/npc/male01/pain04.wav"}, pitch = 92},
    mossman = {gender = "female", fallback = {"vo/npc/female01/pain04.wav"}, pitch = 98},
    odessa  = {gender = "male", fallback = {"vo/npc/male01/pain05.wav"}, pitch = 96},
    grigori = {gender = "male", primary = {"vo/ravenholm/monk_pain04.wav"}, fallback = {"vo/npc/male01/pain06.wav"}, pitch = 100},
    male    = {gender = "male", fallback = {"vo/npc/male01/pain08.wav"}, pitch = 102},
    female  = {gender = "female", fallback = {"vo/npc/female01/pain09.wav"}, pitch = 102}
}

local UI_CUES = {
    meleeImpact = {path = "physics/body/body_medium_impact_hard1.wav", level = 67, volume = 0.55, pitch = 104},
    lifeLost = {path = "buttons/button18.wav", level = 58, volume = 0.55, pitch = 92},
    lastLife = {path = "buttons/button11.wav", level = 62, volume = 0.72, pitch = 82},
    respawn = {path = "items/suitchargeok1.wav", level = 58, volume = 0.58, pitch = 108},
    checkpoint = {path = "buttons/button9.wav", level = 60, volume = 0.62, pitch = 112},
    objectiveClear = {path = "buttons/button14.wav", level = 58, volume = 0.45, pitch = 108},
    levelReady = {path = "buttons/button15.wav", level = 55, volume = 0.42, pitch = 105},
    levelClear = {path = "buttons/button9.wav", level = 65, volume = 0.72, pitch = 122},
    campaignFail = {path = "ambient/alarms/warningbell1.wav", level = 72, volume = 0.80, pitch = 82}
}

local function soundFileExists(path)
    if not isstring(path) or path == "" then return false end
    return file.Exists("sound/" .. path, "GAME")
end

local function usablePool(primary, fallback)
    local usable = {}
    for _, path in ipairs(primary or {}) do
        if soundFileExists(path) then usable[#usable + 1] = path end
    end
    if #usable > 0 then return usable end
    for _, path in ipairs(fallback or {}) do
        if soundFileExists(path) then usable[#usable + 1] = path end
    end
    return usable
end

local function firstUsable(primary, fallback)
    local pool = usablePool(primary, fallback)
    return pool[1]
end

local function nextFromPool(holder, field, pool)
    if not pool or #pool == 0 then return nil end
    holder[field] = ((holder[field] or 0) % #pool) + 1
    return pool[holder[field]]
end

local function playCueOnPlayer(ply, cue)
    if not IsValid(ply) or not cue or not soundFileExists(cue.path) then return end
    ply:EmitSound(cue.path, cue.level or 60, cue.pitch or 100, cue.volume or 0.7, CHAN_AUTO)
end

local function broadcastCue(cue)
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then playCueOnPlayer(ply, cue) end
    end
end

function CombatAudio:PainPoolForPlayer(ply)
    local audio = LOD.Config.Audio
    if not audio or not IsValid(ply) then return nil end

    local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply)
    local characterId = ps and ps.characterId or nil
    local profile = characterId and audio.CharacterPain[characterId] or nil
    local gender = profile and profile.gender or nil

    -- Defensive model fallback for an unusual state before characterId has
    -- synchronized. Never infer a known female citizen model as male.
    if not gender then
        local model = string.lower(ply:GetModel() or "")
        gender = string.find(model, "female", 1, true) and "female" or "male"
    end

    local fallback = gender == "female" and audio.FemalePainFallback or audio.MalePainFallback
    return usablePool(profile and profile.sounds or nil, fallback)
end

function CombatAudio:PlayPlayerPain(ply)
    if not IsValid(ply) then return end
    local audio = LOD.Config.Audio
    if not audio then return end

    local now = CurTime()
    if now < (ply.LODNextPainVoice or 0) then return end
    ply.LODNextPainVoice = now + (audio.PlayerPainCooldown or 0.65)

    local pool = self:PainPoolForPlayer(ply)
    local path = nextFromPool(ply, "LODPainVoiceOrdinal", pool)
    if path then ply:EmitSound(path, 72, 100, 0.92, CHAN_VOICE) end
end

function CombatAudio:DeathProfileForPlayer(ply)
    if not IsValid(ply) then return nil end
    local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply)
    local id = ps and ps.characterId or nil
    local profile = id and CHARACTER_DEATH[id] or nil
    if profile then return profile end

    local model = string.lower(ply:GetModel() or "")
    if string.find(model, "female", 1, true) then return CHARACTER_DEATH.female end
    return CHARACTER_DEATH.male
end

function CombatAudio:PlayPlayerDeath(ply)
    if not IsValid(ply) then return end
    local profile = self:DeathProfileForPlayer(ply)
    if not profile then return end
    local path = firstUsable(profile.primary, profile.fallback)
    if not path then return end

    -- sound.Play is anchored to the corpse position and survives the immediate
    -- transition into restricted spectator mode better than a weapon/entity channel.
    sound.Play(path, ply:GetPos() + Vector(0, 0, 40), 78, profile.pitch or 100, 0.98)
end

function CombatAudio:PlayHostileAttack(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end
    local cfg = LOD.Config.Encounter.Archetypes[hostile.LODArchetypeId or ""]
    local pool = usablePool(cfg and cfg.attackSounds or nil, nil)
    local path = nextFromPool(hostile, "LODAttackSoundOrdinal", pool)
    if path then hostile:EmitSound(path, 78, 100, 0.95, CHAN_VOICE) end
end

function CombatAudio:PlayHostilePain(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end
    local now = CurTime()
    if now < (hostile.LODNextPainAudio or 0) then return end
    hostile.LODNextPainAudio = now + 0.55

    local profile = HOSTILE_AUDIO[hostile.LODArchetypeId or ""]
    if not profile then return end
    local cfg = LOD.Config.Encounter.Archetypes[hostile.LODArchetypeId or ""]
    local pool = usablePool(profile.pain, cfg and cfg.attackSounds or nil)
    local path = nextFromPool(hostile, "LODPainSoundOrdinal", pool)
    if path then hostile:EmitSound(path, 74, profile.footPitch or 100, 0.72, CHAN_VOICE) end
end

function CombatAudio:PlayHostileDeath(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end
    local profile = HOSTILE_AUDIO[hostile.LODArchetypeId or ""]
    if not profile then return end
    local cfg = LOD.Config.Encounter.Archetypes[hostile.LODArchetypeId or ""]
    local pool = usablePool(profile.death, cfg and cfg.attackSounds or nil)
    local path = nextFromPool(hostile, "LODDeathSoundOrdinal", pool)
    if path then sound.Play(path, hostile:WorldSpaceCenter(), 80, profile.footPitch or 100, 0.95) end
end

function CombatAudio:PlayHostileFootstep(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end
    local profile = HOSTILE_AUDIO[hostile.LODArchetypeId or ""]
    if not profile then return end
    local pool = usablePool(profile.footsteps, profile.footFallback)
    local path = nextFromPool(hostile, "LODFootstepOrdinal", pool)
    if not path then return end
    hostile:EmitSound(path, 69, profile.footPitch or 100, profile.footVolume or 0.75, CHAN_BODY)
end

function CombatAudio:PlayEncounterActivation(encounter, anchor)
    if not encounter or not IsValid(anchor) then return end
    local profile = HOSTILE_AUDIO[anchor.LODArchetypeId or ""]
    if not profile then return end
    local cfg = LOD.Config.Encounter.Archetypes[anchor.LODArchetypeId or ""]
    local pool = usablePool(profile.activation, cfg and cfg.attackSounds or nil)
    local path = nextFromPool(anchor, "LODActivationSoundOrdinal", pool)
    if path then anchor:EmitSound(path, 79, profile.footPitch or 100, 0.68, CHAN_VOICE) end
end

function CombatAudio:_UpdateHostileFootsteps(now)
    for _, hostile in ipairs(LOD.HostileRegistry and LOD.HostileRegistry:List() or {}) do
        if IsValid(hostile) and hostile.LODHostile and hostile.LODActivated ~= false then
            local profile = HOSTILE_AUDIO[hostile.LODArchetypeId or ""]
            if profile then
                local pos = hostile:GetPos()
                local last = hostile.LODAudioLastFootPos
                hostile.LODAudioLastFootPos = pos

                if last and hostile:GetVelocity():Length2D() > 18 then
                    -- Clamp one sample's contribution so a teleport/debug placement
                    -- cannot sound like several footsteps at once.
                    local travelled = math.min(80, pos:Distance(last))
                    hostile.LODAudioFootDistance = (hostile.LODAudioFootDistance or 0) + travelled
                    if hostile.LODAudioFootDistance >= (profile.footDistance or 60)
                        and now >= (hostile.LODAudioNextFootstep or 0)
                    then
                        hostile.LODAudioFootDistance = math.max(0, hostile.LODAudioFootDistance - (profile.footDistance or 60))
                        hostile.LODAudioNextFootstep = now + (profile.footInterval or 0.3)
                        self:PlayHostileFootstep(hostile)
                    end
                end
            end
        end
    end
end

function CombatAudio:_MonitorEncounterAudio(state)
    local graph = state and state.Graph
    local plan = graph and graph.EncounterPlan
    if not plan then return end

    self.SeenActivatedEncounters = self.SeenActivatedEncounters or {}
    self.SeenClearedEncounters = self.SeenClearedEncounters or {}

    for _, encounter in ipairs(plan.encounters or {}) do
        if encounter.spawned and not self.SeenActivatedEncounters[encounter.id] then
            self.SeenActivatedEncounters[encounter.id] = true
            local anchor
            for _, ent in ipairs(encounter.entities or {}) do
                if IsValid(ent) then anchor = ent break end
            end
            if IsValid(anchor) then self:PlayEncounterActivation(encounter, anchor) end
        end

        if encounter.cleared and not self.SeenClearedEncounters[encounter.id] then
            self.SeenClearedEncounters[encounter.id] = true
            -- Objective-room combat gets a restrained resolution tone. Ordinary
            -- corridor fights end in natural silence rather than a gamey jingle.
            if encounter.role == "objective" then broadcastCue(UI_CUES.objectiveClear) end
        end
    end
end

function CombatAudio:_MonitorRunState()
    local state = LOD.RunManager and LOD.RunManager.State
    if not state then return end

    local seed = state.LevelSeed
    if seed ~= self.LastLevelSeed then
        local hadPriorLevel = self.LastLevelSeed ~= nil
        self.LastLevelSeed = seed
        self.SeenActivatedEncounters = {}
        self.SeenClearedEncounters = {}
        self.LastGates = {
            state.GatesOpen and state.GatesOpen[1] == true or false,
            state.GatesOpen and state.GatesOpen[2] == true or false,
            state.GatesOpen and state.GatesOpen[3] == true or false
        }
        self.LastFailed = state.Failed == true
        self.LastLevelCleared = state.LevelCleared == true
        self.LastBuildReady = state.BuildReady == true
        if hadPriorLevel and state.BuildReady then broadcastCue(UI_CUES.levelReady) end
    end

    self.LastGates = self.LastGates or {false, false, false}
    for i = 1, 3 do
        local open = state.GatesOpen and state.GatesOpen[i] == true or false
        if open and not self.LastGates[i] then broadcastCue(UI_CUES.checkpoint) end
        self.LastGates[i] = open
    end

    local failed = state.Failed == true
    if failed and not self.LastFailed then broadcastCue(UI_CUES.campaignFail) end
    self.LastFailed = failed

    local cleared = state.LevelCleared == true
    if cleared and not self.LastLevelCleared then broadcastCue(UI_CUES.levelClear) end
    self.LastLevelCleared = cleared

    local ready = state.BuildReady == true
    if ready and self.LastBuildReady == false then broadcastCue(UI_CUES.levelReady) end
    self.LastBuildReady = ready

    self:_MonitorEncounterAudio(state)
end

-- PlayerHurt runs after real damage has been applied, so blocked/zero-damage
-- events do not produce false pain reactions. Fatal damage is reserved for the
-- character's dedicated death voice instead of playing pain+death back-to-back.
hook.Add("PlayerHurt", "LOD_CombatAudio_PlayerHurt", function(victim, attacker, healthRemaining, damageTaken)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if not damageTaken or damageTaken <= 0 then return end
    if LOD.RunManager and not LOD.RunManager:IsActivePlayer(victim) then return end
    if healthRemaining and healthRemaining <= 0 then return end

    if IsValid(attacker) and attacker.LODHostile and (attacker.LODArchetypeId == "shambler" or attacker.LODArchetypeId == "runner") then
        CombatAudio:PlayHostileAttack(attacker)
        playCueOnPlayer(victim, UI_CUES.meleeImpact)
    end
    CombatAudio:PlayPlayerPain(victim)
end)

hook.Add("EntityTakeDamage", "LOD_CombatAudio_HostilePain", function(ent, dmginfo)
    if not IsValid(ent) or not ent.LODHostile then return end
    local incoming = dmginfo and dmginfo:GetDamage() or 0
    if incoming <= 0 or incoming >= ent:Health() then return end
    CombatAudio:PlayHostilePain(ent)
end)

hook.Add("OnNPCKilled", "LOD_CombatAudio_HostileDeath", function(npc)
    if IsValid(npc) and npc.LODHostile then CombatAudio:PlayHostileDeath(npc) end
end)

hook.Add("PlayerDeath", "LOD_CombatAudio_PlayerDeath", function(victim)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    CombatAudio:PlayPlayerDeath(victim)

    -- RunManager also processes PlayerDeath. Inspect authoritative remaining
    -- lives one tick later regardless of hook ordering.
    timer.Simple(0, function()
        if not IsValid(victim) or not LOD.RunManager then return end
        local ps = LOD.RunManager:GetPlayerState(victim)
        if not ps then return end
        if ps.lives == 1 and not ps.eliminated then
            playCueOnPlayer(victim, UI_CUES.lastLife)
        elseif ps.lives > 1 then
            playCueOnPlayer(victim, UI_CUES.lifeLost)
        end
    end)
end)

hook.Add("PlayerSpawn", "LOD_CombatAudio_PlayerSpawn", function(ply)
    timer.Simple(0.08, function()
        if not IsValid(ply) or not LOD.RunManager or not LOD.RunManager:IsActivePlayer(ply) then return end
        local level = LOD.RunManager.State and LOD.RunManager.State.Level or 1
        if ply.LODAudioHasSpawned and ply.LODAudioLastSpawnLevel == level then
            playCueOnPlayer(ply, UI_CUES.respawn)
        end
        ply.LODAudioHasSpawned = true
        ply.LODAudioLastSpawnLevel = level
    end)
end)

hook.Add("Think", "LOD_CombatAudio_Think", function()
    local now = CurTime()
    if now < (CombatAudio.NextThink or 0) then return end
    CombatAudio.NextThink = now + 0.05
    CombatAudio:_UpdateHostileFootsteps(now)
    CombatAudio:_MonitorRunState()
end)

-- Developer-only audible verification without consuming a life or requiring an
-- enemy to connect. These use the player's current authoritative characterId.
concommand.Add("lod_audio_test_pain", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end
    CombatAudio:PlayPlayerPain(ply)
end)

concommand.Add("lod_audio_test_death", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end
    CombatAudio:PlayPlayerDeath(ply)
end)

local function poolCount(primary, fallback)
    return #usablePool(primary, fallback)
end

concommand.Add("lod_audio_audit", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local function report(text)
        print("[LOD:AUDIO] " .. text)
        if IsValid(ply) then ply:ChatPrint(text) end
    end

    for _, id in ipairs({"shambler", "runner", "soldier"}) do
        local profile = HOSTILE_AUDIO[id]
        local cfg = LOD.Config.Encounter.Archetypes[id]
        report(string.format("%s foot=%d pain=%d death=%d activation=%d attack=%d",
            id,
            poolCount(profile.footsteps, profile.footFallback),
            poolCount(profile.pain, cfg and cfg.attackSounds or nil),
            poolCount(profile.death, cfg and cfg.attackSounds or nil),
            poolCount(profile.activation, cfg and cfg.attackSounds or nil),
            poolCount(cfg and cfg.attackSounds or nil, nil)))
    end

    for _, character in ipairs(LOD.Config.Models.Characters or {}) do
        local profile = CHARACTER_DEATH[character.id]
        local path = profile and firstUsable(profile.primary, profile.fallback) or nil
        report(string.format("death %-8s %s", tostring(character.id), path or "MISSING"))
    end

    for name, cue in pairs(UI_CUES) do
        report(string.format("cue %-14s %s", name, soundFileExists(cue.path) and "OK" or ("MISSING " .. cue.path)))
    end
end)
