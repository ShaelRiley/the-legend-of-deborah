-- Production authorities; engine spatial queries, rendering and networking are boundary doubles.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
LOD.Magic._EnsureState=function(_,p) return p.ps end
local E,R,S,F=LOD.Equipment,LOD.RPGAbilityRules,LOD.RPGStatusElements,LOD.MagicForms
local actor=fixture.actor('refresh');local enemy=fixture.actor('refresh-enemy',true)
local Run=fixture.Run;Run.State.PlayerState.refresh=actor.ps;Run.State.BuildReady=true
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self:DistToSqr(Vector()) end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:Distance(b) return (self-b):Length() end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function V:GetNormalized() local n=self:Length();return n>0 and self*(1/n) or Vector() end
function actor:GetShootPos() return Vector(0,0,64) end
function actor:GetAimVector() return Vector(1,0,0) end
function actor:GetClass() return 'player' end
function actor:GetOwner() return nil end
function actor:GetMoveType() return MOVETYPE_WALK end
function actor:WaterLevel() return 0 end
function actor:GetWalkSpeed() return 200 end
function actor:GetRunSpeed() return 400 end
-- Every negative condition uses the same cure path, including infinite-tick ailments.
for id in pairs(S.Registry) do assert(S:Apply(actor,id,enemy,{direct=true,dc=100,duration=20})) end
assert(E:Heal(actor,actor,25),'Full-HP potion must remain a remedy')
for id in pairs(S.Registry) do assert(not S:Has(actor,id),id..' survived potion') end
assert(not S.Active[actor]);assert(not actor.nw.LOD_StatusHeld and not actor.nw.LOD_StatusPoisoned)
-- Production movement hook gets funded Haste from owned/recomputed feat state.
local state=actor.ps.progressionState;state.featIds={'INT_HASTE_1'}
LOD.CharacterProgressionSystem:_RecomputeProgressionState(state)
assert(R:SetHasteActive(actor,true))
local hooks={};local previous=hook.Add;hook.Add=function(_,id,fn) hooks[id]=fn end
-- Reuse the existing authoritative hook from the actual bootstrap registration.
local source=assert(io.open(root..'sv_rpg_gate_d.lua')):read('*a')
local start=assert(source:find('hook.Add("SetupMove", "LOD_RPG_GateD_Movement"',1,true))
local finish=assert(source:find('\nend)',start,true))+5
-- Execute the production hook unchanged with the same resolved AbilityRules.
assert(load('local AbilityRules=LOD.RPGAbilityRules\n'..source:sub(start,finish)))()
hook.Add=previous
local move={KeyDown=function() return false end,forward=200,side=50,speed=200,client=200}
for _,name in ipairs({'ForwardSpeed','SideSpeed','MaxSpeed','MaxClientSpeed'}) do
 local key=({ForwardSpeed='forward',SideSpeed='side',MaxSpeed='speed',MaxClientSpeed='client'})[name]
 move['Get'..name]=function(self) return self[key] end;move['Set'..name]=function(self,v) self[key]=v end
end
hooks.LOD_RPG_GateD_Movement(actor,move)
assert(move.forward==400 and move.side==100 and move.speed==400 and actor.nw.LOD_VoluntaryMovementMultiplier==2)
R:SetHasteActive(actor,false)
state.featIds={};LOD.CharacterProgressionSystem:_RecomputeProgressionState(state);assert(not R:SetHasteActive(actor,true))
-- Solid slab clips area/cone; an open shaft admits the very same vertical target.
local targets={}
local function target(id,x,y,z)
 local p=fixture.actor(id,true);p.pos=Vector(x,y,z)
 p.GetPos=function(self) return self.pos end;p.WorldSpaceCenter=p.GetPos;p.GetOwner=function() end
 p.EntIndex=function() return id end;targets[#targets+1]=p;return p
end
local front=target(11,150,0,64);local above=target(12,80,0,300)
local behind=target(13,-150,0,64);local side=target(14,0,150,64)
LOD.FactionManager={Opponents=function() return targets end,IsOpponent=function(_,_,t) return t and t.LODHostile end}
MASK_SOLID=987;local shaft=false
util.TraceLine=function(t)
 assert(t.mask==MASK_SOLID,'Shot mask misses generated floor slabs')
 local crosses=t.start.z<200 and t.endpos.z>200
 return {Hit=crosses and not shaft,Fraction=crosses and not shaft and .4 or 1,HitPos=t.endpos}
end
local function has(list,value) for _,v in ipairs(list) do if v==value then return true end end return false end
local area=F:_AreaTargets(actor,actor:GetShootPos(),500)
assert(#area==3 and not has(area,above))
shaft=true;assert(has(F:_AreaTargets(actor,actor:GetShootPos(),500),above),'Open vertical geometry stays hittable')
local cone=F:_ConeTargets(actor,actor:GetShootPos(),Vector(1,0,0),500)
assert(#cone==1 and cone[1]==front,'Cone direction excludes sides/rear')
assert(has(F:_ConeTargets(actor,actor:GetShootPos(),(above.pos-actor:GetShootPos()):GetNormalized(),500),above))
shaft=false;assert(not has(F:_ConeTargets(actor,actor:GetShootPos(),(above.pos-actor:GetShootPos()):GetNormalized(),500),above))
-- Both explosive learned projectiles and every bomb route through the same cover resolver.
net.Start=function() end;net.WriteString=function() end;net.WriteVector=function() end;net.WriteEntity=function() end
net.WriteUInt=function() end;net.WriteFloat=function() end;net.Broadcast=function() end
local applied={};local apply=F._ApplyDamage
F._ApplyDamage=function(_,_,_,t,form,content) applied[t]=true;return true end
for _,id in ipairs({'bomb','missile','watermelon'}) do
 applied={};local projectile={valid=true,LODCaster=actor,LODFormId=id,LODCastContext={},LODDirection=Vector(1,0,0),LODBlastRadius=500,
 GetPos=actor.GetShootPos,Remove=function(self) self.valid=false end}
 F:ProjectileImpact(projectile,{HitPos=actor:GetShootPos()})
 assert(applied[front] and not applied[above] and not projectile.valid)
 projectile.valid=true;applied={};F:ProjectileImpact(projectile,{HitPos=actor:GetShootPos()})
 assert(next(applied)==nil,'A second impact callback must not repeat damage')
end
assert(#E.BombTypes==17)
for _,id in ipairs(E.BombTypes) do
 local def=E.Definitions[id];assert(def.throwable and def.effect=='magic_bomb' and not def.drinkable)
 applied={};F:DetonateThrowable(actor,Vector(30,0,64),def)
 assert(applied[front] and not applied[above],id..' area/cover')
 local tags=F:_DamageContext({element=def.element,rider=def.status=='intimidated' and 'morale' or def.status})
 if def.status=='intimidated' then assert(tags.forceMorale)
 elseif def.status then assert(tags.riderStatusId==def.status and S.Registry[def.status]) end
end
F._ApplyDamage=apply
-- Real final getters populate a compact, grouped sheet, not a wall of zero rows.
dofile(root..'sv_sheet_director.lua')
local d=state.derivedStats;d.quantumCostMultiplier=.5;d.healthRegenCeilingFraction=.33
-- Deliberately use a non-unit CON factor to catch base-rate-only displays.
d.healthRegenBaseMaxHPPerSecond=.01;d.conRegenMultiplier=1.5
local rows=LOD.SheetDirector:Rows(actor);local by={}
for _,row in ipairs(rows) do by[row.label]=row.value end
assert(by['Offensive cost multiplier']=='50.0%')
assert(by['Health regeneration']=='1.50 HP/s' and by['Health regeneration cap']=='33.0%')
assert(not by['Haste'] and not by['Current speed multiplier']);assert(#rows<30)
-- Watermelon is selected/granted by the canonical progression, then cast through
-- the actual resource transaction and projectile setup. Only engine entities are doubled.
local P=LOD.MagicProgression
assert(P:GrantForm(state,'watermelon') and P:SelectForm(state,'watermelon'))
state.selectedMagicContentId=nil
assert(LOD.RPG.MagicForms.watermelon.damageDice==2 and LOD.RPG.MagicForms.watermelon.magicCost==24)
local projectile
function V:Angle() return {p=0,y=0,r=0} end
ents=ents or {}
local oldCreate=ents.Create
ents.Create=function(class)
 assert(class=='lod_magic_projectile')
 projectile={valid=true,SetPos=function(self,v) self.pos=v end,SetAngles=function() end,
 Spawn=function(self) self.spawned=true end,Activate=function() end,Remove=function(self) self.valid=false end}
 return projectile
end
LOD.Magic.NextCast={};LOD.Magic.Stats={casts=0}
LOD.Magic._Sync=function() end
actor.ps.magic=100;LOD.Magic.NextCast[actor]=nil
assert(F:CastSelected(actor))
assert(actor.ps.magic==88,'Resolved 50% cost modifier applies to the new Form')
assert(projectile.LODFormId=='watermelon' and projectile.LODCaster==actor and projectile.spawned)
assert(projectile.LODSpeed==580 and projectile.LODMaximumTravel==4000 and projectile.LODBlastRadius>=72)
assert(not F:CastSelected(actor),'Shared cast cooldown applies')
LOD.Magic.NextCast[actor]=nil;actor.ps.magic=0
assert(not F:CastSelected(actor) and actor.ps.magic==0,'Cannot cast without Magic')
ents.Create=oldCreate
-- Finite summon puff is above its origin, bounded, and self-retires even without its summon.
local now=0;CurTime=function() return now end;Material=function() return {} end;EFFECT={}
dofile('gamemodes/legend_of_deborah/entities/effects/lod_summon_puff/init.lua')
local puff=setmetatable({SetPos=function() end,SetRenderBounds=function() end},{__index=EFFECT})
puff:Init({GetOrigin=function() return Vector(0,0,18) end,GetScale=function() return 1 end})
assert(puff:Think());now=.71;assert(not puff:Think())
print('INTEGRATED_REFRESH_PASS: all remedy statuses; owned Haste input/cap/network/removal; Cone angular/vertical cover; Bomb/Missile/17 throwable areas; final derived sheet; finite summon puff')
