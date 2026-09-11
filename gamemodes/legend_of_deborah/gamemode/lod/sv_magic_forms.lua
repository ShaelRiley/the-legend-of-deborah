LOD = LOD or {}
LOD.MagicForms = LOD.MagicForms or {}

local Forms = LOD.MagicForms
local Magic = LOD.Magic
local RPG = LOD.RPG
local Progression = LOD.CharacterProgressionSystem
local MagicProgression = LOD.MagicProgression
local Rules = LOD.RPGAbilityRules
local Rolls = LOD.CombatRolls
local Pushback = LOD.Pushback
local Status = LOD.RPGStatusElements
local Navigator = LOD.MazeNavigator
local Motion = LOD.HostileMotionV2

if not Magic or not RPG or not Progression or not MagicProgression or not Rules or not Rolls then return end

Forms.SourceDocumentId = "1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY"
Forms.SourceRevisionId = "ANLCKQmboT5nux5Lm3q62ObxvAeLRflm1f4D_IsXIOK2bLIp8MfCOfAm5qRLQK7SvE1sWB6zV3Gn_CnaE__-w6fMnNlO9w6XqCYtQQcD_g"
Forms.Tuning = {
    BaseBeamRange = 1152,
    BaseBombBlastRadius = 96,
    BaseBombThrowRange = 1152,
    BombProjectileSpeed = 700,
    BaseMissileRange = 1536,
    BaseMissileBlastRadius = 128,
    MissileProjectileSpeed = 900,
    MissileSteeringDegreesPerSecond = 180,
    MaxActiveGuidedMissilesPerCaster = 1,
    BaseBoltRange = 1920,
    BoltProjectileSpeed = 2400
}
Forms.ContentColors = {
    raw = Color(210, 235, 255), earth = Color(194, 156, 88), fire = Color(255, 105, 45),
    dark = Color(125, 72, 170), ice = Color(125, 220, 255), light = Color(255, 245, 170),
    electric = Color(110, 180, 255)
}
Forms.ActiveMissiles = Forms.ActiveMissiles or setmetatable({}, {__mode = "k"})
Forms.ActiveSummons = Forms.ActiveSummons or setmetatable({}, {__mode = "k"})
Forms.CastSerial = Forms.CastSerial or setmetatable({}, {__mode = "k"})
Forms.Stats = Forms.Stats or {casts = 0, failed = 0, damageEvents = 0, targets = 0,
    summons = 0, projectileImpacts = 0}

util.AddNetworkString("LOD_MagicFormFX")

-- The shared status resolver normally derives Morale DC from DamageInfo's
-- attacker. Proxy summon attacks intentionally expose their Hero as the durable
-- source, so preserve the summon-sealed DC only for the synchronous damage event.
if Status and Status.MoraleDC and not Status.LODMagicProxyMoraleDCWrapped then
    Status.LODMagicProxyMoraleDCWrapped = true
    local baseMoraleDC = Status.MoraleDC
    function Status:MoraleDC(source)
        if IsValid(source) and source.LODMagicProxyMoraleDC ~= nil then
            return source.LODMagicProxyMoraleDC
        end
        return baseMoraleDC(self, source)
    end
end

-- Pushback's wall-crush resolver correctly needs the summoned Seeker as the
-- mechanical attacker so sealed STR/feat state is honored. Its XP attribution
-- seam, however, must resolve that proxy back to the originating Hero.
local Attribution = LOD.CombatAttributionSystem
if Attribution and Attribution.Record and not Attribution.LODMagicSummonCreditWrapped then
    Attribution.LODMagicSummonCreditWrapped = true
    local baseAttributionRecord = Attribution.Record
    function Attribution:Record(target, dmginfo)
        local pending = IsValid(target) and target.LODPendingDamageAttribution or nil
        local proxy = pending and pending.attacker or (dmginfo and dmginfo.GetAttacker and dmginfo:GetAttacker())
        if IsValid(proxy) and proxy.LODSummonedSeeker and IsValid(proxy.LODCaster) then
            local originalPending = pending
            target.LODPendingDamageAttribution = {
                attacker = proxy.LODCaster,
                source = pending and pending.source or "summon"
            }
            local result = {baseAttributionRecord(self, target, dmginfo)}
            target.LODPendingDamageAttribution = originalPending
            return unpack(result)
        end
        return baseAttributionRecord(self, target, dmginfo)
    end
end

RPG.SystemBootstrap = RPG.SystemBootstrap or {}
RPG.SystemBootstrap.MagicFormSystem = "integrated_checkpoint_c"
RPG.SystemBootstrap.SummonProxySystem = "integrated_checkpoint_c"

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do if value == wanted then return true end end
    return false
end

local function actorState(actor)
    return Rules and Rules.ProgressionState and Rules:ProgressionState(actor) or nil
end

local function playerState(ply)
    local run = LOD.RunManager
    return run and run.GetPlayerState and run:GetPlayerState(ply) or nil
end

local function validCaster(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    local run = LOD.RunManager
    if run and run.IsActivePlayer and not run:IsActivePlayer(ply) then return false end
    local state = run and run.State
    return state and not state.Failed and not state.LevelCleared and not state.SimulationFrozen
end

local function activeHostiles()
    local source = LOD.HostileRegistry and LOD.HostileRegistry.List
        and LOD.HostileRegistry:List() or ents.FindByClass("lod_hostile")
    local out = {}
    for _, ent in ipairs(source or {}) do
        if IsValid(ent) and ent.LODHostile and not ent.LODDead and ent:Health() > 0 then out[#out + 1] = ent end
    end
    return out
end

local function cellSize()
    return math.max(1, tonumber(LOD.Config and LOD.Config.Maze and LOD.Config.Maze.CellSize) or 384)
end

function Forms:SpatialBonusCells(actor, state)
    state = state or actorState(actor)
    local derived = state and state.derivedStats or Rules:Derived(actor)
    local wisMod = math.floor(tonumber(derived and derived.wisMod) or 0)
    local bonus = math.max(1, wisMod)
    if contains(state and state.featIds, "WIS_ASTRAL_REACH") then bonus = bonus + 2 end
    return bonus
end

function Forms:SelectedCastState(ply)
    local state = actorState(ply)
    if not state then return nil end
    MagicProgression:EnsureState(state)
    local formId = state.selectedMagicFormId
    if not formId or not RPG.MagicForms[formId] or not contains(state.magicFormIds, formId) then return nil end
    local contentId = state.selectedMagicContentId
    if contentId and (not RPG.MagicContents[contentId] or not contains(state.contentIds, contentId)) then
        contentId = nil
        state.selectedMagicContentId = nil
    end
    return state, RPG.MagicForms[formId], contentId and RPG.MagicContents[contentId] or nil
end

function Forms:TotalBaseCost(form, content)
    return math.max(0, tonumber(form and form.magicCost) or 0)
        + math.max(0, tonumber(content and content.surcharge) or 0)
end

function Forms:_NextCastSerial(ply)
    local serial = (self.CastSerial[ply] or 0) + 1
    self.CastSerial[ply] = serial
    return serial
end

local function worldObstructionFilter(caster, target)
    return function(ent)
        if ent == caster or ent == target then return false end
        if IsValid(ent) and (ent:IsPlayer() or ent.LODHostile or ent.LODSummonedSeeker) then return false end
        local owner = IsValid(ent) and ent:GetOwner() or nil
        if owner == caster then return false end
        return true
    end
end

local function worldLineClear(caster, target, fromPos)
    if not IsValid(target) then return false end
    local tr = util.TraceLine({
        start = fromPos or caster:GetShootPos(),
        endpos = target:WorldSpaceCenter(),
        mask = MASK_SHOT,
        filter = worldObstructionFilter(caster, target)
    })
    return not tr.Hit or tr.Fraction >= 0.995
end

local function rollDetail(contract)
    local out = {}
    for i, value in ipairs(contract and contract.values or {}) do
        local threshold = contract.thresholds and contract.thresholds[i]
        out[#out + 1] = threshold and string.format("%d@%d+", value, threshold) or tostring(value)
    end
    return table.concat(out, ">")
end

function Forms:_TrimContractToBudget(contract, context)
    if not contract then return nil end
    local cap = RPG.Constants.MaxDamageDicePerAttackEvent or 128
    local used = context.damageDiceUsed or 0
    local remaining = math.max(0, cap - used)
    local values = contract.values or {}
    if #values <= remaining then
        context.damageDiceUsed = used + #values
        return contract
    end
    if remaining <= 0 then return nil end
    local trimmed = table.Copy(contract)
    trimmed.values, trimmed.contributions, trimmed.thresholds = {}, {}, {}
    local total = tonumber(contract.bonus) or 0
    for i = 1, remaining do
        trimmed.values[i] = values[i]
        trimmed.contributions[i] = contract.contributions and contract.contributions[i] or values[i]
        trimmed.thresholds[i] = contract.thresholds and contract.thresholds[i] or nil
        total = total + (tonumber(trimmed.contributions[i]) or 0)
    end
    trimmed.total = total
    trimmed.capped = true
    trimmed.baseDice = math.min(tonumber(contract.baseDice) or remaining, remaining)
    context.damageDiceUsed = cap
    return trimmed
end

function Forms:_RollDamage(attacker, form, context)
    local profile = {
        label = string.upper(form.displayName or form.id or "MAGIC"),
        source = "magic " .. tostring(form.id),
        count = form.damageDice,
        sides = form.damageSides,
        bonus = tonumber(form.damageBonus) or 0,
        exploding = form.damageSides == 6 and 6 or nil,
        magicDamage = true
    }
    local rng = Rolls:_RNG(string.format("magic-form:%s:%d", form.id, context.castSerial))
    local contract = Rolls:RollActorDamage(attacker, profile, rng, context.aceBonus or 0)
    return self:_TrimContractToBudget(contract, context)
end

function Forms:_DamageContext(content)
    local context = {magic = true}
    if not content then return context end
    context.element = content.element
    if content.rider == "immolated" or content.rider == "poisoned"
        or content.rider == "held" or content.rider == "muted" then
        context.riderStatusId = content.rider
    elseif content.rider == "morale" then
        context.forceMorale = true
    end
    return context
end

function Forms:_ApplyDamage(attacker, creditCaster, target, form, content, context, direction)
    if not IsValid(target) or target.LODDead or target:Health() <= 0 then return false end
    if (context.damageDiceUsed or 0) >= (RPG.Constants.MaxDamageDicePerAttackEvent or 128) then return false end
    local contract = self:_RollDamage(attacker, form, context)
    if not contract then return false end
    if context.sealedWizardFullMagicIntBonus ~= nil then
        contract.wizardFullMagicIntBonus = context.sealedWizardFullMagicIntBonus
    end
    local tags = self:_DamageContext(content)
    tags.wisScaled = true
    -- Rider DC is part of the caster-side Magic attack state. Seal it from the
    -- mechanical attacker (a copied summon state for proxy attacks), while the
    -- resulting status itself may retain the Hero as its durable source.
    if Status and tags.riderStatusId and Status.Registry and Status.ConditionDC then
        local definition = Status.Registry[tags.riderStatusId]
        if definition and definition.ability then
            tags.riderDC = Status:ConditionDC(attacker, definition.ability)
        end
    end
    if Status and content and content.rider == "morale" and Status.MoraleDC then
        tags.moraleDC = Status:MoraleDC(attacker)
    end
    local total = Rolls:ResolveActorDamage(contract, attacker, target, tags)
    total = math.max(0, tonumber(total) or 0)
    if total <= 0 then return false end

    local before = target:Health()
    local info = DamageInfo()
    local proxyAttack = IsValid(creditCaster) and attacker ~= creditCaster
    -- A summoned Seeker is the mechanical resolver/inflictor, but the originating
    -- Hero remains the durable damage/status source. DMG_ENERGYBEAM is already an
    -- explicit non-firearm branch in the shared combat authority, so this cannot
    -- be reinterpreted as the Hero's held gun attack.
    info:SetAttacker(proxyAttack and creditCaster or (IsValid(attacker) and attacker or creditCaster))
    info:SetInflictor(IsValid(attacker) and attacker or creditCaster)
    info:SetDamage(total)
    info:SetDamageType(DMG_ENERGYBEAM)
    info:SetDamagePosition(target:WorldSpaceCenter())
    info:SetDamageForce(vector_origin)
    if Status and Status.AttachDamageContext then Status:AttachDamageContext(info, tags) end
    if proxyAttack then
        target.LODPendingDamageAttribution = {attacker = creditCaster, source = "summon"}
        if tags.moraleDC ~= nil then creditCaster.LODMagicProxyMoraleDC = tags.moraleDC end
    end
    target:TakeDamageInfo(info)
    if proxyAttack then
        creditCaster.LODMagicProxyMoraleDC = nil
        if IsValid(target) then target.LODPendingDamageAttribution = nil end
    end

    local after = IsValid(target) and target:Health() or 0
    local actual = math.max(0, math.min(before, before - after))
    local survives = IsValid(target) and not target.LODDead and after > 0
    if survives and actual > 0 and content and content.rider == "push" and Pushback and Pushback.Apply then
        Pushback:Apply(target, {
            attacker = IsValid(attacker) and attacker or creditCaster,
            origin = IsValid(creditCaster) and creditCaster:GetPos() or nil,
            direction = direction,
            distance = 336,
            source = "earth content",
            magicPush = true
        })
    end

    local effects = RPG.FeatEffectSystem
    local resource = IsValid(creditCaster) and Magic:_EnsureState(creditCaster) or nil
    local continuations = math.max(0, #(contract.values or {}) - (contract.baseDice or form.damageDice or 0))
    if effects and effects.ApplyFeedbackLoop and resource then
        local restored
        restored, context.feedbackRestored = effects:ApplyFeedbackLoop(
            attacker, resource, continuations, context.feedbackRestored or 0)
        if restored > 0 and Magic._Sync then Magic:_Sync(creditCaster, resource) end
    end
    local defeated = before > 0 and (not IsValid(target) or target.LODDead or after <= 0)
    if effects and effects.ApplyArcRecovery and resource then
        effects:ApplyArcRecovery(attacker, resource, defeated, CurTime())
        if Magic._Sync then Magic:_Sync(creditCaster, resource) end
    end

    self.Stats.damageEvents = (self.Stats.damageEvents or 0) + 1
    self.Stats.targets = (self.Stats.targets or 0) + 1
    self.Stats.damage = (self.Stats.damage or 0) + actual
    Magic.Stats.targets = (Magic.Stats.targets or 0) + 1
    Magic.Stats.damage = (Magic.Stats.damage or 0) + actual
    if IsValid(creditCaster) and Rolls._Send and Rolls._DamageEventText then
        local detail = string.format("[%s%s%s]", rollDetail(contract),
            content and ("; " .. string.upper(content.displayName)) or "; RAW",
            contract.capped and "; work cap" or "")
        Rolls:_Send(creditCaster, 0, Rolls:_DamageEventText(creditCaster,
            contract.formula or string.format("%dd%d!", form.damageDice, form.damageSides),
            actual, target, detail, nil, "Hostile", "magic " .. form.id))
    end
    return true
end

function Forms:_NewContext(ply, form, content)
    local wizardOffense = LOD.RPGWizardOffense
    local sealedFull = wizardOffense and wizardOffense.FullMagicBonus
        and wizardOffense:FullMagicBonus(ply) or 0
    return {
        caster = ply,
        formId = form.id,
        contentId = content and content.id or nil,
        castSerial = nil,
        aceBonus = 0,
        spatialBonusCells = self:SpatialBonusCells(ply),
        damageDiceUsed = 0,
        feedbackRestored = 0,
        sealedWizardFullMagicIntBonus = sealedFull
    }
end

local function broadcastFX(formId, contentId, origin, destination)
    net.Start("LOD_MagicFormFX")
    net.WriteString(formId or "")
    net.WriteString(contentId or "raw")
    net.WriteVector(origin or vector_origin)
    net.WriteVector(destination or origin or vector_origin)
    net.Broadcast()
end

function Forms:_BlastTargets(ply, cells)
    local run = LOD.RunManager and LOD.RunManager.State
    local graph = run and run.Graph
    if not graph or not Navigator then return {} end
    local start = Navigator:WorldToCell(graph, ply:GetPos())
    if not start then return {} end
    local startKey = string.format("%d:%d:%d", start.x, start.y, start.z)
    local seen = {[startKey] = 0}
    local queue = {startKey}
    local head = 1
    while head <= #queue do
        local currentKey = queue[head]
        head = head + 1
        local distance = seen[currentKey]
        local current = graph.Cells[currentKey]
        if current and distance < cells then
            local keys = {}
            for neighborKey in pairs(current.neighbors or {}) do keys[#keys + 1] = neighborKey end
            table.sort(keys)
            for _, neighborKey in ipairs(keys) do
                if seen[neighborKey] == nil and Navigator:CanTraverse(graph, currentKey, neighborKey) then
                    seen[neighborKey] = distance + 1
                    queue[#queue + 1] = neighborKey
                end
            end
        end
    end
    local targets = {}
    for _, hostile in ipairs(activeHostiles()) do
        local cell = Navigator:WorldToCell(graph, hostile:GetPos())
        local key = cell and string.format("%d:%d:%d", cell.x, cell.y, cell.z) or nil
        if key and seen[key] ~= nil and worldLineClear(ply, hostile, ply:GetShootPos()) then
            targets[#targets + 1] = hostile
        end
    end
    table.sort(targets, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return targets
end

function Forms:_CastBlast(ply, form, content, context)
    local rangeCells = 1 + context.spatialBonusCells
    local direction = ply:GetAimVector():GetNormalized()
    local targets = self:_BlastTargets(ply, rangeCells)
    for _, target in ipairs(targets) do
        self:_ApplyDamage(ply, ply, target, form, content, context, direction)
    end
    broadcastFX("blast", content and content.id, ply:GetShootPos(), ply:GetShootPos())
    return true
end

function Forms:_CastBeam(ply, form, content, context)
    local origin = ply:GetShootPos()
    local direction = ply:GetAimVector():GetNormalized()
    if direction == vector_origin then return false end
    local maximum = self.Tuning.BaseBeamRange + context.spatialBonusCells * cellSize()
    local cursor = origin
    local remaining = maximum
    local ignored = {ply}
    for _, other in ipairs(player.GetAll()) do if other ~= ply then ignored[#ignored + 1] = other end end
    local hitCount = 0
    local endpoint = origin + direction * maximum
    local cap = RPG.Constants.MaxPenetrationTargetsPerProjectile or 4
    while remaining > 1 and hitCount < cap do
        local tr = util.TraceLine({start = cursor, endpos = cursor + direction * remaining,
            mask = MASK_SHOT, filter = ignored})
        endpoint = tr.Hit and tr.HitPos or (cursor + direction * remaining)
        if not tr.Hit then break end
        local ent = tr.Entity
        if not IsValid(ent) or not ent.LODHostile or ent.LODDead then break end
        hitCount = hitCount + 1
        self:_ApplyDamage(ply, ply, ent, form, content, context, direction)
        ignored[#ignored + 1] = ent
        local travelled = math.max(1, cursor:Distance(tr.HitPos) + 2)
        remaining = math.max(0, remaining - travelled)
        cursor = tr.HitPos + direction * 2
    end
    broadcastFX("beam", content and content.id, origin, endpoint)
    return true
end

function Forms:_SpawnProjectile(ply, form, content, context)
    local ent = ents.Create("lod_magic_projectile")
    if not IsValid(ent) then return false end
    local direction = ply:GetAimVector():GetNormalized()
    if direction == vector_origin then ent:Remove() return false end
    local speed, range, radius = 0, 0, 0
    if form.id == "bomb" then
        speed = self.Tuning.BombProjectileSpeed
        range = self.Tuning.BaseBombThrowRange
        radius = self.Tuning.BaseBombBlastRadius + context.spatialBonusCells * cellSize()
    elseif form.id == "missile" then
        speed = self.Tuning.MissileProjectileSpeed
        range = self.Tuning.BaseMissileRange + context.spatialBonusCells * cellSize()
        radius = self.Tuning.BaseMissileBlastRadius + context.spatialBonusCells * cellSize()
    elseif form.id == "bolt" then
        speed = self.Tuning.BoltProjectileSpeed
        range = self.Tuning.BaseBoltRange + context.spatialBonusCells * cellSize()
    else
        ent:Remove()
        return false
    end
    ent.LODCaster = ply
    ent.LODFormId = form.id
    ent.LODContentId = content and content.id or nil
    ent.LODCastContext = context
    ent.LODDirection = direction
    ent.LODSpeed = speed
    ent.LODMaximumTravel = range
    ent.LODBlastRadius = radius
    ent.LODSteeringDegreesPerSecond = form.id == "missile"
        and self.Tuning.MissileSteeringDegreesPerSecond or 0
    ent:SetPos(ply:GetShootPos() + direction * 24)
    ent:SetAngles(direction:Angle())
    ent:Spawn()
    ent:Activate()
    if form.id == "missile" then self.ActiveMissiles[ply] = ent end
    return true
end

function Forms:_AreaTargets(caster, origin, radius)
    local targets = {}
    for _, hostile in ipairs(activeHostiles()) do
        if hostile:WorldSpaceCenter():DistToSqr(origin) <= radius * radius
            and worldLineClear(caster, hostile, origin) then
            targets[#targets + 1] = hostile
        end
    end
    table.sort(targets, function(a, b)
        local da, db = a:WorldSpaceCenter():DistToSqr(origin), b:WorldSpaceCenter():DistToSqr(origin)
        if da ~= db then return da < db end
        return a:EntIndex() < b:EntIndex()
    end)
    return targets
end

function Forms:ProjectileImpact(projectile, trace)
    if not IsValid(projectile) then return end
    local caster = projectile.LODCaster
    local form = RPG.MagicForms[projectile.LODFormId]
    local content = projectile.LODContentId and RPG.MagicContents[projectile.LODContentId] or nil
    local context = projectile.LODCastContext
    if not form or not context or not IsValid(caster) then projectile:Remove() return end
    local direction = projectile.LODDirection or projectile:GetForward()
    local point = trace and trace.HitPos or projectile:GetPos()
    if form.id == "bolt" then
        local target = trace and trace.Entity or nil
        if IsValid(target) and target.LODHostile and not target.LODDead then
            self:_ApplyDamage(caster, caster, target, form, content, context, direction)
        end
    else
        for _, target in ipairs(self:_AreaTargets(caster, point, projectile.LODBlastRadius or 0)) do
            self:_ApplyDamage(caster, caster, target, form, content, context, direction)
        end
    end
    self.Stats.projectileImpacts = (self.Stats.projectileImpacts or 0) + 1
    broadcastFX(form.id, content and content.id, projectile:GetPos(), point)
    if form.id == "missile" and self.ActiveMissiles[caster] == projectile then self.ActiveMissiles[caster] = nil end
    projectile:Remove()
end

function Forms:_SummonCount(ply)
    local list = self.ActiveSummons[ply] or {}
    local kept = {}
    for _, ent in ipairs(list) do if IsValid(ent) then kept[#kept + 1] = ent end end
    self.ActiveSummons[ply] = kept
    return #kept
end

function Forms:_SummonPlacement(ply, context)
    local range = context.spatialBonusCells * cellSize()
    local origin = ply:GetShootPos()
    local direction = ply:GetAimVector():GetNormalized()
    if direction == vector_origin then return nil end
    local tr = util.TraceHull({
        start = origin,
        endpos = origin + direction * range,
        mins = Vector(-12, -12, -12),
        maxs = Vector(12, 12, 12),
        mask = MASK_PLAYERSOLID,
        filter = function(ent)
            if ent == ply then return false end
            if IsValid(ent) and (ent:IsPlayer() or ent.LODHostile or ent.LODSummonedSeeker) then return false end
            return true
        end
    })
    local desired = tr.Hit and (tr.HitPos - direction * 20) or tr.HitPos
    local run = LOD.RunManager and LOD.RunManager.State
    local graph = run and run.Graph
    if not graph or not Navigator then return nil end
    local cell = Navigator:WorldToCell(graph, desired)
    if not cell then return nil end
    local position = Motion and Motion.CellFloorPoint and Motion:CellFloorPoint(cell, desired)
        or Navigator:CellCenter(cell) + Vector(0, 0, 2)
    if position:DistToSqr(ply:GetPos()) > (range + 64) * (range + 64) then return nil end
    return position
end

local function frozenProgressionState(source)
    local state = table.Copy(source or {})
    state.featIds = table.Copy(source and source.featIds or {})
    state.contentIds = table.Copy(source and source.contentIds or {})
    state.magicFormIds = table.Copy(source and source.magicFormIds or {})
    state.effectiveAbilities = table.Copy(source and source.effectiveAbilities or {})
    state.featQualificationAbilities = table.Copy(source and source.featQualificationAbilities or {})
    state.derivedStats = table.Copy(source and source.derivedStats or {})
    return state
end

function Forms:_CastSummon(ply, form, content, context)
    local state = actorState(ply)
    local cap = MagicProgression:MaxActiveSummons(state)
    if self:_SummonCount(ply) >= cap then return false, "summon_cap" end
    local position = context.summonPlacement or self:_SummonPlacement(ply, context)
    if not position then return false, "placement" end
    local summon = ents.Create("lod_magic_summon")
    if not IsValid(summon) then return false, "entity" end
    summon.LODCaster = ply
    summon.LODContentId = content and content.id or nil
    summon.LODCastContext = context
    summon.LODProgressionState = frozenProgressionState(state)
    summon.LODSummonMagicPayload = {
        contentId = content and content.id or nil,
        progressionState = summon.LODProgressionState,
        wizardFullMagicIntBonus = context.sealedWizardFullMagicIntBonus,
        placedAt = CurTime()
    }
    summon:SetPos(position)
    summon:Spawn()
    summon:Activate()
    self.ActiveSummons[ply] = self.ActiveSummons[ply] or {}
    self.ActiveSummons[ply][#self.ActiveSummons[ply] + 1] = summon
    self.Stats.summons = (self.Stats.summons or 0) + 1
    broadcastFX("summon", content and content.id, ply:GetShootPos(), position)
    return true
end

function Forms:ResolveSummonAttack(summon, target)
    if not IsValid(summon) or not summon.LODSummonedSeeker or not IsValid(target)
        or not target.LODHostile or target.LODDead then return false end
    local caster = summon.LODCaster
    if not IsValid(caster) then return false end
    local content = summon.LODContentId and RPG.MagicContents[summon.LODContentId] or nil
    local form = {id = "summon", displayName = "Summon", damageDice = 2, damageSides = 6, damageBonus = 4}
    local context = {
        caster = caster,
        formId = "summon",
        contentId = content and content.id or nil,
        castSerial = (summon.LODAttackSerial or 0) + 1000000,
        aceBonus = 0,
        damageDiceUsed = 0,
        feedbackRestored = 0,
        sealedWizardFullMagicIntBonus = summon.LODSummonMagicPayload
            and summon.LODSummonMagicPayload.wizardFullMagicIntBonus or 0
    }
    summon.LODAttackSerial = (summon.LODAttackSerial or 0) + 1
    return self:_ApplyDamage(summon, caster, target, form, content, context,
        (target:WorldSpaceCenter() - summon:WorldSpaceCenter()):GetNormalized())
end

function Forms:_CanCastPreSpend(ply, form, context)
    if form.id == "missile" and IsValid(self.ActiveMissiles[ply]) then return false, "guided_missile_cap" end
    if form.id == "summon" then
        local state = actorState(ply)
        if self:_SummonCount(ply) >= MagicProgression:MaxActiveSummons(state) then return false, "summon_cap" end
        context.summonPlacement = self:_SummonPlacement(ply, context)
        if not context.summonPlacement then return false, "placement" end
    end
    return true
end

function Forms:CastSelected(ply)
    if not validCaster(ply) then return false end
    if Status and not Status:CanInitiateMagic(ply) then return false end
    local state, form, content = self:SelectedCastState(ply)
    if not state or not form then return false end
    local ps = Magic:_EnsureState(ply)
    if not ps then return false end
    local now = CurTime()
    if now < (Magic.NextCast[ply] or 0) then return false end

    local context = self:_NewContext(ply, form, content)
    local preOK, preReason = self:_CanCastPreSpend(ply, form, context)
    if not preOK then
        self.Stats.failed = (self.Stats.failed or 0) + 1
        ply:EmitSound("buttons/button10.wav", 52, 85, 0.45, CHAN_ITEM)
        return false, preReason
    end

    local baseCost = self:TotalBaseCost(form, content)
    local cost = Rules.OffensiveMagicCost and Rules:OffensiveMagicCost(ply, baseCost) or baseCost
    if ps.magic < cost then
        self.Stats.failed = (self.Stats.failed or 0) + 1
        ply:EmitSound("buttons/button10.wav", 52, 85, 0.45, CHAN_ITEM)
        return false, "magic"
    end

    -- Commit the attack transaction only after every no-spend legality check and
    -- affordability check succeeds. Pay before synchronous damage so Magic-recovery
    -- feats see the post-cost resource state, while the full-Magic bonus remains the
    -- cast-initiation snapshot sealed above.
    context.castSerial = self:_NextCastSerial(ply)
    context.aceBonus = Rules.CommitAttack and Rules:CommitAttack(ply) and 1 or 0
    local previousCooldown = Magic.NextCast[ply] or 0
    ps.magic = math.max(0, ps.magic - cost)
    ps.gateEControlMagicTestHoldUntil = nil
    Magic.NextCast[ply] = now + 0.85
    Magic:_Sync(ply, ps)

    local castOK, reason
    if form.id == "blast" then castOK = self:_CastBlast(ply, form, content, context)
    elseif form.id == "beam" then castOK = self:_CastBeam(ply, form, content, context)
    elseif form.id == "bomb" or form.id == "missile" or form.id == "bolt" then
        castOK = self:_SpawnProjectile(ply, form, content, context)
    elseif form.id == "summon" then castOK, reason = self:_CastSummon(ply, form, content, context) end
    if not castOK then
        ps.magic = math.min(100, ps.magic + cost)
        Magic.NextCast[ply] = previousCooldown
        Magic:_Sync(ply, ps)
        self.Stats.failed = (self.Stats.failed or 0) + 1
        return false, reason or "cast"
    end

    local effects = RPG.FeatEffectSystem
    if effects and effects.RecordQuantumSpend then effects:RecordQuantumSpend(ply, baseCost, cost) end
    self.Stats.casts = (self.Stats.casts or 0) + 1
    Magic.Stats.casts = (Magic.Stats.casts or 0) + 1

    ply:EmitSound("ambient/energy/weld2.wav", 76, 95, 0.55, CHAN_STATIC)
    if ply.AnimRestartGesture then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE, true)
    end
    return true
end

-- Existing client and server input continues to call this method. Replacing only
-- its implementation keeps RMB, suppression, Wizard snapshot wrapping, and old
-- test tooling on one authoritative activation seam.
function Magic:CastForceShout(ply)
    return Forms:CastSelected(ply)
end

function Forms:Validate()
    local errors = {}
    local function expect(ok, message) if not ok then errors[#errors + 1] = message end end
    local t = self.Tuning
    expect(t.BaseBeamRange == 1152, "BaseBeamRange")
    expect(t.BaseBombThrowRange == 1152 and t.BaseBombBlastRadius == 96, "Bomb tuning")
    expect(t.BaseMissileRange == 1536 and t.BaseMissileBlastRadius == 128, "Missile range/radius")
    expect(t.MissileProjectileSpeed == 900 and t.MissileSteeringDegreesPerSecond == 180,
        "Missile flight tuning")
    expect(t.MaxActiveGuidedMissilesPerCaster == 1, "one active guided Missile")
    expect(t.BaseBoltRange == 1920 and t.BoltProjectileSpeed == 2400, "Bolt tuning")
    local forms = RPG.MagicForms or {}
    expect(forms.blast and forms.blast.damageDice == 2 and forms.blast.magicCost == 45, "Blast catalog")
    expect(forms.beam and forms.beam.damageDice == 2 and forms.beam.magicCost == 20, "Beam catalog")
    expect(forms.bomb and forms.bomb.damageDice == 3 and forms.bomb.magicCost == 20, "Bomb catalog")
    expect(forms.missile and forms.missile.damageDice == 3 and forms.missile.magicCost == 25, "Missile catalog")
    expect(forms.bolt and forms.bolt.damageDice == 4 and forms.bolt.magicCost == 15, "Bolt catalog")
    expect(forms.summon and forms.summon.magicCost == 40, "Summon catalog")
    local contents = RPG.MagicContents or {}
    expect(contents.earth and contents.earth.surcharge == 10 and contents.earth.rider == "push", "Earth")
    expect(contents.fire and contents.fire.surcharge == 15 and contents.fire.rider == "immolated", "Fire")
    expect(contents.dark and contents.dark.surcharge == 15 and contents.dark.rider == "poisoned", "Dark")
    expect(contents.ice and contents.ice.surcharge == 10 and contents.ice.rider == "held", "Ice")
    expect(contents.light and contents.light.surcharge == 5 and contents.light.rider == "muted", "Light")
    expect(contents.electric and contents.electric.surcharge == 10 and contents.electric.rider == "morale", "Electric")
    expect(self:TotalBaseCost(forms.bolt, contents.light) == 20, "Form + Content cost composition")
    return #errors == 0, errors
end

if LOD.RPGValidation and not LOD.RPGValidation.LODCheckpointCMagicWrapped then
    LOD.RPGValidation.LODCheckpointCMagicWrapped = true
    local validation = LOD.RPGValidation
    local base = validation.Run
    function validation:Run(printResult)
        local baseOK, errors = base(self, false)
        errors = errors or {}
        local formOK, formErrors = Forms:Validate()
        for _, message in ipairs(formErrors or {}) do
            errors[#errors + 1] = "Checkpoint C Magic: " .. tostring(message)
        end
        local progressionOK, progressionErrors = MagicProgression:Validate()
        for _, message in ipairs(progressionErrors or {}) do
            errors[#errors + 1] = "Checkpoint C progression: " .. tostring(message)
        end
        local arcaneOK, arcaneErrors = false, {"Arcane-cap validator unavailable"}
        if LOD.RPGWizardRules and LOD.RPGWizardRules.ValidateArcaneCap then
            arcaneOK, arcaneErrors = LOD.RPGWizardRules:ValidateArcaneCap()
        end
        for _, message in ipairs(arcaneErrors or {}) do
            errors[#errors + 1] = "Checkpoint C Arcane cap: " .. tostring(message)
        end
        local ok = baseOK and formOK and progressionOK and arcaneOK and #errors == 0
        if printResult ~= false then
            if ok then
                print("[LOD:RPG] integrated Checkpoint C validation PASS — forms=6 contents=6 arcaneCap=0.50")
            else
                ErrorNoHalt("[LOD:RPG] integrated Checkpoint C validation FAILED (" .. #errors .. " error(s))\n")
                for _, message in ipairs(errors) do
                    ErrorNoHalt("[LOD:RPG]  - " .. tostring(message) .. "\n")
                end
            end
        end
        return ok, errors
    end
end

concommand.Add("lod_magic_forms_validate", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local ok, errors = Forms:Validate()
    local pOK, pErrors = MagicProgression:Validate()
    if not pOK then for _, err in ipairs(pErrors or {}) do errors[#errors + 1] = "progression: " .. err end end
    local aOK, aErrors = false, {"Arcane-cap validator unavailable"}
    if LOD.RPGWizardRules and LOD.RPGWizardRules.ValidateArcaneCap then
        aOK, aErrors = LOD.RPGWizardRules:ValidateArcaneCap()
    end
    if not aOK then
        for _, err in ipairs(aErrors or {}) do errors[#errors + 1] = "arcane: " .. err end
    end
    ok = ok and pOK and aOK and #errors == 0
    local line = string.format("Magic Checkpoint C validation %s - forms=6 contents=6 casts=%d",
        ok and "PASS" or "FAILED", Forms.Stats.casts or 0)
    print("[LOD:MAGIC-C] " .. line)
    for _, err in ipairs(errors) do ErrorNoHalt("[LOD:MAGIC-C] - " .. tostring(err) .. "\n") end
    if IsValid(ply) then ply:ChatPrint(line) end
end)
