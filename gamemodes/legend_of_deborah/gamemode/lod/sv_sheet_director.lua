-- Resolve current build information at snapshot time, using production getters.
LOD.SheetDirector={}
local D,R,E=LOD.SheetDirector,LOD.RPGAbilityRules,LOD.Equipment
function D:Rows(actor)
    local state=R:ProgressionState(actor);if not state then return {} end
    local d=R:Derived(actor) or {};local x=state.equipmentExtras or {};local rows={}
    local function add(family,label,value,source)
        rows[#rows+1]={family=family,label=label,value=value,source=source}
    end
    local function percent(family,label,value,baseline)
        if math.abs(value-(baseline or 0))>.0001 then add(family,label,string.format('%.1f%%',value*100),'Resolved build') end
    end
    percent('Movement','Current speed multiplier',LOD.RPGStatusElements:CanMoveVoluntarily(actor) and R:MovementMultiplier(actor) or 0,1)
    if R:IsHasteActive(actor) then add('Movement','Haste','ACTIVE / ×2','Haste feat') end
    percent('Offense','Firearm cadence multiplier',R.RateOfFireMultiplier and R:RateOfFireMultiplier(actor) or 1,1)
    if R.BlockChance then percent('Defense','Block',R:BlockChance(actor)) end
    if R.DodgeSnapshot then
        local dodge=R:DodgeSnapshot(actor)
        percent('Defense','Current Dodge',dodge.current or 0)
        percent('Defense','Moving Dodge',dodge.ordinary or 0)
        percent('Defense','Fast-moving Dodge',dodge.elevated or 0)
    end
    percent('Magic','Regeneration multiplier',R:MagicRegenMultiplier(actor),1)
    local cost=tonumber(d.quantumCostMultiplier) or 1
    percent('Magic','Offensive cost multiplier',cost,1)
    if (d.healthRegenCeilingFraction or 0)>0 then
        percent('Recovery','Health regeneration cap',d.healthRegenCeilingFraction)
        add('Recovery','Health regeneration',string.format('%.2f HP/s',LOD.RPG.FeatEffectSystem:HealthRegenPerSecond(actor:GetMaxHealth(),d.conRegenMultiplier,d.healthRegenBaseMaxHPPerSecond)),'While damage-free; capped above')
    end
    local function flat(family,label,value,source)
        if value and value~=0 then add(family,label,tostring(value),source or 'Resolved build') end
    end
    flat('Offense','Physical damage per die',d.physicalDamageBonus)
    flat('Magic','Magic damage per die',d.magicDamageBonus)
    flat('Defense','Damage resistance per die',d.damageResistancePerDie)
    percent('Defense','HP diverted to Magic',d.hpToMagicDiversionFraction or 0)
    percent('Offense','Aim spread multiplier',R:AimSpreadMultiplier(actor),1)
    percent('Offense','Fighter damage multiplier',d.fighterCapstonePhysicalDamageMultiplier or 1,1)
    percent('Magic','Wizard power multiplier',d.wizardCapstoneMagicPowerMultiplier or 1,1)
    flat('Magic','Magic save bonus',d.magicSaveBonus)
    flat('Magic','Magic DC bonus',d.wizardCapstoneMagicDCBonus)
    if (d.rogueBackstabMultiplier or 1)>1 then add('Offense','Backstab multiplier',tostring(d.rogueBackstabMultiplier)..'×','Requires backstab geometry') end
    local owned={};for _,id in ipairs(state.featIds or {}) do owned[id]=true end
    local families=LOD.RPG.CheckpointDStatusProcFamilies or {}
    for _,family in pairs(families) do
        for rank=3,1,-1 do
            local id=family.ids[rank]
            if owned[id] then
                local feat=LOD.RPG.IdentityCatalog.OrdinaryFeats[id]
                percent('Status',feat.displayName..' proc (feat)',feat.effectParams.procChance)
                break
            end
        end
    end
    if state.classId=='wizard' then
        add('Summons / Utility','Active summon limit',tostring(LOD.MagicProgression:MaxActiveSummons(state)),'Resolved build')
        add('Summons / Utility','Summon lifetime',string.format('%.1f seconds',20*(1+math.Clamp(x.summon_duration or 0,-50,50)/100)),'Equipment and base lifetime')
    end
    local skip={movement=true,dodge=true,block=true,magic_regen=true,regen_rate=true,regen_ceiling=true,summon_cap=true,summon_duration=true}
    for _,id in ipairs(E.EconomyOrder) do
        local value=x[id];local def=E.EconomyProperties[id]
        if value and value~=0 and not skip[id] and not def.ability then
            local family=def.rider and 'Status' or (def.element or def.ward or def.weakness) and 'Elemental'
                or def.save and 'Defense' or id=='defense' and 'Defense' or 'Offense'
            local resolved=value
            if def.rider then resolved=math.Clamp(value,0,35)
            elseif def.element then resolved=math.Clamp(value,0,50)
            elseif def.save then resolved=math.Clamp(value,-6,6)
            elseif id=='defense' then resolved=math.Clamp(value,-35,35)
            elseif id=='physical' or id=='magic' then resolved=math.Clamp(value,-35,75) end
            local display=tostring(resolved)..(def.unit or '')
            if def.ward then display='Resistance (shared elemental save)'
            elseif def.weakness then display='Weakness (shared elemental resolver)' end
            add(family,def.label,display,'Equipped items; conditional labels state their requirement')
        end
    end
    local families={Offense=1,Defense=2,Magic=3,Elemental=4,Status=5,Movement=6,Recovery=7,['Summons / Utility']=8}
    table.sort(rows,function(a,b) if a.family~=b.family then return families[a.family]<families[b.family] end return a.label<b.label end)
    return rows
end
local CPS=LOD.CharacterProgressionSystem
local snapshot=CPS.BuildClientSnapshot
function CPS:BuildClientSnapshot(ply)
    local s=snapshot(self,ply)
    if s then s.directedStats=D:Rows(ply) end
    return s
end
-- Suppress LoD setup noise at source; never change a user's volume setting.
hook.Add('EntityEmitSound','LOD_QuietGeneration',function(data)
    local state=LOD.RunManager and LOD.RunManager.State
    if not state or state.BuildReady then return end
    local ent=data.Entity
    if IsValid(ent) and (ent:IsPlayer() or ent.LODGeneratedGeometry or ent.LODHostile or ent.LODSummonedSeeker or ent:GetClass():sub(1,4)=='lod_') then return false end
end)
