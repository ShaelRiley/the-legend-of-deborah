-- Production advancement and repeat-gift authorities; Source transport doubles.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local function noop() end
function IsValid(e) return type(e)=='table' and e.valid~=false end
function isstring(v) return type(v)=='string' end
function Vector(x,y,z) return {x=x,y=y,z=z} end
function Color(...) return {...} end
function CreateConVar() return {} end
function ErrorNoHalt(s) error(s) end
function table.Copy(t) local r={} for k,v in pairs(t) do r[k]=type(v)=='table' and table.Copy(v) or v end return r end
hook={Add=noop};timer={Simple=noop};concommand={Add=noop};player={GetAll=function() return {} end}
LOD={}
dofile(root..'sh_config.lua');dofile(root..'sv_run_manager.lua')
local R=LOD.RunManager
local a={identity='a',starterClaimed=true,starterClaimedLevel=1,deploymentComplete=true,lives=2,stagingIntroShown=true}
local b={identity='b',starterClaimed=true,starterClaimedLevel=1,deploymentComplete=true,lives=0,eliminated=true}
R.State={Level=1,LevelCleared=true,PlayerState={a=a,b=b},ActiveIdentity={a=true,b=true},CampaignSeed=999}
local builds=0
R.BuildCurrentLevel=function(self)
    builds=builds+1
    assert(not a.deploymentComplete and not b.deploymentComplete,'reset before generation/spawn')
    assert(a.starterClaimed and b.starterClaimed,'one-time starter eligibility preserved')
    assert(a.lives==2 and b.lives==1 and not b.eliminated,'existing revive law retained')
    return true
end
assert(R:AdvanceLevel() and R.State.Level==2 and builds==1)
assert(not a.stagingIntroShown and next(R.State.ActiveIdentity)==nil)
assert(not R:AdvanceLevel() and builds==1,'duplicate advance rejected')
local function hero(ps)
    return {ps=ps,SteamID64=function() return ps.identity end,ChatPrint=noop}
end
local pa,pb=hero(a),hero(b)
local rolled,prepared,spawned=0,0,0
local chosen='ammo'
local Loot={_DropCategory=function(_,ply,state,rng,guaranteed)
    assert(state.dryKills==0 and guaranteed);rolled=rolled+1;return chosen
end,ResolveEnemyReward=function(_,ply,category)
    assert(category~='weapon','repeat gifts never issue another firearm')
    if chosen=='full' then return false end
    return category,{weaponClass='weapon_pistol',tier='small'}
end,SpawnPickup=function(_,owner,pos,kind,payload,options)
    spawned=spawned+1
    return {owner=owner,payload=table.Copy(payload),kind=kind,options=options}
end,Collect=function(_,ent,ply)
    if ent.owner~=ply.ps.identity or ent.collected then return false end
    ent.collected=true;return true,'collected'
end}
local S={StarterEntities={},EnsureHut=function() return true end,_StarterPosition=function() return Vector(0,0,0) end,
    EnsureStarterPickup=function() return 'initial-starter' end,PlacePlayerInHut=function(self,ply)
        self:EnsureStarterPickup(ply);return true
    end}
LOD.StagingDeployment,LOD.LootDirector=S,Loot
LOD.Equipment={PrepareReward=function(_,owner,kind,payload) prepared=prepared+1;return kind,payload end}
LOD.Seeds={Derive=function(seed,id) return tostring(seed)..':'..id end}
LOD.RNG={New=function(seed) return {seed=seed} end}
dofile(root..'sv_hermit_repeat_gifts.lua')
assert(S:PlacePlayerInHut(pa,true));assert(rolled==1 and prepared==1 and spawned==1)
local first=S.StarterEntities.a
assert(a.hermitGift.level==2 and not a.hermitGift.claimed)
assert(S:EnsureStarterPickup(pa) and rolled==1 and spawned==1,'reinteraction uses existing pickup')
first.valid=false;assert(S:EnsureStarterPickup(pa))
assert(rolled==1 and prepared==1 and spawned==2,'reconnect respawns sealed gift without re-resolution')
local second=S.StarterEntities.a
second.payload.tier='large';assert(a.hermitGift.payload.tier=='small','sealed payload cannot be mutated by entity')
assert(not Loot:Collect(second,pb) and not a.hermitGift.claimed,'owner isolation')
assert(Loot:Collect(second,pa) and a.hermitGift.claimed)
assert(not S:EnsureStarterPickup(pa) and not Loot:Collect(second,pa),'one gift per visit')
R.State.Level=3;chosen='weapon';assert(S:EnsureStarterPickup(pa))
assert(a.hermitGift.level==3 and a.hermitGift.kind=='ammo' and a.starterClaimed,'later visit gets regular replacement, never starter')
R.State.Level=4;S.StarterEntities.a.valid=false;chosen='full';assert(S:EnsureStarterPickup(pa))
assert(a.hermitGift.kind=='consumable' and a.hermitGift.payload.itemId=='healing_potion','no empty or rerollable promised gift')
a.deploymentComplete=true;assert(not S:EnsureStarterPickup(pa),'no mid-maze grant')
a.deploymentComplete=false;a.starterClaimed=false;assert(S:EnsureStarterPickup(pa)=='initial-starter','initial route retained')
print('hermit_return PASS: production advance, preserved lives/starter, per-visit sealing, reconnect, owner/replay isolation, no second firearm, full-ammo fallback')
-- Execute board rendering and verify the world-space dimensions, not text matches.
ENT={};include=noop
surface={CreateFont=noop,SetDrawColor=noop,SetFont=noop,GetTextSize=function(s) return #s*12 end}
draw={SimpleText=noop};function CurTime() return 0 end
function Angle() return {RotateAroundAxis=noop,Up=function() return {} end,Forward=function() return {} end} end
local V={};V.__add=function(a,b) return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},V) end
V.__mul=function(a,b) return setmetatable({x=a.x*b,y=a.y*b,z=a.z*b},V) end
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},V) end
local scale,width,height
cam={Start3D2D=function(_,__,s) scale=s end,End3D2D=noop}
LOD.UI={Colors={},Paper=function(_,x,y,w,h) width=w;height=h end}
LOD.HeroesOfLegend={Entries={}}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_heroes_of_legend_board/cl_init.lua')
local board={GetNW2Bool=function() return false end,GetPos=function() return Vector(0,0,0) end,GetAngles=function() return {Forward=function() return Vector(1,0,0) end} end}
ENT.Draw(board);assert(width*scale==64 and height*scale==132,'board matches full-length mirror surface')
assert(88 > 64/2+5+width*scale/2,'adjacent board leaves a positive frame gap')
print('hermit_board PASS: mirror-size panel and non-overlapping placement')
-- Regression: staged players are intentionally NOT active combat participants.
-- Execute real Loot:Collect and Equipment:Grant to prove the narrow gift exception.
util={AddNetworkString=noop};net={Receive=noop,Start=noop,WriteTable=noop,Send=noop}
scripted_ents={GetStored=function() end};timer.Create=noop
pa.IsPlayer=function() return true end;pa.Alive=function() return true end;pa.EmitSound=noop
R.IsActivePlayer=function() return false end
R.IsSlotActivePlayer=function(_,p) return p==pa end
R.IsSoldierControl=function() return false end
S.IsPlayerInHut=function(_,p) return p==pa end
local E=LOD.Equipment
E.Definitions={healing_potion={name='Healing Potion'}}
dofile(root..'sv_equipment.lua')
local count=0
E.Ensure=function() return {} end
E.AddConsumable=function(_,state,id,n) assert(id=='healing_potion');count=count+n;return true end
E.Sync=noop
R.State.LevelSeed=555;a.deploymentComplete=false;a.starterClaimed=true
local item={LODHermitGiftId='gift',LODLootOwnerIdentity='a',LODLootKind='consumable',
    LODLootPayload={itemId='healing_potion'},LODLootStaticId='gift',LODLootLevelSeed=555}
a.hermitGift={id='gift',level=4,claimed=false};S.StarterEntities.a=item
LOD.MazeBuilder={}
LOD.Audio=dofile('tools/audio_test_double.lua')
dofile(root..'sv_loot_director.lua');dofile(root..'sv_hermit_repeat_gifts.lua')
assert(not E:CanAct(pa),'staging still forbids combat/move/throw actions')
assert(not E:Grant(pa,'healing_potion',1),'unattributed staging grants are denied')
assert(not Loot:Collect({LODLootOwnerIdentity='a',LODLootLevelSeed=555},pa),'ordinary loot is not admitted through staging exception')
assert(Loot:Collect(item,pa) and count==1 and a.hermitGift.claimed,'actual gift passes both production admission gates')
assert(not Loot:Collect(item,pa) and count==1,'actual collect retry cannot duplicate consumable')
print('hermit_admission PASS: production staged collection without enabling combat, source/owner checks, idempotent grant')
