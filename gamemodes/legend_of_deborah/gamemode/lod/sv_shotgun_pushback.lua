LOD = LOD or {}

local HitFeedback = LOD.M3HitFeedback
local Pushback = LOD.Pushback
if not HitFeedback or not Pushback then return end

local PUSH_DISTANCE = 168

local function shooterFor(hostile)
    local stamp = IsValid(hostile) and hostile.LODLastHitFeedbackEvent or nil
    local attacker = stamp and stamp.attacker or nil
    return IsValid(attacker) and attacker:IsPlayer() and attacker or nil
end

if not HitFeedback.LODShotgunPushbackWrapped then
    HitFeedback.LODShotgunPushbackWrapped = true
    local baseApplyShotgunShellStun = HitFeedback.ApplyShotgunShellStun

    function HitFeedback:ApplyShotgunShellStun(hostile)
        -- Preserve the accepted one-stun-per-shell contract. The shell's authored
        -- push is independently resolved exactly once after pellet aggregation,
        -- so another actor's stun lock cannot suppress a legitimate push event.
        -- Pellet count can never multiply movement, saves, procs, or wall slams.
        local applied = baseApplyShotgunShellStun(self, hostile)
        if not IsValid(hostile) or hostile.LODDead or hostile:Health() <= 0 then
            return applied
        end

        local attacker = shooterFor(hostile)
        local weapon = IsValid(attacker) and attacker:GetActiveWeapon() or nil
        local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
        local procDistance, pusherProc = 0, false
        if effects and effects.TryPusherProc then
            procDistance, pusherProc = effects:TryPusherProc(
                attacker, hostile, CurTime())
        end
        local requestedDistance = PUSH_DISTANCE + procDistance
        local result = Pushback:Apply(hostile, {
            attacker = attacker,
            inflictor = weapon,
            distance = requestedDistance,
            source = pusherProc and "shotgun+pusher" or "shotgun",
            pusherProc = pusherProc
        })

        hostile.LODLastShotgunPush = result and {
            distance = result.moved or 0,
            requested = requestedDistance,
            pusherProc = pusherProc,
            crushed = result.crushed == true,
            crushDamage = result.crushDamage or 0,
            at = CurTime(),
            attacker = attacker
        } or nil
        return applied
    end
end

concommand.Add("lod_shotgun_push_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local recent = 0
    local maxDistance = 0
    local crushes = 0
    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        local push = IsValid(hostile) and hostile.LODLastShotgunPush or nil
        if push and CurTime() - (push.at or 0) <= 10 then
            recent = recent + 1
            maxDistance = math.max(maxDistance, push.distance or 0)
            if push.crushed then crushes = crushes + 1 end
        end
    end

    local line = string.format("recent=%d maxPush=%.1f nominal=%d wallCrushes=%d genericAuthority=true",
        recent, maxDistance, PUSH_DISTANCE, crushes)
    print("[LOD:SHOTGUN-PUSH] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
