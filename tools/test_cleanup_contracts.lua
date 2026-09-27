-- Actual campaign, party and loot authorities with existing native boundaries.
local f=dofile('tools/test_spot15_soldier_queue.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local R,L=f.Run,LOD.LootDirector
local checks,failures=0,{}
local function check(ok,msg)
 checks=checks+1
 if not ok then failures[#failures+1]=msg;print('CLEANUP_FAIL '..msg) end
end
-- Pre-build counts follow admission, including dead Heroes with remaining lives,
-- but never the explicit spectator choice retained across a successful clear.
dofile(root..'sv_multiplayer_contracts.lua')
f.reset()
local hero=f.actor('hero');local spectator=f.actor('spectator')
spectator.ps.queue='spectator';R.State.ActiveIdentity[spectator.id]=nil
check(R:_ConnectedPartyCountForBuild()==1,'positive-life spectator excluded from build budget')
local dead=f.actor('dead');dead.hp=0;dead.ps.lives=2
check(R:_ConnectedPartyCountForBuild()==2,'waiting dead Hero with lives retained in build budget')
local eliminated=f.actor('eliminated');eliminated.ps.eliminated=true;eliminated.ps.lives=0
check(R:_ConnectedPartyCountForBuild()==2,'eliminated Hero excluded')
local newcomer=f.actor('newcomer');R.State.PlayerState[newcomer.id]=nil
check(R:_ConnectedPartyCountForBuild()==3,'unadmitted connected newcomer included')
for i=1,5 do f.actor('extra'..i) end
check(R:_ConnectedPartyCountForBuild()==4,'four-slot build cap retained')
f.reset();local only=f.actor('spectator-only');only.ps.queue='spectator'
check(R:_ConnectedPartyCountForBuild()==1,'empty-party minimum retained')
-- Observe actual NewCampaign metadata, leaving layout construction at its native
-- boundary. Deterministic entropy inputs do not replace campaign classification.
f.reset()
local build=R.BuildCurrentLevel
R.BuildCurrentLevel=function() return true end
R._DefaultSeed=function() return 73 end;R._DefaultRosterSeed=function() return 91 end
local dev=GetConVar('lod_developer_mode') or CreateConVar('lod_developer_mode',0)
local campaign,roster=GetConVar('lod_campaign_seed'),GetConVar('lod_roster_seed')
for _,case in ipairs({{0,0,true,nil},{41,0,false,'custom campaign seed'},
 {0,42,false,'custom roster seed'},{41,42,false,'custom campaign seed'}}) do
 campaign.value,roster.value,dev.value=case[1],case[2],1
 check(R:NewCampaign(),'campaign still builds')
 check(R.State.Ranked==case[3] and R.State.UnrankedReason==case[4],
  'campaign classification '..case[1]..'/'..case[2])
end
campaign.value,roster.value,dev.value=0,0,0;R.BuildCurrentLevel=build
-- Exercise SpawnPickup + prune; entity methods and transmission are native-only
-- boundaries, not replacement expiry/ownership/cap logic.
f.reset();hero=f.actor('loot-owner')
local oldCreate,oldReward,oldTransmit=ents.Create,LOD.Equipment.PrepareReward,L._ApplyTransmission
ents.Create=function()
 local ent={valid=true,nw={}}
 function ent:EntIndex() return 123 end
 function ent:SetPos(v) self.pos=v end
 function ent:SetAngles(v) self.angles=v end
 function ent:Spawn() self.spawned=true end
 function ent:SetNW2String(k,v) self.nw[k]=v end
 function ent:Remove() self.valid=false end
 return ent
end
LOD.Equipment.PrepareReward=function(_,owner,kind,payload) return kind,payload end
L._ApplyTransmission=function() end;L.Entities={}
local static=L:SpawnPickup(hero.id,Vector(),'health',{}, {staticId='sealed-static'})
local transient=L:SpawnPickup(hero.id,Vector(),'health',{}, {})
check(IsValid(static) and static.LODLootExpiresAt==nil,'static pickup has no transient expiry')
check(IsValid(transient) and transient.LODLootExpiresAt>CurTime(),'enemy drop retains expiry')
local deadline=transient.LODLootExpiresAt
f.now(deadline+.001);L:_PruneEntities()
check(IsValid(static) and not IsValid(transient),'prune retains static while expiring enemy drop')
check(static.LODLootOwnerIdentity==hero.id and static.LODLootStaticId=='sealed-static','static owner/identity preserved')
R.State.LevelSeed=R.State.LevelSeed+1;L:_PruneEntities()
check(not IsValid(static) and #L.Entities==0,'static pickup still retired on level change')
ents.Create,LOD.Equipment.PrepareReward,L._ApplyTransmission=oldCreate,oldReward,oldTransmit
check(#failures==0,'all cleanup contracts')
assert(#failures==0,table.concat(failures,'; '))
print('CLEANUP_CONTRACTS_PASS '..checks..' production assertions')
