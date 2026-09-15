-- One defender roll per physical attack, at the final shared mitigation seam.
local Rules = assert(LOD.RPGAbilityRules)
Rules.BlockEvents = setmetatable({}, {__mode="k"})
util.AddNetworkString("LOD_BlockPulse")

function Rules:BlockChance(actor)
    local state, derived = self:ProgressionState(actor), self:Derived(actor)
    return math.Clamp((tonumber(state and state.equipmentBlockChanceContribution) or 0)
        + (tonumber(derived and derived.blockChanceContribution) or 0), 0, LOD.Equipment.BlockCap)
end

function Rules:ApplyBlock(target, info)
    if not info or info:GetDamage() <= 0 or not IsValid(target)
        or target:IsPlayer() and not target:Alive() or target.LODDead then return false end
    local status = LOD.RPGStatusElements
    local context = status and status:DamageContext(info,target) or {}
    local attacker = info:GetAttacker()
    if not IsValid(attacker) or attacker == target or attacker == game.GetWorld()
        or context.dodged or context.magic or (context.element and not context.physical) or context.statusDamage
        or context.passiveDamage or context.auraBurst or context.reactiveDamage
        or context.wallCrush or context.environmental or context.unavoidable or context.scriptedKill
        or context.ignoreBlock or info:IsDamageType(DMG_FALL) or info:IsDamageType(DMG_CRUSH)
        or not (info:IsDamageType(DMG_BULLET) or info:IsDamageType(DMG_BUCKSHOT)
            or info:IsDamageType(DMG_CLUB) or info:IsDamageType(DMG_SLASH)) then return false end
    local event = context.attackEvent or info
    local targets = self.BlockEvents[event]
    if not targets then targets=setmetatable({}, {__mode="k"}); self.BlockEvents[event]=targets end
    local identity, epoch = self:ProgressionState(target), LOD.RunManager.State
    local result = targets[target]
    if not result or result.identity ~= identity or result.epoch ~= epoch or result.levelSeed ~= epoch.LevelSeed then
        local chance = self:BlockChance(target)
        local rolls = LOD.CombatRolls
        local natural = chance > 0 and rolls:_RNG("block:"..target:EntIndex()):Float(0,1) or 1
        result={identity=identity,epoch=epoch,levelSeed=epoch.LevelSeed,blocked=natural < chance}
        targets[target]=result
        if chance > 0 then
            local text = string.format("%s BLOCK %s — roll %.2f%% / %.0f%%%s", rolls:EntityDisplayName(target),
                result.blocked and "SUCCESS" or "FAILED", natural*100,chance*100,result.blocked and "; 0 HP damage" or "")
            local data={event="block",chance=chance,roll=natural,blocked=result.blocked}
            if target:IsPlayer() then rolls:_Send(target,3,text,"resist",data) end
            if attacker:IsPlayer() then rolls:_Send(attacker,3,text,"resist",data) end
        end
        if result.blocked then
            target:EmitSound("physics/metal/metal_solid_impact_bullet1.wav",60,110,0.4)
            if target:IsPlayer() then net.Start("LOD_BlockPulse"); net.Send(target) end
            self.Stats.blocks=(self.Stats.blocks or 0)+1
        end
    end
    if not result.blocked then return false end
    info:SetDamage(0); info:SetDamageForce(vector_origin)
    context.blocked=true
    if status then status:AttachDamageContext(info,context) end
    return true
end
