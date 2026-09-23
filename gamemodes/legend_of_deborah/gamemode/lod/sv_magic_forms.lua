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
    Wall = {lifetime=10, durationPerWis=2, maxLifetime=30, baseWidth=288, height=112,
        thickness=12, reach=240, minWidth=48, contact=24, interval=.1, hitDelay=1,
        stunMultiplier=2.5, maxActive=1, maxGlobal=16, clearance=4, minHeight=48,
        groundProbe=512, fitStep=24, fitAttempts=5, previewInterval=.15, previewHeartbeat=.5},
    SuperBall = {speed=900, lifetime=6, bounces=32, hits=6, perTargetDelay=.3,
        maxActive=2, maxGlobal=32, radius=8, gravity=260, jitter=.18, steps=4, separation=.5},
    Watermelon = {lifetime=8, radius=7, gravity=600, restitution=.78, minLift=220,
        hitDelay=.35, separation=1, steps=4},
    WatermelonSpeed = 580,
    WatermelonRange = 4000,
    WatermelonRadius = 72,
    BaseConeRange = 480,
    ConeHalfAngle = 32,
    CastCooldown = 0.85,
    BeamCooldown = 0.65,
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
Forms.ActiveWalls = Forms.ActiveWalls or {}
Forms.ActiveSuperBalls = Forms.ActiveSuperBalls or {}
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
    if LOD.Equipment and LOD.Equipment:IsActive(ply) then return false end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    local run = LOD.RunManager
    if run and run.IsActivePlayer and not run:IsActivePlayer(ply) then return false end
    local state = run and run.State
    return state and not state.Failed and not state.LevelCleared and not state.SimulationFrozen
end

local function validTarget(caster, target)
    if LOD.FactionManager and LOD.FactionManager.IsOpponent then
        return LOD.FactionManager:IsOpponent(caster, target)
    end
    return IsValid(target) and target.LODHostile and not target.LODDead and target:Health() > 0
end

local function activeHostiles(caster)
    if LOD.FactionManager and LOD.FactionManager.Opponents then return LOD.FactionManager:Opponents(caster) end
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

function Forms:SelectedCastState(ply,button)
    local state = actorState(ply)
    if not state then return nil end
    MagicProgression:EnsureState(state)
    local formId = button and state.magicBindings[tostring(button)] or state.selectedMagicFormId
    if button and not state.magicBindings[tostring(button)] then return nil end
    if not MagicProgression:FormAllowed(state,formId) then return nil end
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
        mask = MASK_SOLID,
        filter = worldObstructionFilter(caster, target)
    })
    return not tr.Hit or tr.Fraction >= 0.995
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
        magicDamage = not form.physical, attackEvent = context
    }
    local rng = Rolls:_RNG(string.format("magic-form:%s:%d", form.id, context.castSerial))
    local contract = Rolls:RollActorDamage(attacker, profile, rng, context.aceBonus or 0)
    return self:_TrimContractToBudget(contract, context)
end

function Forms:_DamageContext(content)
    local context = {magic = true}
    if not content then return context end
    context.element = content.element
    if Status and Status.Registry and Status.Registry[content.rider] then
        context.riderStatusId = content.rider
    elseif content.rider == "morale" then
        context.forceMorale = true
    end
    return context
end

function Forms:_ReportDamageRoll(creditCaster, target, form, content, contract, amount)
    if not IsValid(creditCaster) then return end
    local view = contract.feedResolution and contract.feedResolution.resolvedContract or contract
    local continuations = math.max(0, #(view.values or {}) - (view.baseDice or form.damageDice or 0))
    if continuations > 0 and Rolls.EmitDiceExplosionFX then
        Rolls:EmitDiceExplosionFX(creditCaster, "magic_" .. form.id, continuations, 1)
    end
    if Rolls._Send and Rolls._DamageEventText then
        local detail = string.format("[rolls %s%s%s]", LOD.DieLogger:RollBreakdown(contract),
            content and ("; " .. string.upper(content.displayName)) or "; RAW",
            contract.capped and "; work cap" or "")
        if contract.magicSave then
            local save=contract.magicSave
            detail=detail..string.format(" [%s save %d vs DC %d: %s]",string.upper(save.ability),
                save.total,save.dc,save.passed and "HALF DAMAGE" or "FULL DAMAGE")
        end
        Rolls:_Send(creditCaster, 0, Rolls:_DamageEventText(creditCaster,
            LOD.DieLogger:DamageFormula(contract) or string.format("%dd%d!", form.damageDice, form.damageSides),
            amount, target, detail, nil, "Hostile", "magic " .. form.id))
    end
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
    if context.wand then
        tags.wand=true
        contract.equipmentSnapshot=context.equipmentSnapshot
    end
    tags.throwable = form.throwable == true
    tags.wisScaled = not form.physical
    if form.physical then tags.magic=false;tags.physical=true end
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
    if form.saveAbility then
        local dc=Status:ConditionDC(attacker,form.saveAbility)
        local save,natural=Status:ConditionSave(target,form.saveAbility,
            Rolls:_RNG("magic-save:"..form.id..":"..context.castSerial))
        local passed=save>=dc
        if passed then total=total*.5 end
        contract.magicSave={ability=form.saveAbility,dc=dc,total=save,natural=natural,passed=passed}
    end
    if total <= 0 then
        self:_ReportDamageRoll(creditCaster,target,form,content,contract,0)
        return false
    end

    local before = target:Health()
    local info = LOD.NewDamageInfo()
    local proxyAttack = IsValid(creditCaster) and attacker ~= creditCaster
    -- A summoned Seeker is the mechanical resolver/inflictor, but the originating
    -- Hero remains the durable damage/status source. DMG_ENERGYBEAM is already an
    -- explicit non-firearm branch in the shared combat authority, so this cannot
    -- be reinterpreted as the Hero's held gun attack.
    info:SetAttacker(proxyAttack and creditCaster or (IsValid(attacker) and attacker or creditCaster))
    info:SetInflictor(IsValid(attacker) and attacker or creditCaster)
    info:SetDamage(total)
    info:SetDamageType(form.physical and DMG_BLAST or DMG_ENERGYBEAM)
    info:SetDamagePosition(target:WorldSpaceCenter())
    info:SetDamageForce(vector_origin)
    tags.attackEvent, tags.damageContract, tags.actorDamageResolved = context, contract, true
    if Status and Status.AttachDamageContext then Status:AttachDamageContext(info, tags) end
    local previousAttribution = target.LODPendingDamageAttribution
    local previousProxyDC = IsValid(creditCaster) and creditCaster.LODMagicProxyMoraleDC
    if proxyAttack then
        target.LODPendingDamageAttribution = {attacker = creditCaster, source = "summon"}
        if tags.moraleDC ~= nil then creditCaster.LODMagicProxyMoraleDC = tags.moraleDC end
    end
    target:TakeDamageInfo(info)
    if proxyAttack then
        creditCaster.LODMagicProxyMoraleDC = previousProxyDC
        if IsValid(target) then target.LODPendingDamageAttribution = previousAttribution end
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

    local stunMultiplier=form.hitStunMultiplier or (form.id=="wall" and self.Tuning.Wall.stunMultiplier)
    if survives and actual > 0 and stunMultiplier and LOD.M3HitFeedback then
        if form.hitStunMultiplier then
            stunMultiplier=stunMultiplier*(tags.elementResolution and tags.elementResolution.hitStunMultiplier or 1)
        end
        LOD.M3HitFeedback:ApplyHitStun(target,1,attacker,stunMultiplier)
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
    self:_ReportDamageRoll(creditCaster,target,form,content,contract,actual)
    return true
end

function Forms:_NewContext(ply, form, content)
    local wizardOffense = LOD.RPGWizardOffense
    local sealedFull = wizardOffense and wizardOffense.FullMagicBonus
        and wizardOffense:FullMagicBonus(ply) or 0
    return {
        equipmentSnapshot=LOD.Equipment and LOD.Equipment.CaptureAttack and LOD.Equipment:CaptureAttack(ply,nil) or nil,
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

local function broadcastFX(formId, contentId, origin, destination, caster, area)
    net.Start("LOD_MagicFormFX")
    net.WriteString(formId or "")
    net.WriteString(contentId or "raw")
    net.WriteVector(origin or vector_origin)
    net.WriteVector(destination or origin or vector_origin)
    net.WriteEntity(IsValid(caster) and caster or NULL)
    -- Shape comes from the targeting transaction, never a guessed client radius.
    net.WriteUInt(area and area.kind or 0, 2)
    if area and area.kind == 1 then
        net.WriteFloat(area.radius)
    elseif area and area.kind == 2 then
        local maze = LOD.Config.Maze
        net.WriteVector(LOD.MazeBuilder:CellCenter({x=0,y=0,z=0}))
        net.WriteFloat(maze.CellSize)
        net.WriteFloat(maze.LevelHeight)
        net.WriteUInt(#area.cells, 16)
        -- The canonical maze is 21x21 with at most four layers: three bytes per
        -- reachable cell, no per-cell packet and no client navigation scan.
        for _, cell in ipairs(area.cells) do
            net.WriteUInt(cell.x, 8); net.WriteUInt(cell.y, 8); net.WriteUInt(cell.z, 8)
        end
    end
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
    local targets, footprint = {}, {}
    for _, key in ipairs(queue) do
        local cell = graph.Cells[key]
        if cell then footprint[#footprint + 1] = {x=cell.x,y=cell.y,z=cell.z} end
    end
    for _, hostile in ipairs(activeHostiles(ply)) do
        local cell = Navigator:WorldToCell(graph, hostile:GetPos())
        local key = cell and string.format("%d:%d:%d", cell.x, cell.y, cell.z) or nil
        if key and seen[key] ~= nil and worldLineClear(ply, hostile, ply:GetShootPos()) then
            targets[#targets + 1] = hostile
        end
    end
    table.sort(targets, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return targets, footprint
end

-- All instantaneous/area forms share generated solid cover semantics. Open
-- stairs and shafts remain legal: elevation alone never rejects an exposed hit.
function Forms:LineOfEffect(caster, target, origin)
    return worldLineClear(caster, target, origin)
end

function Forms:_ConeTargets(caster, origin, direction, range)
    local targets = {}
    local threshold = math.cos(math.rad(self.Tuning.ConeHalfAngle))
    for _, target in ipairs(self:_AreaTargets(caster, origin, range)) do
        local offset = target:WorldSpaceCenter() - origin
        if offset:LengthSqr() > 0 and offset:GetNormalized():Dot(direction) >= threshold then
            targets[#targets + 1] = target
        end
    end
    return targets
end

function Forms:_CastCone(ply, form, content, context)
    local origin, direction = ply:GetShootPos(), ply:GetAimVector():GetNormalized()
    if direction == vector_origin then return false end
    local range = self.Tuning.BaseConeRange + context.spatialBonusCells * cellSize()
    for _, target in ipairs(self:_ConeTargets(ply, origin, direction, range)) do
        self:_ApplyDamage(ply, ply, target, form, content, context, direction)
    end
    broadcastFX("cone", content and content.id, origin, origin + direction * range, ply)
    return true
end

function Forms:_CastBlast(ply, form, content, context)
    local rangeCells = 1 + context.spatialBonusCells
    local direction = ply:GetAimVector():GetNormalized()
    local targets, footprint = self:_BlastTargets(ply, rangeCells)
    local origin = ply:GetShootPos()
    for _, target in ipairs(targets) do
        self:_ApplyDamage(ply, ply, target, form, content, context, direction)
    end
    broadcastFX("blast", content and content.id, origin, origin, ply,
        {kind=2, cells=footprint or {}})
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
    for _, other in ipairs(player.GetAll()) do
        if other ~= ply and not validTarget(ply, other) then ignored[#ignored + 1] = other end
    end
    local hitCount = 0
    local endpoint = origin + direction * maximum
    local cap = RPG.Constants.MaxPenetrationTargetsPerProjectile or 128
    local seen, steps = {}, 0
    while remaining > 1 and hitCount < cap and steps < 512 do
        if context.sourceValid and not context.sourceValid() then break end
        steps = steps + 1
        local tr = util.TraceLine({start = cursor, endpos = cursor + direction * remaining,
            mask = MASK_SOLID, filter = ignored})
        endpoint = tr.Hit and tr.HitPos or (cursor + direction * remaining)
        if not tr.Hit then break end
        local ent = tr.Entity
        local body = IsValid(ent) and (ent.LODHostile or ent.LODSummonedSeeker or (ent.IsPlayer and ent:IsPlayer()))
        if not body or seen[ent] then break end
        seen[ent] = true
        if validTarget(ply, ent) then
            hitCount = hitCount + 1
            self:_ApplyDamage(ply, ply, ent, form, content, context, direction)
        end
        ignored[#ignored + 1] = ent
        local travelled = math.max(1, cursor:Distance(tr.HitPos) + 2)
        remaining = math.max(0, remaining - travelled)
        cursor = tr.HitPos + direction * 2
    end
    broadcastFX("beam", content and content.id, origin, endpoint, ply)
    return true
end

Forms.BroadcastFX = function(_,...) return broadcastFX(...) end

function Forms:_SpawnProjectile(ply, form, content, context)
    local ent = ents.Create("lod_magic_projectile")
    if not IsValid(ent) then return false end
    local direction = ply:GetAimVector():GetNormalized()
    if direction == vector_origin then ent:Remove() return false end
    local speed, range, radius = 0, 0, 0
    local delivery=form.projectile
    if delivery then
        speed,range=delivery.speed,delivery.range
        local origin=ply:GetShootPos()
        local trace=util.TraceHull({start=origin,endpos=origin,mins=Vector(-3,-3,-3),
            maxs=Vector(3,3,3),mask=MASK_SOLID,filter=ply})
        if trace.StartSolid or trace.AllSolid then ent:Remove();return false end
    elseif form.id == "super_ball" then
        speed = self.Tuning.SuperBall.speed
        range = speed * self.Tuning.SuperBall.lifetime
    elseif form.id == "watermelon" then
        speed = self.Tuning.WatermelonSpeed
        range = self.Tuning.WatermelonRange
        radius = self.Tuning.WatermelonRadius + context.spatialBonusCells * cellSize()
    elseif form.id == "bomb" then
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
    ent.LODFormId = delivery and delivery.form or form.id
    ent.LODContentId = content and content.id or nil
    ent.LODCastContext = context
    ent.LODExpiresAt = delivery and CurTime()+delivery.lifetime or nil
    ent.LODDirection = direction
    ent.LODSpeed = speed
    ent.LODMaximumTravel = range
    ent.LODBlastRadius = radius
    ent.LODSteeringDegreesPerSecond = form.id == "missile"
        and self.Tuning.MissileSteeringDegreesPerSecond or 0
    -- The ricochet begins at the shoot origin: never teleport its hull past a wall.
    ent:SetPos(ply:GetShootPos() + direction * ((delivery or form.id=="super_ball" or form.id=="watermelon") and 0 or 24))
    ent:SetAngles(direction:Angle())
    ent:Spawn()
    ent:Activate()
    if not IsValid(ent) then return false end
    if form.id == "missile" then self.ActiveMissiles[ply] = ent end
    if form.id == "super_ball" then self.ActiveSuperBalls[ent] = ply end
    return true,ent
end

-- Only equipment deliveries opt into this stronger source/life binding. Normal
-- Forms retain their existing projectile lifecycle and presentation contracts.
function Forms:ProjectileContextValid(projectile)
    local context=projectile.LODCastContext
    if not context or not context.moveBinding then return true end
    return (not projectile.LODExpiresAt or CurTime()<projectile.LODExpiresAt)
        and LOD.Equipment:MoveAttackValid(projectile.LODCaster,context)
end

function Forms:_AreaTargets(caster, origin, radius)
    local targets = {}
    for _, hostile in ipairs(activeHostiles(caster)) do
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

Forms.TargetIsOpponent = function(_,caster,target) return validTarget(caster,target) end
Forms.LineOfEffect = function(_,caster,target,origin) return worldLineClear(caster,target,origin) end

function Forms:SuperBallHit(projectile,target,origin,usedRider)
    local caster,context=projectile.LODCaster,projectile.LODCastContext
    if not context or not validTarget(caster,target) or not worldLineClear(caster,target,origin) then return false end
    local content=RPG.MagicContents[projectile.LODContentId]
    if usedRider and content then content=table.Copy(content);content.rider=nil end
    local before=target:Health()
    self:_ApplyDamage(caster,caster,target,RPG.MagicForms.super_ball,content,context,projectile.LODDirection)
    projectile.LODBallLastDamaged=not IsValid(target) or target:Health()<before
    broadcastFX('super_ball',projectile.LODContentId,origin,projectile:GetPos(),caster)
    return true
end

function Forms:ProjectileImpact(projectile, trace)
    if not IsValid(projectile) then return end
    if projectile.LODImpactResolved then return end
    projectile.LODImpactResolved = true
    if not self:ProjectileContextValid(projectile) then projectile:Remove();return end
    local caster = projectile.LODCaster
    local context = projectile.LODCastContext
    local form = context and context.deliveryForm or RPG.MagicForms[projectile.LODFormId]
    local content = context and context.deliveryContent or (projectile.LODContentId and RPG.MagicContents[projectile.LODContentId] or nil)
    if not form or not context or not IsValid(caster) then projectile:Remove() return end
    local direction = projectile.LODDirection or projectile:GetForward()
    local point = trace and trace.HitPos or projectile:GetPos()
    if trace and trace.HitNormal then point = point + trace.HitNormal * 2 end
    if projectile.LODFormId == "bolt" then
        local target = trace and trace.Entity or nil
        if validTarget(caster, target) then
            self:_ApplyDamage(caster, caster, target, form, content, context, direction)
        end
    else
        for _, target in ipairs(self:_AreaTargets(caster, point, projectile.LODBlastRadius or 0)) do
            local rider=content
            if projectile.LODMelon and projectile.LODMelon.riders[target] and content then rider=table.Copy(content);rider.rider=nil end
            self:_ApplyDamage(caster, caster, target, form, rider, context, direction)
        end
    end
    self.Stats.projectileImpacts = (self.Stats.projectileImpacts or 0) + 1
    broadcastFX(projectile.LODFormId, content and content.id, projectile:GetPos(), point, caster,
        projectile.LODFormId ~= "bolt" and {kind=1, radius=projectile.LODBlastRadius or 0} or nil)
    if form.id == "missile" and self.ActiveMissiles[caster] == projectile then self.ActiveMissiles[caster] = nil end
    projectile:Remove()
end

function Forms:DetonateThrowable(caster,origin,definition)
    local form={id="bomb",throwable=true,displayName=definition.name,damageDice=LOD.Equipment.BombTuning.damageDice,
        damageSides=LOD.Equipment.BombTuning.damageSides,physical=definition.element==nil}
    local content={id=definition.element or "raw",displayName=definition.name,element=definition.element,
        rider=definition.status=="intimidated" and "morale" or definition.status}
    local context=self:_NewContext(caster,form,content)
    context.castSerial=self:_NextCastSerial(caster)
    local radius=LOD.Equipment.BombTuning.radius
    for _,target in ipairs(self:_AreaTargets(caster,origin,radius)) do
        self:_ApplyDamage(caster,caster,target,form,content,context,(target:WorldSpaceCenter()-origin):GetNormalized())
    end
    broadcastFX("bomb",content.id,origin,origin,caster,{kind=1,radius=radius})
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
    if not actorState(ply) or actorState(ply).classId ~= "wizard" then return false, "wizard_only" end
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
    broadcastFX("summon", content and content.id, ply:GetShootPos(), position, ply)
    return true
end

function Forms:ResolveSummonAttack(summon, target)
    if not IsValid(summon) or not summon.LODSummonedSeeker
        or not validTarget(summon, target) then return false end
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
    local origin,point=summon:WorldSpaceCenter(),target:WorldSpaceCenter()
    local result=self:_ApplyDamage(summon, caster, target, form, content, context,
        (point-origin):GetNormalized())
    if result then broadcastFX("summon_hit",content and content.id or "raw",origin,point,caster) end
    return result
end

function Forms:_CanCastPreSpend(ply, form, context)
    if form.id=="wall" then return self:CanPlaceWall(ply,context) end
    if form.id=="super_ball" then
        local own,total=0,0
        for ent,caster in pairs(self.ActiveSuperBalls) do
            if not IsValid(ent) then self.ActiveSuperBalls[ent]=nil
            else total=total+1;if caster==ply then own=own+1 end end
        end
        if own>=self.Tuning.SuperBall.maxActive or total>=self.Tuning.SuperBall.maxGlobal then return false,"super_ball_cap" end
    end
    if form.id == "missile" and IsValid(self.ActiveMissiles[ply]) then return false, "guided_missile_cap" end
    if form.id == "summon" then
        local state = actorState(ply)
        if self:_SummonCount(ply) >= MagicProgression:MaxActiveSummons(state) then return false, "summon_cap" end
        context.summonPlacement = self:_SummonPlacement(ply, context)
        if not context.summonPlacement then return false, "placement" end
    end
    return true
end

local function castNotice(ply, form, content, reason, cost, remaining, serial)
    local presentation = LOD.RPGPresentation
    if not presentation or not presentation.Event then return end
    local reasons = {wall_cap="Wall limit reached", wall_placement="aim at a clear floor gap", wall_ground="no floor within reach",
        wall_reach="floor is beyond Wall reach", wall_slope="surface is too steep", wall_anchor_blocked="ground probe begins inside solid geometry",
        wall_space="not enough clear space", wall_ceiling="ceiling too low", wall_narrow="gap too narrow", wall_blocked="solid cover blocks placement", super_ball_cap = "Super Ball limit reached", magic = "insufficient Magic", guided_missile_cap = "guided missile already active",
        summon_cap = "summon limit reached", placement = "no clear summon placement",
        status = "current status prevents Magic", entity = "summon unavailable", cast = "cast failed"}
    local label = form and (form.displayName or form.id) or "Magic"
    if content then label = label .. " / " .. (content.displayName or content.id) end
    local text = reason and (label .. ": " .. (reasons[reason] or reason) .. " — no Magic spent")
        or string.format("%s — %g Magic spent / %.1f remaining", label, cost, remaining)
    presentation:Event(ply, reason and "blocked" or "magic", text,
        {event = "magic_cast", form = form and form.id, content = content and content.id,
            outcome = reason or "committed", spent = reason and 0 or cost, remaining = remaining,
            cast_serial = serial}, reason and ("cast:" .. reason) or nil)
end

function Forms:CastSelected(ply,button)
    if not validCaster(ply) then return false end
    if Status and not Status:CanInitiateMagic(ply) then
        castNotice(ply, nil, nil, "status")
        return false
    end
    local state, form, content = self:SelectedCastState(ply,button)
    if not state or not form then return false end
    local ps = Magic:_EnsureState(ply)
    if not ps then return false end
    local now = CurTime()
    if now < (Magic.NextCast[ply] or 0) then return false end

    local context = self:_NewContext(ply, form, content)
    local preOK, preReason = self:_CanCastPreSpend(ply, form, context)
    if not preOK then
        self.Stats.failed = (self.Stats.failed or 0) + 1
        LOD.Audio:Emit(ply,'deny')
        castNotice(ply, form, content, preReason, 0, ps.magic)
        return false, preReason
    end

    local baseCost = self:TotalBaseCost(form, content)
    local cost = Rules.OffensiveMagicCost and Rules:OffensiveMagicCost(ply, baseCost) or baseCost
    if ps.magic < cost then
        self.Stats.failed = (self.Stats.failed or 0) + 1
        LOD.Audio:Emit(ply,'deny')
        castNotice(ply, form, content, "magic", 0, ps.magic)
        return false, "magic"
    end

    -- Commit the attack transaction only after every no-spend legality check and
    -- affordability check succeeds. Pay before synchronous damage so Magic-recovery
    -- feats see the post-cost resource state, while the full-Magic bonus remains the
    -- cast-initiation snapshot sealed above.
    context.auraBurst = RPG:PrepareCheckpointDAuraBurst(ply)
    context.castSerial = self:_NextCastSerial(ply)
    local previousAceReady = ply.LODRPGNextAceReadyAt
    context.aceBonus = Rules.CommitAttack and Rules:CommitAttack(ply) and 1 or 0
    local previousCooldown = Magic.NextCast[ply] or 0
    ps.magic = math.max(0, ps.magic - cost)
    ps.gateEControlMagicTestHoldUntil = nil
    Magic.NextCast[ply] = now + (form.id == "beam" and self.Tuning.BeamCooldown or self.Tuning.CastCooldown)
    ply:SetNW2Float("LOD_MagicNextCast", Magic.NextCast[ply])
    Magic:_Sync(ply, ps)

    local castOK, reason
    if form.id == "wall" then castOK = self:_CastWall(ply, form, content, context)
    elseif form.id == "cone" then castOK = self:_CastCone(ply, form, content, context)
    elseif form.id == "blast" then castOK = self:_CastBlast(ply, form, content, context)
    elseif form.id == "beam" then castOK = self:_CastBeam(ply, form, content, context)
    elseif form.id == "bomb" or form.id == "missile" or form.id == "bolt" or form.id == "watermelon" or form.id == "super_ball" then
        castOK = self:_SpawnProjectile(ply, form, content, context)
    elseif form.id == "summon" then castOK, reason = self:_CastSummon(ply, form, content, context) end
    if not castOK then
        ps.magic = math.min(100, ps.magic + cost)
        Magic.NextCast[ply] = previousCooldown
        ply:SetNW2Float("LOD_MagicNextCast", previousCooldown)
        ply.LODRPGNextAceReadyAt = previousAceReady
        Magic:_Sync(ply, ps)
        self.Stats.failed = (self.Stats.failed or 0) + 1
        castNotice(ply, form, content, reason or "cast", 0, ps.magic, context.castSerial)
        return false, reason or "cast"
    end

    local effects = RPG.FeatEffectSystem
    if effects and effects.RecordQuantumSpend then effects:RecordQuantumSpend(ply, baseCost, cost) end
    -- One observer event only after a real committed activation. Failed/refunded
    -- casts and sustained utility drains cannot trigger Aura Burst.
    if cost > 0 then hook.Run("LODDiscreteMagicSpent", ply, cost, context) end
    self.Stats.casts = (self.Stats.casts or 0) + 1
    Magic.Stats.casts = (Magic.Stats.casts or 0) + 1

    ply:EmitSound("ambient/energy/weld2.wav", 76, 95, 0.55, CHAN_STATIC)
    if ply.AnimRestartGesture then
        ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE, true)
    end
    castNotice(ply, form, content, nil, cost, ps.magic, context.castSerial)
    return true
end

-- Existing client and server input continues to call this method. Replacing only
-- its implementation keeps RMB, suppression, Wizard snapshot wrapping, and old
-- test tooling on one authoritative activation seam.
function Magic:CastForceShout(ply,button)
    return Forms:CastSelected(ply,button)
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
    expect(forms.blast and forms.blast.damageDice == 2 and forms.blast.magicCost == 30, "Blast catalog")
    expect(forms.beam and forms.beam.damageDice == 3 and forms.beam.magicCost == 18, "Beam catalog")
    expect(forms.bomb and forms.bomb.damageDice == 3 and forms.bomb.magicCost == 20, "Bomb catalog")
    expect(forms.missile and forms.missile.damageDice == 3 and forms.missile.magicCost == 28, "Missile catalog")
    expect(forms.bolt and forms.bolt.damageDice == 4 and forms.bolt.magicCost == 15, "Bolt catalog")
    expect(forms.summon and forms.summon.magicCost == 12, "Summon catalog")
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
