-- Production hostile death/scheduler with native mutation boundaries mocked.
-- This verifies Lua lifecycle safety, not a reproduction of a Source crash.
local now, insideDamage, nextId = 0, false, 0
local timers, hooks, stages = {}, {}, {}
local function noop() end
function AddCSLuaFile() end
function include() end
function CurTime() return now end
function IsValid(v) return type(v) == 'table' and v.valid ~= false end
function Vector(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
vector_origin = Vector()
NULL = {valid=false}
ACT_DIESIMPLE, ACT_IDLE, COLLISION_GROUP_DEBRIS, SOLID_NONE, MOVETYPE_NONE = 1,2,3,4,5
timer = {
    Create=function(id,delay,reps,fn) timers[id]={delay=delay,fn=fn} end,
    Exists=function(id) return timers[id] ~= nil end,
    Adjust=function(id,delay) assert(timers[id]);timers[id].delay=delay end,
    Remove=function(id) timers[id]=nil end,
    Simple=function() error('death must use the shared scheduler') end
}
concommand = {Add=noop}
hook = {Run=function(id,...) if hooks[id] then return hooks[id](...) end end}
LOD = {RunManager={State={LevelSeed=123}}, RPGTestLog={Write=function(_,event,fields)
    assert(event=='HOSTILE_DEATH_STAGE')
    stages[#stages+1]=fields
end}}
ENT = {}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local D = LOD.HostileDeathPresentation
local encounters, credits, drops, pulses, notes = 0,0,0,0,0
local attacker, inflictor = {}, {}
local damageLive = true
local damage = {
    GetAttacker=function() assert(damageLive, 'retained native damage userdata');return attacker end,
    GetInflictor=function() assert(damageLive, 'retained native damage userdata');return inflictor end
}
LOD.EncounterDirector = {OnHostileKilled=function(_,hostile,dmg)
    assert(insideDamage and hostile.LODDead and dmg==damage)
    encounters=encounters+1
    hostile:OnKilled(dmg) -- an extension re-enters death: must not settle twice
end}
hooks.OnNPCKilled=function(hostile,a,i)
    assert(insideDamage and hostile.LODDead and a==attacker and i==inflictor)
    credits=credits+1
end
hooks.LOD_HostileDeathApplyPose=function(hostile)
    assert(not insideDamage)
    hostile.poseCount=(hostile.poseCount or 0)+1
end
hooks.LOD_HostileDeathBlinkPulse=function() pulses=pulses+1 end
hooks.LOD_HostileDeathConvertNote=function() notes=notes+1 end
local function actor()
    nextId=nextId+1
    local h=setmetatable({id=nextId,LODHostile=true,LODArchetypeId='soldier',
        LODActivated=true,LODTarget=attacker,LODWaypoints={1},LODSoldierBurst={}, mutations=0}, {__index=ENT})
    function h:EntIndex() return self.id end
    function h:Health() return 0 end
    function h:WorldSpaceCenter() return vector_origin end
    local function native(self)
        assert(not insideDamage, 'native corpse mutation inside death callback')
        self.mutations=self.mutations+1
    end
    h.SetNW2Bool=native;h.SetNW2Entity=native;h.SetVelocity=native
    h.SetCollisionGroup=native;h.SetSolid=native;h.SetMoveType=native
    h.DrawShadow=native;h.StartActivity=native;h.SetPlaybackRate=native
    h.loco={SetDesiredSpeed=function() native(h) end}
    h.LODWeaponVisual={Remove=function(self) native(h);self.valid=false end}
    function h:SetNoDraw(v) native(self);self.noDraw=v end
    function h:GetNoDraw() return self.noDraw end
    function h:Remove() native(self);self.valid=false end
    function h:_SpawnPlaceholderLoot()
        assert(not insideDamage)
        if self.LODDeathLevelSeed==LOD.RunManager.State.LevelSeed then drops=drops+1 end
    end
    return h
end
local function kill(h)
    insideDamage=true;damageLive=true
    h:OnKilled(damage)
    insideDamage=false;damageLive=false
    assert(h.LODDead and not h.LODActivated and not h.LODTarget and not h.LODSoldierBurst)
    assert(h.mutations==0, 'corpse changed before the native stack returned')
end
local function tick(delta)
    now=now+delta
    local t=timers.LOD_HostileDeathPresentationShared
    if t then t.fn() end
end
local a=actor()
kill(a)
assert(encounters==1 and credits==1 and #D.Pending==1 and #D.Active==0)
assert(stages[1].stage=='callback_enter' and stages[3].stage=='kill_hooks_complete')
tick(.01)
assert(a.LODDeathPresentationStarted and a.mutations>0 and a.poseCount==1)
assert(#D.Pending==0 and #D.Active==1 and D.TotalDeaths==1)
a:OnKilled(damage);a:_BeginDeathPresentation()
assert(credits==1 and D.TotalDeaths==1 and a.poseCount==1)
tick(1.3)
assert(not IsValid(a) and drops==1 and pulses==4 and notes==3)
assert(#D.Active==0 and not timers.LOD_HostileDeathPresentationShared)
assert(stages[#stages].stage=='loot_complete')

-- Entity removed between death and presentation is safely discarded.
local removed=actor();kill(removed);removed:Remove();tick(.01)
assert(#D.Pending==0 and #D.Active==0 and not timers.LOD_HostileDeathPresentationShared)
assert(drops==1 and D.TotalDeaths==1)

-- Many simultaneous deaths share one timer and keep their original level seed.
local batch={}
for i=1,20 do batch[i]=actor();kill(batch[i]) end
assert(#D.Pending==20 and D.SharedTimerStarts==3)
LOD.RunManager.State.LevelSeed=456
tick(.01)
assert(#D.Active==20 and D.SharedTimerStarts==3)
for _,h in ipairs(batch) do assert(h.LODDeathLevelSeed==123 and h.poseCount==1) end
tick(1.3)
for _,h in ipairs(batch) do assert(not IsValid(h)) end
assert(#D.Active==0 and #D.Pending==0 and not timers.LOD_HostileDeathPresentationShared)
assert(drops==1 and credits==22 and encounters==22)
print('HOSTILE_DEATH_HANDOFF_PASS: deferred native mutations, single settlement, corpse lifecycle, removed entities, shared batching, stale level isolation')
