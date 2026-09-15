-- Production equipment transport with Source timer/net boundaries doubled.
dofile('tools/test_checkpoint_d_closure.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E=LOD.Equipment
local timers,hooks,receivers,packets={},{},{},{}
local now=100
CurTime=function() return now end
IsValid=function(p) return type(p)=='table' and p.valid==true end
ErrorNoHalt=function(message) error(message) end
hook.Add=function(_,id,fn) hooks[id]=fn end
hook.Remove=function(_,id) hooks[id]=nil end
hook.Run=function() end
timer.Simple=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end
local function flush()
    now=now+.101
    local due=timers;timers={}
    for _,task in ipairs(due) do task.fn() end
end
local Run={State={},ApplyPlayerState=function() end}
function Run:IsSoldierControl(p) return p.soldier end
function Run:GetPlayerState(p) return p.ps end
function Run:IsActivePlayer() return true end
LOD.RunManager=Run
LOD.StagingDeployment=nil
local current,reads
local clientSnapshots={}
local function wireSize(v)
    if type(v)=='table' then
        local n=2;for k,x in pairs(v) do n=n+wireSize(k)+wireSize(x) end;return n
    elseif type(v)=='string' then return #v+2
    elseif type(v)=='number' then return 9
    elseif type(v)=='boolean' then return 2 end
    return 1
end
net.Receive=function(name,fn) receivers[name]=fn end
net.Start=function(name) current={name=name} end
net.WriteTable=function(t) current.state=table.Copy(t);current.bytes=3+wireSize(t) end
net.BytesWritten=function() return current.bytes end
net.ReadTable=function() return table.Copy(current.state) end
net.Send=function(p)
    current.ply=p;current.wire=table.Copy(current.state)
    E.Snapshot=clientSnapshots[p] or {items={},slots={}}
    E.HasSnapshot=clientSnapshots[p]~=nil
    receivers.LOD_EquipmentSnapshot()
    clientSnapshots[p]=E.Snapshot
    current.state=table.Copy(E.Snapshot)
    packets[#packets+1]=current
end
net.ReadString=function() return table.remove(reads,1) end
dofile(root..'sv_snapshot_delivery.lua')
dofile(root..'sv_equipment.lua')
LOD.UI={Colors={}};LOD.Spellbook={}
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
istable=function(v) return type(v)=='table' end
dofile(root..'cl_equipment.lua')
local Delivery=LOD.SnapshotDelivery
local function player(id)
    local p={valid=true,ps={equipment={items={},slots={}}},nw={}}
    function p:IsPlayer() return true end
    function p:EntIndex() return id end
    function p:Alive() return true end
    function p:GetActiveWeapon() return nil end
    function p:HasWeapon() return self.given end
    function p:Give() self.given=true end
    function p:SetNW2String(k,v) self.nw[k]=v end
    p.SetNW2Int=p.SetNW2String
    return p
end
local p,q=player(1),player(2)
local state=p.ps.equipment
for i=1,32 do
    local item=E:Generate(i,999,'ring','capacity:'..i)
    state.items[item.id]=item
end
assert(E:AddConsumable(state,'healing_potion',3))
for _=1,100 do E:Sync(p) end
assert(#timers==1 and timers[1].delay==.1 and #packets==0)
assert(p.given and p.nw.LOD_ThrowableCount==3,'Held weapon/count apply before network flush')
assert(E:Consume(state,'healing_potion'));E:Sync(p)
assert(p.nw.LOD_ThrowableCount==2)
flush()
assert(#packets==1 and packets[1].state.items.healing_potion.count==2,'One latest inventory for burst')
assert(packets[1].bytes<60000,'Capacity inventory fits one message with headroom')
print(string.format('Equipment burst: 101 Sync calls -> 1 packet, %d estimated bytes',packets[1].bytes))
packets={}
for _=1,100 do E:Sync(p) end
flush();assert(#packets==0,'Identical inventories produce no traffic')
-- Nested counts change despite a same-valued slot key. No alias in last cache.
assert(E:Consume(state,'healing_potion'));E:Sync(p);flush()
assert(#packets==1 and packets[1].state.items.healing_potion.count==1)
assert(packets[1].wire.equipmentDelta and packets[1].bytes<1000,'Consumable delta avoids unchanged item rolls')
-- Active weapon changes send metadata only, retaining all 32 client records.
packets={};state.activeWeaponClass='weapon_357';E:Sync(p);flush()
assert(#packets==1 and packets[1].state.activeWeaponClass=='weapon_357')
assert(next(packets[1].wire.state.items)==nil and packets[1].bytes<1000)
local count=0;for _ in pairs(packets[1].state.items) do count=count+1 end
assert(count==33,'Unchanged records survive delta merge')
print(string.format('Weapon switch: %d estimated bytes; no unchanged item records resent',packets[1].bytes))
packets={};assert(E:Consume(state,'healing_potion'));E:Sync(p);flush()
assert(not packets[1].state.items.healing_potion and not packets[1].state.slots.throwable,'Removal clears record and occupancy')
local added=E:Generate(201,9,'boots','replacement');state.items[added.id]=added
assert(E:Equip(state,added.id,'feet'));E:Sync(p);flush()
assert(packets[2].state.items[added.id].name==added.name and packets[2].state.slots.feet==added.id)

packets={}
local sheet=function() return {xp=10} end
Delivery:Queue(p,'LOD_RPG_Snapshot',sheet);flush();packets={}
reads={'snapshot','',''};receivers.LOD_EquipmentRequest(80,p)
Delivery:Queue(p,'LOD_RPG_Snapshot',sheet);flush()
assert(#packets==1 and packets[1].name=='LOD_EquipmentSnapshot' and not packets[1].wire.equipmentDelta,'Explicit equipment recovery leaves sheet cache intact and sends full baseline')
packets={};E:Sync(p);p.soldier=true;flush()
assert(#packets==1 and next(packets[1].state.items)==nil,'Role transition clears old Hero inventory')
p.soldier=false;p.ps={equipment={items={},slots={}}}
E:Sync(p);p.ps.equipment.items.replacement={definitionId='healing_potion',count=1};flush()
assert(packets[#packets].state.items.replacement and not packets[#packets].state.items.healing_potion,'Dispatch resolves replacement character')
packets={};E:Sync(p);hooks.LOD_SnapshotDeliveryDisconnect(p);flush()
assert(#packets==0 and Delivery.Players[p]==nil)
E:Sync(p);flush();assert(#packets==1,'Reconnect restores unchanged state')
packets={};E:Sync(p);hooks.LOD_SnapshotDeliveryCleanup();flush();assert(#packets==0)
for _=1,100 do E:Sync(p);E:Sync(q) end
assert(#timers==2,'Pending work remains bounded by players, not requests')
flush();assert(#packets==2 and packets[1].ply~=packets[2].ply)
for _,packet in ipairs(packets) do
    assert((packet.state.items.replacement~=nil)==(packet.ply==p),'Owner-only delivery')
end
print('EQUIPMENT_DELIVERY_PASS: immediate effects; capacity/burst/dedup; nested mutation; resync; current role/record; disconnect/cleanup/owner isolation')

-- A client without the initial baseline requests a full snapshot, not a partial inventory.
local requested=0
E.HasSnapshot=false
E.Request=function(_,action) assert(action=='snapshot');requested=requested+1 end
current.state={equipmentDelta=true,state={items={},slots={}},removed={}}
receivers.LOD_EquipmentSnapshot();assert(requested==1)
print('EQUIPMENT_DELTA_PASS: production server writer and client receiver; unchanged record retention; change/add/remove/role reset/full recovery')

-- A delayed body-map drag cannot unequip a newly replaced item in that slot.
assert(E:AddConsumable(p.ps.equipment,'stink_bomb',1))
assert(E:Equip(p.ps.equipment,'stink_bomb','throwable'))
now=now+1;reads={'unequip','healing_potion','throwable'}
receivers.LOD_EquipmentRequest(160,p)
assert(p.ps.equipment.slots.throwable=='stink_bomb')
now=now+1;reads={'unequip','stink_bomb','throwable'}
receivers.LOD_EquipmentRequest(160,p)
assert(not p.ps.equipment.slots.throwable and p.ps.equipment.items.stink_bomb)
print('EQUIPMENT_STALE_DROP_PASS: server checks expected item before unequipping')
