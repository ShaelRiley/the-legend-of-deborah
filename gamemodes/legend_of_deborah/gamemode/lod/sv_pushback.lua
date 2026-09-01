LOD = LOD or {}
LOD.Pushback = LOD.Pushback or {}

local Pushback = LOD.Pushback
local Motion = LOD.HostileMotionV2
if not Motion then return end

local CRUSH_PROFILE = {label = "WALL CRUSH", source = "wall crush", count = 1, sides = 3}
local CRUSH_IMPACT_SOUND = "physics/body/body_medium_impact_hard6.wav"
local CRUSH_BREAK_SOUND = "physics/body/body_medium_break4.wav"
local CRUSH_SLAM_SOUND = "ambient/machines/thumper_hit.wav"
local WALL_CLASSES = {
    lod_static_box = true,
    lod_gate = true,
    lod_jail_door = true
}

util.AddNetworkString("LOD_PushbackFX")

Pushback.Stats = Pushback.Stats or {pushes = 0, wallCrushes = 0, crushDamage = 0}

local function crushSurface(trace)
    if not trace or not trace.Hit then return false end
    if trace.HitWorld then return true end
    local ent = trace.Entity
    return IsValid(ent) and WALL_CLASSES[ent:GetClass()] == true
end

local function traceBounds(hostile)
    local mins, maxs = hostile:GetCollisionBounds()
    if not mins or not maxs then
        return Vector(-14, -14, 4), Vector(14, 14, 56)
    end

    -- Lift the trace slightly off the generated floor so a horizontal push does
    -- not mistake the floor beneath the hostile for the blocking wall.
    mins = Vector(mins.x, mins.y, math.max(mins.z + 4, 4))
    maxs = Vector(maxs.x, maxs.y, math.max(mins.z + 8, maxs.z - 4))
    return mins, maxs
end

local function resolveDirection(hostile, opts)
    local direction = opts.direction
    if direction then
        direction = Vector(direction.x, direction.y, 0)
    else
        local origin = opts.origin
        if not origin and IsValid(opts.attacker) then origin = opts.attacker:GetPos() end
        if origin then direction = hostile:GetPos() - origin end
        if direction then direction.z = 0 end
    end

    if not direction or direction:LengthSqr() <= 0.01 then
        if IsValid(opts.attacker) then
            direction = opts.attacker:GetAimVector()
            direction.z = 0
        end
    end
    if not direction or direction:LengthSqr() <= 0.01 then return nil end
    return direction:GetNormalized()
end

local function playWallCrushAudio(hostile, damage)
    if not IsValid(hostile) then return end

    -- One recognizable layered signature marks the mechanical event itself:
    -- heavy body impact + short crunch + a low slam transient that cuts through
    -- gunfire and the Force Shout. Slightly lower pitch on larger 1d3 results
    -- makes stronger crushes feel heavier without adding more HUD noise.
    local strength = math.Clamp(math.floor((tonumber(damage) or 1) + 0.5), 1, 3)
    local impactPitch = 102 - (strength - 1) * 5
    local breakPitch = 108 - (strength - 1) * 6
    local slamPitch = 124 - (strength - 1) * 5
    hostile:EmitSound(CRUSH_IMPACT_SOUND, 78, impactPitch, 0.90, CHAN_BODY)
    hostile:EmitSound(CRUSH_BREAK_SOUND, 72, breakPitch, 0.62, CHAN_STATIC)
    if file.Exists("sound/" .. CRUSH_SLAM_SOUND, "GAME") then
        hostile:EmitSound(CRUSH_SLAM_SOUND, 84, slamPitch, 0.72, CHAN_AUTO)
    end
end

local function broadcastPushFX(hostile, startPos, destination, trace, crushed, opts)
    local moved = startPos:Distance(destination)
    if moved <= 0.05 and not crushed then return end

    local validHostile = IsValid(hostile)
    local impactPos = trace and trace.Hit and trace.HitPos or destination
    local impactNormal = trace and trace.Hit and trace.HitNormal or vector_origin
    net.Start("LOD_PushbackFX")
    net.WriteEntity(validHostile and hostile or NULL)
    net.WriteVector(startPos)
    net.WriteVector(destination)
    net.WriteVector(impactPos)
    net.WriteVector(impactNormal)
    net.WriteBool(crushed == true)
    net.WriteString(string.sub(tostring(opts and opts.source or "generic"), 1, 24))
    -- Capture the hostile's presentation before crush damage can kill/remove it.
    -- Clients can therefore draw a short model-silhouette trail without spawning
    -- temporary entities or depending on the hostile remaining valid next frame.
    net.WriteString(validHostile and tostring(hostile:GetModel() or "") or "")
    net.WriteAngle(validHostile and hostile:GetAngles() or angle_zero)
    net.Broadcast()
end

function Pushback:_RollWallCrush(hostile, opts)
    if not IsValid(hostile) or hostile.LODDead or hostile:Health() <= 0 then return 0 end
    local rolls = LOD.CombatRolls
    if not rolls or not rolls._RNG or not rolls._RollFormula then return 0 end

    local source = tostring(opts.source or "push")
    local sourceAttacker = IsValid(opts.attacker) and opts.attacker or nil
    local rng = rolls:_RNG("wall-crush:" .. source)
    local rules = LOD.RPGAbilityRules
    local derived = rules and rules.Derived and rules:Derived(sourceAttacker) or nil
    local bonusDice = math.max(0,
        math.floor(tonumber(derived and derived.fighterCapstoneWallSlamBonusDice) or 0))
    local contract = rolls.RollActorDamage
        and rolls:RollActorDamage(sourceAttacker, CRUSH_PROFILE, rng, bonusDice) or nil
    local total = contract and rolls:ResolveActorDamage(contract, sourceAttacker, hostile, {})
        or rolls:_RollFormula(CRUSH_PROFILE, rng)
    local values = contract and contract.values or nil
    total = math.max(1, math.floor((total or 1) + 0.5))

    -- The crush cue is emitted before damage so even a lethal crush has one clear
    -- audio identity rather than being swallowed by the hostile death transition.
    playWallCrushAudio(hostile, total)

    -- The wall is the direct damage source. Keep the initiating player/effect in
    -- our own record and combat feed, but deliver DMG_CRUSH environmentally so a
    -- shotgun-triggered crush cannot look like a second bullet hit and cannot
    -- create another firearm hit-confirm or hit-stun event.
    local world = game.GetWorld()
    local info = DamageInfo()
    info:SetAttacker(world)
    info:SetInflictor(world)
    info:SetDamage(total)
    info:SetDamageType(DMG_CRUSH)
    info:SetDamageForce(vector_origin)
    hostile.LODPendingDamageAttribution = {attacker = sourceAttacker, source = source}
    hostile:TakeDamageInfo(info)
    hostile.LODPendingDamageAttribution = nil

    self.Stats.wallCrushes = (self.Stats.wallCrushes or 0) + 1
    self.Stats.crushDamage = (self.Stats.crushDamage or 0) + total
    hostile.LODLastWallCrush = {
        at = CurTime(),
        damage = total,
        attacker = sourceAttacker,
        source = source,
        rolls = values
    }

    if IsValid(sourceAttacker) and sourceAttacker:IsPlayer() and rolls._Send and rolls._DamageEventText then
        local detail = string.format("[roll %d; from %s push]", values and values[1] or total, source)
        local formula = contract and contract.formula or "1d3"
        rolls:_Send(sourceAttacker, 0, rolls:_DamageEventText(sourceAttacker, formula, total,
            hostile, detail, nil, "Hostile", "wall crush"))
    end

    return total
end

function Pushback:Apply(hostile, opts)
    opts = opts or {}
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return nil end
    if hostile.LODDeadcrabState == "latched" then return nil end

    local distance = math.max(0, tonumber(opts.distance) or 0)
    local rules = LOD.RPGAbilityRules
    local attackerDerived = rules and rules.Derived and rules:Derived(opts.attacker) or nil
    distance = distance * math.max(0,
        tonumber(attackerDerived and attackerDerived.fighterCapstoneOutgoingPushMultiplier) or 1)
    if distance <= 0 then return nil end
    local direction = resolveDirection(hostile, opts)
    if not direction then return nil end

    local startPos = hostile:GetPos()
    local mins, maxs = traceBounds(hostile)
    local trace = util.TraceHull({
        start = startPos,
        endpos = startPos + direction * distance,
        mins = mins,
        maxs = maxs,
        mask = MASK_PLAYERSOLID,
        filter = {hostile, opts.attacker}
    })

    local travel = distance
    if trace.Hit then
        travel = math.max(0, distance * math.Clamp(trace.Fraction or 0, 0, 1) - 1)
    end
    local destination = startPos + direction * travel
    destination.z = startPos.z

    if travel > 0.05 then
        local yaw = hostile:GetAngles().y
        hostile:SetPos(destination)
        hostile:SetAngles(Angle(0, yaw, 0))
        hostile.LODMotionLastPos = destination
        hostile.LODMotionLastUpdate = CurTime()
        hostile.LODMotionVelocity = vector_origin
        hostile.LODMotionSpeed = 0
        hostile.LODMotionMode = "pushback:" .. tostring(opts.source or "generic")
        hostile.LODNextRouteRefresh = 0
        hostile.LODNextTargetRefresh = 0
    end

    self.Stats.pushes = (self.Stats.pushes or 0) + 1
    local crushed = crushSurface(trace)

    -- Broadcast the already-resolved authoritative path before crush damage can
    -- kill/remove the hostile. Clients render only presentation; they never infer
    -- displacement, collision, or crush state independently.
    broadcastPushFX(hostile, startPos, destination, trace, crushed, opts)

    local crushDamage = crushed and self:_RollWallCrush(hostile, opts) or 0
    local result = {
        requested = distance,
        moved = travel,
        blocked = trace.Hit == true,
        crushed = crushed,
        crushDamage = crushDamage,
        hitEntity = trace.Entity
    }
    hostile.LODLastPushback = {
        at = CurTime(),
        requested = distance,
        moved = travel,
        crushed = crushed,
        crushDamage = crushDamage,
        source = tostring(opts.source or "generic")
    }
    return result
end

concommand.Add("lod_pushback_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format("pushes=%d wallCrushes=%d crushDamage=%d crushDie=1d3",
        Pushback.Stats.pushes or 0, Pushback.Stats.wallCrushes or 0,
        Pushback.Stats.crushDamage or 0)
    print("[LOD:PUSHBACK] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
