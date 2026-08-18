LOD = LOD or {}
LOD.CombatAudio = LOD.CombatAudio or {}

local CombatAudio = LOD.CombatAudio

local function soundFileExists(path)
    if not isstring(path) or path == "" then return false end
    return file.Exists("sound/" .. path, "GAME")
end

local function firstUsablePool(primary, fallback)
    local usable = {}
    for _, path in ipairs(primary or {}) do
        if soundFileExists(path) then usable[#usable + 1] = path end
    end
    if #usable > 0 then return usable end

    -- The citizen pain banks are base-HL2 assets and are our guaranteed
    -- gender-correct fallback when a named character lacks a mounted pain bank.
    for _, path in ipairs(fallback or {}) do usable[#usable + 1] = path end
    return usable
end

local function nextFromPool(holder, field, pool)
    if not pool or #pool == 0 then return nil end
    holder[field] = ((holder[field] or 0) % #pool) + 1
    return pool[holder[field]]
end

function CombatAudio:PainPoolForPlayer(ply)
    local audio = LOD.Config.Audio
    if not audio or not IsValid(ply) then return nil end

    local ps = LOD.RunManager and LOD.RunManager:GetPlayerState(ply)
    local characterId = ps and ps.characterId or nil
    local profile = characterId and audio.CharacterPain[characterId] or nil
    local gender = profile and profile.gender or nil

    -- Defensive model fallback for an unusual state before characterId has
    -- synchronized. It never guesses female as male or vice versa for the two
    -- generic citizen models used by this gamemode.
    if not gender then
        local model = string.lower(ply:GetModel() or "")
        gender = string.find(model, "female", 1, true) and "female" or "male"
    end

    local fallback = gender == "female" and audio.FemalePainFallback or audio.MalePainFallback
    return firstUsablePool(profile and profile.sounds or nil, fallback)
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
    if not path then return end

    -- CHAN_VOICE keeps the vocal reaction distinct from weapon/impact channels.
    ply:EmitSound(path, 72, 100, 0.92, CHAN_VOICE)
end

function CombatAudio:PlayHostileAttack(hostile)
    if not IsValid(hostile) or not hostile.LODHostile then return end
    local cfg = LOD.Config.Encounter.Archetypes[hostile.LODArchetypeId or ""]
    local pool = cfg and cfg.attackSounds or nil
    if not pool or #pool == 0 then return end

    local usable = {}
    for _, path in ipairs(pool) do
        if soundFileExists(path) then usable[#usable + 1] = path end
    end
    if #usable == 0 then return end

    local path = nextFromPool(hostile, "LODAttackSoundOrdinal", usable)
    if path then hostile:EmitSound(path, 78, 100, 0.95, CHAN_VOICE) end
end

-- PlayerHurt runs only after real damage has been applied, so blocked/zero-damage
-- events do not produce false pain reactions. The hostile vocalization is emitted
-- from the attacker so its location is readable even before the player turns.
hook.Add("PlayerHurt", "LOD_CombatAudio_PlayerHurt", function(victim, attacker, healthRemaining, damageTaken)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if not damageTaken or damageTaken <= 0 then return end
    if LOD.RunManager and not LOD.RunManager:IsActivePlayer(victim) then return end

    if IsValid(attacker) and attacker.LODHostile and (attacker.LODArchetypeId == "shambler" or attacker.LODArchetypeId == "runner") then
        CombatAudio:PlayHostileAttack(attacker)
    end
    CombatAudio:PlayPlayerPain(victim)
end)

-- Developer-only audible verification without consuming a life or requiring an
-- enemy to connect. This uses the player's current authoritative characterId.
concommand.Add("lod_audio_test_pain", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if not IsValid(ply) or not ply:IsAdmin() then return end
    CombatAudio:PlayPlayerPain(ply)
end)
