-- Actual close-defense and sanctuary authorities; only native entity lookup,
-- admission results and movement boundaries are doubled. Not hardware FPS.
local mode,parentDir,tracePath=arg[1],arg[2],arg[3]
local probe=mode=='--probe'
local external=probe or mode=='--gate'
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local trace={}
local function note(...) local a={...};for i,v in ipairs(a)do a[i]=tostring(v)end
    trace[#trace+1]=table.concat(a,'|') end
local closeReads,statusCalls=0,0
do
    local H=dofile('tools/test_bestiary_b7.lua')
    if external then dofile(parentDir..'/sv_enemy_melee.lua') end
    local E,Status=LOD.EnemyRoster,LOD.RPGStatusElements
    LOD.EntrySafety=nil
    local ids={};local recording=false
    local has=Status.Has
    Status.Has=function(self,e,id,...)
        if recording then statusCalls=statusCalls+1;note('status',ids[e],id) end
        return has(self,e,id,...)
    end
    local function actor(id)
        H.reset();H.at(10000)
        local data=H.actor(id);local e=setmetatable({}, {
            __index=function(_,k)
                if recording and type(k)=='string' and k:sub(1,3)=='LOD' then closeReads=closeReads+1 end
                return data[k]
            end,
            __newindex=function(_,k,v)data[k]=v end})
        ids[e]=id
        data._RefreshTarget=function(self) self.refreshes=(self.refreshes or 0)+1 end
        data.LODTarget=nil;data.LODNextCloseDefense=0;data.LODHitStunUntil=0
        if E.Definitions[id] then E:Prepare(e) end
        Status:BindActorLife(e)
        return e,data
    end
    -- Stable real life/status/context queries; no skipped status cleanup, time
    -- service, attack opportunities or target refresh in the candidate.
    for _,id in ipairs({'shambler','runner','bioblaster','arccaster','seeker','gaoler'})do
        local e,data=actor(id);assert(not E:TickCloseDefense(e))
        data.refreshes=0;recording=true
        for i=1,600 do note('tick',id,E:TickCloseDefense(e),data.refreshes or 0,data.LODRosterAttack~=nil) end
        recording=false
    end
    Status.Has=has
    -- A callback can change the archetype or pending attack. No field borrow
    -- crosses a status, ownership or Prepare callback boundary.
    for _,change in ipairs({'status archetype','status primary','prepare archetype','ownership archetype'})do
        local e,data=actor('arccaster');local prepare,live=E.Prepare,E.Live
        if change=='status archetype' or change=='status primary' then
            Status.Has=function(self,a,id,...)
                local present,entry=has(self,a,id,...)
                if a==e and id=='morale_flee' then
                    if change=='status archetype' then a.LODArchetypeId='runner'
                    else a.LODSoldierBurst={} end
                end
                return present,entry
            end
        elseif change=='prepare archetype' then
            E.Prepare=function(self,a)prepare(self,a);a.LODArchetypeId='runner'end
        else E.Live=function(self,r,s)local ok=live(self,r,s);data.LODArchetypeId='runner';return ok end end
        assert(not E:TickCloseDefense(e) and not data.refreshes and not data.LODRosterAttack,
            'stale close-defense field across '..change)
        note('callback',change,data.LODArchetypeId,data.LODSoldierBurst~=nil)
        Status.Has=has;E.Prepare,E.Live=prepare,live
    end
    -- Real Has clears an expired entry and exposes the callback's new primary
    -- commitment before the fallback can acquire a target.
    local e,data=actor('arccaster');local hookRun=hook.Run;local clears=0
    Status.Active[e]={intimidated={expiresAt=9999}}
    hook.Run=function(event,a,id,reason)
        if event=='LODStatusCleared' and a==e then clears=clears+1;a.LODSniperShot={} end
        return hookRun(event,a,id,reason)
    end
    assert(not E:TickCloseDefense(e) and clears==1 and not data.refreshes and data.LODSniperShot,
        'expired status cleanup/primary commitment changed')
    note('expired',clears,Status.Active[e]==nil,data.LODSniperShot~=nil)
    hook.Run=hookRun
end

local cellQueries,positionQueries,decisions=0,0,0
do
    local saved=arg[1];arg[1]='--runtime'
    local H=dofile('tools/test_bestiary_b29.lua');arg[1]=saved
    if external then dofile(parentDir..'/sv_entry_safety.lua') end
    local S=LOD.EntrySafety;local state,g=H.X.R.State,H.graph
    state.Graph=g;state.BuildReady=true;state.Failed=false;state.LevelCleared=false;state.SimulationFrozen=false
    S:Context()
    local exact,cancel=S.ExactCell,S.Cancel
    local admitted=H.actor('admitted',4)
    local result,limited,moveOnClaim,actor,events
    S.Service=function()events[#events+1]='service'end
    S.Claim=function()
        events[#events+1]='claim'
        if moveOnClaim then actor:SetPos(LOD.MazeNavigator:CellCenter(H.cell(2))+Vector(0,0,12)) end
        return result,limited
    end
    S.ExactCell=function(self,graph,p)cellQueries=cellQueries+1;return exact(self,graph,p)end
    S.Cancel=function(self,e)events[#events+1]='cancel';return cancel(self,e)end
    S.Withdraw=function()events[#events+1]='withdraw'end
    LOD.HostileMotionV2={Stop=function()events[#events+1]='stop'end}
    local function runCase(name,depth,target,isLimited,count)
        actor=H.actor('work-'..name,depth,true);result,limited=target,isLimited
        local getPos=actor.GetPos
        actor.GetPos=function(self)positionQueries=positionQueries+1;return getPos(self)end
        for i=1,count do
            events={}
            local answer=S:BeforeAI(actor);decisions=decisions+1
            note('admission',name,answer,table.concat(events,','),actor.LODEntrySuppressed==true,
                actor.LODEntryTarget==admitted,actor.LODEntryPermitUntil~=nil)
            if target then assert(not answer and actor.LODEntryTarget==admitted and actor.LODEntryPermitUntil)
            elseif isLimited or depth<=S.Config.Apron or moveOnClaim then
                assert(answer and actor.LODEntrySuppressed and not actor.LODEntryTarget)
            else assert(not answer and not actor.LODEntrySuppressed) end
        end
    end
    runCase('admitted',4,admitted,false,1000)
    runCase('admitted-limited',4,admitted,true,1000)
    runCase('denied',4,nil,true,1000)
    runCase('ordinary',24,nil,false,1000)
    runCase('apron',2,nil,false,1000)
    moveOnClaim=true;runCase('claim-move',24,nil,false,1);moveOnClaim=false
    -- Changed owner/run state must still be serviced and rejected immediately.
    state.SimulationFrozen=true;events={}
    assert(not S:BeforeAI(actor));note('frozen',table.concat(events,','))
    state.SimulationFrozen=false
    actor.LODDead=true;events={};assert(not S:BeforeAI(actor));note('dead',table.concat(events,','))
end
if not probe then
    assert(closeReads<=134400 and statusCalls==12000,'close defense repeats native Lua-field reads or skips status queries')
    assert(cellQueries==2001 and positionQueries==12003,'admission still performs unused cell/position queries')
end
if tracePath then local f=assert(io.open(tracePath,'w'));f:write(table.concat(trace,'\n'));f:close() end
print(string.format('ENEMY_AI_WORK_PASS close_lua_field_reads=%d status_queries=%d ticks=3600 admission_decisions=%d cell_queries=%d position_queries=%d trace_rows=%d; callback/expiry/primary/fresh-position/lifecycle parity; not native FPS',
    closeReads,statusCalls,decisions,cellQueries,positionQueries,#trace))
