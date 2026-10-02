-- Actual live/death Tetris, board, network/input and lifecycle authorities.
-- Only native entities, transport and clock are deterministic boundary doubles.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local Run,CPS=fixture.Run,LOD.CharacterProgressionSystem
local clock,action=100,0
CurTime=function() return clock end
local receivers,hooks,timers={}, {},{}
local noop=function() end
net.Receive=function(name,fn) receivers[name]=fn end
net.ReadUInt=function() return action end
net.Start=noop;net.Send=noop;net.WriteUInt=noop;net.WriteInt=noop;net.WriteBool=noop
hook.Add=function(event,name,fn) hooks[name]=fn end
local paidEvents, prepared = {}, 0
hook.Run=function(event,actor,cost,context)
 if event=='LODDiscreteMagicSpent' then
  assert(actor.id=='live-tetris','only the paying actor emits Magic spend')
  assert(cost==15 and actor.ps.magic>=0 and context.source=='russian_asset_live','exact committed activation')
  assert(context.auraBurst and context.auraBurst.serial==prepared,'existing aura snapshot is forwarded once')
  paidEvents[#paidEvents+1]={actor=actor,cost=cost,context=context}
 end
end
LOD.RPG.PrepareCheckpointDAuraBurst=function(_,actor)
 prepared=prepared+1
 assert(actor.ps.magic>=15,'snapshot before the one-time Magic debit')
 return {serial=prepared}
end
timer.Simple=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end
local p=fixture.actor('live-tetris')
Run.State.PlayerState[p.id]=p.ps
Run.State.BuildReady=true;Run.State.Graph={};Run.State.CampaignEpoch=1
p.ps.lives=3;p.LODRunSpawnSerial=1
p.ps.progressionState.featIds={'CON_RUSSIAN_ASSET'}
CPS:_RecomputeProgressionState(p.ps.progressionState)
function p:GetClass() return 'player' end
function p:UnSpectate() end
function p:Spawn() self.hp=self.max end
player.GetAll=function() return {p} end
LOD.Magic._EnsureState=function(_,actor) return actor.ps end
LOD.Magic._Sync=noop
dofile(root..'sv_equipment_moves.lua')
LOD.DeathTetris=nil
dofile(root..'sh_tetris.lua');dofile(root..'sv_death_tetris.lua')
local D,T=LOD.DeathTetris,LOD.Tetris
local function check(v,message) assert(v,'RUSSIAN_ASSET_LIVE: '..message) end
local function directions(values)
 for _,v in ipairs(values) do action=v;receivers.LOD_RussianAssetDirection(0,p) end
 return D.Sessions[p.id]
end
p.ps.magic=14.999
check(not directions({1,2,3,4}) and p.ps.magic==14.999,'insufficient Magic rejects without debit')
p.ps.magic=15
check(not directions({1,3,2,4}),'wrong order rejected')
check(not directions({1,2,3}),'incomplete sequence is not activation')
check(#paidEvents==0 and prepared==0,'unfunded/wrong/incomplete input has no paid-activation observers')
LOD.Equipment.MoveSessions[p]={tokens={'UP','DOWN'}}
local s=assert(directions({4}))
check(#LOD.Equipment.MoveSessions[p].tokens==0,'successful live opening immediately retires a special-move prefix')
check(s.kind=='live' and s.endsAt==nil and p.ps.magic==0,'one exact 15-Magic debit; no timer')
check(p.nw.LOD_LiveTetrisActive and not p.nw.LOD_DeathTetrisActive and not p.nw.LOD_DeathInteraction,'no death/safety state')
check(not Run.State.SimulationFrozen and not p.LODDead and p:Alive(),'world and body remain live')
check(not D:StartSession(p,'live') and p.ps.magic==0,'duplicate start cannot debit again')
check(#paidEvents==1 and prepared==1,'one successful opening produces exactly one existing Aura Burst observation')
check(not D:IsDeathInteractionFor(p),'live session does not enter protected death interaction')
local cmd={ClearMovement=function() error('live Tetris must not root the actor') end,
 ClearButtons=function() error('live Tetris must not freeze the actor') end}
hooks.LOD_DeathTetrisBlockDungeonInput(p,cmd)
-- Four real I-piece line clears, not a mocked reward helper.
for lines,reward in ipairs({20,60,100,160}) do
 clock=clock+2;s.game=T.NewGame(lines)
 for y=21-lines,20 do for x=1,10 do s.game.board[y][x]=(x==5) and 0 or 1 end end
 s.game.current={id=1,rotation=2,x=3,y=1}
 p.max=1000;p.hp=200;p.ps.nextLifeHPBonus=7
 action=5;receivers.LOD_TetrisInput(0,p)
 check(s.lastClearLines==lines and p.hp==200+reward,'actual '..lines..'-line clear heals '..reward)
 check(p.ps.nextLifeHPBonus==7,'live healing cannot bank next-life overfill')
end
p.max=100;p.hp=95
check(D:HealLiveLines(s,4)==5 and p.hp==100,'discard excess healing at ordinary MaxHP')
p.hp=125;check(D:HealLiveLines(s,4)==0 and p.hp==125,'cannot extend or erase existing unrelated overfill')
-- Indefinite session survives thousands of seconds and a lost board, with no upkeep.
p.hp=80;s.game.gameOver=true;clock=clock+10000
hooks.LOD_DeathTetrisThink()
check(D.Sessions[p.id]==s and p.ps.magic==0,'no continuing drain or session deadline')
action=5;receivers.LOD_TetrisInput(0,p)
check(not s.game.gameOver and p.ps.magic==0,'board restart remains in the same paid session')
action=6;receivers.LOD_TetrisInput(0,p)
check(not D.Sessions[p.id] and not p.nw.LOD_LiveTetrisActive,'voluntary close removes UI grant')
check(#paidEvents==1 and prepared==1,'clears, indefinite upkeep, board restart and closure never re-trigger paid activation')
-- A live body may lose HP and die; the ordinary death lifecycle closes Tetris.
p.ps.magic=15;s=assert(D:StartSession(p,'live'));p:SetHealth(0);p.ps.respawnAt=clock+20
hooks.LOD_DeathTetrisPrepare(p)
check(not D.Sessions[p.id] and not p.nw.LOD_LiveTetrisActive,'death closes live mode immediately')
timers[#timers].fn()
local death=assert(D.Deaths[p.id])
check(death.hardCapAt==clock+120,'Russian Asset retains the real 120-second death cap')
local deathSession=assert(D:StartSession(p,'death'))
check(p.ps.magic==0,'death Tetris has no new activation cost')
check(#paidEvents==2 and prepared==2,'death Tetris never dispatches a paid Magic activation')
for y=19,20 do for x=1,10 do deathSession.game.board[y][x]=x<=2 and 0 or 1 end end
deathSession.game.current={id=2,rotation=1,x=0,y=1}
p.ps.nextLifeHPBonus=7;clock=clock+1;action=5;receivers.LOD_TetrisInput(0,p)
check(p.ps.nextLifeHPBonus==67,'death double clear keeps doubled +60 overfill semantics')
D:EndDeath(p.id);p.hp=100
local staleCases={
 {name='death',change=function() p.hp=0 end,restore=function() p.hp=100 end},
 {name='disconnect',change=function() p.valid=false end,restore=function() p.valid=true end},
 {name='spawn',change=function() p.LODRunSpawnSerial=p.LODRunSpawnSerial+1 end},
 {name='actor replacement',change=function() local old=p.ps.progressionState;p.ps.progressionState=table.Copy(old);p.LODProgressionState=p.ps.progressionState end},
 {name='equipment-independent run epoch',change=function() Run.State.CampaignEpoch=Run.State.CampaignEpoch+1 end},
 {name='dungeon',change=function() Run.State.Level=Run.State.Level+1 end},
 {name='same-seed graph rebuild',change=function() Run.State.Graph={} end},
 {name='failure',change=function() Run.State.Failed=true end,restore=function() Run.State.Failed=nil end},
 {name='victory',change=function() Run.State.LevelCleared=true end,restore=function() Run.State.LevelCleared=nil end},
 {name='transition',change=function() Run.State.BuildReady=false end,restore=function() Run.State.BuildReady=true end},
 {name='paused lifecycle',change=function() Run.State.SimulationFrozen=true end,restore=function() Run.State.SimulationFrozen=nil end},
 {name='hot reload',change=function() dofile(root..'sv_death_tetris.lua') end},
}
for _,case in ipairs(staleCases) do
 p.ps.magic=30;p.hp=50;s=assert(D:StartSession(p,'live'));case.change()
 check(D:HealLiveLines(s,4)==0,'no stale healing after '..case.name)
 hooks.LOD_DeathTetrisThink()
 check(not D.Sessions[p.id],case.name..' ends old live session')
 if case.restore then case.restore() end
end
-- Input sources share the actual client edge recognizer; aliases never duplicate.
local held,packets={},{}
KEY_LEFT=88;KEY_RIGHT=89;KEY_UP=90;KEY_DOWN=91;KEY_F=33
Color=function(...) return {...} end
surface={CreateFont=noop,PlaySound=noop};gui={IsGameUIVisible=function() return false end}
vgui={GetKeyboardFocus=function() end};LocalPlayer=function() return p end
input={IsKeyDown=function(key) return held[key] or false end,IsButtonDown=function(key) return held[key] or false end}
local packet
net.Start=function(name) packet={name=name} end
net.WriteUInt=function(value) packet.value=value end
net.SendToServer=function() packets[#packets+1]=packet end
LOD.TetrisClient=nil
dofile(root..'cl_tetris.lua')
local C=LOD.TetrisClient
local function press(key)
 held[key]=true;hooks.LOD_RussianAssetDirectionalInput()
 hooks.LOD_RussianAssetDirectionalInput() -- repeated frame is not a repeated edge
 held[key]=nil;hooks.LOD_RussianAssetDirectionalInput()
end
for _,keys in ipairs({{KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN},{149,147,146,148},{KEY_LEFT,147,KEY_UP,148}}) do
 packets={}
 for _,key in ipairs(keys) do press(key) end
 check(#packets==4,'exactly four keyboard/POV edges')
 for i,row in ipairs(packets) do check(row.name=='LOD_RussianAssetDirection' and row.value==i,'identical arrow/D-pad sequence '..i) end
end
packets={};held[KEY_LEFT]=true;held[149]=true;hooks.LOD_RussianAssetDirectionalInput()
check(#packets==1,'simultaneous alias press is one edge');held={};hooks.LOD_RussianAssetDirectionalInput()
-- Ambiguous chords must invalidate a partial server sequence rather than
-- serialize the client's LEFT/RIGHT/UP/DOWN polling order into an activation.
for _,keys in ipairs({{KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN},{KEY_UP,148}}) do
 clock=clock+2;p.ps.magic=30
 check(not directions({1,2}),'partial sequence waits for ordered directions')
 packets={}
 for _,key in ipairs(keys) do held[key]=true end
 hooks.LOD_RussianAssetDirectionalInput();hooks.LOD_RussianAssetDirectionalInput()
 check(#packets==1 and packets[1].name=='LOD_RussianAssetDirection' and packets[1].value==0,
  'same-frame keyboard/mixed-device chord emits one reset')
 directions({packets[1].value})
 check(D.LiveSequences[p].index==0,'chord invalidates the server partial sequence')
 check(not directions({3,4}) and p.ps.magic==30,'chord cannot complete or spend for an ordered sequence')
 held={};hooks.LOD_RussianAssetDirectionalInput()
end
clock=clock+2;packets={}
for _,key in ipairs({KEY_LEFT,147,KEY_UP,148}) do press(key) end
local ordered={};for _,row in ipairs(packets) do ordered[#ordered+1]=row.value end
check(directions(ordered) and p.ps.magic==15,'ordered mixed-device edges still activate for exactly 15 Magic')
D:EndSession(p.id)
C.active=true;C.kind=3;C.gameOver=false;packets={}
held[KEY_LEFT]=true;hooks.LOD_RussianAssetDirectionalInput()
hooks.LOD_DeathTetrisControls(p,'+moveleft',true)
check(#packets==1 and packets[1].name=='LOD_TetrisInput','raw input and bind do not double move')
held={};held[KEY_F]=true;hooks.LOD_DeathTetrisFInput()
check(packets[#packets].value==6,'F requests voluntary live closure')
print('RUSSIAN_ASSET_LIVE_PASS: real sequence/board/net, exact cost, capped immediate healing, no upkeep/protection, 12 lifecycle boundaries, death120/+60 retained, keyboard/controller parity')
