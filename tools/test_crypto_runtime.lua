-- Real production equipment, SQLite persistence and economy integration.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,Run=LOD.Equipment,fixture.Run
getmetatable(Vector()).__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
local hooks=fixture.hooks
sql={Query=WalletSQLQuery,LastError=WalletSQLError,SQLStr=function(s) return "'"..s:gsub("'","''").."'" end}
util.TableToJSON=WalletJSONEncode
util.JSONToTable=function(s,_,preserve) assert(preserve,'Wallet must preserve string keys');return WalletJSONDecode(s) end
local errors={};ErrorNoHalt=function(s) errors[#errors+1]=s end
local handlers={};net.Receive=function(name,fn) handlers[name]=fn end
net.ReadString=function() return '' end
LOD.SnapshotDelivery={Queue=function() end,Invalidate=function() end}
local S={EnsureHut=function() return true end,_ExecuteDeploymentTransition=function(_,p) p.active=true end,
    IsPlayerInHut=function(_,p) return p.inHut~=false end}
LOD.StagingDeployment=S
Run.IsSlotActivePlayer=function(_,p) return p.slot~=false end
Run.CompleteLevel=function(self) if self.State.LevelCleared then return false end;self.State.LevelCleared=true;return true end
Run.AdvanceLevel=function(self) self.State.Level=self.State.Level+1;self.State.LevelCleared=false;return true end
local all={}
local function actor(id,enemy)
    local p=fixture.actor(id,enemy)
    p.EyePos=p.GetPos;p.WorldSpaceCenter=p.GetPos
    p.GetAmmo=function(self) return self.ammo end
    p.RemoveAllAmmo=function(self) self.ammo={} end
    p.GetWeapons=function(self) local w={};for _,v in pairs(self.weapons) do w[#w+1]=v end;return w end
    p.StripWeapon=function(self,class) self.weapons[class]=nil end
    local give=p.Give
    function p:Give(class)
        local w=give(self,class)
        if w then w.Clip2=function() return -1 end;w.SetClip2=function() end end
        return w
    end
    return p
end
local a,b,soldier=actor('76561198000000001'),actor('76561198000000002'),actor('76561198000000003')
all={a,b,soldier};player.GetAll=function() return all end
Run.State={Ranked=true,Level=1,LevelSeed=77,CampaignSeed=73,BuildReady=true,PlayerState={}}
for _,p in ipairs(all) do Run.State.PlayerState[p.id]=p.ps end
GM.EntityTakeDamage=function() end
LOD.SoldierProgression.Attach=function(_,p) p.soldier=true;return {} end
dofile(root..'sv_faction_manager.lua')
dofile(root..'sv_crypto_store.lua');local Store=LOD.CryptoStore
assert(Store.Ready)
Run.State.RunId=Store:NextRunID()
dofile(root..'sv_crypto_director.lua');local C=LOD.CryptoDirector
dofile(root..'sv_crypto_statue.lua')
dofile(root..'sv_crypto_runtime.lua')
C.Statue={valid=true,GetPos=function() return Vector() end,WorldSpaceCenter=function() return Vector() end}
local blocked=false
util.TraceLine=function() return {Hit=blocked,Entity=nil} end
local function size(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local function account(p) return assert(Store:Read(p.id)) end
local function near(x,y) assert(math.abs(x-y)<.00001,tostring(x)..' ~= '..tostring(y)) end
-- Participation and actual post-damage HP deltas, including overkill and blocks.
C:Participate(a);C:Participate(b)
local enemy=actor('enemy',true)
local function damage(source,target,amount,lethal)
    local info={GetAttacker=function() return source end,GetDamage=function() return amount end}
    GM:EntityTakeDamage(target,info)
    target.hp=target.hp-amount
    if lethal then C:HeroLifeConsumed(target,source) end
    hooks.LOD_CryptoEffectiveDamage(target,info,amount>0)
    hooks.LOD_CryptoEffectiveDamage(target,info,amount>0) -- duplicate post cannot count twice
end
enemy.hp=90;damage(a,enemy,900);near(C:LevelState().heroes[a.id],90)
enemy.hp=10;damage(b,enemy,10);near(C:LevelState().heroes[b.id],10)
local shares=C:Allocations(C:LevelState(),1)
assert(shares[a.id].amount==70 and shares[b.id].amount==30)
assert(not C:Settle(),'No currency before rescue')
Run.State.LevelCleared=true
assert(C:Settle());assert(account(a).balance==70 and account(b).balance==30)
assert(account(a).score==70)
assert(not C:Settle());assert(account(a).balance==70)
-- Database identity survives connection close/reopen and production-store reload.
WalletSQLReconnect();dofile(root..'sv_crypto_store.lua')
assert(LOD.CryptoStore:Read(a.id).balance==70)
assert(LOD.CryptoStore:NextRunID()~=Run.State.RunId,'Run IDs cannot collide after restart')
C:LevelState().settled=nil;assert(not C:Settle());assert(account(a).balance==70,'Ledger protects duplicate after volatile cache loss')
Run.State.LevelCleared=false;Run.State.Level=2
C:Participate(a);C:Participate(b)
-- Healing is limited to outstanding hostile-caused loss. Self/regen/friendly loops earn nothing.
a.hp=100;b.hp=100;enemy.hp=100
damage(enemy,b,40);assert(C:LevelState().wounds[b.id].amount==40)
assert(E:Heal(a,b,25));near(C:LevelState().heroes[a.id],25)
b.hp=100 -- unattributed regen clears remaining hostile debt before next damage
local before=C:LevelState().heroes[a.id]
damage(a,b,20);assert(E:Heal(a,b,25));near(C:LevelState().heroes[a.id],before)
damage(enemy,b,20);assert(E:Heal(b,b,25));near(C:LevelState().heroes[b.id],0)
-- Soldier elimination gives exactly one proportional credit for the consumed life.
LOD.SoldierProgression:Attach(soldier)
b.hp=100;damage(soldier,b,40);damage(soldier,b,100,true)
assert(C:LevelState().eliminations==1);near(C:LevelState().soldiers[soldier.id],1)
assert(C:Allocations(C:LevelState(),2)[soldier.id].amount==22)
-- A stale old hit followed by an administrative death cannot create credit.
b.hp=100;damage(soldier,b,1);b.hp=0;C:HeroLifeConsumed(b,{valid=true})
assert(C:LevelState().eliminations==1)
-- Switching roles permanently forfeits Hero share for this dungeon.
LOD.SoldierProgression:Attach(a)
shares=C:Allocations(C:LevelState(),2)
assert(shares[a.id].role=='soldier' and shares[a.id].amount==0)
local sum=0;for _,share in pairs(shares) do sum=sum+share.amount end;assert(sum==200)
a.soldier=false;a.hp=100;b.hp=100;a.active=false;b.active=false
-- Milestones are frozen once, persist through sale and stop at eight slots.
for _,level in ipairs({1,5,10,20}) do assert(C:Milestone(a.id,level));assert(not C:Milestone(a.id,level)) end
assert(size(account(a).tokens)==4)
local token=next(account(a).tokens)
local frozen=account(a).tokens[token].item
assert(C:Recreate(a,token));assert(account(a).tokens[token].lastRun==Run.State.RunId)
local owned=E:Equipped(a.ps.equipment,E:Placement({items={},slots={}},frozen))
assert(owned and owned.name==frozen.name and owned.id~=frozen.id)
assert(WalletJSONEncode(owned.properties)==WalletJSONEncode(frozen.properties))
assert(not C:Recreate(a,token),'Second click cannot recreate')
Run.State.Level=3;assert(not C:Recreate(a,token),'New maze is same run')
Run.State.RunId=Store:NextRunID();assert(C:Recreate(a,token),'New campaign restores entitlement')
local value=E:Value(frozen);local balance=account(a).balance
assert(C:Sell(a,token));assert(account(a).balance==balance+value and account(a).score==70)
assert(not C:Sell(a,token));assert(not C:Milestone(a.id,1),'Selling never renews milestone')
-- Fill another account, earn a pending frozen milestone, sell and promote without reroll.
for i=1,8 do assert(C:CollectToken(b,C:GenerateToken(b.id,'test-rare:'..i,'Rare enemy drop',2))) end
assert(size(account(b).tokens)==8)
local ninth=C:GenerateToken(b.id,'test-rare:9','Rare enemy drop',2)
assert(not C:CollectToken(b,ninth))
assert(C:Milestone(b.id,1));assert(account(b).pending['1'])
local pending=account(b).pending['1'];local sellId=next(account(b).tokens)
assert(C:Sell(b,sellId));local after=account(b)
assert(size(after.tokens)==8 and not after.pending['1'] and after.tokens[pending.id].item.name==pending.item.name)
assert(not C:Sell(a,pending.id),'Cannot sell another account token')
-- Rollback includes ledger/account and engine inventory; failure leaves entitlement reusable.
token=next(account(a).tokens)
local original=account(a)
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not C:Sell(a,token));assert(account(a).balance==original.balance and account(a).tokens[token])
local bag=WalletJSONEncode(a.ps.equipment);local ammo=WalletJSONEncode(a.ammo)
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not C:Recreate(a,token));assert(account(a).tokens[token].lastRun~=Run.State.RunId)
assert(WalletJSONEncode(a.ps.equipment)==bag and WalletJSONEncode(a.ammo)==ammo)
assert(C:Recreate(a,token))
-- Normal weapon admission failures cannot spend a DFT recreation.
local weaponToken=C:GenerateToken(a.id,'weapon-failure','Rare enemy drop',2)
weaponToken.item=E:Generate(401,2,'weapon_357','weapon-failure')
assert(C:CollectToken(a,weaponToken))
a.weapons.weapon_357=nil;a.failGive=true
assert(not C:Recreate(a,weaponToken.id));assert(not account(a).tokens[weaponToken.id].lastRun)
a.failGive=false;assert(C:Recreate(a,weaponToken.id))
-- Capacity failure leaves recreation available, through real equipment admission.
Run.State.RunId=Store:NextRunID()
local cap=E.MaximumStoredEquipment;E.MaximumStoredEquipment=0
assert(not C:Recreate(a,weaponToken.id));assert(account(a).tokens[weaponToken.id].lastRun~=Run.State.RunId)
E.MaximumStoredEquipment=cap;assert(C:Recreate(a,weaponToken.id))
-- Separate rare stream has the authored low frequency and deterministic replay.
a.active=true
local Loot=LOD.LootDirector
local spawn=Loot.SpawnPickup
local rareHits,rareIDs=0,{}
function Loot:SpawnPickup(id,pos,kind,payload)
    assert(kind=='dft' and id==a.id);assert(E:ValidateWearable(payload.token.item))
    rareHits=rareHits+1;rareIDs[#rareIDs+1]=payload.token.id
    return {valid=true}
end
for i=1,10000 do C:RareOpportunity(a,enemy,i) end
assert(rareHits>=2 and rareHits<=25,'Expected approximately ten 1/1000 hits')
local sequence=table.concat(rareIDs,'|');rareHits=0;rareIDs={}
for i=1,10000 do C:RareOpportunity(a,enemy,i) end
assert(table.concat(rareIDs,'|')==sequence,'No reroll on deterministic replay')
Loot.SpawnPickup=spawn
-- Existing death handoff is the once-only opportunity authority.
local opportunity=C.RareOpportunity;local attempts=0
C.RareOpportunity=function() attempts=attempts+1 end
local objective,lootstate,drop=Loot._ObjectiveClearDrop,Loot._PlayerLootState,Loot._DropCategory
Loot._ObjectiveClearDrop=function() return false end
Loot._PlayerLootState=function() return {killSerial=0} end
Loot._DropCategory=function() return nil end
enemy.GetNW2Int=function(_,_,fallback) return fallback end
enemy.LODDeathLevelSeed=Run.State.LevelSeed
a.active=true;b.active=false;soldier.active=false
Loot:OnHostileLootHandoff(enemy);Loot:OnHostileLootHandoff(enemy)
assert(attempts==1,'Repeated death handoff cannot roll again')
C.RareOpportunity=opportunity;Loot._ObjectiveClearDrop=objective;Loot._PlayerLootState=lootstate;Loot._DropCategory=drop
a.active=false
-- Authentic statue, role, life, staging and LOS gates are rechecked per action.
blocked=true;assert(not C:Sell(a,token));blocked=false
for _,change in ipairs({function() a.soldier=true end,function() a.hp=0 end,function() a.ps.deploymentComplete=true end,
    function() a.inHut=false end,function() a.slot=false end}) do
    change();assert(not C:CanUseStatue(a));a.soldier=false;a.hp=100;a.ps.deploymentComplete=false;a.inHut=true;a.slot=true
end
-- Range, wrong statue, oversized/repeated/foreign network actions.
local statuePos=C.Statue.GetPos
C.Statue.GetPos=function() return Vector(10000,0,0) end
assert(not C:CanUseStatue(a));C.Statue.GetPos=statuePos
assert(not C:OpenStatue(a,{valid=true}))
local oldTime=CurTime;local clock=100;CurTime=function() return clock end
local reads=0;local fields={'snapshot',''}
net.ReadString=function() reads=reads+1;return fields[(reads-1)%2+1] end
local request=handlers.LOD_WalletRequest
request(4097,a);assert(reads==0)
request(64,a);assert(reads==2)
request(64,a);assert(reads==2,'Repeated request discarded before parsing')
clock=clock+1;fields={'sell',pending.id}
local otherBalance=account(b).balance;request(128,a)
assert(account(b).tokens[pending.id] and account(b).balance==otherBalance)
CurTime=oldTime
-- Atomic multi-account rescue failure holds advancement, then retries once.
Run.State.Level=4;Run.State.LevelCleared=true;Run.State.crypto=nil
local level=C:LevelState();level.heroes={[a.id]=90,[b.id]=10}
local beforeA,beforeB=account(a).balance,account(b).balance
clock=200;CurTime=function() return clock end
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not Run:AdvanceLevel() and Run.State.Level==4)
assert(account(a).balance==beforeA and account(b).balance==beforeB,'No partial multi-account payout')
assert(not Run:AdvanceLevel(),'Failed settlement retry is throttled')
clock=202;assert(Run:AdvanceLevel() and Run.State.Level==5)
assert(account(a).balance==beforeA+280 and account(b).balance==beforeB+120)
CurTime=oldTime
Run.State.Ranked=false
assert(not C:Sell(a,token) and not C:Recreate(a,token) and not C:Milestone(a.id,1))
Run.State.Ranked=true
-- Corruption remains present and visible, rather than resetting the account.
assert(sql.Query("UPDATE lod_crypto_accounts SET body='{}' WHERE account="..sql.SQLStr(a.id))~=false)
assert(not Store:Read(a.id));assert(#errors>=3)
assert(sql.Query('SELECT body FROM lod_crypto_accounts WHERE account='..sql.SQLStr(a.id))[1].body=='{}')
print('CRYPTO_SQLITE_PASS: real SQLite reopen/unique RunIDs; exact contribution allocation; role/death/healing guards; milestones/capacity/pending; frozen recreation; sale/lifetime separation; replay/rollback/corruption; statue authorization; unranked isolation')
