-- Real staging/roster/settlement seams; only Source entity/transport boundaries
-- are doubled. Existing crypto suite retains durable Abundance transaction tests.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
function CreateConVar() return {} end
GM={};function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0,
 Forward=function() return Vector(1,0,0) end,Right=function() return Vector(0,1,0) end} end
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local notices={};function ErrorNoHalt(s) notices[#notices+1]=s end
local now=20;function CurTime() return now end
player={GetAll=function() return {} end}
net.WriteBool=noop;net.WriteUInt=noop;net.WriteString=noop;net.Send=noop
LOD.LootDirector={};LOD.CryptoDirector={};LOD.CryptoStore={};LOD.Equipment={}
dofile(root..'sv_run_manager.lua')
local R=LOD.RunManager
R.NewCampaign=function(self)
 self.State={Level=1,CampaignEpoch=2,CampaignSeed=55,RunId='fresh',BuildReady=true,RescuedDamsels={},PlayerState={}}
 return true
end
R.BuildCurrentLevel=function() return true end
LOD.Hector={RescueAllowed=function(_,s) return s.acceptedHector==true end}
LOD.ProgressionDirector={CanRescueTarget=function() return true end,Announce=noop,SyncAll=noop}
dofile(root..'sh_damsels.lua')
dofile(root..'sv_staging_deployment.lua')
local S,D=LOD.StagingDeployment,LOD.Damsels
local born,removed,actors=0,0,{}
local failCreate,failSpawn=false,false
local duringActivate
ents.Create=function(class)
 if failCreate then return nil end
 born=born+1
 local e={class=class,nw={}}
 function e:SetPos(p) self.pos=p end;function e:GetPos() return self.pos end
 function e:WorldSpaceCenter() return self.pos+Vector(0,0,36) end
 function e:SetAngles(a) self.ang=a end
 function e:SetStageKind(k) self.kind=k end;function e:SetStageLabel(v) self.label=v end
 function e:Spawn() if failSpawn then error('native spawn unavailable') end end
 function e:Activate() if duringActivate then duringActivate(self) end end
 function e:Remove() assert(self.valid~=false,'double remove');self.valid=false;removed=removed+1 end
 actors[#actors+1]=e;return e
end
local function room()
 S.HutCenter=Vector();S.HutAngles=Angle();S.HutHalfForward=448;S.HutHalfRight=288
 S.HutGuideDistance=82;S.HutAnchorSource='native-enclosed-room'
 S.PortalEntity={};S.EnsureRoomDecor=noop
end
R.State={Level=20,CampaignEpoch=1,CampaignSeed=55,RunId='campaign',Graph={},BuildReady=true,
 RescuedDamsels={},PlayerState={},ActiveIdentity={}}
room()
dofile(root..'sv_damsels.lua')
S.IsPlayerInHut=function() return true end
R.IsActivePlayer=function() return true end;R.IsSlotActivePlayer=function() return true end
R.IsSoldierControl=function() return false end
local hero={IsPlayer=function() return true end,Alive=function() return true end,Nick=function() return 'Hero' end,
 GetPos=function() return Vector(82,0,0) end,EyePos=function() return Vector(82,0,50) end}
local ps={identity='hero',lives=3,deploymentComplete=false}
R.GetPlayerState=function() return ps end
util.TraceLine=function() return {Hit=false} end
util.TraceHull=function() return {Hit=false} end
assert(S:EnsureHut() and born==1)
local hermit=S.GuideEntity
assert(hermit.class=='lod_staging_prop' and hermit.label=='DUNGEON HERMIT' and not D.Entities[20])
assert(not R:CompleteLevel(hero) and S.GuideEntity==hermit and not R.State.RescuedDamsels[20],
 'pre-defeat rescue must not reveal or replace Hermit')
R.State.HectorRevealed=true
assert(S:EnsureGuide() and S.GuideEntity==hermit and hermit.label=='HECTOR THE DIRECTOR')
assert(not S:DeborahSucceeded() and not D.Entities[20],'revelation alone does not imply rescue')
R.State.acceptedHector=true
assert(R:CompleteLevel(hero) and R.State.LevelCleared and R.State.Abundance)
local deborah=S.GuideEntity
assert(not IsValid(hermit) and IsValid(deborah) and D.Entities[20]==deborah)
assert(deborah.class=='lod_rescued_damsel' and deborah.LODDamselLevel==20 and deborah.LODCampaignEpoch==1)
assert(deborah:GetPos():DistToSqr(Vector(82,0,0))==0 and #S.HutEntities==1,
 'sole Deborah takes exact former guide anchor')
assert(not R:CompleteLevel(hero) and born==2,'duplicate rescue does not duplicate actor or settlement')
assert(S:EnsureHut() and born==2 and D.Entities[20]==deborah,'roster cannot spawn second Deborah')
-- Canonical flags, rather than a second succession state or the current level,
-- survive regeneration, endless progression, late join and ordinary rebuilds.
R.State.Level=21;R.State.LevelCleared=false;R.State.Graph={}
assert(S:EnsureHut() and D.Entities[20]==deborah and S:GuideName()=='DEBORAH')
assert(D:CanUse(hero,deborah))
local V=getmetatable(Vector());function V:Dot(v) return self.x*v.x+self.y*v.y+self.z*v.z end
hero.GetAimVector=function() return Vector(0,0,-1) end
hero.GetEyeTrace=function() return {Entity=deborah,HitPos=deborah:WorldSpaceCenter()} end
IN_USE=32
local use=D.Use;local talks=0;D.Use=function(_,p,e) assert(p==hero and e==deborah);talks=talks+1 end
env.hooks.LOD_DamselUse(hero,IN_USE);assert(talks==1,'guide membership must not suppress aimed E')
D.Use=use
ps.deploymentComplete=true;assert(not D:CanUse(hero,deborah));ps.deploymentComplete=false
hero.Alive=function() return false end;assert(not D:CanUse(hero,deborah));hero.Alive=function() return true end
assert(D:CanUse(hero,deborah),'revived/reconnected Hero uses same authority')
local impostor={LODDamselLevel=20,LODCampaignEpoch=1}
assert(not D:CanUse(hero,impostor),'unregistered Deborah cannot claim Abundance')
-- Reuse the real Abundance gate; transaction doubles capture the one existing
-- authoritative delegation without adding a service or claim surface.
local claims=0
local C,Store=LOD.CryptoDirector,LOD.CryptoStore
C.Account=function() return 'account' end;C.Ranked=function() return true end
C.PromotePending=noop;C.GenerateToken=function() return {id='token'} end;C.Sync=noop
Store.History=noop
local account={tokens={}}
Store.Transaction=function(_,_,kind,ids,fn) assert(kind=='abundance' and ids[1]=='account');claims=claims+1;return fn({account=account}) end
assert(C:ClaimAbundance(hero) and claims==1 and account.tokens.token)
assert(not C:ClaimAbundance(hero) and claims==2,'canonical cooldown rejects repeated claims')
-- Disappearance and partial creation never leave an obsolete Hermit or block
-- functional portal access. Retry is bounded and repairs the sole roster alias.
deborah:Remove();failCreate=true
assert(S:EnsureHut() and not IsValid(S.GuideEntity) and born==2)
assert(S:EnsureHut() and born==2,'same-frame guide retry is bounded')
failCreate=false;failSpawn=true;now=now+1
assert(S:EnsureHut() and born==3 and not IsValid(actors[3]),'partially spawned guide is cleaned')
failSpawn=false;now=now+1
assert(S:EnsureHut() and born==4 and IsValid(S.GuideEntity) and D.Entities[20]==S.GuideEntity)
local rebuilt=S.GuideEntity
S:_ClearHutPresentation();assert(not IsValid(rebuilt));room()
assert(S:EnsureHut() and born==5 and D.Entities[20]==S.GuideEntity)
assert(R.State.RescuedDamsels[20] and R.State.Abundance,'presentation failure never rolls back reward/eligibility')
-- A native activation callback can reset the campaign. The rejected actor
-- must never be published into either state's roster, even at identical epochs.
S.GuideEntity:Remove()
local oldState=R.State
local replacement={};for key,value in pairs(oldState) do replacement[key]=value end
replacement.Graph={}
local rejected
duringActivate=function(e) if not rejected then rejected=e;R.State=replacement end end
assert(S:EnsureHut() and not IsValid(rejected),'reentrant native reset cleans partial actor')
duringActivate=nil;now=now+1
assert(S:EnsureHut() and D.Entities[20].LODCampaignState==replacement)
assert(R.State.CampaignEpoch==oldState.CampaignEpoch,'test exercises exact state beyond epoch')
-- Epoch isolation even when campaign and dungeon seeds are reused.
local stale=S.GuideEntity;R.State.CampaignEpoch=9
assert(not D:CanUse(hero,stale))
assert(S:EnsureHut() and not IsValid(stale) and D.Entities[20].LODCampaignEpoch==9)
assert(R:NewCampaign());room()
assert(S:EnsureHut() and S:GuideName()=='DUNGEON HERMIT' and S.GuideEntity.class=='lod_staging_prop')
assert(not R.State.HectorRevealed and not D.Entities[20] and not S:DeborahSucceeded())
local before=born;R.State.RescuedDamsels[1]=true;failSpawn=true
assert(S:EnsureHut() and born==before+1 and not IsValid(actors[#actors]),'failed supporting damsel cannot block staging')
assert(S:EnsureHut() and born==before+1,'supporting actor retry is bounded')
failSpawn=false;now=now+1
assert(S:EnsureHut() and IsValid(D.Entities[1]) and born==before+2,'supporting roster repairs through ordinary rebuild')
-- Production next-tick placement owns its exact built graph/campaign, not just
-- a reused seed. Neither a reset nor an in-place same-seed rebuild can replay it.
local callbacks={};timer.Simple=function(_,fn) callbacks[#callbacks+1]=fn end
local placements=0;local place=S.PlacePlayerInHut
S.PlacePlayerInHut=function() placements=placements+1;return true end
player.GetAll=function() return {hero} end
assert(R:BuildCurrentLevel());assert(#callbacks==1)
R.State.Graph={};callbacks[1]();assert(placements==0,'stale same-seed graph callback moved Hero')
assert(R:BuildCurrentLevel());assert(#callbacks==2)
local replaced={};for key,value in pairs(R.State) do replaced[key]=value end
R.State=replaced;callbacks[2]();assert(placements==0,'foreign same-epoch campaign callback moved Hero')
assert(R:BuildCurrentLevel());callbacks[3]();assert(placements==1,'current callback still stages Hero')
S.PlacePlayerInHut=place
print('DEBORAH_SUCCESSION_PASS: accepted settlement, exact sole actor/anchor, revelation secrecy, replay, endless/rebuild/reconnect/death, Abundance authority, partial failure/retry and fresh-campaign reversal')
