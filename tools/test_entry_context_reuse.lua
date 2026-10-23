-- Exercise real admission/lifecycle work; operation counts are not FPS evidence.
local oldarg=arg[1];arg[1]='--runtime'
local H=dofile('tools/test_bestiary_b29.lua');arg[1]=oldarg
-- Supply the native C-clock metadata missing from this table-only engine fixture.
local originalInfo=debug.getinfo
local fixtureClock=CurTime
debug.getinfo=function(f,...)if f==fixtureClock then return {what='C'}end;return originalInfo(f,...)end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_entry_safety.lua')
debug.getinfo=originalInfo
local S,R,g=H.S,H.X.R,H.graph
local service,context,claim=S.Service,S.Context,S.Claim
local originalTime=CurTime
local cases,checks=0,0
local function expect(v,message)checks=checks+1;assert(v,message)end
local function setup()
    CurTime=originalTime;H.time(50000)
    S.Service,S.Context,S.Claim=service,context,claim
    setmetatable(S,nil);setmetatable(R,nil);setmetatable(LOD,nil)
    R.State={Graph=g,Level=1,LevelSeed=7123,CampaignEpoch=2,RunId=3,BuildReady=true,PlayerState={}}
    LOD.RunManager=R;LOD.FactionManager.LivingTargets=function()return {}end
    H.X.T.setHeroes({});S:Reset();S:Context();S.NextService=50001
    local e=H.actor('entry-reuse',24,true,'shambler')
    return e,S.Owner
end
local function run(e)
    local counts={service=0,context=0,claim=0}
    local oldHook,oldMask,oldCount=debug.gethook()
    debug.sethook(function(event)
        if event~='call' and event~='tail call' then return end
        local f=debug.getinfo(2,'f').func
        if f==service then counts.service=counts.service+1
        elseif f==context then counts.context=counts.context+1
        elseif f==claim then counts.claim=counts.claim+1 end
    end,'c')
    local ok,value=pcall(S.BeforeAI,S,e)
    if oldHook then debug.sethook(oldHook,oldMask,oldCount)else debug.sethook()end
    expect(ok,value);expect(value==false,'ordinary distant actor suppressed')
    cases=cases+1;return counts
end
local e=setup();local c=run(e)
expect(c.service==1 and c.context==2 and c.claim==0,'already-serviced native admission repeated service/context')
local customCalls=0
e=setup();S.Service=function(self)customCalls=customCalls+1;return service(self)end;c=run(e)
expect(customCalls==2 and c.claim==1,'custom service was skipped')
e=setup();S.Context=function(self)customCalls=customCalls+1;return context(self)end;c=run(e)
expect(c.service==2 and c.claim==1,'custom context was skipped')
e=setup();S.Claim=function(self,a)customCalls=customCalls+1;return claim(self,a)end;c=run(e)
expect(c.service==2 and c.claim==1,'custom claim was skipped')
e=setup();CurTime=function()return originalTime()end;c=run(e)
expect(c.service==2 and c.claim==1,'custom clock bypassed ordinary service')
for _,kind in ipairs({'state','graph','seed','level','epoch','run','owner','deadline'})do
    local owner;e,owner=setup();local getPos=e.GetPos;local changed=false
    e.GetPos=function(self)
        if not changed then
            changed=true
            if kind=='state' then local replacement={};for k,v in pairs(R.State)do replacement[k]=v end;R.State=replacement
            elseif kind=='graph' then local replacement={};for k,v in pairs(g)do replacement[k]=v end;R.State.Graph=replacement
            elseif kind=='seed' then R.State.LevelSeed=R.State.LevelSeed+1
            elseif kind=='level' then R.State.Level=R.State.Level+1
            elseif kind=='epoch' then R.State.CampaignEpoch=R.State.CampaignEpoch+1
            elseif kind=='run' then R.State.RunId=R.State.RunId+1
            elseif kind=='owner' then S.Owner=nil
            else H.time(50002)end
        end
        return getPos(self)
    end
    c=run(e)
    expect(c.service==2 and c.claim==1,kind..' mutation reused stale service')
    if kind~='deadline' then expect(S.Owner~=owner,kind..' mutation kept old owner')
    else expect(S.NextService>CurTime(),'expired service did not run')end
end
for _,object in ipairs({'system','manager','state','graph','owner','global'})do
    e=setup();local t=object=='system'and S or object=='manager'and R or object=='state'and R.State
        or object=='graph'and g or object=='owner'and S.Owner or LOD
    setmetatable(t,{__index=function()return nil end});c=run(e);setmetatable(t,nil)
    expect(c.service==2 and c.claim==1,'metatable-backed '..object..' did not fall back')
end
e=setup();local inheritedReads=0;S.Claim=nil
setmetatable(S,{__index=function(_,k)if k=='Claim'then inheritedReads=inheritedReads+1;return claim end end})
c=run(e);setmetatable(S,nil);S.Claim=claim
expect(inheritedReads==1 and c.claim==1,'inherited claim callback was read more than once')
CurTime=originalTime
-- A Lua clock already installed when the module loads must never qualify.
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_entry_safety.lua')
service,context,claim=S.Service,S.Context,S.Claim
e=setup();c=run(e)
expect(c.service==2 and c.context==4 and c.claim==1,'preexisting Lua clock used native shortcut')
print('ENTRY_CONTEXT_REUSE_PASS '..cases..' cases '..checks..' assertions; native service reuse, custom providers, clock/deadline and same-seed owner/state/graph mutations; no FPS inference')
