LOD = LOD or {}
LOD.Pushback = LOD.Pushback or {}

local Pushback = LOD.Pushback
local Motion = LOD.HostileMotionV2
if not Motion then return end

local BASE_CRUSH_PROFILE = {label = "WALL CRUSH", source = "wall crush", count = 1, sides = 3}
local CRUSH_IMPACT_SOUND = "physics/body/body_medium_impact_hard6.wav"
local CRUSH_BREAK_SOUND = "physics/body/body_medium_break4.wav"
local CRUSH_SLAM_SOUND = "ambient/machines/thumper_hit.wav"
local WALL_CLASSES = {
    lod_static_box = true,
    lod_gate = true,
    lod_jail_door = true
}

util.AddNetworkString("LOD_PushbackFX")

Pushback.Stats = Pushback.Stats or {
    pushes = 0,
    wallCrushes = 0,
    crushDamage = 0,
    saveRolls = 0,
    savesSucceeded = 0,
    savesFailed = 0,
    pushImmuneBlocks = 0
}
Pushback.SaveRNGState = Pushback.SaveRNGState or setmetatable({}, {__mode = "k"})

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

function Pushback:WallCrushProfile(derived, opts)
    opts = opts or {}
    local profile = table.Copy(BASE_CRUSH_PROFILE)
    local pusherFamilyEligible = opts.magicPush ~= true
        or opts.pusherFamilyEligible == true
    profile.sides = pusherFamilyEligible and math.max(2,
        math.floor(tonumber(derived and derived.wallSlamDieSides) or 3)) or 3
    profile.classExplosionImmune = pusherFamilyEligible and derived
        and derived.wallSlamClassExplosionImmune == true or false
    local crowbarBonus = opts.crowbarPush == true and math.max(0,
        math.floor(tonumber(derived and derived.crowbarWallSlamBonusDice) or 0)) or 0
    profile.count = math.max(1, (profile.count or 1) + crowbarBonus)
    return profile
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
    local profile = self:WallCrushProfile(derived, opts)
    local bonusDice = math.max(0,
        math.floor(tonumber(derived and derived.fighterCapstoneWallSlamBonusDice) or 0))
    local contract = rolls.RollActorDamage
        and rolls:RollActorDamage(sourceAttacker, profile, rng, bonusDice) or nil
    local total = contract and rolls:ResolveActorDamage(contract, sourceAttacker, hostile, {})
        or rolls:_RollFormula(profile, rng)
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
    local actualDieCount = contract and contract.baseDice or profile.count
    if opts.crowbarPush == true then
        self.Stats.lastCrowbarWallDieCount = actualDieCount
        self.Stats.lastCrowbarWallDieSides = profile.sides
    end
    hostile.LODLastWallCrush = {
        at = CurTime(),
        damage = total,
        attacker = sourceAttacker,
        source = source,
        rolls = values,
        dieCount = actualDieCount,
        dieSides = profile.sides,
        classExplosionImmune = profile.classExplosionImmune
    }

    if IsValid(sourceAttacker) and sourceAttacker:IsPlayer() and rolls._Send and rolls._DamageEventText then
        local detail = string.format("[rolls %s; from %s push]",
            values and table.concat(values, ">") or tostring(total), source)
        local formula = contract and contract.formula
            or string.format("%dd%d", profile.count or 1, profile.sides)
        rolls:_Send(sourceAttacker, 0, rolls:_DamageEventText(sourceAttacker, formula, total,
            hostile, detail, nil, "Hostile", "wall crush"))
    end

    return total
end

local function round(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function log2(value)
    return math.log(value) / math.log(2)
end

function Pushback:ResolveSharedPushSave(requestedDistance, attackerDerived,
    defenderDerived, sizeScale, natural, opts)
    opts = opts or {}
    local requested = math.max(0, tonumber(requestedDistance) or 0)
    local size = math.max(0.01, tonumber(sizeScale) or 1)
    local sizeModifier = math.Clamp(round(12 * log2(size)), -8, 6)
    local sizeMultiplier = math.Clamp(1 / size, 0.50, 2.00)
    local sizeAdjusted = round(requested * sizeMultiplier)
    if opts.pushImmune == true then
        return 0, {
            pushImmune = true,
            rolled = false,
            requested = requested,
            sizeScale = size,
            sizeModifier = sizeModifier,
            sizeMultiplier = sizeMultiplier,
            sizeAdjusted = sizeAdjusted,
            saveSucceeded = nil,
            resolved = 0
        }
    end

    local attackSTR = tonumber(attackerDerived and attackerDerived.strMod) or 0
    local attackProficiency = tonumber(attackerDerived
        and attackerDerived.levelProficiency) or 0
    local defendSTR = tonumber(defenderDerived and defenderDerived.strMod) or 0
    local defendProficiency = tonumber(defenderDerived
        and defenderDerived.levelProficiency) or 0
    local d20 = math.Clamp(math.floor(tonumber(natural) or 1), 1, 20)
    local dc = 10 + attackSTR + attackProficiency
    local save = d20 + defendSTR + defendProficiency + sizeModifier
    local succeeded = save >= dc
    local successfulFraction = succeeded
        and math.Clamp(tonumber(opts.successfulSaveFraction) or 0, 0, 1) or 1
    local postSave = sizeAdjusted * successfulFraction
    local incoming = opts.ignoreResistance == true and 1
        or math.max(0, tonumber(opts.incomingMultiplier) or 1)
    local steadfast = opts.ignoreResistance == true and 1
        or math.max(0, tonumber(opts.steadfastMultiplier) or 1)
    local resolved = postSave * incoming * steadfast
    return resolved, {
        pushImmune = false,
        rolled = true,
        natural = d20,
        dc = dc,
        save = save,
        saveSucceeded = succeeded,
        successfulSaveFraction = successfulFraction,
        requested = requested,
        sizeScale = size,
        sizeModifier = sizeModifier,
        sizeMultiplier = sizeMultiplier,
        sizeAdjusted = sizeAdjusted,
        postSave = postSave,
        incomingMultiplier = incoming,
        steadfastMultiplier = steadfast,
        resolved = resolved
    }
end

local function actorKey(actor)
    local rules = LOD.RPGAbilityRules
    local state = rules and rules.ProgressionState and rules:ProgressionState(actor) or nil
    if state and state.actorId then return tostring(state.actorId) end
    return IsValid(actor) and tostring(actor:EntIndex()) or "world"
end

function Pushback:_PushSaveNatural(attacker, defender)
    local runState = LOD.RunManager and LOD.RunManager.State
    local levelSeed = runState and runState.LevelSeed or 1
    local key = IsValid(attacker) and attacker or self
    local stream = self.SaveRNGState[key]
    if not stream or stream.levelSeed ~= levelSeed then
        stream = {levelSeed = levelSeed, serial = 0}
        self.SaveRNGState[key] = stream
    end
    stream.serial = stream.serial + 1
    local seed = LOD.Seeds.Derive(levelSeed, string.format(
        "push-save:v1:%s:%d:%d", actorKey(attacker),
        IsValid(defender) and defender:EntIndex() or 0, stream.serial))
    return LOD.RNG.New(seed):Int(1, 20)
end

function Pushback:ValidateSharedPushSave()
    local errors = {}
    local function expect(ok, message)
        if not ok then errors[#errors + 1] = message end
    end
    local distance, result = self:ResolveSharedPushSave(168,
        {strMod = 2, levelProficiency = 1},
        {strMod = 1, levelProficiency = 0}, 1, 10, {})
    expect(result.dc == 13 and result.save == 11 and not result.saveSucceeded,
        "failed STR push save")
    expect(distance == 168 and result.sizeAdjusted == 168,
        "ordinary failed-save distance")
    distance, result = self:ResolveSharedPushSave(168,
        {strMod = 0, levelProficiency = 0},
        {strMod = 0, levelProficiency = 0}, 1.33, 20, {})
    expect(result.saveSucceeded and distance == 0 and result.sizeModifier == 5
        and result.sizeAdjusted == 126, "large defender brace and distance scaling")
    distance, result = self:ResolveSharedPushSave(168, {}, {}, 0.33, 10, {})
    expect(not result.saveSucceeded and distance == 336 and result.sizeModifier == -8,
        "tiny defender save penalty and displacement cap")
    distance, result = self:ResolveSharedPushSave(168, {}, {}, 1, 1,
        {incomingMultiplier = 0.75, steadfastMultiplier = 0.75})
    expect(distance == 94.5, "post-save defender multipliers")
    distance, result = self:ResolveSharedPushSave(168, {}, {}, 1, 1,
        {pushImmune = true})
    expect(distance == 0 and result.pushImmune and not result.rolled,
        "PushImmune skips save")
    local profile = self:WallCrushProfile(
        {wallSlamDieSides = 8, wallSlamClassExplosionImmune = true}, {})
    expect(profile.sides == 8 and profile.classExplosionImmune,
        "Pusher sealed wall-slam profile")
    profile = self:WallCrushProfile(
        {wallSlamDieSides = 12, wallSlamClassExplosionImmune = false}, {})
    expect(profile.sides == 12 and not profile.classExplosionImmune,
        "Space Hog SUPER-d12 wall-slam profile")
    profile = self:WallCrushProfile(
        {wallSlamDieSides = 12, wallSlamClassExplosionImmune = false},
        {magicPush = true})
    expect(profile.sides == 3 and not profile.classExplosionImmune,
        "unbridged Magic push retains baseline wall-slam profile")
    profile = self:WallCrushProfile({
        wallSlamDieSides = 3,
        wallSlamClassExplosionImmune = false,
        crowbarWallSlamBonusDice = 1
    }, {crowbarPush = true})
    expect(profile.count == 2 and profile.sides == 3,
        "Wrecking Bar baseline 2d3 profile")
    profile = self:WallCrushProfile({
        wallSlamDieSides = 12,
        wallSlamClassExplosionImmune = false,
        crowbarWallSlamBonusDice = 1
    }, {crowbarPush = true})
    expect(profile.count == 2 and profile.sides == 12
        and not profile.classExplosionImmune,
        "Wrecking Bar plus Space Hog SUPER-2d12 profile")
    return #errors == 0, errors
end

function Pushback:Apply(hostile, opts)
    opts = opts or {}
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return nil end
    if hostile.LODDeadcrabState == "latched" then return nil end

    local authoredDistance = math.max(0, tonumber(opts.distance) or 0)
    local rules = LOD.RPGAbilityRules
    local attackerDerived = rules and rules.Derived and rules:Derived(opts.attacker) or nil
    local defenderDerived = rules and rules.Derived and rules:Derived(hostile) or nil
    local effects = LOD.RPG and LOD.RPG.FeatEffectSystem
    local parts
    if effects and effects.ResolvePushDistance then
        _, parts = effects:ResolvePushDistance(
            authoredDistance, attackerDerived, defenderDerived, opts)
    else
        local outgoing = math.max(0, tonumber(attackerDerived
            and attackerDerived.fighterCapstoneOutgoingPushMultiplier) or 1)
        parts = {
            authored = authoredDistance,
            outgoingMultiplier = outgoing,
            magicPushMultiplier = 1,
            incomingMultiplier = 1,
            steadfastMultiplier = 1
        }
    end
    local assembled = authoredDistance * (parts.outgoingMultiplier or 1)
        * (parts.magicPushMultiplier or 1)
        * math.max(0, tonumber(attackerDerived and attackerDerived.bigGuyPhysicalPushMultiplier) or 1)
    local sizeScale = hostile:GetNW2Float("LOD_SizeScale", 1)
    local pushImmune = opts.pushImmune == true or hostile.LODPushImmune == true
        or hostile:GetNW2Bool("LOD_PushImmune", false)
    local natural = opts.pushSaveNatural
        or (not pushImmune and self:_PushSaveNatural(opts.attacker, hostile) or 1)
    local distance, save = self:ResolveSharedPushSave(
        assembled, attackerDerived, defenderDerived, sizeScale, natural, {
            pushImmune = pushImmune,
            successfulSaveFraction = opts.successfulSaveFraction
                or (tonumber(attackerDerived and attackerDerived.steamrollerSuccessfulSaveFraction) or 0),
            ignoreResistance = opts.ignoreResistance,
            incomingMultiplier = parts.incomingMultiplier,
            steadfastMultiplier = parts.steadfastMultiplier
        })
    self.Stats.pushes = (self.Stats.pushes or 0) + 1
    self.Stats.lastAuthoredDistance = authoredDistance
    self.Stats.lastAssembledDistance = assembled
    self.Stats.lastSizeAdjustedDistance = save.sizeAdjusted
    self.Stats.lastRequestedDistance = distance
    self.Stats.lastOutgoingMultiplier = parts.outgoingMultiplier
    self.Stats.lastMagicPushMultiplier = parts.magicPushMultiplier
    self.Stats.lastIncomingMultiplier = parts.incomingMultiplier
    self.Stats.lastSteadfastMultiplier = parts.steadfastMultiplier
    self.Stats.lastSaveNatural = save.natural
    self.Stats.lastSaveDC = save.dc
    self.Stats.lastSaveTotal = save.save
    self.Stats.lastSaveSucceeded = save.saveSucceeded
    if save.rolled then
        self.Stats.saveRolls = (self.Stats.saveRolls or 0) + 1
        if save.saveSucceeded then
            self.Stats.savesSucceeded = (self.Stats.savesSucceeded or 0) + 1
        else
            self.Stats.savesFailed = (self.Stats.savesFailed or 0) + 1
        end
    elseif save.pushImmune then
        self.Stats.pushImmuneBlocks = (self.Stats.pushImmuneBlocks or 0) + 1
    end
    local rolls = LOD.CombatRolls
    if save.rolled and IsValid(opts.attacker) and opts.attacker:IsPlayer()
        and rolls and rolls._Send then
        rolls:_Send(opts.attacker, 2, string.format(
            "PUSH SAVE d20=%d; total %d vs DC %d; %s; distance %.1f",
            save.natural, save.save, save.dc,
            save.saveSucceeded and "BRACED" or "FAILED", distance))
    end
    if distance <= 0 then
        local result = {
            authored = authoredDistance,
            assembled = assembled,
            sizeAdjusted = save.sizeAdjusted,
            requested = 0,
            resolved = 0,
            outgoingMultiplier = parts.outgoingMultiplier,
            magicPushMultiplier = parts.magicPushMultiplier,
            incomingMultiplier = parts.incomingMultiplier,
            steadfastMultiplier = parts.steadfastMultiplier,
            moved = 0,
            blocked = false,
            crushed = false,
            crushDamage = 0,
            pushSave = save
        }
        hostile.LODLastPushback = {
            at = CurTime(),
            authored = authoredDistance,
            assembled = assembled,
            sizeAdjusted = save.sizeAdjusted,
            requested = 0,
            moved = 0,
            crushed = false,
            crushDamage = 0,
            source = tostring(opts.source or "generic"),
            pushSave = save,
            outgoingMultiplier = parts.outgoingMultiplier,
            magicPushMultiplier = parts.magicPushMultiplier,
            incomingMultiplier = parts.incomingMultiplier,
            steadfastMultiplier = parts.steadfastMultiplier
        }
        return result
    end
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

    local crushed = crushSurface(trace)

    -- Broadcast the already-resolved authoritative path before crush damage can
    -- kill/remove the hostile. Clients render only presentation; they never infer
    -- displacement, collision, or crush state independently.
    broadcastPushFX(hostile, startPos, destination, trace, crushed, opts)

    local crushDamage = crushed and self:_RollWallCrush(hostile, opts) or 0
    local result = {
        authored = authoredDistance,
        assembled = assembled,
        sizeAdjusted = save.sizeAdjusted,
        requested = distance,
        resolved = distance,
        outgoingMultiplier = parts.outgoingMultiplier,
        magicPushMultiplier = parts.magicPushMultiplier,
        incomingMultiplier = parts.incomingMultiplier,
        steadfastMultiplier = parts.steadfastMultiplier,
        moved = travel,
        blocked = trace.Hit == true,
        crushed = crushed,
        crushDamage = crushDamage,
        hitEntity = trace.Entity,
        pushSave = save
    }
    hostile.LODLastPushback = {
        at = CurTime(),
        authored = authoredDistance,
        assembled = assembled,
        sizeAdjusted = save.sizeAdjusted,
        requested = distance,
        outgoingMultiplier = parts.outgoingMultiplier,
        magicPushMultiplier = parts.magicPushMultiplier,
        incomingMultiplier = parts.incomingMultiplier,
        steadfastMultiplier = parts.steadfastMultiplier,
        moved = travel,
        crushed = crushed,
        crushDamage = crushDamage,
        source = tostring(opts.source or "generic"),
        pushSave = save
    }
    return result
end

concommand.Add("lod_pushback_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format("pushes=%d saves=%d pass=%d fail=%d immune=%d wallCrushes=%d crushDamage=%d last=d20:%s total:%s DC:%s braced:%s",
        Pushback.Stats.pushes or 0, Pushback.Stats.saveRolls or 0,
        Pushback.Stats.savesSucceeded or 0, Pushback.Stats.savesFailed or 0,
        Pushback.Stats.pushImmuneBlocks or 0, Pushback.Stats.wallCrushes or 0,
        Pushback.Stats.crushDamage or 0,
        tostring(Pushback.Stats.lastSaveNatural), tostring(Pushback.Stats.lastSaveTotal),
        tostring(Pushback.Stats.lastSaveDC), tostring(Pushback.Stats.lastSaveSucceeded))
    print("[LOD:PUSHBACK] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
