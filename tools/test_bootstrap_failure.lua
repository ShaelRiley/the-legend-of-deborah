-- Exercise the production bootstrap's exception and partial-state boundary.
local hooks, commands, timers = {}, {}, {}
local errors, calls, fail = {}, 0, true
local human = {valid=true}
LOD={RunManager={State={}}}
function IsValid(v) return type(v)=='table' and v.valid==true end
function ErrorNoHalt(s) errors[#errors+1]=s end
game={GetMap=function() return 'gm_flatgrass' end}
player={GetAll=function() return {human} end}
hook={Add=function(e,n,f) hooks[e]=f end}
timer={Simple=function(_,f) timers.load=f end, Create=function(n,_,_,f) timers[n]=f end,
 Remove=function(n) timers[n]=nil end}
concommand={Add=function(n,f) commands[n]=f end}
function LOD.RunManager:NewCampaign()
 calls=calls+1
 self.State={CampaignSeed=calls,BuildReady=false}
 if fail then error('injected build exception after seed assignment') end
 self.State.BuildReady=true
 return true
end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_campaign_bootstrap_reliability.lua')
local B=LOD.CampaignBootstrapReliability
local survived, ok = pcall(function() return B:Ensure('failure fixture',true) end)
assert(survived and not ok,'bootstrap exception escaped recovery boundary')
assert(not B.InProgress and #errors==1,'failed recovery left a permanent latch')
assert(B.LastError:find('injected build exception',1,true))
assert(not B:Ensure('automatic retry',true) and calls==1,'unbounded automatic retry')
fail=false
assert(B:Ensure('explicit retry',false) and calls==2,'partial seed suppressed explicit recovery')
assert(B.Recoveries==1 and not B.LastError and not B.InProgress)
assert(B:Ensure('already live',false) and calls==2,'live campaign rebuilt')

-- A normal false return after seed assignment has the same retry semantics.
LOD.RunManager.State={}
function LOD.RunManager:NewCampaign()
 calls=calls+1;self.State={CampaignSeed=calls,BuildReady=false}
 return false,'injected validation failure'
end
assert(not B:Ensure('returned failure',false))
assert(not B.InProgress and B.LastError=='injected validation failure')
local before=calls
assert(not B:Ensure('retry returned failure',false) and calls==before+1)
-- A replacement state owned by another lifecycle authority must not be rebuilt.
LOD.RunManager.State={CampaignSeed=999,BuildReady=true}
assert(B:Ensure('external recovery',false) and calls==before+1)
print('PASS bootstrap exceptions, partial seed retry, bounded automatic recovery and live-state preservation')
