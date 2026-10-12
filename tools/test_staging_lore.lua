-- Production talk/service authorities with Source transport and geometry doubles.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local function noop() end
function IsValid(e) return type(e)=='table' and e.valid~=false end
local V={};V.__index=V
function V:DistToSqr(b) return (self.x-b.x)^2+(self.y-b.y)^2+(self.z-b.z)^2 end
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
local now=0
function CurTime() return now end
function ErrorNoHalt(s) error(s) end
util={AddNetworkString=noop,TraceLine=function() return {Hit=false} end}
hook={Add=noop};concommand={Add=noop};timer={Simple=noop};player={GetAll=function() return {} end}
local packets,packet={},nil
net={Start=function(name) packet={name=name,values={}} end,
 WriteUInt=function(n,bits)
  assert((packet.name=='LOD_DamselDialogue' and bits==5 and n>=0 and n<=31)
   or (packet.name=='LOD_DamselState' and (bits==31 or bits==32)))
  packet.values[#packet.values+1]=n
 end,
 WriteString=function(s) assert(type(s)=='string' and #s<64000);packet.values[#packet.values+1]=s end,
 Send=function(p) packet.player=p;packets[#packets+1]=packet end}
local S={EnsureHut=function() return true end,IsPlayerInHut=function() return true end}
local R={State={Level=1,CampaignEpoch=42,BuildReady=true,RescuedDamsels={},DamselClaims={}},
 IsSlotActivePlayer=function() return true end,IsSoldierControl=function() return false end}
local states={};R.GetPlayerState=function(_,p) return states[p] end
function S:DeborahSucceeded() return R.State.RescuedDamsels[20]==true end
LOD={StagingDeployment=S,RunManager=R,Equipment={},CryptoDirector={},CryptoStore={}}
dofile(root..'sh_damsels.lua');dofile(root..'sv_damsels.lua');dofile(root..'sv_staging_lore.lua')
local D=LOD.Damsels
local rewards={'ammo','ammo','ammo','ammo','ammo','heal','cure','magic','equipment','equipment',
 'equipment','equipment','equipment','equipment','equipment','consumable','full_heal','deb','life','abundance'}
local parameters={'weapon_pistol','weapon_smg1','weapon_shotgun','weapon_357','weapon_ar2',25,0,25,
 'gloves','ring','boots','headwear','vest','trousers','shield','healing_potion',0,false,1,1}
for i,def in ipairs(D.Definitions) do
 assert(def.reward==rewards[i],'lore changed service '..def.name)
 if i==18 then assert(def.parameter.min==25 and def.parameter.max==75) else assert(def.parameter==parameters[i]) end
 assert(#def.dialogue==(i==20 and 2 or 3) and type(def.dialogue[1])=='string')
 assert(def.frequency==((i<=8 or i==16) and 'visit' or 'campaign'),'lore changed claim cadence')
end
local function hero()
 return {IsPlayer=function() return true end,Alive=function() return true end,
  GetPos=function() return Vector(0,0,0) end,EyePos=function() return Vector(0,0,64) end}
end
local p,q=hero(),hero();states[p]={identity='p'};states[q]={identity='q'}
net.WriteDouble=function(v) packet.values[#packet.values+1]=v end
net.WriteBool=function(v) packet.values[#packet.values+1]=v end
D:Sync(p);assert(packets[#packets].values[25]==42,'campaign epoch missing from state tail')
local guide={LODCampaignState=R.State,LODCampaignEpoch=42,
 GetPos=function() return Vector(72,0,0) end,WorldSpaceCenter=function() return Vector(72,0,36) end}
S.GuideEntity=guide
local function talk(who) now=now+1;return S:TalkGuide(who or p,guide) end
local seen={}
for level=1,20 do
 R.State.Level=level
 local before=#packets;assert(talk());assert(#packets==before+1)
 local pkt=packets[#packets];assert(pkt.name=='LOD_DamselDialogue' and pkt.player==p and pkt.values[1]==31)
 assert(pkt.values[2]==S.LoreChapters[level].text and not pkt.values[2]:find('Hector',1,true))
 assert(pkt.values[3]:find('DUNGEON '..level..' — ',1,true)==1)
 assert(not seen[pkt.values[2]]);seen[pkt.values[2]]=true
 assert(R.State.Level==level and next(R.State.RescuedDamsels)==nil and next(R.State.DamselClaims)==nil)
 assert(not S:TalkGuide(p,guide),'same-tick duplicate accepted')
 assert(S:TalkGuide(q,guide),'other player shared a talk cursor/cooldown')
 assert(talk() and packets[#packets].values[2]==S.LoreChapters[level].text,'repeat talk advanced story')
end
R.State.HectorRevealed=true;assert(talk())
assert(packets[#packets].values[1]==30 and packets[#packets].values[2]==S.RevealedLore)
R.State.RescuedDamsels[20]=true;assert(not talk(),'retired Hermit talked after succession')
R.State.RescuedDamsels[20]=nil;R.State.HectorRevealed=nil
for _,field in ipairs({'Failed','LevelCleared','SimulationFrozen'}) do
 R.State[field]=true;assert(not talk(),field);R.State[field]=nil
end
R.State.BuildReady=false;assert(not talk());R.State.BuildReady=true
for _,field in ipairs({'eliminated','deploymentComplete'}) do states[p][field]=true;assert(not talk());states[p][field]=nil end
local active,soldier=R.IsSlotActivePlayer,R.IsSoldierControl
R.IsSlotActivePlayer=function() return false end;assert(not talk());R.IsSlotActivePlayer=active
R.IsSoldierControl=function() return true end;assert(not talk());R.IsSoldierControl=soldier
local hut=S.IsPlayerInHut;S.IsPlayerInHut=function() return false end;assert(not talk());S.IsPlayerInHut=hut
util.TraceLine=function() return {Hit=true} end;assert(not talk());util.TraceLine=function() return {Hit=false} end
local pos=guide.GetPos;guide.GetPos=function() return Vector(113,0,0) end;assert(not talk())
guide.GetPos=function() return Vector(112,0,0) end;assert(talk());guide.GetPos=pos
guide.LODCampaignEpoch=41;assert(not talk());guide.LODCampaignEpoch=42
guide.LODCampaignState={};assert(not talk());guide.LODCampaignState=R.State
S.GuideEntity={};assert(not talk());S.GuideEntity=guide
local alive=p.Alive;p.Alive=function() return false end;assert(not talk());p.Alive=alive
guide.valid=false;assert(not talk());guide.valid=nil
R.State.Level=21;assert(not talk(),'unrescued guide fabricated endless lore');R.State.Level=2
-- Exercise native ENT:Use, rather than only the direct authority.
ENT={KIND_GUIDE=1};include=noop;AddCSLuaFile=noop
dofile('gamemodes/legend_of_deborah/entities/entities/lod_staging_prop/init.lua')
guide.KIND_GUIDE=1;guide.GetStageKind=function() return 1 end;now=now+1;ENT.Use(guide,p)
assert(packets[#packets].values[2]==S.LoreChapters[2].text)
-- Conversation when a campaign gift is already claimed never repeats its grant.
local grant=0;D.Grant=function() grant=grant+1;return true,'actual service receipt' end
D.CanUse=function() return true end
local ent={LODDamselLevel=9}
now=now+1;assert(D:Use(p,ent) and grant==1)
now=now+1;assert(not D:Use(p,ent) and grant==1)
assert(packets[#packets].values[2]==D.Definitions[9].dialogue[(2+9)%3+1])
assert(packets[#packets].values[3]=='My gift for this campaign is already yours.')
-- Deborah explains Cash even if daily Abundance is unavailable; no pedestal grant.
local calls=0;LOD.CryptoDirector.ClaimAbundance=function() calls=calls+1;return false,'already claimed today' end
ent.LODDamselLevel=20;R.State.Level=21
now=now+1;assert(not D:Use(p,ent) and calls==1 and grant==1)
assert(packets[#packets].values[1]==20 and packets[#packets].values[3]=='already claimed today')
assert(packets[#packets].values[2]:find('cash',1,true))
print('STAGING_LORE_PASS: 20 distinct chapters; native Use; independent/replay talks; reveal/succession; 19 admission boundaries; unchanged20 service parameters/cadences; claimed-gift and unavailable-Abundance dialogue')
