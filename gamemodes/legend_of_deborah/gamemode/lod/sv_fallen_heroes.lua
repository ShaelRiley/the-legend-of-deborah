-- Big Skeleton: detached player incarnations, never event instances or players.
LOD.FallenHeroes = LOD.FallenHeroes or {}
local F = LOD.FallenHeroes
local Run, Rules = LOD.RunManager, LOD.RPGAbilityRules
F.Records, F.Serial = {}, 0
F.Captured=setmetatable({}, {__mode="k"})
F.RiseSeconds, F.ServiceSeconds, F.Maximum = 3, .25, 32
local function key(c) return c and LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function copy(v) return table.Copy(v or {}) end
local function clockLive(s)
    local c=s.CampaignClock
    return not c or not (c.expired or c.scene or c.deadline and SysTime()>=c.deadline)
end
function F:Current(r)
    local s=Run.State
    return r and not r.retired and r.run==s and r.graph==s.Graph and r.seed==s.LevelSeed
        and r.epoch==s.CampaignEpoch and r.campaign==s.CampaignSeed and r.level==s.Level
        and s.BuildReady and not s.Failed and not s.LevelCleared and clockLive(s)
end
function F:Owned(e)
    local r=IsValid(e) and e.LODFallenHero
    return r and r.entity==e and self:Current(r) and e.LODProgressionState==r.profile
end
function F:Live(e)
    return self:Owned(e) and not e.LODDead and e:Health()>0 and not Run.State.SimulationFrozen
        and CurTime()>=(e.LODFallenHero.readyAt or math.huge)
end
function F:Notice(r,text,event)
    if LOD.CombatRolls and LOD.CombatRolls._Send then
        LOD.CombatRolls:_Send(player.GetAll(),3,text)
    end
    if LOD.RPGTestLog then LOD.RPGTestLog:Write("FALLEN_HERO",{event=event,id=r.id,
        identity=r.identity,name=r.name,class=r.profile.classId,level=r.profile.level}) end
end
function F:Retire(r)
    r.retired=true -- revoke every attack before native removal can call back
    if IsValid(r.entity) then r.entity:Remove() end
end
function F:Cleanup()
    for _,r in ipairs(self.Records) do self:Retire(r) end
    self.Records={}
    self.Captured=setmetatable({}, {__mode="k"})
end

-- Invoked only by HandleDeath's accepted Hero/Soldier branches. No native spawn,
-- inventory write, roll, reward or timer is performed inside the lethal stack.
function F:Capture(ply,ps)
    local s=Run.State
    if not IsValid(ply) or not ply:IsPlayer() or not ps or not s.Graph
        or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen or not clockLive(s)
        then return false end
    local soldier=Run:IsSoldierControl(ply)==true
    if not soldier and not Run:IsActivePlayer(ply) then return false end
    local source=Rules:ProgressionState(ply)
    if not source then return false end
    local staging=LOD.StagingRoom
    if staging and staging.IsPlayerInHut and staging:IsPlayerInHut(ply) then return false end
    local cell
    if LOD.EntrySafety then cell=LOD.EntrySafety:ExactCell(s.Graph,ply:GetPos())
    else cell=LOD.MazeNavigator:WorldToCell(s.Graph,ply:GetPos()) end
    if not cell then return false end
    local old=self.Captured[ply]
    local life=ply.LODRunSpawnSerial or ply.LODCombatLifeSerial or 0
    if old and old.run==s and old.graph==s.Graph and old.life==life then return false end
    self.Serial=self.Serial+1
    self.Captured[ply]={run=s,graph=s.Graph,life=life}
    local p=copy(source)
    local identity=p.characterIdentityPackage or {}
    local name=soldier and (ply:Nick().."'s Soldier") or identity.fullDisplayName or ps.characterName or ply:Nick()
    local r={id=self.Serial,run=s,graph=s.Graph,seed=s.LevelSeed,epoch=s.CampaignEpoch,
        campaign=s.CampaignSeed,level=s.Level,identity=ps.identity or Run:IdentityOf(ply),name=name,
        profile=p,equipment=soldier and {} or copy(ps.equipment),inventory={},soldierCopy=soldier,
        origin=Vector(ply:GetPos().x,ply:GetPos().y,ply:GetPos().z),cellKey=key(cell),
        armor=math.max(0,ply:Armor()),createdAt=CurTime(),weapons={}}
    r.equipment.items,r.equipment.slots=r.equipment.items or {},r.equipment.slots or {}
    r.inventory.ammo=copy(ply:GetAmmo())
    local active=ply:GetActiveWeapon()
    r.weaponClass=IsValid(active) and active:GetClass() or r.inventory.activeWeaponClass
    for _,w in ipairs(ply:GetWeapons()) do
        if IsValid(w) then
            local ammo=w:GetPrimaryAmmoType()
            r.weapons[w:GetClass()]={clip=math.max(0,w:Clip1()),ammoType=ammo,
                clipSize=math.max(1,w:GetMaxClip1()),delay=w.Primary and w.Primary.Delay,
                model=w:GetModel()}
        end
    end
    -- Runtime identity is new; every authored build field remains a deep copy.
    p.actorId="fallen:"..tostring(s.RunId or s.CampaignSeed)..":"..self.Serial
    -- Keep Hero rules (not weaker ordinary-enemy CON/diversion caps). Native
    -- LODHostile owns allegiance; actorType never grants a player connection.
    p.fallenHero,p.usesMagic=true,true
    p.magic=math.Clamp(tonumber(soldier and source.magic or ps.magic) or 0,0,100)
    p.skeletonName="Skeleton of "..name
    p.archetypeId="soldier" -- locomotion shell only; attacks use the copied kit
    r.maxHP=math.max(1,ply:GetMaxHealth())
    r.speed=math.max(1,ply:GetWalkSpeed())
    -- Do not mutate native entities from a death callback even at the cap.
    self.Records[#self.Records+1]=r
    return true,r
end

function F:Position(r)
    local g=r.graph
    local start=g.Cells[r.cellKey]
    if not start then return nil end
    -- A short traversable BFS handles stair/ledge deaths without crossing locks.
    local queue,seen={start},{[r.cellKey]=true}
    local probe={GetHull=function() return Vector(-16,-16,0),Vector(16,16,72) end}
    for i=1,12 do
        local c=queue[i];if not c then break end
        if LOD.SafeTeleport:FlatCell(g,c) then
            local center=LOD.MazeNavigator:CellCenter(c)
            local points={center,center+Vector(48,0,0),center+Vector(-48,0,0),
                center+Vector(0,48,0),center+Vector(0,-48,0)}
            if i==1 then table.insert(points,1,r.origin) end
            for _,pos in ipairs(points) do
                if not LOD.EntrySafety or LOD.EntrySafety:SpawnPositionAllowed(pos) then
                    local landing=LOD.SafeTeleport:Landing(probe,g,c,pos)
                    if landing then return landing,key(c) end
                end
            end
        end
        local neighbors={};for n in pairs(c.neighbors) do neighbors[#neighbors+1]=n end;table.sort(neighbors)
        for _,n in ipairs(neighbors) do
            if not seen[n] and #queue<12 and LOD.MazeNavigator:CanTraverse(g,key(c),n) then
                seen[n]=true;queue[#queue+1]=g.Cells[n]
            end
        end
    end
end

function F:Spawn(r)
    if not self:Current(r) or r.entity then return false end
    local pos,home=self:Position(r)
    if not pos then return false end
    local e=ents.Create("lod_hostile")
    if not IsValid(e) then return false end
    r.entity=e
    e.LODFallenHero,e.LODSkeletonHero,e.LODVarianceApplied=r,true,true
    e.LODProgressionState,e.LODArchetypeId=r.profile,"soldier"
    e.LODInstanceSeed=LOD.Seeds.Derive(r.seed,"fallen-hero:"..r.id)
    e.LODHomeCellKey=home
    e:SetPos(pos);e:Spawn();e:Activate()
    if not IsValid(e) or not self:Current(r) then
        if IsValid(e) then e:Remove() end
        r.entity=nil;return false
    end
    e.LODConfig=copy(LOD.Config.Encounter.Archetypes.soldier)
    e.LODConfig.model,e.LODConfig.name=LOD.SkeletonHero.Model,r.profile.skeletonName
    -- MotionV2 applies the copied derived multiplier exactly once.
    e.LODConfig.speed=r.speed/math.max(.01,(Rules.HostileDexMovementMultiplier and Rules:HostileDexMovementMultiplier(e) or 1)
        *(Rules.RogueMovementMultiplier and Rules:RogueMovementMultiplier(e) or 1))
    e:SetModel(LOD.SkeletonHero.Model)
    if LOD.HostileAnimation then LOD.HostileAnimation:Apply(e,ACT_IDLE,true) end
    e:SetColor(LOD.SkeletonHero.Colors[r.profile.classId] or color_white)
    e:SetMaxHealth(r.maxHP);e:SetHealth(r.maxHP)
    e:SetNW2Bool("LOD_SkeletonHero",true)
    e:SetNW2String("LOD_MonsterName",r.profile.skeletonName)
    e:SetNW2String("LOD_FallenOwner",tostring(r.identity))
    e:SetNW2Int("LOD_CharacterLevel",r.profile.level)
    e:SetNW2Float("LOD_SizeScale",1)
    e.LODCharacterLevel,e.LODMonsterTier=r.profile.level,r.profile.tierId
    LOD.CharacterProgressionSystem:SyncMonsterIdentity(e,r.profile)
    r.readyAt=CurTime()+self.RiseSeconds
    e:SetNW2Float("LOD_SkeletonRiseAt",r.readyAt)
    -- The native model has no weapon entity authority: this remains a cosmetic
    -- prop; copied ammunition/items live exclusively in the detached record.
    self:WeaponVisual(e,r.weaponClass)
    e.GetShootPos=function(actor) return actor:WorldSpaceCenter()+Vector(0,0,16) end
    e.GetAimVector=function(actor) return actor.LODFallenAim or actor:GetForward() end
    e.Alive=function(actor) return not actor.LODDead and actor:Health()>0 end
    LOD.Magic:_Sync(e,LOD.Magic:_EnsureState(e))
    e:EmitSound("physics/body/body_medium_break2.wav",70,90,.7)
    self:Notice(r,r.name.." has fallen. Their skeleton rises in three seconds.","rise")
    return true
end

function F:WeaponVisual(e,class)
    local r=e.LODFallenHero
    local w=r.weapons[class or ""]
    if IsValid(e.LODWeaponVisual) then
        if w and w.model and w.model~="" then e.LODWeaponVisual:SetModel(w.model);e.LODWeaponVisual:SetNoDraw(false)
        else e.LODWeaponVisual:SetNoDraw(true) end
    end
    e:SetNW2String("LOD_FallenWeapon",class or "")
end
function F:EquipmentSnapshot(e,class)
    local r=e.LODFallenHero;local p=r.profile
    local item=class and LOD.Equipment:Equipped(r.equipment,class)
    local snap={extras=copy(p.equipmentExtras),derived=copy(p.derivedStats),weapon=class,
        itemId=item and item.id,ownerIdentity=r.identity,runId=r.run.RunId,levelSeed=r.seed,
        injured=e:Health()<=e:GetMaxHealth()*.5,still=e:GetVelocity():Length2D()<5,
        charged=p.magic>=75,dc={},origin=e:GetPos()}
    for _,v in ipairs(item and item.properties or {}) do
        local d=LOD.Equipment:RecordDefinition(item,v)
        if d and d.element then snap.element=d.element end
    end
    local status=LOD.RPGStatusElements
    for id,d in pairs(status.Registry) do snap.dc[id]=status:ConditionDC(e,d.ability) end
    return snap
end
function F:SelectWeapon(e,class)
    local r=e.LODFallenHero
    if r.weaponClass==class and r.equipment.activeWeaponClass==class then return end
    r.weaponClass,r.equipment.activeWeaponClass=class,class
    local p=r.profile
    local a,_,block,extras=LOD.Equipment:Contributions(r.equipment)
    p.equipmentAbilityDelta,p.equipmentBlockChanceContribution,p.equipmentExtras=a,block,extras
    LOD.CharacterProgressionSystem:_RecomputeProgressionState(p)
    self:WeaponVisual(e,class)
end
local function melee(class) return class=="weapon_crowbar" or class=="weapon_lod_crowbar" end
function F:Weapon(e)
    local r=e.LODFallenHero
    local function usable(class)
        local w=r.weapons[class or ""]
        if not w then return false end
        if melee(class) then return true end
        if class=="weapon_lod_wand" then
            local item=LOD.Equipment:Equipped(r.equipment,class)
            return item and (item.charges or 0)>0
        end
        return LOD.CombatRolls.PlayerDamageProfiles[class] and
            (class=="weapon_ar2" and r.soldierCopy or w.clip>0 or (r.inventory.ammo[w.ammoType] or 0)>0)
    end
    if usable(r.weaponClass) then return r.weaponClass end
    local ids={};for id in pairs(r.weapons) do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids) do if usable(id) then self:SelectWeapon(e,id);return id end end
end

function F:FireWeapon(e,target,class,burstRound)
    local r=e.LODFallenHero;local w=r.weapons[class]
    if not w or not self:Live(e) or not LOD.RPGStatusElements:CanInitiateAttack(e) then return false end
    if class=="weapon_lod_wand" then return self:Cast(e,target,true) end
    local unlimited=class=="weapon_ar2" and r.soldierCopy
    if not melee(class) and not unlimited and not burstRound and w.clip<=0 then
        local remaining=r.inventory.ammo[w.ammoType] or 0
        local n=math.min(w.clipSize,remaining)
        w.clip=n;r.inventory.ammo[w.ammoType]=remaining-n
        r.nextAttack=CurTime()+1.5
        return n>0
    end
    if class=="weapon_ar2" and not burstRound then
        local cfg=LOD.PlayerWeaponSpecials.AR2Config
        local bonus=Rules.BurstBonusRounds and Rules:BurstBonusRounds(e) or 0
        local count=Rules.ResolveBurstCount and Rules:ResolveBurstCount(cfg.baseBurstShots,bonus) or cfg.baseBurstShots
        if not unlimited then w.clip=w.clip-1 end
        r.burst={remaining=count,nextAt=CurTime(),direction=e:GetAimVector(),target=target,
            spacing=cfg.burstSpacing/math.max(1,Rules:RateOfFireMultiplier(e)),recovery=cfg.recovery}
        return true
    end
    local rolls=LOD.CombatRolls
    local event={equipmentSnapshot=self:EquipmentSnapshot(e,class)}
    LOD.FactionManager:CaptureAttackPermission(e,event)
    local weaponClass=class=="weapon_lod_crowbar" and "weapon_crowbar" or class
    local contract
    if melee(class) then
        local profile=LOD.RPG.FeatEffectSystem:CrowbarDamageProfile(e)
        profile=copy(profile);profile.attackEvent=event
        contract=rolls:RollActorDamage(e,profile,rolls:_RNG("fallen:crowbar"),Rules:CommitAttack(e) and 1 or 0)
        contract.equipmentSnapshot=event.equipmentSnapshot
        if LOD.RPGCrossFeats then LOD.RPGCrossFeats:AugmentMeteor(e,contract,rolls:_RNG("fallen:meteor")) end
    else contract=rolls:RollPlayerWeapon(e,weaponClass,event) end
    if not contract or not self:Live(e) then return false end
    if not melee(class) and not burstRound and not unlimited then w.clip=w.clip-1 end
    local function hit(victim,pos)
        if not self:Live(e) or not LOD.FactionManager:CanDamage(e,victim,event) then return end
        if contract.pellets then
            contract.hits[victim]=(contract.hits[victim] or 0)+1
            contract.hitPositions[victim]=pos
            return
        end
        local tags={physical=true,melee=melee(class),actorDamageResolved=true,
            attackEvent=event,damageContract=contract,meteor=melee(class) and contract or nil}
        local damage=rolls:ResolveActorDamage(contract,e,victim,tags)
        local info=LOD.NewDamageInfo()
        info:SetAttacker(e);info:SetInflictor(e);info:SetDamage(damage)
        info:SetDamageType(melee(class) and DMG_CLUB or DMG_BULLET)
        info:SetDamagePosition(pos);info:SetDamageForce(vector_origin)
        LOD.RPGStatusElements:AttachDamageContext(info,tags)
        rolls:QueueDamageReport(info,function(finalDamage)
            rolls:_Send({e,victim},0,rolls:_DamageEventText(e,LOD.DieLogger:DamageFormula(contract),
                finalDamage,victim,rolls:_PlayerRollDetail(contract),nil,"Hero",class))
        end)
        LOD.FactionManager:DealDamage(victim,info,event,e)
    end
    contract.hitPositions={}
    if melee(class) then
        local tr=util.TraceHull({start=e:GetShootPos(),endpos=e:GetShootPos()+e:GetAimVector()*80,
            mins=Vector(-8,-8,-8),maxs=Vector(8,8,8),mask=MASK_SHOT,filter=e})
        if IsValid(tr.Entity) then hit(tr.Entity,tr.HitPos) end
    else
        e:FireBullets({Src=e:GetShootPos(),Dir=e:GetAimVector(),Num=contract.pellets or 1,
            Spread=Vector(1,1,0)*(contract.pellets and .055 or .015),Tracer=1,Damage=0,Force=0,
            Callback=function(_,tr,info)
                info:SetDamage(0)
                if IsValid(tr.Entity) then hit(tr.Entity,tr.HitPos) end
                return {damage=false}
            end})
        if contract.pellets and self:Live(e) then rolls:SettleShotgun(e,contract);rolls:_FinishShotgunFeed(e,contract) end
    end
    if self:Live(e) then
        if LOD.HostileAnimation then LOD.HostileAnimation:PlayerAttack(e) end
        e:EmitSound(melee(class) and "Weapon_Crowbar.Single" or "Weapon_"..
            ({weapon_pistol="Pistol",weapon_smg1="SMG1",weapon_ar2="AR2",weapon_357="357",weapon_shotgun="Shotgun"})[class]..".Single",70)
    end
    return true
end

local spellMethods={beam="_CastBeam",blast="_CastBlast",cone="_CastCone",wall="_CastWall",summon="_CastSummon",missile="_SpawnProjectile",
    bomb="_SpawnProjectile",bolt="_SpawnProjectile",super_ball="_SpawnProjectile",watermelon="_SpawnProjectile"}
function F:Spell(e)
    local p=e.LODFallenHero.profile
    local function owned(id)
        if not spellMethods[id] or not LOD.MagicProgression:FormAllowed(p,id) then return false end
        for _,v in ipairs(p.magicFormIds or {}) do if v==id then return true end end
    end
    local id=p.selectedMagicFormId
    if not owned(id) then id=nil;for _,v in ipairs(p.magicFormIds or {}) do if owned(v) then id=v;break end end end
    local content=p.selectedMagicContentId
    local has=false;for _,v in ipairs(p.contentIds or {}) do if v==content then has=true end end
    return id and LOD.RPG.MagicForms[id],has and LOD.RPG.MagicContents[content] or nil
end
function F:Cast(e,target,wand)
    if not self:Live(e) or not LOD.RPGStatusElements:CanInitiateMagic(e) then return false end
    local r=e.LODFallenHero;local forms=LOD.MagicForms
    local form,content=self:Spell(e)
    local item
    if wand then
        item=LOD.Equipment:Equipped(r.equipment,"weapon_lod_wand")
        if not item or (item.charges or 0)<=0 then return false end
        form=copy(LOD.RPG.MagicForms.beam)
        local derived=Rules:Derived(e) or {}
        if not derived.canActivateWandsScrolls or (derived.arcaneItemUseChance or 0)<=0 then return false end
        form.damageDice=3
        local element=self:EquipmentSnapshot(e,"weapon_lod_wand").element
        content=element and copy(LOD.RPG.MagicContents[element]) or nil
        if content then content.rider=nil end
    end
    if not form or not spellMethods[form.id] then return false end
    local context=forms:_NewContext(e,form,content)
    context.sourceValid=function() return F:Live(e) end
    context.fallenHero=true
    if wand then context.wand=true;context.equipmentSnapshot=self:EquipmentSnapshot(e,"weapon_lod_wand") end
    if not forms:_CanCastPreSpend(e,form,context) then return false end
    local cost=wand and 0 or Rules:OffensiveMagicCost(e,forms:TotalBaseCost(form,content))
    if r.profile.magic<cost then return false end
    context.auraBurst=LOD.RPG:PrepareCheckpointDAuraBurst(e)
    context.castSerial=forms:_NextCastSerial(e)
    local oldAce=e.LODRPGNextAceReadyAt
    local primed,observation=Rules:CommitAttack(e,true)
    context.aceBonus=primed and 1 or 0
    LOD.FactionManager:CaptureAttackPermission(e,context)
    r.profile.magic=r.profile.magic-cost
    if item then
        item.charges=item.charges-1
        if not Rules:TryArcaneItemUse(e) then return false end
    end
    LOD.Magic:_Sync(e,r.profile)
    if not self:Live(e) then return false end
    local ok=forms[spellMethods[form.id]](forms,e,form,content,context)
    if not ok then
        r.profile.magic=math.min(100,r.profile.magic+cost)
        e.LODRPGNextAceReadyAt=oldAce
        LOD.Magic:_Sync(e,r.profile)
        return false
    end
    if observation and Rules.ObserveCommittedAttack then Rules:ObserveCommittedAttack(e,observation) end
    local effects=LOD.RPG.FeatEffectSystem
    if effects.RecordQuantumSpend then effects:RecordQuantumSpend(e,forms:TotalBaseCost(form,content),cost) end
    if ok and cost>0 then hook.Run("LODDiscreteMagicSpent",e,cost,context) end
    if ok and self:Live(e) and LOD.HostileAnimation then LOD.HostileAnimation:PlayerAttack(e) end
    return ok
end

function F:TickAI(e)
    local motion,status=LOD.HostileMotionV2,LOD.RPGStatusElements
    local r=e.LODFallenHero
    if not self:Live(e) then r.attack=nil;r.burst=nil;motion:Stop(e);return true end
    if motion:HoldHitStun(e,CurTime()) or status:HandleAIFlee(e,r.graph,motion)
        or not status:CanMoveVoluntarily(e) then r.attack=nil;r.burst=nil;motion:Stop(e);return true end
    if r.burst then
        motion:Stop(e)
        local burst=r.burst
        if not status:CanInitiateAttack(e) then r.burst=nil;return true end
        e.LODFallenAim=burst.direction
        if CurTime()>=burst.nextAt then
            self:FireWeapon(e,burst.target,"weapon_ar2",true)
            burst.remaining=burst.remaining-1;burst.nextAt=CurTime()+burst.spacing
            if burst.remaining<=0 then r.burst=nil;r.nextAttack=CurTime()+burst.recovery end
        end
        return true
    end
    e:_RefreshTarget(r.graph)
    local target=e.LODTarget
    if not IsValid(target) then r.attack=nil;motion:Stop(e);return true end
    local from,to=e:GetShootPos(),target:WorldSpaceCenter()
    e.LODFallenAim=(to-from):GetNormalized()
    local class=self:Weapon(e)
    local form=self:Spell(e)
    local spell=form and (r.profile.classId=="wizard" or not class or (r.attackSerial or 0)%3==2)
    local range=(spell or class and not melee(class)) and 700 or 80
    local clear=e:_HasLineOfSight(target)
    if clear and from:DistToSqr(to)<=range*range then
        motion:Stop(e)
        if e.loco then e.loco:FaceTowards(Vector(to.x,to.y,e:GetPos().z)) end
        if r.attack then
            local a=r.attack
            if a.target~=target or not LOD.FactionManager:CanAcquirePlayerTarget(target)
                or not status:CanInitiateAttack(e) then r.attack=nil
            elseif CurTime()>=a.at then
                r.attack=nil;r.attackSerial=(r.attackSerial or 0)+1
                r.nextAttack=CurTime()+math.max(.35,tonumber(class and r.weapons[class].delay) or .8)
                    /math.max(1,Rules:RateOfFireMultiplier(e))
                local cast=a.spell and self:Cast(e,target)
                if not cast and class then self:FireWeapon(e,target,class) end
            end
        elseif CurTime()>=(r.nextAttack or 0) and status:CanInitiateAttack(e) then
            r.attack={target=target,at=CurTime()+.65,spell=spell}
            e:SetNW2Float("LOD_SkeletonAttackAt",r.attack.at)
            e:EmitSound("physics/body/body_medium_break2.wav",60,120,.25)
        end
    else
        r.attack=nil
        e:_RefreshRoute(r.graph)
        local waypoint=e:_AdvanceWaypoint()
        if waypoint then motion:MoveToward(e,waypoint) else motion:Stop(e) end
    end
    return true
end

function F:AcceptDeath(e,info)
    local r=e.LODFallenHero
    if not self:Owned(e) or r.killed or e.LODDead or e:Health()>0 or Run.State.SimulationFrozen then return false end
    r.killed=true;r.attack=nil
    local attacker=info and info:GetAttacker()
    r.killerIdentity=IsValid(attacker) and attacker:IsPlayer() and Run:IdentityOf(attacker) or nil
    return true
end
function F:ResolveDeath(e)
    local r=e.LODFallenHero
    if not self:Owned(e) or not r.killed then return false end
    if not r.epitaph then
        r.epitaph=true
        self:Notice(r,r.killerIdentity==r.identity and (r.name.." laid their own bones to rest.")
            or r.name.." has been avenged. Rest in pieces.","defeated")
        if not self:Owned(e) then return false end
        e:EmitSound("physics/body/body_medium_break3.wav",70,85,.7)
    end
    return self:Owned(e)
end
function F:AbsorbArmor(e,info)
    local r=e.LODFallenHero
    if not r or r.armor<=0 or info:GetDamage()<=0 then return end
    -- Source's ordinary player armor ratio/cost, without creating a player body.
    for _,kind in ipairs({DMG_FALL,DMG_DROWN,DMG_POISON,DMG_RADIATION}) do
        if kind and info:IsDamageType(kind) then return end
    end
    local incoming=info:GetDamage()
    local absorbed=math.min(incoming*.8,r.armor*2)
    r.armor=math.max(0,r.armor-absorbed*.5)
    info:SetDamage(incoming-absorbed)
end
function F:Service()
    if CurTime()<(self.nextService or 0) then return end
    self.nextService=CurTime()+self.ServiceSeconds
    for i=#self.Records,1,-1 do
        local r=self.Records[i]
        if not self:Current(r) or r.entity and not IsValid(r.entity) then self:Retire(r);table.remove(self.Records,i) end
    end
    while #self.Records>self.Maximum do self:Retire(table.remove(self.Records,1)) end
    local attempts=0
    for _,r in ipairs(self.Records) do
        if Run.State.SimulationFrozen then r.frozenAt=r.frozenAt or CurTime()
        else
            if r.frozenAt then
                if r.readyAt then r.readyAt=r.readyAt+CurTime()-r.frozenAt end
                r.frozenAt=nil
                if IsValid(r.entity) then r.entity:SetNW2Float("LOD_SkeletonRiseAt",r.readyAt) end
            end
            if not r.entity and attempts<2 and CurTime()>=(r.nextAttempt or 0) then
                attempts=attempts+1;r.nextAttempt=CurTime()+1
                local ok,result=pcall(self.Spawn,self,r)
                if not ok then
                    if IsValid(r.entity) then r.entity:Remove() end
                    r.entity=nil
                    if r.lastError~=tostring(result) then
                        r.lastError=tostring(result)
                        ErrorNoHalt("[LOD:SKELETON] spawn retry: "..r.lastError.."\n")
                    end
                end
            end
        end
    end
end
hook.Add("Think","LOD_FallenHeroes",function() F:Service() end)
concommand.Add("lod_skeleton_status",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local pending,alive=0,0
    for _,r in ipairs(F.Records) do if not r.entity then pending=pending+1 elseif not r.killed then alive=alive+1 end end
    local text=string.format("Skeletons: fallen=%d pending=%d; event priority=65%%, drought cap=2 populated dungeons",alive,pending)
    print("[LOD:SKELETON] "..text);if IsValid(ply) then ply:ChatPrint(text) end
end)
