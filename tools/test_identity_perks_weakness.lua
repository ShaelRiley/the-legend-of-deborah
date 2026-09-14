-- Production generators and combat resolvers; only Source entities are faked.
dofile('tools/test_checkpoint_d_closure.lua')
local base = 'gamemodes/legend_of_deborah/gamemode/lod/'
dofile(base .. 'sv_combat_rolls.lua')
dofile(base .. 'sv_magnum_super_explosive.lua')
net.Start=function() end;net.Send=function() end;net.WriteUInt=function() end
local D, H, R, CPS = LOD.IdentityPerkDirector, LOD.HeroAbilityRolls, LOD.RPGAbilityRules, LOD.CharacterProgressionSystem
local Rolls = LOD.CombatRolls
local function eq(a,b,why) assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a)..' ~= '..tostring(b)) end
local abilities = {'str','dex','con','int','wis','cha'}
local below74, tieTargets = false, {}
for seed=1,400 do
    local a,total,attempts,audit = H:Generate(seed)
    local b,total2,attempts2,audit2 = H:Generate(seed)
    eq(total,total2,'deterministic total'); eq(attempts,attempts2)
    assert(audit.rawTotal>=74)
    local sum,penalty = 0,0
    for _,id in ipairs(abilities) do eq(a[id],b[id]); sum=sum+a[id] end
    eq(sum,total)
    for i,p in ipairs(audit.penalties) do
        eq(p.before-p.amount,p.after); eq(p.after,a[p.ability]); eq(p.ability,audit2.penalties[i].ability)
        assert(p.amount >= (i==1 and 2 or 1) and p.amount <= (i==1 and 4 or 3))
        if i>1 then assert(audit.penalties[i-1].before<=p.before) end
        penalty=penalty+p.amount
    end
    eq(audit.rawTotal-penalty,total)
    below74=below74 or total<74
    local _,_,ties=H:ApplyWeakness(LOD.RPG.NewAbilityBlock(12),seed)
    tieTargets[ties[1].ability]=true
end
assert(below74,'no post-weakness rejection')
for _,id in ipairs(abilities) do assert(tieTargets[id],'tie substream must not always penalize a fixed ability') end
local lows = {str=3,dex=4,con=5,int=18,wis=18,cha=18}
local weak = H:ApplyWeakness(lows,5)
assert(weak.str<3,'base scores remain unclamped until derived stats')

local weapons,enemies=D:TargetRegistries()
assert(weapons.crowbar and weapons.grenade and weapons.magnum and not weapons.unarmed and not weapons.magic)
for _,family in ipairs({'ZOMBIE','FAST_ZOMBIE','SOLDIER'}) do assert(enemies[family]) end
eq(D:ModelFamily({model='models/zombie/classic.mdl'}),'ZOMBIE')
eq(D:ModelFamily({model='future-model.mdl',baseModel='models/combine_soldier.mdl'}),'SOLDIER')
local seen={}
for seed=1,300 do
    local p={rosterSeed=seed,heroIdentityId='hero',originIndex=1,backgroundIndex=2,motiveIndex=3}
    local q=table.Copy(p)
    D:EnsurePackage(p); D:EnsurePackage(q)
    eq(#p.identityPerkRecords,3)
    for i,record in ipairs(p.identityPerkRecords) do
        seen[record.handlerId]=true
        eq(record.handlerId,q.identityPerkRecords[i].handlerId); eq(record.targetId,q.identityPerkRecords[i].targetId)
        assert(#D:Description(record)>20)
        if record.handlerId=='ABILITY_BONUS' then assert(LOD.RPG.NewAbilityBlock(0)[record.targetId]~=nil)
        elseif record.handlerId=='FAVORED_WEAPON' then assert(weapons[record.targetId])
        else assert(enemies[record.targetId]) end
    end
    local records=p.identityPerkRecords
    assert(not D:EnsurePackage(p)); eq(p.identityPerkRecords,records,'no reroll')
end
assert(seen.ABILITY_BONUS and seen.FAVORED_ENEMY and seen.FAVORED_WEAPON)
local w,e,a=D:Aggregate({{handlerId='ABILITY_BONUS',targetId='str'},{handlerId='ABILITY_BONUS',targetId='str'},{handlerId='ABILITY_BONUS',targetId='str'}})
eq(a.str,6,'three static +2 records stack')
w,e=D:Aggregate({{handlerId='FAVORED_WEAPON',targetId='pistol'},{handlerId='FAVORED_WEAPON',targetId='pistol'},{handlerId='FAVORED_ENEMY',targetId='ZOMBIE'}})
eq(w.pistol,2);eq(e.ZOMBIE,1)
for _,catalog in ipairs({LOD.RPG.IdentityCatalog.Origins,LOD.RPG.IdentityCatalog.Backgrounds,LOD.RPG.IdentityCatalog.Motives}) do
    eq(#catalog,64)
    for _,trait in ipairs(catalog) do assert(trait.categoryName and trait.flavorText and not trait.mechanicalEffect and not trait.effectHandlerId) end
end

IsValid=function(a) return type(a)=='table' and a.valid==true end
CurTime=function() return 100 end
game={GetWorld=function() return nil end}
LOD.RunManager={State={LevelSeed=1}}
R.ProgressionState=function(_,actor) return actor and actor.state end
local function actor(id,kind,config)
    local s=CPS:NewProgressionState(tostring(id),kind,kind=='hero' and 'hero' or 'shambler')
    s.baseAbilities=LOD.RPG.NewAbilityBlock(10);s.classId='fighter'
    CPS:_RecomputeProgressionState(s)
    local a={id=id,valid=true,state=s,LODConfig=config,LODHostile=kind=='ai'}
    function a:IsPlayer() return kind~='ai' end
    function a:EntIndex() return self.id end
    function a:GetClass() return "lod_hostile" end
    function a:Health() return 100 end
    function a:Alive() return true end
    function a:SetNW2Bool() end
    function a:SetNW2Float() end
    function a:GetNW2Bool(_,default) return default end
    return a
end
local hero=actor(1,'hero')
hero.state.characterIdentityPackage={identityPerkVersion=D.Version,favoredWeaponStacks={pistol=2,shotgun=1,magnum=1},favoredEnemyStacks={ZOMBIE=1},identityAbilityDelta=LOD.RPG.NewAbilityBlock(0)}
local zombie=actor(2,'ai',{model='models/zombie/classic.mdl'})
local soldier=actor(3,'ai',{model='models/combine_soldier.mdl'})
local profile=LOD.RPG.PlayerWeaponDamageProfiles.weapon_pistol
local contract=Rolls:RollActorDamage(hero,profile,LOD.RNG.New(123),0)
local original=contract.total
local final=Rolls:ResolveActorDamage(contract,hero,zombie,{physical=true})
local view=contract.feedResolution.resolvedContract
assert(view and view.favoredEnemyDice==1 and #view.chainStarts==2)
eq(contract.total,original,'shared base immutable');eq(#contract.values,1)
near(final,view.total+2)
local detail=LOD.DieLogger:RollBreakdown(contract)
assert(detail:find('favored%-enemy') and detail:find('favored weapon'))
assert(LOD.DieLogger:DamageFormula(contract):find('favored enemy'))
local again=Rolls:ResolveActorDamage(contract,hero,zombie,{physical=true})
near(again,final);eq(contract.feedResolution.resolvedContract,view,'one target roll cached')
near(Rolls:ResolveActorDamage(contract,hero,soldier,{physical=true}),original+2)
eq(contract.feedResolution.resolvedContract,nil,'nonmatching target inherits no bonus dice')
eq(D:WeaponBonus(contract,{},0),0,'zero/immunity cannot be resurrected')
for _,tag in ipairs({'wallCrush','environmental','nonAttack','statusDamage','passiveDamage','reactiveDamage','auraBurst','personalityAura'}) do eq(D:WeaponBonus(contract,{[tag]=true},10),0) end
local naked={total=4,values={4}}
eq(D:TargetContract(naked,hero,zombie,{}),naked,'no authored primary means no extra die')

-- Per-die CON and whole-hit scaling precede the one flat weapon bonus.
zombie.state.derivedStats.damageResistancePerDie=2
hero.state.derivedStats.physicalDamageMultiplier=1.5
local c=Rolls:RollActorDamage(hero,profile,LOD.RNG.New(42),0)
local amount=Rolls:ResolveActorDamage(c,hero,zombie,{physical=true})
local resolution=c.feedResolution
local subtotal=0;for _,value in ipairs(resolution.reduced) do subtotal=subtotal+value end
near(amount,subtotal*1.5+2)
local immuneResolve=R.ResolveDamageContract
R.ResolveDamageContract=function() return 0,{},0 end
near(Rolls:ResolveActorDamage(c,hero,zombie,{physical=true}),0)
R.ResolveDamageContract=immuneResolve
hero.state.derivedStats.physicalDamageMultiplier=1
zombie.state.derivedStats.damageResistancePerDie=0

-- Shotgun target aggregation invokes the same bonus once, irrespective of pellets.
local shell=Rolls:RollPlayerWeapon(hero,'weapon_shotgun',{})
local shellAmount=Rolls:ResolveActorDamage(shell,hero,zombie,{physical=true,shotgunHits=12,shotgunShares=6})
near(shellAmount,shell.feedResolution.resolvedContract.total*2+1)

-- Extra damage dice use actual explosion paths and obey event caps before rolling.
local oldNew=LOD.RNG.New
local draws=0
local function forceExtra(values)
    draws=0
    LOD.RNG.New=function() return {state=7,Int=function(_,low,high)
        draws=draws+1;local v=assert(values[draws],'unexpected hidden die beyond cap');assert(v>=low and v<=high);return v end} end
end
local magic=Rolls:RollActorDamage(hero,{sides=6,count=1,magicDamage=true,attackEvent={damageDiceUsed=1}},oldNew(1),0)
forceExtra({6,6,1})
local magicAmount=Rolls:ResolveActorDamage(magic,hero,zombie,{magic=true})
eq(draws,3);eq(#magic.feedResolution.resolvedContract.values,4)
near(magicAmount,magic.total+13)
LOD.RNG.New=oldNew
local capped=Rolls:RollActorDamage(hero,{sides=12,count=1,magicDamage=true,attackEvent={damageDiceUsed=127}},oldNew(1),0)
forceExtra({12})
Rolls:ResolveActorDamage(capped,hero,zombie,{magic=true})
eq(draws,1);eq(capped.attackEvent.damageDiceUsed,128)
assert(capped.feedResolution.resolvedContract.capped)
LOD.RNG.New=oldNew

-- Defender-specific suppression preserves the new target view's metadata.
local blast=Rolls:RollActorDamage(hero,{sides=6,count=1,magicDamage=true},oldNew(1),0)
zombie.state.featIds={'CON_BLAST_PROOF'}
zombie.LODRPGBlastProofReadyAt=nil
forceExtra({6,6,1})
local blastAmount=Rolls:ResolveActorDamage(blast,hero,zombie,{magic=true})
local suppressed=blast.feedResolution.resolvedContract
assert(suppressed.blastProofSuppressed and suppressed.profile and suppressed.attackEvent)
eq(#suppressed.values,2);near(blastAmount,blast.total+6)
LOD.RNG.New=oldNew
zombie.state.featIds={}

-- Intrinsic +6 survives into stable feat qualification, with only universal cap.
local abilityHero=actor(11,'hero')
abilityHero.state.identityAbilityDelta.str=6
CPS:_RecomputeProgressionState(abilityHero.state)
eq(abilityHero.state.effectiveAbilities.str,16)
eq(abilityHero.state.featQualificationAbilities.str,16)
abilityHero.state.baseAbilities.str=29
CPS:_RecomputeProgressionState(abilityHero.state)
eq(abilityHero.state.effectiveAbilities.str,30)
eq(abilityHero.state.featQualificationAbilities.str,30)

-- Existing Hero migration changes only old perk mechanics, not rolled base scores.
local old=actor(10,'hero').state
old.characterIdentityPackage={rosterSeed=99,heroIdentityId='old',originIndex=1,backgroundIndex=2,motiveIndex=64,identityAbilityDelta={str=1}}
local baseBefore=old.baseAbilities
assert(D:EnsureState(old));CPS:_RecomputeProgressionState(old)
eq(old.baseAbilities,baseBefore)
local package=old.characterIdentityPackage
local snap=D:Snapshot(LOD.RPG.IdentityCatalog.Origins[1],package,1)
eq(snap.perkDisplayName,package.identityPerkRecords[1].displayName)
assert(not snap.mechanicalEffect:find('Breadcrumb'))
assert(not D:EnsureState(old))
print('IDENTITY_WEAKNESS_PASS — deterministic weakness, three legal perk handlers, stacking, migration, per-target dice, scaling, immunity and caps')
