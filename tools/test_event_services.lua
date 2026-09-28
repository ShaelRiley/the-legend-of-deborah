-- Actual equipment, status, loot, event admission and real SQLite transactions.
-- Only Source entities/native state and packet delivery are engine boundaries.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run})
local root,E,D,Run,Store=F.root,LOD.Equipment,F.D,F.Run,F.Store
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
dofile(root..'sv_crypto_director.lua')
dofile(root..'sv_debbie_junk.lua')
dofile(root..'sv_event_transactions.lua')
dofile(root..'sv_event_services.lua')
local T,Services=LOD.EventTransactions,LOD.EventServices.Definitions
local serial,p,q=0
local nativeSQL=sql.Query
local function actor(id)
    local a=equipment.actor(id)
    a.SteamID64=function(self) return self.id end
    a.pos=Vector();a.GetPos=function(self) return self.pos end
    a.EyePos,a.WorldSpaceCenter=a.GetPos,a.GetPos
    a.GetNW2Int=a.GetNW2Float
    a.ps.deploymentComplete,a.ps.lives,a.ps.equipmentLifeSerial=true,3,1
    a.ps.equipment={items={},slots={}}
    return a
end
local function build(id,retain)
    serial=serial+1
    sql.Query=nativeSQL;F.traceBlocked=false
    local old=Run.State
    Run.State={RunId=retain and old.RunId or 'services:'..serial,CampaignSeed=41,CampaignEpoch=serial,
        Level=1,LevelSeed=F.graph.MasterLevelSeed,Graph=F.graph,BuildReady=true,Ranked=false,
        EventServiceRewards=retain and old.EventServiceRewards or nil,
        EventServiceMarket=retain and old.EventServiceMarket or nil}
    if not retain then p=actor(tostring(76561198000008000+serial*2));q=actor(tostring(76561198000008001+serial*2)) end
    F.online[1],F.online[2]=p,q
    Run.State.PlayerState={[p.id]=p.ps,[q.id]=q.ps}
    local k,c=next(F.graph.Cells)
    local i={id='service:'..serial,archetype=id,contract='UTILITY',cell=c,cellKey=k,
        seed=78491,placement={cellKey=k},claims={},entities={}}
    assert(D:Activate(F.graph,{mode='preview',selectedCount=1,instances={i}}))
    p.pos,q.pos=i.entities[1]:GetPos(),i.entities[1]:GetPos()
    return i
end
local function funds(a,n)
    assert(Store:Transaction('fixture:'..serial..':'..a.id..':'..n,'fixture',{a.id},function(accounts)
        accounts[a.id].balance=n;return true
    end))
end
local function balance(a) return assert(Store:Read(a.id)).balance end
local function use(i,a) return D:Interact(i.entities[1],a or p) end
local function review(i,a)
    a=a or p;local ok,why=use(i,a)
    assert(not ok and type(why)=='string' and why:find('Use again',1,true),tostring(why))
    assert(Services[i.archetype].Snapshot(i,a,a.id).action=='CONFIRM THIS OFFER')
end
local function complete(i,a) review(i,a);local ok,why=use(i,a);assert(ok,tostring(why));return why end
local function wear(a,seed,slot)
    local item=E:Generate(99111+seed,1,'ring','service-fixture:'..serial..':'..seed)
    assert(E:StoreWearable(E:Ensure(a.ps),item))
    if slot then assert(E:Equip(a.ps.equipment,item.id,slot)) end
    return a.ps.equipment.items[item.id]
end
local function countWear(a) return E:StoredEquipmentCount(a.ps.equipment) end

-- Costs are never spent on a first review; payment and native HP are indivisible.
local i=build('triage_station');p.hp=25;funds(p,100)
review(i);assert(p.hp==25 and balance(p)==100)
local got=assert(use(i));assert(got and p.hp==100 and balance(p)==88)
assert(not use(i) and balance(p)==88)
local receipt=assert(T.Claim(i,p.id));assert(receipt.debit==12)
local savedRun=Run.State.RunId
i=build('triage_station',true);p.hp=10
assert(Run.State.RunId==savedRun and not use(i) and p.hp==10,'regeneration renewed paid claim')

-- Failed COMMIT undoes the provisional native mutation, including post-mutation throws.
i=build('triage_station');p.hp=31;funds(p,100);review(i)
sql.Query=function(s) if s=='COMMIT' then return false end;return nativeSQL(s) end
assert(not use(i));sql.Query=nativeSQL
assert(p.hp==31 and balance(p)==100 and not T.Claim(i,p.id))
local setHealth=p.SetHealth
p.SetHealth=function(self,n) self.hp=n;error('native throws after mutation') end
assert(not use(i));p.SetHealth=setHealth
assert(p.hp==31 and balance(p)==100 and not T.Claim(i,p.id))
assert(use(i) and p.hp==100 and balance(p)==88)

-- A replacement body is never healed/refunded by a stale native callback.
i=build('triage_station');p.hp=20;funds(p,100);review(i)
setHealth=p.SetHealth
p.SetHealth=function(self,n)
    self.hp=n;self.ps.equipmentLifeSerial=self.ps.equipmentLifeSerial+1;self.hp=43
end
assert(not use(i));p.SetHealth=setHealth
assert(p.hp==43 and balance(p)==100 and not T.Claim(i,p.id))

i=build('blood_dynamo');p.hp=10;p.ps.magic=20
assert(not use(i) and p.hp==10)
p.hp=11;complete(i);assert(p.hp==1 and p.ps.magic==45)
assert(not use(i) and p.hp==1 and p.ps.magic==45)

-- Protected/equipped gear is never selected. Review binds the exact inventory.
i=build('salvage_press');local equipped=wear(p,1,'left_hand');local stock=wear(p,2);stock.economyExcluded=true
assert(not use(i))
local sold=wear(p,3);local v=E:Value(sold);review(i)
local before=p.ps.equipment;p.ps.equipment=table.Copy(before)
assert(not use(i) and p.ps.equipment.items[sold.id] and balance(p)==0,'inventory replacement bypassed review')
assert(use(i));assert(balance(p)==v and not p.ps.equipment.items[sold.id])
assert(p.ps.equipment.items[equipped.id] and p.ps.equipment.items[stock.id])

i=build('salvage_press');sold=wear(p,44);review(i)
sold.cosmeticReviewProof='changed after review'
assert(not use(i) and p.ps.equipment.items[sold.id] and balance(p)==0,'in-place edit bypassed exact review')
assert(use(i) and not p.ps.equipment.items[sold.id])

i=build('salvage_press');sold=wear(p,4);review(i);before=p.ps.equipment
sql.Query=function(s) if s=='COMMIT' then return false end;return nativeSQL(s) end
assert(not use(i));sql.Query=nativeSQL
assert(p.ps.equipment==before and p.ps.equipment.items[sold.id] and balance(p)==0 and not T.Claim(i,p.id))

i=build('reforging_bench');local a=wear(p,5);local b=wear(p,6)
local offer=assert(Services.reforging_bench.Quote(i,p,p.id));local out=offer.item
assert(E:ValidateWearable(out) and E:Value(out)<=E:Value(a)+E:Value(b))
complete(i);assert(countWear(p)==1 and p.ps.equipment.items[out.id])
assert(not p.ps.equipment.items[a.id] and not p.ps.equipment.items[b.id])

i=build('key_cutter');p.ps.magic=20;assert(E:AddConsumable(p.ps.equipment,'healing_potion',1))
assert(E:AddConsumable(p.ps.equipment,'chest_key',9));review(i)
assert(not use(i) and p.ps.magic==20 and p.ps.equipment.items.healing_potion.count==1)
assert(E:Consume(p.ps.equipment,'chest_key'));review(i)
assert(use(i));assert(p.ps.magic==0 and not p.ps.equipment.items.healing_potion and p.ps.equipment.items.chest_key.count==9)

-- Canonical ammo selection grants only the held family; full gun costs nothing.
i=build('ammo_transmuter');p.ps.magic=50
local gun=p:Give('weapon_pistol');gun.GetPrimaryAmmoType=function() return 'Pistol' end
p.activeClass='weapon_pistol';p.ammo.Pistol=0;complete(i)
assert(p.ps.magic==35 and p.ammo.Pistol==18)
i=build('ammo_transmuter');p.ps.magic=50
gun=p:Give('weapon_pistol');gun.GetPrimaryAmmoType=function() return 'Pistol' end
p.activeClass='weapon_pistol';p.ammo.Pistol=54
local other=p:Give('weapon_smg1');other.GetPrimaryAmmoType=function() return 'SMG1' end
review(i);assert(not use(i) and p.ps.magic==50 and p.ammo.Pistol==54 and p:GetAmmoCount('SMG1')==0)

i=build('ammo_transmuter');p.ps.magic=50
gun=p:Give('weapon_pistol');gun.GetPrimaryAmmoType=function() return 'Pistol' end
p.activeClass='weapon_pistol';p.ammo.Pistol=3;review(i)
local setAmmo=p.SetAmmo
p.SetAmmo=function(self,n,kind) self.ammo[kind]=n;error('native SetAmmo after mutation') end
assert(not use(i));p.SetAmmo=setAmmo
assert(p.ammo.Pistol==3 and p.ps.magic==50 and not T.Claim(i,p.id))

i=build('prisoner_barter');assert(E:AddConsumable(p.ps.equipment,'healing_potion',1))
local cap=E:StorageCapacity(p.ps.equipment)
for n=1,cap do wear(p,100+n) end
review(i);assert(not use(i) and p.ps.equipment.items.healing_potion.count==1)
local remove=next(p.ps.equipment.items)
while remove=='healing_potion' do remove=next(p.ps.equipment.items,remove) end
assert(E:Discard(p.ps.equipment,remove));review(i)
assert(use(i) and not p.ps.equipment.items.healing_potion and countWear(p)==cap)

-- Status bargain uses the shared authority and cannot cash an existing curse.
i=build('overclock_console');p.ps.magic=1
complete(i);assert(p.ps.magic==100 and LOD.RPGStatusElements:Has(p,'reckless'))
i=build('overclock_console');p.ps.magic=1;review(i)
sql.Query=function(s) if s=='COMMIT' then return false end;return nativeSQL(s) end
assert(not use(i));sql.Query=nativeSQL
assert(p.ps.magic==1 and not LOD.RPGStatusElements:Has(p,'reckless') and not T.Claim(i,p.id))

-- Shared auction: exact frozen item, explicit falling price, one party owner.
i=build('contraband_lot');funds(p,10000);funds(q,10000)
local lot=assert(Services.contraband_lot.Quote(i,p,p.id));local originalItem=table.Copy(lot.item)
F.now=F.now+60;local cheaper=assert(Services.contraband_lot.Quote(i,p,p.id));assert(cheaper.price<lot.price)
review(i,p);review(i,q);assert(use(i,p));assert(not use(i,q))
assert(countWear(p)==1 and countWear(q)==0 and balance(q)==10000)
local oldMarket=Run.State.EventServiceMarket
i=build('contraband_lot',true)
assert(Run.State.EventServiceMarket==oldMarket and T.Equal(Services.contraband_lot.Quote(i,p,p.id).item,originalItem))
assert(not use(i,q) and countWear(q)==0)

i=build('contraband_lot');funds(p,10000);funds(q,10000);review(i,p);review(i,q)
local reentered,otherAccepted=false,nil
sql.Query=function(s)
    if not reentered and s:find('INSERT INTO lod_crypto_ledger',1,true) then
        reentered=true;otherAccepted=use(i,q)
    end
    return nativeSQL(s)
end
assert(use(i,p));sql.Query=nativeSQL
assert(reentered and not otherAccepted and countWear(p)==1 and countWear(q)==0 and balance(q)==10000)

i=build('life_underwriter');p.ps.lives=1;assert(not use(i));p.ps.lives=2
complete(i);assert(p.ps.lives==1 and balance(p)==40 and not use(i))

-- Reentrant Use remains busy; failed presentation cannot reopen final receipts.
i=build('life_underwriter');review(i)
local nested
sql.Query=function(s)
    if s:find('INSERT INTO lod_crypto_ledger',1,true) then nested=use(i) end
    return nativeSQL(s)
end
local report=E.Report;E.Report=function() error('native feedback') end
assert(use(i));E.Report=report;sql.Query=nativeSQL
assert(nested==false and p.ps.lives==2 and balance(p)==40 and not use(i))

-- Native state cancellation after SQL writes preserves costs and claims.
i=build('key_cutter');p.ps.magic=80;assert(E:AddConsumable(p.ps.equipment,'healing_potion',1));review(i)
before=p.ps.equipment
sql.Query=function(s)
    if s:find('INSERT INTO lod_crypto_ledger',1,true) then Run.State.SimulationFrozen=true end
    return nativeSQL(s)
end
assert(not use(i));sql.Query=nativeSQL;Run.State.SimulationFrozen=false
assert(p.ps.equipment==before and p.ps.magic==80 and p.ps.equipment.items.healing_potion.count==1 and not T.Claim(i,p.id))

-- The final native visibility trace can replace a life after initial admission.
-- Recheck exact ownership after that boundary before committing Lua resources.
i=build('life_underwriter');review(i)
local realTrace,pending,oldLife=util.TraceLine,false,p.ps.equipmentLifeSerial
sql.Query=function(s)
    if s:find('INSERT INTO lod_crypto_ledger',1,true) then pending=true end
    return nativeSQL(s)
end
util.TraceLine=function(...)
    if pending then pending=false;p.ps.equipmentLifeSerial=oldLife+1;p.LODRunSpawnSerial=2 end
    return realTrace(...)
end
assert(not use(i));util.TraceLine=realTrace;sql.Query=nativeSQL
assert(p.ps.lives==3 and balance(p)==0 and not T.Claim(i,p.id))

-- A reused ps object with the same scalar value still belongs to a new life;
-- compensation must not replace its lives with the prior Hero's value.
i=build('life_underwriter');review(i);oldLife=p.ps.equipmentLifeSerial
sql.Query=function(s)
    if s=='COMMIT' then p.ps.equipmentLifeSerial=oldLife+1;p.ps.lives=2;return false end
    return nativeSQL(s)
end
assert(not use(i));sql.Query=nativeSQL
assert(p.ps.lives==2 and balance(p)==0 and not T.Claim(i,p.id))
D:Cleanup('service test');assert(not i.serviceOffers and #i.entities==0)
print('EVENT_SERVICES_PASS: ten real services; informed exact review; canonical health/ammo/status/equipment; SQL/native rollback; shared/personal durable claims; regeneration, life replacement, full bags, reentrancy and cleanup')
