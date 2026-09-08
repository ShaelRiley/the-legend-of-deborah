-- Reproduce a copied entity table that has the wrapper but lacks its named helper.
local frame, genericTicks = 1, 0
local class = {
    Initialize = function(self) self.initialized = true end,
    _BehaviourTick = function() genericTicks = genericTicks + 1 end
}
LOD = {Config = {Encounter = {Archetypes = {}, Templates = {}}}}
scripted_ents = {GetStored = function() return {t = class} end}
hook = {Add = function() end}
concommand = {Add = function() end}
function FrameNumber() return frame end
function IsValid() return false end
ACT_RUN = 1
assert(loadfile('gamemodes/legend_of_deborah/gamemode/lod/sv_deadcrab.lua'))()
local crab = {LODArchetypeId = 'deadcrab', LODActivated = true, LODDeadcrabState = 'latched'}
assert(crab._RunDeadcrabTick == nil)
class._BehaviourTick(crab) -- previously crashes at self:_RunDeadcrabTick()
assert(genericTicks == 0 and crab.LODDeadcrabDispatchFrame == frame)
frame = frame + 1
crab.LODDeadcrabState = nil
class._BehaviourTick(crab)
assert(genericTicks == 1) -- no live target: ordinary routing still runs
frame = frame + 1
class._BehaviourTick({LODArchetypeId = 'soldier'})
assert(genericTicks == 2)
class.Initialize(crab)
assert(crab.initialized and crab._RunDeadcrabTick == class._RunDeadcrabTick)
frame = frame + 1
crab.LODDeadcrabState = 'latched'
assert(crab:_RunDeadcrabTick()) -- Motion V2 named dispatch remains available
assert(not crab:_RunDeadcrabTick()) -- same-frame guard preserved
frame = frame + 1
crab.LODActivated = false
assert(crab:_RunDeadcrabTick())
print('deadcrab_dispatch PASS: missing helper, generic fallback, non-Deadcrab, instance publication, Motion V2 dispatch and frame guard')
