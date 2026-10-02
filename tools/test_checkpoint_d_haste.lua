local base='gamemodes/legend_of_deborah/gamemode/lod/'
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
function IsValid(v) return type(v)=='table' and v.valid~=false end
function GetConVar() return nil end
MOVETYPE_WALK=2;MOVETYPE_LADDER=9;IN_JUMP=2
concommand={Add=function() end}
LOD={RPG={IdentityCatalog={OrdinaryFeats={}},FeatEffectSystem={}},RPGAbilityRules={},
 RPGStatusElements={CanMoveVoluntarily=function(_,a)return not a.held end}}
local R,E=LOD.RPGAbilityRules,LOD.RPG.FeatEffectSystem
function R:Derived(a) return a.derived end
function E:ApplyDerived() end
dofile(base..'sv_rpg_checkpoint_d_haste.lua')
local ok,errors=R:ValidateCheckpointDHaste();assert(ok,table.concat(errors,';'))
local a={ground=true,moveType=MOVETYPE_WALK,alive=true,water=0,
 derived={hasteMovementMultiplier=1.33,springHeelAirMovementMultiplier=1.5}}
function a:IsPlayer()return true end
function a:Alive()return self.alive end
function a:GetMoveType()return self.moveType end
function a:WaterLevel()return self.water end
function a:OnGround()return self.ground end
function a:IsFrozen()return self.frozen end
function a:InVehicle()return self.vehicle end
function a:SetVelocity()error('voluntary multiplier cannot write a discrete or forced velocity')end
local mv={forward=100,side=-80,max=220,client=220}
function mv:GetForwardSpeed()return self.forward end;function mv:SetForwardSpeed(n)self.forward=n end
function mv:GetSideSpeed()return self.side end;function mv:SetSideSpeed(n)self.side=n end
function mv:GetMaxSpeed()return self.max end;function mv:SetMaxSpeed(n)self.max=n end
function mv:GetMaxClientSpeed()return self.client end;function mv:SetMaxClientSpeed(n)self.client=n end
function mv:KeyDown(key)return key==IN_JUMP and self.jump==true end
R:ApplyVoluntaryMovementFeats(a,mv)
assert(mv.forward==133 and mv.side==-106.4 and mv.max==220*1.33)
mv.forward,mv.side,mv.max,mv.client,mv.jump=100,-80,220,220,true
R:ApplyVoluntaryMovementFeats(a,mv)
assert(mv.forward==100 and mv.side==-80 and mv.max==220 and mv.client==220,
 'grounded jump command cannot feed Haste into the first airborne acceleration')
mv.jump=false
a.ground=false;assert(R:VoluntaryFeatMovementMultiplier(a)==1.5,'air uses Spring Heel, never Haste')
a.derived.springHeelAirMovementMultiplier=nil
assert(R:VoluntaryFeatMovementMultiplier(a)==1,'Haste does not accelerate air movement')
a.ground=true
for _,k in ipairs({'frozen','vehicle','held'})do a[k]=true;assert(R:VoluntaryFeatMovementMultiplier(a)==1,k);a[k]=false end
a.moveType=MOVETYPE_LADDER;assert(R:VoluntaryFeatMovementMultiplier(a)==1)
a.moveType=MOVETYPE_WALK;a.water=2;assert(R:VoluntaryFeatMovementMultiplier(a)==1)
a.water=0;a.alive=false;assert(R:VoluntaryFeatMovementMultiplier(a)==1)
assert(R.SetHasteActive==nil and R.HasteDrainPerSecond==nil and R.IsHasteActive==nil)
local d={};E:ApplyDerived({featIds={'INT_HASTE_1','INT_HASTE_2','INT_HASTE_3'}},d)
assert(d.hasteEnabled and d.hasteMovementMultiplier==1.33 and d.hasteDrainMultiplier==nil,'removed ranks cannot multiply passive Haste')
print('HASTE_PASS: one passive 1.33 ground wish multiplier; no Magic/toggle/drain; air/forces/ladders/status exclusions')

-- Simulate a still-loaded pre-rebalance Haste closure during AutoRefresh.
local removed={}
timer={Remove=function(id) removed[id]=true end}
hook={Remove=function(event,id) removed[event..'/'..id]=true end}
net={Receivers={lod_hastetoggle=function() error('retired toggle') end}}
function a:SetNW2Bool(id,value) assert(id=='LOD_HasteActive' and value==false);self.oldActive=value end
a.LODNextHasteToggle=90
E.LODPassiveHaste20261002=nil;E.LODCheckpointDHasteDerivedWrapped=true;E.HasteState={[a]={active=true}}
R.IsHasteActive=function()return true end;R.SetHasteActive=function()end;R.HasteDrainPerSecond=function()return 99 end
local oldDerived=E.ApplyDerived
E.ApplyDerived=function(self,state,d) oldDerived(self,state,d);d.hasteRank=3;d.hasteDrainMultiplier=.66 end
local oldMovement=function() return R:IsHasteActive(a) and 2 or 1 end
dofile(base..'sv_rpg_checkpoint_d_haste.lua')
assert(oldMovement()==1 and R.SetHasteActive==nil and R.HasteDrainPerSecond==nil)
assert(E.HasteState==nil and a.oldActive==false and a.LODNextHasteToggle==nil and net.Receivers.lod_hastetoggle==nil)
assert(removed.LOD_RPG_CheckpointDHasteDrain and removed['LODMagicRegenerationSuppressed/LOD_RPG_CheckpointDHaste'])
local migrated={};E:ApplyDerived({featIds={'INT_HASTE_1'}},migrated)
assert(migrated.hasteMovementMultiplier==1.33 and migrated.hasteRank==nil and migrated.hasteDrainMultiplier==nil)
print('HASTE_HOT_RELOAD_PASS: old timer, input, state, regeneration and captured movement closures retired safely')

-- Actual client SetupMove projection and server feat seam must agree at takeoff,
-- in ordinary grounded movement, and while airborne. None owns carried impulses.
local callbacks={}
hook.Add=function(_,id,fn) callbacks[id]=fn end
LocalPlayer=function() return a end
function a:GetNW2Float(id,fallback) return (self.nw or {})[id] or fallback end
a.alive,a.ground,a.water,a.moveType=true,true,0,MOVETYPE_WALK
a.derived={hasteMovementMultiplier=1.33,springHeelAirMovementMultiplier=1.5}
a.nw={LOD_HasteMovementMultiplier=1.33,LOD_SpringHeelAirMultiplier=1.5}
dofile(base..'sh_feat_movement.lua')
dofile(base..'cl_rpg_movement.lua')
function mv:GetVelocity() error('feat multiplier must not read/copy forced velocity') end
function mv:SetVelocity() error('feat multiplier must not rewrite forced velocity') end
local function resetMove(jump)
 mv.forward,mv.side,mv.max,mv.client,mv.jump=100,-80,220,220,jump
end
for _,ground in ipairs({true,false}) do
 for _,jump in ipairs({true,false}) do
  a.ground=ground
  resetMove(jump);R:ApplyVoluntaryMovementFeats(a,mv)
  local f,s,max,client=mv.forward,mv.side,mv.max,mv.client
  resetMove(jump);callbacks.LOD_PredictedVoluntarySpeed(a,mv)
  assert(mv.forward==f and mv.side==s and mv.max==max and mv.client==client,
   'client/server wish axes and caps agree across takeoff boundary')
  local expected=ground and (jump and 1 or 1.33) or 1.5
  assert(math.abs(mv.forward-100*expected)<.00001 and math.abs(mv.max-220*expected)<.00001)
 end
end
print('HASTE_TAKEOFF_PREDICTION_PASS: grounded takeoff excludes Haste; ordinary ground and Spring Heel air controls match; carried impulses untouched')
