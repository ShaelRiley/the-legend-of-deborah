-- First-hit contact and native movement wiring, not direct resolver-only tests.
local env=dofile('tools/test_heavy_plumber.lua')
local E,p,enemy=env.equipment,env.player,env.enemy
function p:WaterLevel() return 0 end
local callbacks={}
local baseAdd=hook.Add
hook.Add=function(event,id,fn) callbacks[id]=fn;if baseAdd then baseAdd(event,id,fn) end end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_equipment_stomp.lua')
-- Load the exact registered SetupMove callback, keeping other gate-D hooks out
-- of this bounded fixture. The authoritative callback itself is not reimplemented.
local file=assert(io.open('gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua'))
local text=file:read('*a');file:close()
local first=assert(text:find('hook.Add("SetupMove", "LOD_RPG_GateD_Movement", function',1,true))
local last=assert(text:find('\nend)',first,true))
assert(load('local AbilityRules=LOD.RPGAbilityRules\n'..text:sub(first,last+4)))()
local setup,finish=assert(callbacks.LOD_RPG_GateD_Movement),assert(callbacks.LOD_EquipmentStompContact)
local function movement(pos,velocity)
    local d=env.data(pos,velocity)
    function d:KeyDown() return false end
    for _,field in ipairs({'ForwardSpeed','SideSpeed','MaxSpeed','MaxClientSpeed'}) do
        d['Get'..field]=function(self) return self[field] or 0 end
        d['Set'..field]=function(self,v) self[field]=v end
    end
    return d
end
-- Native movement can first strike the top, then slide laterally/downward
-- before FinishMove. The actual trace impact, not the final origin, is contact.
env.reset()
setup(p,movement(p.position))
assert(E.StompFlights[p],'Ordinary grounded SetupMove must arm equipped boots')
p.airborne=true;p.ground=NULL;p.position=Vector(24,0,80)
local d=movement(p.position,Vector(500,0,-200));setup(p,d)
d.pos=Vector(36,0,70);d.velocity=Vector(500,0,0)
local oldTrace=util.TraceHull
util.TraceHull=function(q)
    local tr=oldTrace(q)
    if q.endpos.z<q.start.z then tr.HitPos=Vector(30,0,74);tr.Fraction=.5 end
    return tr
end
assert(finish(p,d)==nil,'FinishMove must not suppress native state application')
assert(enemy.hp<100 and d.velocity.z>0,
    'A first upward-normal top contact must stomp even after a small native post-contact slide')
assert(d.pos.x==36 and d.pos.z==70,'Stomp must not teleport to the earlier contact')
local hp=enemy.hp;finish(p,d);assert(enemy.hp==hp,'No replay of one FinishMove')
-- Missing/incorrect first-contact geometry cannot borrow the final top position.
for _,kind in ipairs({'missing','below','side','allsolid','startsolid'}) do
    env.reset();setup(p,movement(p.position));p.airborne=true;p.ground=NULL;p.position=Vector(0,0,80)
    d=movement(p.position,Vector(25,0,-200));setup(p,d);d.pos=Vector(0,0,74)
    util.TraceHull=function(q)
        local tr=oldTrace(q)
        if q.endpos.z<q.start.z then
            tr.HitPos=kind=='missing' and nil or Vector(0,0,kind=='below' and 68 or 74)
            if kind=='missing' then tr.HitPos=nil end
            if kind=='side' then tr.HitNormal=Vector(1,0,0) end
            tr.AllSolid=kind=='allsolid';tr.StartSolid=kind=='startsolid'
        end
        return tr
    end
    finish(p,d);assert(enemy.hp==100,kind)
end
-- A real contact consumes the flight even when an unsafe ceiling denies bounce.
env.reset();setup(p,movement(p.position));p.airborne=true;p.ground=NULL;p.position=Vector(0,0,80)
d=movement(p.position,Vector(25,0,-200));setup(p,d);d.pos=Vector(0,0,74)
util.TraceHull=function(q)
    local tr=oldTrace(q)
    if q.endpos.z>q.start.z then tr.StartSolid=true else tr.HitPos=Vector(0,0,74) end
    return tr
end
finish(p,d);assert(enemy.hp==100 and E.StompFlights[p].spent and d.velocity.z<0,'Unsafe ceiling: no damage, no bounce, consumed flight')
print('STOMP_CONTACT_PASS: actual movement hook wiring, first-impact geometry, no teleport/replay, malformed/side/solid contact rejection, unsafe-bounce consumption')
