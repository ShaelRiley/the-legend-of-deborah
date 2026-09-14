-- Real defense -> Feedback roll -> presentation packet -> client sound/draw.
local root = "gamemodes/legend_of_deborah/gamemode/lod/"
SERVER, CLIENT = true, false
local clock, pending = 100, {}
local function noop() end
CurTime = function() return clock end
IsValid = function(v) return type(v)=="table" and v.valid==true end
isstring = function(v) return type(v)=="string" end
unpack = table.unpack
math.Clamp = function(v,a,b) return math.max(a, math.min(b,v)) end
string.Trim = function(s) return s:match('^%s*(.-)%s*$') end
table.Copy = function(t)
    if type(t)~="table" then return t end
    local c={}; for k,v in pairs(t) do c[k]=table.Copy(v) end; return c
end
local vec={}; vec.__index=vec
Vector = function(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vec) end
vec.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
vec.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
vec.__mul=function(a,n) return Vector(a.x*n,a.y*n,a.z*n) end
function vec:GetNormalized() local n=math.sqrt(self.x^2+self.y^2+self.z^2); return n>0 and self*(1/n) or Vector() end
function vec:Angle() return {Right=function() return Vector(0,1,0) end} end
LerpVector=function(t,a,b) return a+(b-a)*t end
vector_origin=Vector()
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a or 255} end
Material=function() return {} end
local hooks, receivers, commands, packets, logs = {}, {}, {}, {}, {}
hook={Add=function(event,name,fn) hooks[event]=hooks[event] or {}; hooks[event][name]=fn end,
    Remove=function(event,name) if hooks[event] then hooks[event][name]=nil end end}
timer={Simple=function(_,fn) pending[#pending+1]=fn end, Create=noop, Remove=noop}
concommand={Add=function(name,fn) commands[name]=fn end}
local packet, readPacket, cursor
local function write(v,t) packet[#packet+1]={v,t} end
local function read(t) cursor=cursor+1; assert(readPacket[cursor][2]==t,"wire mismatch"); return readPacket[cursor][1] end
net={Receive=function(name,fn) receivers[name]=fn end, Start=function(name) packet={name=name} end,
    WriteUInt=write, ReadUInt=read, WriteString=function(v) write(v,'s') end, ReadString=function() return read('s') end,
    WriteBool=function(v) write(v,'b') end, ReadBool=function() return read('b') end,
    WriteVector=function(v) write(v,'v') end, ReadVector=function() return read('v') end,
    Send=function(ply) packet.recipient=ply; packets[#packets+1]=packet end, SendToServer=function() packets[#packets+1]=packet end}
util={AddNetworkString=noop, TableToJSON=function(t) return table.Copy(t) end}
GM={}
GetConVar=function() return {GetBool=function() return false end} end
ErrorNoHalt=function(s) error(s) end
DMG_SHOCK=256
function DamageInfo()
    local d={damage=0}
    function d:SetDamage(v) self.damage=v end
    function d:GetDamage() return self.damage end
    function d:SetAttacker(a) self.attacker=a end
    function d:GetAttacker() return self.attacker end
    d.SetInflictor=noop; d.SetDamageType=noop; d.SetDamagePosition=noop; d.SetDamageForce=noop
    return d
end
local function actor(id,human,pos)
    return {valid=true, hp=100, IsPlayer=function() return human end, EntIndex=function() return id end,
        Nick=function() return 'Wizard' end, GetClass=function() return 'lod_hostile' end,
        GetShootPos=function() return pos end, WorldSpaceCenter=function() return pos end,
        GetAimVector=function() return Vector(1,0,0) end, Alive=function() return true end,
        Health=function(self) return self.hp end, TakeDamageInfo=function(self,d) self.hp=self.hp-d:GetDamage() end}
end
local wizard=actor(1,true,Vector(0,0,64))
local enemy=actor(2,false,Vector(200,0,64)); enemy.LODHostile=true
enemy.LODProgressionState={derivedStats={damageResistancePerDie=1}}
local ps={magic=100, progressionState={classId='wizard',derivedStats={intMod=2,
    hpToMagicDiversionFraction=.25,wizardClassHpToMagicDiversionFraction=.25}}}
player={GetAll=function() return {wizard} end}
LOD={RPG={PlayerWeaponDamageProfiles={}}, RPGPresentation={},
    RunManager={State={LevelSeed=1},GetPlayerState=function(_,a) return a==wizard and ps or nil end},
    Magic={_EnsureState=function() return ps end,_Sync=noop,CastForceShout=noop},
    RPGTestLog={Write=function(_,name,fields) logs[#logs+1]={name=name,fields=fields} end}}
local contexts=setmetatable({},{__mode='k'})
LOD.RPGStatusElements={DamageContext=function(_,d) return contexts[d] end, Has=function() return false end,
    AttachDamageContext=function(_,d,c) contexts[d]=c end}
dofile(root..'sh_die_logger.lua')
dofile(root..'sv_combat_rolls.lua')
dofile(root..'sv_combat_feed_semantics.lua')
dofile(root..'sv_rpg_gate_d.lua')
dofile(root..'sv_rpg_wizard_feedback.lua')
dofile(root..'sv_rpg_presentation.lua')
dofile(root..'sv_rpg_major_fx_bridge.lua')
local offense=LOD.RPGWizardOffense
assert(offense:Install())
assert(LOD.RPGPresentation:InstallFeedbackPresentation())
pending={}
-- Fixed RNG boundary: real formula resolver still rolls, counts and mitigates.
LOD.CombatRolls._RNG=function() return {Float=function() return 0 end,Int=function() return 2 end} end
local incoming=DamageInfo(); incoming:SetDamage(8); incoming:SetAttacker(enemy)
contexts[incoming]={damageContract={values={6,2}}}
local result=LOD.RPGAbilityRules:ApplyPlayerDefense(wizard,incoming)
assert(result.finalHPDamage==6 and result.actualMagicDiversion==2 and ps.magic==98)
assert(#pending==1,'Feedback proc schedules exactly one return')
pending[1]()
assert(enemy.hp==96 and offense.Stats.feedbackProcs==1,'2d4+2 minus CON 1 per die gives 4 damage')
local shield, feedback, shieldText, feedbackText
local majorCount=0
for _,p in ipairs(packets) do
    if p.name=='LOD_RPGMajorFX' then
        majorCount=majorCount+1
        if p[2][1]==4 then shield=p else feedback=p end
    elseif p.name=='LOD_CombatRoll' then
        if p[2][1]:find('ARCANE DIVERSION',1,true) then shieldText=p[2][1] else feedbackText=p[2][1] end
    end
end
assert(majorCount==2 and shield and feedback,'one FX packet for each actual committed reaction')
assert(shieldText:find('(6) HP AFTER DIVERSION',1,true)==1 and shieldText:find('8 incoming - 2 diverted = 6 HP',1,true))
assert(feedbackText:find('(4) DAMAGE',1,true)==1 and feedbackText:find('CON -1/die: 1 + 1 = 4',1,true))
assert(feedback[4][1]=='(4) DAMAGE — 2d4+2' and feedback[6][1].x==200)
local before=#packets
assert(not LOD.RPGPresentation:SendFX(wizard,4,'shield','spam'))
assert(#packets==before,'cosmetic shield flood is bounded at the server')
incoming:SetDamage(0)
assert(not LOD.RPGAbilityRules:ApplyPlayerDefense(wizard,incoming) and #packets==before,'zero damage fabricates no cue')
local originalWrite, originalError = net.WriteVector, ErrorNoHalt
local presentationErrors = 0
net.WriteVector = function() error('simulated transport failure') end
ErrorNoHalt = function() presentationErrors=presentationErrors+1 end
clock=clock+1
incoming:SetDamage(8); contexts[incoming].feedbackIneligible=true
result=LOD.RPGAbilityRules:ApplyPlayerDefense(wizard,incoming)
assert(result.finalHPDamage==6 and ps.magic==96 and presentationErrors==1,
    'a presentation failure cannot abort or repeat the committed defense')
net.WriteVector, ErrorNoHalt = originalWrite, originalError

SERVER,CLIENT=false,true
clock=100
LocalPlayer=function() return wizard end
ScrW=function() return 1280 end; ScrH=function() return 800 end
local sounds,drawn,beams,sprites={},0,0,0
surface={CreateFont=noop,PlaySound=function(s) sounds[#sounds+1]=s end,SetDrawColor=noop,DrawLine=noop}
draw={SimpleTextOutlined=function() drawn=drawn+1 end}
render={SetMaterial=noop,DrawBeam=function() beams=beams+1 end,DrawSprite=function() sprites=sprites+1 end}
dofile(root..'cl_wizard_fx.lua')
dofile(root..'cl_rpg_major_fx.lua')
local major,fx=LOD.RPGMajorFX,LOD.WizardFX
major:Trigger(2,'LEVEL UP','',1)
local baseline=#sounds
local function deliver(p) readPacket,cursor=p,0; receivers[p.name]() end
deliver(shield); deliver(feedback)
assert(major.active.kind==2 and fx.active[1] and fx.active[4],'both reactions coexist with level-up')
assert(#sounds==baseline+2 and sounds[#sounds]~=sounds[#sounds-1],'independent catch/discharge sounds requested')
hooks.PostDrawTranslucentRenderables.LOD_WizardReactionWorld(true,false)
assert(beams==0 and sprites==0,'no duplicate depth-pass effects')
clock=clock+.1
hooks.PostDrawTranslucentRenderables.LOD_WizardReactionWorld(false,false)
hooks.PostDrawHUD.LOD_WizardReactionHUD()
assert(beams==8 and sprites>0 and drawn==4,'actual world particles/arc and both first-person labels render')
for i=1,100 do fx:Trigger(4,'shield','',i) end
local count=0; for _ in pairs(fx.active) do count=count+1 end
assert(count==2,'reaction storage remains bounded during rapid events')
clock=clock+1
hooks.PostDrawHUD.LOD_WizardReactionHUD()
assert(not next(fx.active),'expired reactions leave no retained effects')
fx:Trigger(1,'return','',1); hooks.PreCleanupMap.LOD_WizardReactionCleanup()
assert(not next(fx.active) and not next(fx.sounds),'map cleanup resets presentation')
print('WIZARD_REACTION_FX_PASS: actual defense/Feedback, totals, transport, sound, drawing and bounded cleanup')
