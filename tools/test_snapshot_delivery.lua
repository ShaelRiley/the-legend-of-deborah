-- Exercise real progression/snapshot producers; fake only Source boundaries.
dofile('tools/test_checkpoint_d_closure.lua')
local base = 'gamemodes/legend_of_deborah/gamemode/lod/'
local CPS = LOD.CharacterProgressionSystem
local ticks, packets, hooks = {}, {}, {}
local now = 100
CurTime = function() return now end
hook.Add = function(event, id, fn) hooks[id] = fn end
hook.Run = function() end
timer.Simple = function(delay, fn) ticks[#ticks + 1] = {at=now+delay, fn=fn} end
IsValid = function(p) return type(p)=='table' and p.valid==true end
ErrorNoHalt = function(message) error(message) end
dofile(base .. 'sv_snapshot_delivery.lua')
local function flush()
    now=now+0.101
    local due=ticks; ticks={}
    for _,task in ipairs(due) do
        if task.at<=now then task.fn() else ticks[#ticks+1]=task end
    end
end
local p = {valid=true, IsPlayer=function() return true end,
    Nick=function() return 'Tester' end, Health=function() return 92 end, EntIndex=function() return 1 end,
    SetMaxHealth=function() end, SetHealth=function() end,
    SetNW2Int=function(self,key,value) self[key]=value end,
    SetNW2Float=function() end, SetNW2Bool=function() end, SetModelScale=function() end, SetHull=function() end, SetHullDuck=function() end,
    GetNW2Int=function(_,_,v) return v or 0 end, GetNW2Bool=function(_,_,v) return v or false end,
    GetVelocity=function() return {Length2D=function() return 0 end} end,
    GetWalkSpeed=function() return 200 end, GetRunSpeed=function() return 400 end,
    GetActiveWeapon=function() return nil end, ChatPrint=function() end}
local ps = {identity='test',ordinal=1,model='models/player/Group01/male_07.mdl',
    characterName='Test Hero',lives=2,starterWeaponClass='weapon_pistol',deploymentComplete=true}
LOD.RunManager = {State={CampaignSeed=777,RosterSeed=777,LevelSeed=777,Level=1,PlayerState={test=ps}},
    GetPlayerState=function(_,who) if who==p or who=='test' then return ps end end,
    IsSoldierControl=function() return false end, IdentityOf=function() return 'test' end}
player.GetAll=function() return {p} end
local current, bytes
-- Source net.WriteTable uses a type byte per key/value, doubles for numbers,
-- NUL-terminated strings and a nil terminator per table. Conservative bit rounding.
local function wireSize(v)
    if type(v)=='table' then
        local n=2
        for k,item in pairs(v) do n=n+wireSize(k)+wireSize(item) end
        return n
    elseif type(v)=='string' then return #v+2
    elseif type(v)=='number' then return 9
    elseif type(v)=='boolean' then return 2 end
    return 1
end
net.Start=function(name) current={name=name}; bytes=3 end
net.WriteTable=function(t) current.snapshot=table.Copy(t);bytes=bytes+wireSize(t) end
net.BytesWritten=function() return bytes end
net.Send=function(who) current.player=who;current.bytes=bytes;packets[#packets+1]=current end

local state = CPS:InitializeHero(LOD.RunManager,ps,{id='test',name='Test Hero',model=ps.model,presentationSex='male'})
assert(CPS:CommitClass(p,'rogue'))
local draft=CPS:_NextPendingOrdinaryDraft(state)
assert(CPS:CommitFeat(p,draft.offerFeatIds[1],1))
assert(CPS:SetHeroXP(p,877))
local draft3=CPS:_NextPendingOrdinaryDraft(state)
if draft3 then assert(CPS:CommitFeat(p,draft3.offerFeatIds[1],3)) end
flush()
packets={}
-- The final logged Blast: five kills, contribution and killing-blow pools.
for _,amount in ipairs({12,8,12,8,21,14,15,10,27,18}) do assert(CPS:AwardHeroXP(p,amount)) end
assert(state.xp==1022,'XP awards remain immediate and exact')
assert(#packets==0,'no snapshots inside the multi-kill transaction')
flush()
assert(#packets==1 and packets[1].name=='LOD_RPG_Snapshot','one final sheet; unchanged book suppressed')
assert(packets[1].snapshot.xp==1022,'latest XP must reach the client')
for _,feat in ipairs(packets[1].snapshot.ownedFeats) do assert(feat.effect:match('%S')) end
local total=0;for _,packet in ipairs(packets) do total=total+packet.bytes end
print(string.format('Blast snapshot burst: %d packets, %d estimated bytes',#packets,total))
assert(total<16384,'bounded post-Blast state burst')
assert(p.LOD_RPGBreadcrumbCells==LOD.RPGAbilityRules:BreadcrumbCells(p),
    'derived sync wrapper must forward self and player to its base')
packets={}
for _=1,100 do CPS:SyncPlayer(p) end
flush();assert(#packets==0,'identical repeated state must not produce traffic')
LOD.SnapshotDelivery:Invalidate(p); CPS:SyncPlayer(p);flush()
assert(#packets==2,'explicit resync recovers both unchanged snapshots')
packets={}
LOD.RunManager.State.Level=2
assert(CPS:SetHeroXP(p,3000))
assert(state.level==5 and #state.magicFormIds==2,'level-five grants are immediate')
flush()
assert(#packets==2,'level-up sends final sheet and changed book once each')
local book
for _,packet in ipairs(packets) do
    if packet.name=='LOD_MagicSpellbookSnapshot' then book=packet.snapshot end
    assert(packet.bytes<32768,'full authored snapshots fit with transport headroom')
end
assert(book and #book.magicFormIds==2,'newly granted Form is present in final snapshot')

-- Queued reads see the current actor, and caches never alias mutable profiles.
local Delivery=LOD.SnapshotDelivery
local shared={role='hero',abilities={str=13}}
local function build() return shared end
packets={};Delivery:Queue(p,'LOD_RPG_Snapshot',build)
shared.role='soldier';shared.abilities.str=17;flush()
assert(packets[1].snapshot.role=='soldier','retired Hero snapshot must not arrive after transition')
shared.abilities.str=18;Delivery:Queue(p,'LOD_RPG_Snapshot',build);flush()
assert(#packets==2 and packets[2].snapshot.abilities.str==18,'nested mutation must invalidate cache')
packets={};Delivery:Queue(p,'LOD_RPG_Snapshot',build)
hooks.LOD_SnapshotDeliveryDisconnect(p);flush()
assert(#packets==0 and Delivery.Players[p]==nil,'disconnected work is cancelled')
Delivery:Queue(p,'LOD_RPG_Snapshot',build);flush()
assert(#packets==1,'reconnection receives same-valued state')
packets={};Delivery:Queue(p,'LOD_RPG_Snapshot',build)
hooks.LOD_SnapshotDeliveryCleanup();flush();assert(#packets==0,'cleanup cancels old work')
Delivery:Queue(p,'LOD_RPG_Snapshot',build);flush();assert(#packets==1,'new level receives state')

local p2=table.Copy(p);packets={}
for _=1,100 do
    Delivery:Queue(p,'LOD_RPG_Snapshot',function() return {xp=1} end)
    Delivery:Queue(p2,'LOD_RPG_Snapshot',function() return {xp=2} end)
end
assert(#ticks==2,'one scheduled callback per connected player')
flush();assert(#packets==2 and packets[1].player~=packets[2].player,'multiplayer recipient isolation')
local seen={};for _,packet in ipairs(packets) do seen[packet.player]=packet.snapshot.xp end
assert(seen[p]==1 and seen[p2]==2,'no cross-player state leakage')
assert(next(Delivery.Players[p].pending)==nil and not Delivery.Players[p].scheduled,'idle has no recurring work')
print('[SNAPSHOT_DELIVERY] PASS: production XP burst, latest-state delivery, dedup, resync, lifecycle and multiplayer isolation')


-- First-time class selection must deliver the feat draft through the actual
-- deferred producer, not only generate it successfully on the server.
function p:GetMaxHealth() return 100 end
for _,classId in ipairs({'fighter','rogue','wizard'}) do
    Delivery:Invalidate(p);packets={}
    ps.progressionState=nil;ps.deploymentComplete=false
    LOD.RunManager.State.Level=1
    local fresh=CPS:InitializeHero(LOD.RunManager,ps,{id='test',name='Test Hero',model=ps.model,presentationSex='male'})
    assert(not CPS:IsDeploymentEligible(ps))
    assert(CPS:CommitClass(p,classId));flush()
    local sheet
    for _,packet in ipairs(packets) do if packet.name=='LOD_RPG_Snapshot' then sheet=packet.snapshot end end
    assert(sheet and sheet.classId==classId and sheet.classPassive:match('%S'))
    if classId=='fighter' then assert(sheet.classPassive:find('33% cap',1,true)) end
    assert(sheet.featDraft and #sheet.featDraft.offers==3 and sheet.pendingFeatCount==1)
    local trio={};for i,offer in ipairs(sheet.featDraft.offers) do
        assert(offer.effect:match('%S'));trio[i]=offer.featId
    end
    assert(trio[1]~=trio[2] and trio[2]~=trio[3] and trio[1]~=trio[3])
    assert(not CPS:IsDeploymentEligible(ps),'Class alone must not bypass the feat requirement')
    -- Reopening/reconnecting after a failed delivery must retain the same trio.
    Delivery:Invalidate(p);CPS:SyncPlayer(p);flush()
    local replay=CPS:BuildClientSnapshot(p)
    for i,id in ipairs(trio) do assert(replay.featDraft.offers[i].featId==id) end
    assert(CPS:CommitFeat(p,trio[1],1));flush()
    assert(CPS:IsDeploymentEligible(ps),'Committed class + feat must unlock the portal prerequisite')
    local completed=CPS:BuildClientSnapshot(p)
    assert(completed.pendingFeatCount==0 and completed.ordinaryFeatsCommitted==1)
end
print('CLASS_DRAFT_DELIVERY_PASS: Fighter/Rogue/Wizard commit -> three delivered offers -> stable refresh -> feat commit -> deployment eligible')
