-- Real production equipment, SQLite persistence and economy integration.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,Run=LOD.Equipment,fixture.Run
getmetatable(Vector()).__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
local hooks=fixture.hooks
sql={Query=WalletSQLQuery,LastError=WalletSQLError,SQLStr=function(s,noQuotes) local escaped=s:gsub("'","''");return noQuotes and escaped or "'"..escaped.."'" end}
util.TableToJSON=WalletJSONEncode
util.JSONToTable=function(s,_,preserve) assert(preserve,'Wallet must preserve string keys');return WalletJSONDecode(s) end
local errors={};ErrorNoHalt=function(s) errors[#errors+1]=s end
net.WriteUInt=function() end;net.WriteFloat=function() end;net.WriteBool=function() end
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
    p.Nick=function() return id end
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
for _,p in ipairs(all) do Run.State.PlayerState[p.id]=p.ps;p.ps.progressionState.level=1 end
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
assert(account(a).milestones['1'] and account(b).milestones['1'])
local rescueTokens=WalletJSONEncode(account(b).tokens)
assert(not C:Settle());assert(account(a).balance==70)
assert(WalletJSONEncode(account(b).tokens)==rescueTokens,'Rescue retry cannot duplicate or reroll tokens')
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
-- DFTs are rescue rewards only; milestones remain frozen and capped.
assert(not C:Milestone(a.id,1))
Run.State.LevelCleared=true
assert(account(a).milestones['1'] and not C:Milestone(a.id,1))
for _,level in ipairs({5,10,20}) do assert(C:Milestone(a.id,level));assert(not C:Milestone(a.id,level)) end
assert(size(account(a).tokens)==4)
Run.State.LevelCleared=false
local token=next(account(a).tokens)
local frozen=account(a).tokens[token].item
assert(C:Recreate(a,token));assert(account(a).tokens[token].lastRun==Run.State.RunId)
local owned=E:Equipped(a.ps.equipment,E:Placement({items={},slots={}},frozen))
assert(owned and owned.name==frozen.name and owned.id~=frozen.id and owned.recreatedFrom==token and owned.economyExcluded)
assert(WalletJSONEncode(owned.properties)==WalletJSONEncode(frozen.properties))
assert(not C:Recreate(a,token),'Second click cannot recreate')
Run.State.Level=3;assert(not C:Recreate(a,token),'New maze is same run')
Run.State.RunId=Store:NextRunID();assert(C:Recreate(a,token),'New campaign restores entitlement')
local value=E:Value(frozen);local balance=account(a).balance
assert(C:Sell(a,token));assert(account(a).balance==balance+value and account(a).score==70)
assert(not C:Sell(a,token));assert(not C:Milestone(a.id,1),'Selling never renews milestone')
-- Fill another account, earn a pending frozen milestone, sell and promote without reroll.
Run.State.LevelCleared=true
for i=1,8-size(account(b).tokens) do assert(C:CollectToken(b,C:GenerateToken(b.id,'test-rare:'..i,'Rare enemy drop',2))) end
assert(size(account(b).tokens)==8)
local ninth=C:GenerateToken(b.id,'test-rare:9','Rare enemy drop',2)
assert(not C:CollectToken(b,ninth))
assert(C:Milestone(b.id,5));assert(account(b).pending['5'])
local pending=account(b).pending['5'];local sellId=next(account(b).tokens)
Run.State.LevelCleared=false
assert(C:Sell(b,sellId));local after=account(b)
assert(size(after.tokens)==8 and not after.pending['5'] and after.tokens[pending.id].item.name==pending.item.name)
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
assert(not C:CollectToken(a,weaponToken))
Run.State.LevelCleared=true
assert(C:CollectToken(a,weaponToken))
Run.State.LevelCleared=false
a.weapons.weapon_357=nil;a.failGive=true
assert(not C:Recreate(a,weaponToken.id));assert(not account(a).tokens[weaponToken.id].lastRun)
a.failGive=false;assert(C:Recreate(a,weaponToken.id))
-- Capacity failure leaves recreation available, through real equipment admission.
Run.State.RunId=Store:NextRunID()
local cap=E.MaximumStoredEquipment;E.MaximumStoredEquipment=0
assert(not C:Recreate(a,weaponToken.id));assert(account(a).tokens[weaponToken.id].lastRun~=Run.State.RunId)
E.MaximumStoredEquipment=cap;assert(C:Recreate(a,weaponToken.id))
-- Ordinary enemy opportunities never create DFTs.
a.active=true
local Loot=LOD.LootDirector
local spawn=Loot.SpawnPickup
local rareHits=0
function Loot:SpawnPickup() rareHits=rareHits+1 end
for i=1,10000 do C:RareOpportunity(a,enemy,i) end
assert(rareHits==0)
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
assert(attempts==0,'Ordinary enemy death never rolls a DFT')
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
-- Debbie junk exchanges use the real SQLite transaction/ledger and equipment generator.
dofile(root..'sv_debbie_junk.lua')
a.active=false;b.active=false;a.ps.deploymentComplete=false;b.ps.deploymentComplete=false
local function junk(p,seed)
    local item=E:Generate(seed,8,'ring','junk:'..p.id..':'..seed)
    E:Ensure(p.ps).items[item.id]=item;return item
end
local first=junk(a,8001);local second=junk(b,8002)
local firstValue=E:Value(first);local balance=account(a).balance;local other=account(b).balance
assert(not C:ExchangeJunk(b,'sell_items',{first.id}),'Foreign inventory ID accepted')
assert(not C:ExchangeJunk(a,'sell_items',{first.id,first.id}),'Duplicate selection accepted')
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not C:ExchangeJunk(a,'sell_items',{first.id}));assert(a.ps.equipment.items[first.id] and account(a).balance==balance)
assert(C:ExchangeJunk(a,'sell_items',{first.id}));assert(not a.ps.equipment.items[first.id] and account(a).balance==balance+firstValue)
assert(not C:ExchangeJunk(a,'sell_items',{first.id}));assert(account(a).balance==balance+firstValue)
assert(C:ExchangeJunk(b,'sell_items',{second.id}));assert(account(b).balance==other+E:Value(second))
local one,two=junk(a,8011),junk(a,8012);balance=account(a).balance
local originalBag=WalletJSONEncode(a.ps.equipment)
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not C:ExchangeJunk(a,'fuse_items',{one.id,two.id}))
assert(WalletJSONEncode(a.ps.equipment)==originalBag and account(a).balance==balance,'Fusion partially consumed on rollback')
local input=E:Value(one)+E:Value(two);local ok,receipt=C:ExchangeJunk(a,'fuse_items',{one.id,two.id});assert(ok,receipt)
local fused=a.ps.equipment.items[receipt.item];assert(fused and E:ValidateWearable(fused))
assert(E:Value(fused)>=input*.85 and E:Value(fused)<=input)
assert(not a.ps.equipment.items[one.id] and not a.ps.equipment.items[two.id] and account(a).balance==balance)
assert(not C:ExchangeJunk(a,'fuse_items',{one.id,two.id}),'Replay created a second fused item')
local locked=junk(a,8099);locked.recreatedFrom='token'
assert(not C:ExchangeJunk(a,'sell_items',{locked.id}) and not C:ExchangeJunk(a,'fuse_items',{locked.id,fused.id}))
-- Actual recreated equipment remains excluded after stowing/restoring, including
-- mixed piles. Either legacy provenance field independently prevents conversion.
local reproduced=0
for id,item in pairs(a.ps.equipment.items) do
    if item.recreatedFrom then
        reproduced=reproduced+1;E:UnequipItem(a.ps.equipment,id)
        local before=WalletJSONEncode(a.ps.equipment);local funds=account(a).balance
        assert(not C:ExchangeJunk(a,'sell_items',{id,fused.id}))
        assert(not C:ExchangeJunk(a,'fuse_items',{id,fused.id}))
        assert(before==WalletJSONEncode(a.ps.equipment) and funds==account(a).balance)
    end
end
assert(reproduced>1,'Exercise real token recreations across runs, not only synthetic flags')
local legacy=junk(a,8100);a.ps.equipment.items[legacy.id]=nil;legacy.id='recreated:legacy';a.ps.equipment.items[legacy.id]=legacy
assert(not E:JunkEligible(a.ps.equipment,legacy.id))
a.ps.equipment.items[legacy.id]=nil
local wearing=junk(a,8110);assert(E:Equip(a.ps.equipment,wearing.id,'left_hand'))
E:Sync(a)
local wornBag=WalletJSONEncode(a.ps.equipment);balance=account(a).balance
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not C:ExchangeJunk(a,'sell_items',{wearing.id}))
assert(wornBag==WalletJSONEncode(a.ps.equipment) and balance==account(a).balance,'Failed sale unequipped gear')
assert(C:ExchangeJunk(a,'sell_items',{wearing.id}))
assert(not a.ps.equipment.slots.left_hand and not a.ps.equipment.items[wearing.id])
local worn,spare=junk(a,8111),junk(a,8112);assert(E:Equip(a.ps.equipment,worn.id,'right_hand'))
assert(C:ExchangeJunk(a,'fuse_items',{worn.id,spare.id}))
assert(not a.ps.equipment.slots.right_hand and not a.ps.equipment.items[worn.id])
-- Bulk sale revalidates all reviewed IDs and commits the complete pile once.
local bulk,total={},0
for i=1,12 do local item=junk(a,8200+i);bulk[#bulk+1]=item.id;total=total+E:Value(item) end
assert(E:Equip(a.ps.equipment,bulk[1],'left_hand'))
balance=account(a).balance
assert(not C:ExchangeJunk(a,'sell_unequipped',bulk),'A stale equipped selection must reject the whole sale')
assert(a.ps.equipment.items[bulk[12]] and account(a).balance==balance)
E:UnequipItem(a.ps.equipment,bulk[1])
local protected={bulk[1],locked.id}
assert(not C:ExchangeJunk(a,'sell_unequipped',protected),'DFT equipment is protected in bulk sales')
local exchangeStore=LOD.CryptoStore
local transact=exchangeStore.Transaction
for _,change in ipairs({'equipped','protected','removed'}) do
    local saved=table.Copy(a.ps.equipment)
    function exchangeStore:Transaction(event,kind,ids,mutate)
        if change=='equipped' then a.ps.equipment.slots.left_hand=bulk[1]
        elseif change=='protected' then a.ps.equipment.items[bulk[1]].economyExcluded=true
        else a.ps.equipment.items[bulk[1]]=nil end
        local atCommit=WalletJSONEncode(a.ps.equipment)
        local ok,reason=transact(self,event,kind,ids,mutate)
        assert(WalletJSONEncode(a.ps.equipment)==atCommit,'Failure altered inventory')
        return ok,reason
    end
    assert(not C:ExchangeJunk(a,'sell_unequipped',bulk),'In-transaction '..change..' change accepted')
    assert(account(a).balance==balance,'Rejected review paid currency')
    a.ps.equipment=saved
end
exchangeStore.Transaction=transact
WalletSQLFail('INSERT INTO lod_crypto_ledger')
assert(not C:ExchangeJunk(a,'sell_unequipped',bulk))
for _,id in ipairs(bulk) do assert(a.ps.equipment.items[id],'Rollback lost an item') end
assert(account(a).balance==balance)
assert(C:ExchangeJunk(a,'sell_unequipped',bulk))
for _,id in ipairs(bulk) do assert(not a.ps.equipment.items[id]) end
assert(account(a).balance==balance+total)
assert(not C:ExchangeJunk(a,'sell_unequipped',bulk),'Bulk replay settled twice')
assert(account(a).balance==balance+total)
-- The network adapter sends a matching result and refresh even on denied input.
local strings={'sell_items',locked.id};local uints={1,57};local responses={}
net.ReadString=function() return table.remove(strings,1) end
net.ReadUInt=function() return table.remove(uints,1) end
net.WriteTable=function(row) responses[#responses+1]=row end
handlers.LOD_JunkExchange(100,a)
assert(responses[#responses].request==57 and not responses[#responses].ok)
assert(responses[#responses].message:find('DFT-created',1,true))
local expectedCount=0
for _,p in ipairs({a,b,soldier}) do
    local value=account(p).balance;for _,token in pairs(account(p).tokens) do value=value+E:Value(token.item) end
    if value>0 then expectedCount=expectedCount+1 end
end
local rows=C:StakeholderRows({a,b,soldier});assert(#rows==expectedCount and #rows>=2 and rows[1].value>=rows[2].value)
for _,row in ipairs(rows) do
    local p=row.id==a.id and a or row.id==b.id and b or soldier
    local expected=account(p).balance;for _,token in pairs(account(p).tokens) do expected=expected+E:Value(token.item) end
    assert(row.value==expected,'Stakeholders must include both wallet balance and canonical DFT valuation')
end
assert(#C:StakeholderRows({a})==expectedCount,'Persisted holders remain visible while offline')
-- More than two pages, equal-value account ordering, current-session names and
-- changes after the cache was populated all pass through the real SQLite store.
local holders={}
for i=1,23 do
    local id=string.format('765611981%08d',i)
    holders[i]=actor(id)
    assert(exchangeStore:Transaction('board:'..i,'board_fixture',{id},function(accounts)
        accounts[id].balance=100000;accounts[id].name='Offline '..i;return true
    end))
end
holders[1].Nick=function() return 'Current session name' end
local ordered=C:StakeholderRows({holders[1],holders[1]})
local last,seen=nil,{}
for _,row in ipairs(ordered) do
    assert(not seen[row.id],'No duplicate account when current and persisted records overlap');seen[row.id]=true
    if last then assert(last.value>row.value or (last.value==row.value and last.id<row.id)) end
    last=row
end
assert(#ordered==expectedCount+23 and seen[holders[23].id])
local function findRow(rows,id) for _,row in ipairs(rows) do if row.id==id then return row end end end
assert(findRow(ordered,holders[1].id).name=='Current session name')
assert(exchangeStore:Transaction('board:updated','board_fixture',{holders[23].id},function(accounts)
    accounts[holders[23].id].balance=200000;return true
end))
assert(C:StakeholderRows({})[1].id==holders[23].id,'Committed holdings invalidate the ranking cache')
local oldHumans=player.GetHumans;player.GetHumans=function() return {holders[1]} end
local oldWrite,oldSend=net.WriteTable,net.Send
local delivered,recipient
net.WriteTable=function(rows) delivered=rows end;net.Send=function(ply) recipient=ply end
C.Stakeholders={}
hooks.LOD_StakeholdersJoin(holders[1]);table.remove(fixture.timers)()
assert(recipient==holders[1] and #delivered==expectedCount+23 and delivered[1].id==holders[23].id,
    'Late join gets fresh complete holdings even with an empty broadcast cache')
net.WriteTable,net.Send=oldWrite,oldSend;player.GetHumans=oldHumans
print('JUNK_SQLITE_PASS: ownership/duplicate/replay; real sale/fusion rollback and atomicity; 85–100% valid value; DFT mint exclusion; Stakeholder sorting/denominations/rounding')

-- Four-action token exchange uses real SQLite and cannot refresh recreation.
local tokenA,tokenB=a.id..':test-fusion:1',a.id..':test-fusion:2'
local expectedValue
assert(Store:Transaction('seed-token-exchange','test',{a.id},function(accounts)
    local items={E:Generate(9081,8,'ring','token-input:1'),E:Generate(9082,8,'ring','token-input:2')}
    expectedValue=E:Value(items[1])+E:Value(items[2])
    accounts[a.id].tokens={}
    for i,key in ipairs({tokenA,tokenB}) do accounts[a.id].tokens[key]={id=key,item=items[i],reason='test',source='test',depth=8,run=Run.State.RunId,lastRun=i==1 and Run.State.RunId or nil} end
    return true,{}
end))
local before=account(a);local walletBefore=before.balance
assert(not C:ExchangeTokens(b,'sell_tokens',{tokenA}),'Cross-player token isolation')
assert(not C:ExchangeTokens(a,'sell_tokens',{tokenA,tokenA}),'Duplicate token denied')
WalletSQLFail('INSERT OR REPLACE INTO lod_crypto_accounts')
assert(not C:ExchangeTokens(a,'fuse_tokens',{tokenA,tokenB}))
assert(account(a).tokens[tokenA] and account(a).tokens[tokenB] and account(a).balance==walletBefore,'Failed commit preserves both DFTs')
assert(C:ExchangeTokens(a,'fuse_tokens',{tokenA,tokenB}))
local fusedToken
for _,t in pairs(account(a).tokens) do fusedToken=t end
assert(fusedToken and fusedToken.lastRun==Run.State.RunId and not account(a).tokens[tokenA])
assert(E:Value(fusedToken.item)>=expectedValue*.85 and E:Value(fusedToken.item)<=expectedValue)
assert(not C:Recreate(a,fusedToken.id),'Fusion must not refresh used recreation')
assert(not C:ExchangeTokens(a,'fuse_tokens',{tokenA,tokenB}),'No replay fusion')
WalletSQLReconnect();assert(account(a).tokens[fusedToken.id].lastRun==Run.State.RunId,'DFT provenance and entitlement survive reopen')
assert(C:ExchangeTokens(a,'sell_tokens',{fusedToken.id}))
assert(account(a).balance==walletBefore+E:Value(fusedToken.item) and account(a).score==before.score)
assert(not C:ExchangeTokens(a,'sell_tokens',{fusedToken.id}),'Sale settles once')
print('DFT_EXCHANGE_SQLITE_PASS: batch ownership/duplicates, fusion value, commit rollback, recreation inheritance, SQLite reopen, single settlement, lifetime-score isolation')

-- Damsel rewards use the same wallet transaction and native inventory authority.
net.WriteUInt=function() end;net.WriteFloat=function() end;net.WriteBool=function() end
dofile(root..'sv_damsels.lua')
local D=LOD.Damsels
local now=1900000000;local realTime=os.time;os.time=function() return now end
Run.State.Abundance=true;Run.State.Level=21;Run.State.HighestLevel=21;Run.State.CampaignEpoch=8
Run.State.BuildReady=true;Run.State.LevelCleared=false;Run.State.Failed=false;Run.State.SimulationFrozen=false
Run.State.RescuedDamsels={};Run.State.DamselClaims={};Run.State.Ranked=true
for i=1,20 do Run.State.RescuedDamsels[i]=true end
for _,p in ipairs({a,b}) do p.active=false;p.inHut=true;p.soldier=false;p.ps.deploymentComplete=false;p.ps.eliminated=false;p.hp=100 end
local function rescued(i)
    local ent={valid=true,LODDamselLevel=i,LODCampaignEpoch=8,GetPos=function() return Vector() end,WorldSpaceCenter=function() return Vector() end}
    D.Entities[i]=ent;return ent
end
blocked=false;rescued(20)
assert(Store:Transaction('abundance-clean','test',{a.id,b.id},function(accounts)
    for _,acc in pairs(accounts) do acc.tokens={};acc.pending={};acc.abundanceClaimAt=nil end
    return true,{}
end))
assert(D:CanUse(a,D.Entities[20]))
assert(C:ClaimAbundance(a));assert(size(account(a).tokens)==1 and account(a).abundanceClaimAt==now)
assert(not C:ClaimAbundance(a));assert(size(account(a).tokens)==1)
assert(C:ClaimAbundance(b) and size(account(b).tokens)==1,'daily gift is per account')
WalletSQLReconnect()
local rejoined=actor(a.id);rejoined.active=false;rejoined.inHut=true
rejoined.ps=a.ps;Run.State.PlayerState[a.id]=rejoined.ps
assert(not C:ClaimAbundance(rejoined),'reconnect/storage reopen cannot refresh cooldown')
Run.State.RunId=Store:NextRunID()
assert(not C:ClaimAbundance(a),'new campaign cannot bypass persistent cooldown')
now=now+86399;assert(not C:ClaimAbundance(a))
now=now+1
WalletSQLFail('INSERT OR REPLACE INTO lod_crypto_accounts')
assert(not C:ClaimAbundance(a));assert(account(a).abundanceClaimAt==now-86400,'failed commit consumes no cooldown')
assert(C:ClaimAbundance(a) and size(account(a).tokens)==2)
local abundanceToken
for id,t in pairs(account(a).tokens) do if t.source:find('abundance:') then abundanceToken=id end end
assert(C:Recreate(a,abundanceToken))
local protected=false
for _,item in pairs(E:Ensure(a.ps).items) do if item.recreatedFrom==abundanceToken then protected=item.economyExcluded end end
assert(protected,'Abundance recreation retains existing anti-resale/fusion provenance')
now=now+86400
assert(Store:Transaction('abundance-full','test',{a.id},function(accounts)
    for i=1,8-size(accounts[a.id].tokens) do
        local t=C:GenerateToken(a.id,'capacity:'..i,'test',21);accounts[a.id].tokens[t.id]=t
    end
    return true,{}
end))
assert(not C:ClaimAbundance(a) and account(a).abundanceClaimAt==now-86400,'full wallet leaves gift unclaimed')
assert(C:Sell(a,next(account(a).tokens)));assert(C:ClaimAbundance(a))
Run.State.Ranked=false;assert(not C:ClaimAbundance(b));Run.State.Ranked=true
blocked=true;assert(not C:ClaimAbundance(b));blocked=false
b.ps.deploymentComplete=true;assert(not C:ClaimAbundance(b));b.ps.deploymentComplete=false
-- Campaign and per-visit rewards survive a new player object; failed services retry.
local calls=0;local originalGrant=D.Grant;local lines={}
D.Dialogue=function(_,_,level,line,result) lines[#lines+1]={level,line,result} end
D.Grant=function() calls=calls+1;return true,'claimed' end
D.NextTalk[a]=nil;assert(D:Use(a,rescued(9)))
D.NextTalk[a]=nil;assert(not D:Use(a,D.Entities[9]) and calls==1)
D.NextTalk[rejoined]=nil;assert(not D:Use(rejoined,D.Entities[9]) and calls==1)
Run.State.Level=22;D.NextTalk[a]=nil;assert(not D:Use(a,D.Entities[9]) and calls==1)
D.NextTalk[a]=nil;assert(D:Use(a,rescued(6)))
Run.State.Level=23;D.NextTalk[a]=nil;assert(D:Use(a,D.Entities[6]) and calls==3)
D.Grant=function() return false,'full' end
D.NextTalk[a]=nil;assert(not D:Use(a,rescued(10)))
D.Grant=originalGrant
-- Execute production reward handlers, including strict ammo family boundaries.
Run._SyncPlayerVars=function() end
dofile(root..'sv_magic.lua')
a.ps.equipment={items={},slots={}};a.weapons={};a.ammo={}
a.GetNW2Int=a.GetNW2Float
for i=1,5 do a:Give(D.Definitions[i].parameter) end
assert(D:Grant(a,D.Definitions[1],'pistol'))
assert(a:GetAmmoCount('Pistol')>0 and a:GetAmmoCount('SMG1')==0,'Nessa cannot refill another family')
assert(not D:Grant(a,D.Definitions[1],'pistol-full'))
for i=2,5 do assert(D:Grant(a,D.Definitions[i],'ammo:'..i)) end
LOD.RPGStatusElements.Active[a]={poisoned={expiresAt=CurTime()+100}}
assert(D:Grant(a,D.Definitions[7],'cure') and not LOD.RPGStatusElements.Active[a])
assert(not D:Grant(a,D.Definitions[7],'cure-empty'))
a.hp=1;assert(D:Grant(a,D.Definitions[6],'heal') and a.hp==26)
a.ps.magic=1;assert(D:Grant(a,D.Definitions[8],'magic') and a.ps.magic==26)
for i=9,15 do
    assert(D:Grant(a,D.Definitions[i],'equipment:'..i),'gift slot '..i)
end
local gifts=0
for _,item in pairs(a.ps.equipment.items) do if item.id:find("damsel:",1,true) then assert(item.economyExcluded);gifts=gifts+1 end end
assert(gifts==7,'seven distinct generated gear slots, all resale/fusion excluded')
assert(D:Grant(a,D.Definitions[16],'consumable'))
assert(D:Grant(a,D.Definitions[17],'full') and a.hp==a.max)
local beforeDeb=account(a).balance
assert(D:Grant(a,D.Definitions[18],'coins'))
assert(account(a).balance>=beforeDeb+25 and account(a).balance<=beforeDeb+75)
assert(not D:Grant(a,D.Definitions[18],'coins-replay'))
a.ps.lives=1;assert(D:Grant(a,D.Definitions[19],'life') and a.ps.lives==2)
-- After statue recreation, real inventory admission allows staged equipment.
assert(not E:CanAct(a) and E:CanManageInventory(a))
local item=E:Generate(123,20,'weapon_pistol','staged-weapon')
assert(E:AcquireWorldItem(a,item,true,'damsel'))
assert(E:InventoryWeapon(a,item.id,false),'stage player equips/selects owned weapon after statue')
a.ps.deploymentComplete=true;assert(not E:CanManageInventory(a));a.ps.deploymentComplete=false
os.time=realTime
print('DAMSEL_REWARDS_SQLITE_PASS: per-player rolling24h/reconnect/reset/rollback/full-wallet; existing DFT provenance; identity claims, real ammo/health/magic/gear/potion/coins/life; staging equipment')

-- Cross-authority treasure settlement uses the real wallet transaction. Only
-- detached Lua references participate; no native grant is needed for a DFT.
local treasureId='76561198000000901'
local function treasure(label)
    return C:GenerateToken(treasureId,'treasure-chest:'..Run.State.RunId..':'..Run.State.Level..':'..label,
        'Dungeon treasure chest',Run.State.Level)
end
local function settlement(token)
    local owner={equipment={keys=1},claim=nil}
    local original=owner.equipment
    local staged={keys=0}
    local result={token=token.id}
    local participant={}
    participant.validate=function() return owner.equipment==original and owner.claim==nil,'stale' end
    participant.apply=function() owner.equipment=staged;owner.claim=result end
    participant.rollback=function()
        if owner.equipment==staged then owner.equipment=original end
        if owner.claim==result then owner.claim=nil end
    end
    return owner,participant,original,staged
end
assert(C:TreasureCapacity(treasureId))
local t=treasure('one')
for _,pattern in ipairs({'INSERT INTO lod_crypto_history','INSERT OR REPLACE INTO lod_crypto_accounts',
    'INSERT INTO lod_crypto_ledger','COMMIT'}) do
    local owner,participant,original=settlement(t)
    WalletSQLFail(pattern)
    local ok,why=C:SettleTreasureChest(treasureId,t,participant)
    assert(not ok and why=='storage')
    assert(owner.equipment==original and owner.equipment.keys==1 and owner.claim==nil)
    assert(not Store:Read(treasureId).tokens[t.id] and not Store:Receipt('mint:'..t.id))
    assert(#Store:Recent(treasureId)==0,'failed settlement left history')
end
local owner,participant=settlement(t)
local ok,receipt=C:SettleTreasureChest(treasureId,t,participant)
assert(ok and receipt.token==t.id and owner.equipment.keys==0 and owner.claim.token==t.id)
local treasury=assert(Store:Read(treasureId))
assert(treasury.tokens[t.id] and treasury.balance==0 and treasury.score==0)
assert(size(treasury.tokens)==1 and #Store:Recent(treasureId)==1)
-- Selling/removing a token does not restore its immutable entitlement.
assert(Store:Transaction('treasure-fixture-sale','test',{treasureId},function(accounts)
    accounts[treasureId].tokens[t.id]=nil;return true
end))
owner,participant=settlement(t)
local duplicate,why=C:SettleTreasureChest(treasureId,t,participant)
assert(not duplicate and why=='already' and owner.equipment.keys==1 and owner.claim==nil)
WalletSQLReconnect()
assert(Store:Receipt('mint:'..t.id).token==t.id and not Store:Read(treasureId).tokens[t.id])
-- A guard is checked again after serialization, before reference application.
local late=treasure('late')
owner,participant=settlement(late)
local validations=0
participant.validate=function() validations=validations+1;return validations==1,'stale' end
assert(not C:SettleTreasureChest(treasureId,late,participant))
assert(validations==2 and owner.equipment.keys==1 and not Store:Receipt('mint:'..late.id))
local throwing=treasure('throwing')
local original,staged
owner,participant,original,staged=settlement(throwing)
participant.apply=function() owner.equipment=staged;error('injected participant failure') end
assert(not C:SettleTreasureChest(treasureId,throwing,participant))
assert(owner.equipment==original and not Store:Read(treasureId).tokens[throwing.id])
-- Compensation must not overwrite another owner's replacement.
local replacement={keys=7}
participant.apply=function() owner.equipment=replacement;error('replacement during apply') end
assert(not C:SettleTreasureChest(treasureId,throwing,participant))
assert(owner.equipment==replacement)
assert(Store:Transaction('treasure-fill','test',{treasureId},function(accounts)
    for i=1,8 do local fill=treasure('fill-'..i);accounts[treasureId].tokens[fill.id]=fill end
    return true
end))
local capacity,reason=C:TreasureCapacity(treasureId)
assert(not capacity and reason=='full')
owner,participant=settlement(late)
local full,fullReason=C:SettleTreasureChest(treasureId,late,participant)
assert(not full and fullReason=='full' and owner.equipment.keys==1 and not Store:Receipt('mint:'..late.id))
assert(Store:Transaction('treasure-free','test',{treasureId},function(accounts)
    local tokenId=next(accounts[treasureId].tokens);accounts[treasureId].tokens[tokenId]=nil;return true
end))
assert(C:SettleTreasureChest(treasureId,late,participant) and owner.equipment.keys==0)
assert(size(Store:Read(treasureId).tokens)==8)
local wrong=treasure('wrong');wrong.run='retired-campaign'
assert(not C:SettleTreasureChest(treasureId,wrong,participant))
wrong=treasure('wrong');wrong.depth=Run.State.Level+1
assert(not C:SettleTreasureChest(treasureId,wrong,participant))
wrong=treasure('wrong');wrong.source='other-source';wrong.id=treasureId..':'..wrong.source
assert(not C:SettleTreasureChest(treasureId,wrong,participant))
assert(not C:SettleTreasureChest(treasureId,t,{}))
print('TREASURE_SQLITE_PASS: finite DFT capacity; guarded key/claim reference settlement; history/account/ledger/COMMIT rollback; stale/throwing participant; replacement preservation; retry, sale/reopen replay and score isolation')

-- Corruption remains present and visible, rather than resetting the account.
assert(sql.Query("UPDATE lod_crypto_accounts SET body='{}' WHERE account="..sql.SQLStr(a.id))~=false)
assert(not Store:Read(a.id));assert(#errors>=3)
assert(sql.Query('SELECT body FROM lod_crypto_accounts WHERE account='..sql.SQLStr(a.id))[1].body=='{}')
print('CRYPTO_SQLITE_PASS: real SQLite reopen/unique RunIDs; exact contribution allocation; role/death/healing guards; milestones/capacity/pending; frozen recreation; sale/lifetime separation; replay/rollback/corruption; statue authorization; unranked isolation')
