-- Execute the real footstep hook and RNG with only native boundaries doubled.
-- --probe SOURCE TRACE compares published source without a candidate work bound.
-- --gate [SOURCE] also rejects the unchanged parent on actual field crossings.
local mode = arg[1] or '--gate'
local source = arg[2] or 'gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_variance.lua'
local tracePath = arg[3]
local trace, entities, registry, hooks = {}, {}, {}, {}
local recording = false
local counts = {lookups=0,writes=0,tables=0,types=0,positions=0,velocities=0,rolls=0}
local function number(n) return string.format('%.17g', n) end
local function value(v)
    if type(v)=='table' and v.x then return number(v.x)..','..number(v.y)..','..number(v.z) end
    if type(v)=='number' then return number(v) end
    if type(v)=='table' then return 'table' end
    return tostring(v)
end
local function note(...)
    local parts={...};for i,v in ipairs(parts) do parts[i]=value(v) end
    trace[#trace+1]=table.concat(parts,'|')
end
local function noop() end
local vector={};vector.__index=vector
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vector) end
function vector:Length2D()
    if self.onLength then self.onLength() end
    return math.sqrt(self.x*self.x+self.y*self.y)
end
function vector:Distance(v)
    if self.onDistance then self.onDistance() end
    return math.sqrt((self.x-v.x)^2+(self.y-v.y)^2+(self.z-v.z)^2)
end
function IsValid(e) return entities[e] and entities[e].valid~=false or false end
function isentity(e)
    if recording then counts.types=counts.types+1 end
    return entities[e] and entities[e].native~=false or false
end
local native={}
function native.GetTable(e)
    if recording then counts.tables=counts.tables+1 end
    local d=assert(entities[e]);if d.badTable=='nil' then return nil elseif d.badTable then return 17 end
    return d.fields
end
function FindMetaTable(name) return name=='Entity' and native or nil end
hook={Add=function(_,id,f)hooks[id]=f end}
concommand={Add=noop};scripted_ents={GetStored=function()return nil end}
timer={Exists=function()return false end,Create=noop}
LOD={Config={Encounter={InstanceVariance={}}},HostileRegistry={List=function()return registry end}}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_rng.lua')
local originalIsEntity,originalFind=isentity,FindMetaTable
local function loadHook(fallback)
    FindMetaTable=fallback=='no-meta' and function()return nil end or originalFind
    isentity=fallback=='no-type' and nil or originalIsEntity
    dofile(source)
    FindMetaTable,isentity=originalFind,originalIsEntity
    return assert(hooks.LOD_EnemyVariancePhysicalFootsteps)
end
local step=loadHook()
local function actor(id,options)
    options=options or {}
    local d={id=id,fields={},inherited={},valid=true,native=options.native,badTable=options.badTable,
        pos=Vector(),velocity=Vector(20,0,0)}
    local e=setmetatable({}, {
        __index=function(_,key)
            if recording then counts.lookups=counts.lookups+1 end
            local v=d.fields[key];if v~=nil then return v end
            return d.inherited[key]
        end,
        __newindex=function(_,key,v)
            if recording then counts.writes=counts.writes+1 end
            d.fields[key]=v;note('write',id,key,v)
        end})
    entities[e]=d
    d.inherited.GetTable=function()error('custom instance GetTable must not be used')end
    d.inherited.GetPos=function()
        if recording then counts.positions=counts.positions+1 end
        note('position',id,d.pos);if d.onPosition then d.onPosition() end;return d.pos
    end
    d.inherited.GetVelocity=function()
        if recording then counts.velocities=counts.velocities+1 end
        note('velocity',id,d.velocity);if d.onVelocity then d.onVelocity() end;return d.velocity
    end
    local rng=LOD.RNG.New(731+id)
    local float=rng.Float
    rng.Float=function(self,lo,hi)
        if recording then counts.rolls=counts.rolls+1 end
        local out=float(self,lo,hi);note('rng',id,lo,hi,out,self.state)
        if d.onRoll then d.onRoll() end
        return out
    end
    d.fields={LODStrideRNG=rng,LODStrideLastPos=Vector(),LODDead=false,LODActivated=true,
        LODStrideAccumDistance=0,LODStrideTargetDistance=52,LODStrideBaseDistance=52,
        LODStrideOrdinal=0}
    return e,d
end
local function swap(d,changes)
    local f={};for k,v in pairs(d.fields)do f[k]=v end
    for k,v in pairs(changes or {})do f[k]=v end
    d.fields=f;note('swap',d.id)
end
local function snapshot(d)
    local f=d.fields
    note('state',d.id,f.LODStrideLastPos or 'nil',f.LODStrideAccumDistance or 'nil',
        f.LODStrideTargetDistance or 'nil',f.LODStrideFactor or 'nil',
        f.LODStrideOrdinal or 'nil',f.LODStrideRNG and f.LODStrideRNG.state or 'nil')
end
local scenarios=0
local function run(label,options,prepare,after)
    scenarios=scenarios+1;note('scenario',label)
    local e,d=actor(scenarios,options);registry={e}
    if prepare then prepare(d,e) end
    step();snapshot(d)
    if after then after(d,e) end
    return e,d
end

-- Exact native thresholds, vertical travel, cap, missing defaults and one roll
-- per physical step (never a catch-up loop), across independent production RNGs.
for _,speed in ipairs({0,7.999999999999999,8,8.000000000000002,20})do
    for _,distance in ipairs({0,51.99999999999999,52,52.00000000000001,79.99999999999999,80,80.00000000000001,500})do
        for _,axis in ipairs({'x','y','z'})do
            run('boundary '..number(speed)..' '..number(distance)..' '..axis,nil,function(d)
                d.velocity=Vector(speed,0,0);d.pos[axis]=distance
            end,function(d)
                local expected=speed>8 and math.min(80,distance)>=52
                assert((d.fields.LODStrideOrdinal==1)==expected,'step/speed/cap threshold changed')
            end)
        end
    end
end
for _,state in ipairs({'dead','inactive','latched','leaping','no-last','no-rng','invalid','default-target','default-base','zero-target'})do
    run(state,nil,function(d)
        d.pos=Vector(100,0,0)
        if state=='dead' then d.fields.LODDead=true
        elseif state=='inactive' then d.fields.LODActivated=false
        elseif state=='latched' then d.fields.LODDeadcrabState='latched'
        elseif state=='leaping' then d.fields.LODDeadcrabState='leaping'
        elseif state=='no-last' then d.fields.LODStrideLastPos=nil
        elseif state=='no-rng' then d.fields.LODStrideRNG=nil
        elseif state=='invalid' then d.valid=false
        elseif state=='default-target' then d.fields.LODStrideTargetDistance=nil
        elseif state=='default-base' then d.fields.LODStrideTargetDistance=nil;d.fields.LODStrideBaseDistance=nil
        elseif state=='zero-target' then d.fields.LODStrideTargetDistance=0 end
    end)
end
for _,fallback in ipairs({'plain-actor','nil-table','bad-table','no-meta','no-type','inherited','false-owned'})do
    local options=fallback=='plain-actor' and {native=false}
        or fallback=='nil-table' and {badTable='nil'} or fallback=='bad-table' and {badTable='number'} or nil
    if fallback=='no-meta' or fallback=='no-type' then step=loadHook(fallback) end
    if fallback=='no-type' then isentity=nil end
    run(fallback,options,function(d)
        d.pos=Vector(52,0,0)
        if fallback=='inherited' then
            for _,key in ipairs({'LODStrideLastPos','LODDead','LODActivated','LODStrideTargetDistance','LODStrideBaseDistance'})do
                d.inherited[key]=d.fields[key];d.fields[key]=nil
            end
        elseif fallback=='false-owned' then
            d.inherited.LODDead=true;d.inherited.LODActivated=false
        end
    end,function(d)assert(d.fields.LODStrideOrdinal==1,'native/table/inheritance fallback changed')end)
    isentity=originalIsEntity
    step=loadHook()
end

for _,key in ipairs({'LODStrideLastPos','LODDead','LODActivated','LODStrideTargetDistance'})do
    run('custom inherited lookup '..key,nil,function(d)
        d.pos=Vector(60,0,0);local inherited=d.fields[key];d.fields[key]=nil
        setmetatable(d.inherited,{__index=function(_,name)
            if name==key then
                swap(d,{LODStrideAccumDistance=13,LODStrideTargetDistance=72,LODActivated=false})
                return inherited
            end
        end})
    end)
end

-- SetTable is a native supported operation: getters, vector overrides and RNG
-- callbacks can replace the table, change scalar inputs or revoke eligibility.
for _,where in ipairs({'position','velocity','length','distance','rng'})do
    run('table replacement '..where,nil,function(d)
        d.pos=Vector(60,0,0)
        local change=function()
            swap(d,{LODStrideAccumDistance=17,LODStrideTargetDistance=70,LODStrideBaseDistance=31,
                LODStrideOrdinal=4})
        end
        if where=='position' then d.onPosition=change
        elseif where=='velocity' then d.onVelocity=change
        elseif where=='length' then d.velocity.onLength=change
        elseif where=='distance' then d.pos.onDistance=change
        else d.onRoll=change end
    end)
end
for _,where in ipairs({'position','velocity','length','distance'})do
    for _,flag in ipairs({'LODDead','LODActivated','LODDeadcrabState'})do
        run('live eligibility '..where..' '..flag,nil,function(d)
            d.pos=Vector(80,0,0)
            local mutate=function()
                local v='latched';if flag=='LODDead' then v=true elseif flag=='LODActivated' then v=false end
                swap(d,{[flag]=v})
            end
            if where=='position' then d.onPosition=mutate
            elseif where=='velocity' then d.onVelocity=mutate
            elseif where=='length' then d.velocity.onLength=mutate
            else d.pos.onDistance=mutate end
        end)
    end
end

-- The same entity crosses activation/death/transmission/refresh boundaries.
local e,d=run('same entity lifecycle',nil,function(x)x.pos=Vector(12,0,0)end)
for tick=1,60 do
    d.pos=Vector(tick*19,tick%3,0);d.valid=tick%11~=0
    d.fields.LODActivated=tick%7~=0;d.fields.LODDead=tick%13==0
    d.fields.LODDeadcrabState=tick%5==0 and 'latched' or nil
    if tick%9==0 then swap(d) end
    if tick%10==0 then step=loadHook() end
    registry=tick%17==0 and {} or {e}
    note('lifecycle',tick);step();snapshot(d)
end

-- Work bound measures actual entity lookup plus every new native table/type
-- query; GetPos/GetVelocity, writes and RNG remain observable in both traces.
registry={};local actors={}
for id=1,58 do
    local a,x=actor(1000+id);x.pos=Vector(id*120,0,0)
    x.fields.LODStrideLastPos=Vector(id*120,0,0)
    actors[id]=x;registry[id]=a
end
for k in pairs(counts)do counts[k]=0 end
recording=true
for tick=1,240 do
    for id,x in ipairs(actors)do x.pos=Vector(id*120+tick*4,0,0)end
    note('work tick',tick);step()
    for _,x in ipairs(actors)do snapshot(x)end
end
recording=false
local ticks=58*240
assert(counts.positions==ticks and counts.velocities==ticks,'native movement polling changed')
local crossings=counts.lookups+counts.tables+counts.types
if tracePath then
    local f=assert(io.open(tracePath,'w'));f:write(table.concat(trace,'\n'),'\n');f:close()
end
print(string.format('STRIDE_WORK scenarios=%d ticks=%d lookups=%d writes=%d tables=%d types=%d crossings=%d positions=%d velocities=%d rolls=%d trace_lines=%d',
    scenarios,ticks,counts.lookups,counts.writes,counts.tables,counts.types,crossings,
    counts.positions,counts.velocities,counts.rolls,#trace))
if mode~='--probe' then assert(crossings<=ticks*9,'unchanged native field work exceeds the footstep gate') end
print('STRIDE_WORK_PASS: exact boundaries, physical cadence/RNG, live callbacks/table replacement, inherited/legacy fallbacks and lifecycle')
