SERVER,CLIENT=true,false
local now=10
function CurTime() return now end
function IsValid(a) return type(a)=='table' and a.valid~=false end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function V:Normalize() local l=self:Length2D();self.x=self.x/l;self.y=self.y/l end
function V:GetNormalized() local v=Vector(self.x,self.y,self.z);v:Normalize();return v end
function V:Distance(v) return (self-v):Length2D() end
MOVETYPE_WALK,MASK_PLAYERSOLID=1,2
engine={TickInterval=function() return .05 end}
local receivers,events={},0
net={Receive=function(n,f) receivers[n]=f end,Start=function() end,WriteEntity=function() end,WriteString=function() end,Broadcast=function() end}
hook={Run=function() events=events+1 end}
local wall=false
util={AddNetworkString=function() end,TraceHull=function() return {StartSolid=wall,Fraction=wall and 0 or 1} end}
LOD={RPG={},Equipment={},RunManager={State={LevelSeed=1}},RPGAbilityRules={},MagicForms={},Magic={}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
local E,R,F,M,Run=LOD.Equipment,LOD.RPGAbilityRules,LOD.MagicForms,LOD.Magic,LOD.RunManager
local p={ps={equipment={items={},slots={}},magic=100},pos=Vector(0,0,0),alive=true}
function p:GetPos() return self.pos end
function p:GetAimVector() return Vector(1,0,0) end
function p:GetMoveType() return MOVETYPE_WALK end
function p:GetHull() return Vector(-16,-16,0),Vector(16,16,72) end
function p:Crouching() return false end
function p:EmitSound() end
function Run:GetPlayerState(a) return a.ps end
function E:CanAct(a) return a.alive and not a.soldier end
function E:IsActive(a) return a.throwable end
function E:Report() end
local held,muted=false,false
LOD.RPGStatusElements={CanMoveVoluntarily=function() return not held end,CanInitiateMagic=function() return not muted end}
function M:_EnsureState(a) return a.ps end
function M:_Sync() end
local damage,push=0,0
local function enemy(hp,x) return {hp=hp,GetPos=function() return Vector(x,0,0) end,Health=function(s) return s.hp end} end
local a,b=enemy(100,1),enemy(100,2)
function F:_NewContext() return {} end
function F:_NextCastSerial() return 1 end
function F:_BlastTargets(_,cells) assert(cells==1);return {a,b} end
function F:_ApplyDamage(_,_,t,form,content,context)
    assert(form.damageDice==1 and form.damageSides==6 and content==nil and context.castSerial)
    damage=damage+1;if t==a then t.hp=t.hp-3 end -- second target's shared defense resolves to zero
end
LOD.Pushback={Apply=function(_,t,opts) assert(t==a and opts.distance==96 and opts.magicPush);push=push+1 end}
E.Projectiles={}
dofile(root..'sv_equipment_moves.lua')
local state=p.ps.equipment
state.items.boots={definitionId='boots',count=1,properties={{id='move_quickstep',amount=1}}}
state.items.ring={definitionId='ring',count=1,properties={{id='move_rebuff',amount=1}}}
state.items.ring2={definitionId='ring',count=1,properties={{id='move_rebuff',amount=1}}}
E:Equip(state,'boots','feet');E:Equip(state,'ring','left_hand');E:Equip(state,'ring2','right_hand')
local function recipe(tokens)
    local result
    for _,token in ipairs(tokens) do now=now+.1;result=E:DirectionToken(p,token) end
    return result
end
assert(recipe({'UP','UP','UP'}) and p.ps.magic==90)
assert(not recipe({'UP','UP','UP'}) and p.ps.magic==90,'Cooldown cannot spend twice')
assert(recipe({'LEFT','DOWN','RIGHT'}) and p.ps.magic==70 and damage==2 and push==1,'Both active grants; duplicate Rebuff does not multiply')
assert(events==2)
now=now+5
p.throwable=true
assert(not recipe({'UP','UP','UP'}) and p.ps.magic==70)
p.throwable=false
E:DirectionToken(p,'UP');E:DirectionToken(p,'RESET')
assert(not recipe({'UP','UP'}),'Menu reset discards partial recipe')
now=now+1
assert(not recipe({'UP'}),'Timeout discards old input')
E:DirectionToken(p,'RESET');held=true
assert(not recipe({'UP','UP','UP'}) and p.ps.magic==70,'Held blocks dash before spending')
held=false;wall=true
assert(not recipe({'UP','UP','UP'}) and p.ps.magic==70,'Solid start rejected before spending')
wall=false;p.ps.magic=9
assert(not recipe({'UP','UP','UP'}) and p.ps.magic==9)
p.ps.magic=100
assert(recipe({'UP','UP','UP'}))
local data={v=Vector(20,0,0),max=100}
function data:GetVelocity() return self.v end
function data:SetVelocity(v) self.v=v end
function data:GetMaxSpeed() return self.max end
function data:GetMaxClientSpeed() return self.max end
function data:SetMaxSpeed(v) self.max=v end
function data:SetMaxClientSpeed() end
function data:SetForwardSpeed() end
function data:SetSideSpeed() end
R:ApplyVoluntaryDash(p,data);assert(data.v.x==450)
p.pos=Vector(22.5,0,0);now=now+.05;R:ApplyVoluntaryDash(p,data)
assert(R.VoluntaryDashes[p].remaining==67.5)
now=now+.21;R:ApplyVoluntaryDash(p,data);assert(not R.VoluntaryDashes[p] and data.v.x==20,'No continuing dash momentum')
E:Unequip(state,'feet');now=now+3
assert(not recipe({'UP','UP','UP'}),'Inactive grant cannot activate')
muted=true;assert(not recipe({'LEFT','DOWN','RIGHT'}));muted=false
p.soldier=true;assert(not recipe({'LEFT','DOWN','RIGHT'}));p.soldier=false
local old=E:MoveSession(p);Run.State.LevelSeed=2
assert(E:MoveSession(p)~=old,'Input/cooldowns bound to level identity')
E:ClearTransient(p);assert(not E.MoveSessions[p])
print('EQUIPMENT_MOVES_PASS: simultaneous grants; dedupe; costs/cooldowns; inactive, Held, Muted, Throwable and Soldier rejection; buffer reset; voluntary dash expiry; canonical area/damage/Push delegates')
