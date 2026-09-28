local e=dofile('tools/music_test_fixture.lua');local check=e.check
SERVER=true
local p={valid=true,staged=true,pos=Vector(100,100,0),on=1,ground=true}
function p:GetInfoNum() return self.on end
function p:ChatPrint() end
function p:GetNW2Bool() return self.staged end
function p:Alive() return true end
function p:OnGround() return self.ground end
function p:GetPos() return self.pos end
function p:IsPlayer() return true end
function p:Health() return self.hp or 100 end
function p:GetMaxHealth() return 100 end
function p:IsSuperAdmin() return self.admin end
e.player=p;player={GetAll=function() return {p} end}
local ps={deploymentComplete=true}
local graph={Cells={['1:1:0']={x=1,y=1,z=0},['1:1:1']={x=1,y=1,z=1}},Width=1,Height=1,Layers=2,VerticalEdges={},Progression={}}
local s={RunId='run1',CampaignEpoch=1,CampaignSeed=7,Level=1,BuildReady=true,Graph=graph}
LOD.RunManager={State=s,GetPlayerState=function() return ps end}
local events={};LOD.CombatRolls={_Send=function(_,owner,cat,text,family,fields) events[#events+1]={owner=owner,text=text,family=family,fields=fields} end}
LOD.CampaignTimeout={Remaining=function(_,clock) return clock.remaining end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_music.lua')
local D=LOD.MusicDirector;D.Catalog=e.catalog()
check(not D:Enabled(p),'master disabled by default')
local plan=D:Prepare(s,1)
local baseline=table.concat(plan.floors)
check(D:Configure('set','pair'),'valid set accepted')
check(table.concat(D:Prepare(s,1).floors)==baseline,'active plan remains frozen')
check(not D:Configure('set','missing') and D.Settings.set=='pair','invalid setting preserves prior selection')
local nextPlan=D:Prepare(s,2)
for _,id in ipairs(nextPlan.floors) do check(id=='alpha' or id=='beta','future plan applies saved restriction') end
local l=D:Listener(p);local target=D:Target(p,l,s)
check(target.role=='T0' and target.targets[1].block==plan.floors[1],'staging binds upcoming physical Floor1')
p.staged=false;local deployed=D:Target(p,l,s)
check(deployed.plan==target.plan and deployed.targets[1].block==target.targets[1].block,'portal no reroll/restart')
s.CampaignClock={remaining=50};target=D:Target(p,l,s)
check(target.role=='T3','uses effective canonical timer')
s.CampaignClock.remaining=800;e.now=e.now+7;D:Target(p,l,s);e.now=e.now+7;target=D:Target(p,l,s)
check(target.role=='T0','real time extension relaxes normally')
s.Graph.Progression.Warden={entry={x=1,y=1,z=0},court={['1:1:0']=true}}
s.Warden={started=true,dead=false};target=D:Target(p,l,s)
check(target.role=='BOSS','committed arena dedicated loop')
s.Level=20;s.Warden.dead=true;LOD.Hector={RescueAllowed=function() return false end}
target=D:Target(p,l,s);check(target.role=='BOSS','Gordon to Hector handoff keeps boss role')
LOD.Hector.RescueAllowed=function() return true end
target=D:Target(p,l,s);check(target.role=='T0','boss defeat alone is calm, not victory')
s.Level=1;s.Warden=nil;s.Graph.Progression.Warden=nil
-- Actual start ACK goes through canonical private record path, never a title from the client.
e.set('lod_music_enabled',1);D:Update(p,s);l=D:Listener(p)
local bid=l.plans[1].floors[1];e.receive('LOD_MusicPlaying',l.sequence,1,bid)
check(#events==1 and events[1].family=='music' and events[1].text=='Now playing: '..plan.blocks[bid].title,'private canonical authored name')
e.now=e.now+1;e.receive('LOD_MusicPlaying',l.sequence,2,bid);check(#events==1,'duplicate confirmation deduplicated')
e.now=e.now+1;e.receive('LOD_MusicPlaying',l.sequence,3,'not-authorized');check(#events==1,'unassigned/spoofed block rejected')
s.LevelCleared=true;D:ClearAccepted(s);local receipt=s.MusicVictory
D:ClearAccepted(s);check(s.MusicVictory==receipt,'single accepted clear receipt')
target=D:Target(p,l,s);check(target.role=='POST' and target.canVictory,'only clear offers one-shot')
e.hooks.LOD_MusicLeave(p);check(not receipt.participants[p],'reconnect cannot replay clear')
s.Level=2;s.LevelCleared=false;s.BuildReady=false;target=D:Target(p,D:Listener(p),s)
check(target.role=='POST' and target.victory==receipt.id,'bridge survives successful old-maze cleanup')
s.BuildReady=true;p.staged=true;target=D:Target(p,D:Listener(p),s)
check(target.plan==nextPlan.id and target.role=='T0','next staging exact preplanned T0')
e.set('lod_music_enabled',0);D:Update(p,s);check(not D:Enabled(p),'server off overrides player on')
check(not D:Configure('post_victory','bad'),'invalid policy rejected')
for _,role in ipairs({'boss','victory','interlude'}) do
 check(D:Configure('universal_'..role,'1'),'independent override on')
 check(D:Configure('universal_'..role,'0'),'independent override off')
end
print('MUSIC_SERVER PASS '..e.checks)
