-- Event settlement composes the existing wallet and detached Equipment authority.
-- Receipts belong to account/campaign/dungeon/archetype, never a layout or body.
LOD.EventTransactions = {}
local T, Run, E, Store = LOD.EventTransactions, assert(LOD.RunManager), assert(LOD.Equipment), assert(LOD.CryptoStore)
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
T.Equal=equal
function T.Key(instance,identity,label,shared)
    return 'event-expansion:'..tostring(instance.runId)..':'..tostring(instance.level)..':'
        ..instance.archetype..':'..tostring(label or 'claim')..':'..(shared and 'party' or identity)
end
function T.Claim(instance,identity,label,shared)
    return Store:Receipt(T.Key(instance,identity,label,shared))
end
function T.Seed(instance,identity,label)
    return LOD.Seeds.Derive(LOD.Seeds.DeriveLevel(Run.State.CampaignSeed,instance.level),
        'dungeon-events:'..instance.archetype..':'..tostring(label or 'reward')..':'..identity)
end
function T.Begin(director,instance,ply,identity,entity)
    local ps=Run:GetPlayerState(ply)
    entity=entity or instance.entities[1]
    if not Store:ValidAccount(identity) or not director:InteractionCurrent(instance,ply,identity,ps,entity) then
        return nil,'This event or Hero has changed.'
    end
    local original=E:Ensure(ps)
    local b={director=director,instance=instance,ply=ply,identity=identity,ps=ps,entity=entity,
        original=original,before=table.Copy(original),staged=table.Copy(original),
        life=ps.equipmentLifeSerial,spawn=ply.LODRunSpawnSerial,hero=ps.heroSerial,progression=ps.progressionState,
        run=Run.State,runId=Run.State.RunId,level=Run.State.Level,epoch=Run.State.CampaignEpoch,claim=instance.claims[identity]}
    function b.ownsHero()
        return IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:SteamID64()==identity
            and Run:GetPlayerState(ply)==ps and Run.State==b.run
            and Run.State.RunId==b.runId and Run.State.Level==b.level and Run.State.CampaignEpoch==b.epoch
            and ps.equipmentLifeSerial==b.life and ply.LODRunSpawnSerial==b.spawn
            and ps.heroSerial==b.hero and ps.progressionState==b.progression
    end
    function b.current()
        if not b.ownsHero() or not director:InteractionCurrent(instance,ply,identity,ps,entity) then return false end
        -- InteractionCurrent performs the native visibility trace. Its return
        -- cannot authorize a body or inventory replaced inside that callback.
        return b.ownsHero() and ps.equipment==original and equal(original,b.before)
            and instance.claims[identity]==b.claim and (not b.claim or b.claim.state=='resolving')
    end
    return b
end

-- psFields and extension callbacks may only assign run-owned Lua state. Native
-- effects use Provisional below; CryptoStore's participant stays callback-free.
function T.Commit(b,options)
    options=options or {}
    local debit,credit=options.debit or 0,options.credit or 0
    if debit<0 or credit<0 or debit%1~=0 or credit%1~=0 then return false,'Invalid event settlement.' end
    local fields={}
    for key,value in pairs(options.psFields or {}) do
        fields[#fields+1]={key=key,before=b.ps[key],after=value}
    end
    local function current()
        if not b.current() then return false,'This event or Hero has changed.' end
        if options.validate and not options.validate() then return false,'The offer changed. Review it again.' end
        if options.validate and not b.current() then return false,'This event or Hero has changed.' end
        for _,field in ipairs(fields) do if b.ps[field.key]~=field.before then return false,'Hero resources changed.' end end
        return true
    end
    local valid,reason=current();if not valid then return false,reason end
    local changed=not equal(b.staged,b.before)
    local event=T.Key(b.instance,b.identity,options.label,options.shared)
    local kind='dungeon_event_'..b.instance.archetype
    local ok,receipt=Store:Transaction(event,kind,{b.identity},function(accounts)
        local active,why=current();if not active then return false,why end
        if accounts[b.identity].balance<debit then return false,'Insufficient $DEB. Nothing spent.' end
        accounts[b.identity].balance=accounts[b.identity].balance-debit+credit
        local result=table.Copy(options.result or {})
        result.account=b.identity;result.debit=debit;result.credit=credit
        Store:History(b.identity,event,kind,result)
        return true,result
    end,{
        validate=current,
        apply=function()
            if changed then b.ps.equipment=b.staged end
            for _,field in ipairs(fields) do b.ps[field.key]=field.after end
            if options.apply then options.apply() end
        end,
        rollback=function()
            -- The same ps table can be recycled by death/respawn. Equal scalar
            -- values do not prove ownership of that replacement Hero's life.
            if not b.ownsHero() then return end
            if b.ps.equipment==b.staged then b.ps.equipment=b.original end
            for _,field in ipairs(fields) do if b.ps[field.key]==field.after then b.ps[field.key]=field.before end end
            if options.rollback then options.rollback() end
        end
    })
    if not ok then return false,receipt end
    -- A broken presentation callback cannot reopen a settled claim.
    if changed then pcall(E.Sync,E,b.ply) end
    if options.psFields and options.psFields.magic~=nil and LOD.Magic then pcall(LOD.Magic._Sync,LOD.Magic,b.ply,b.ps) end
    if options.psFields and options.psFields.lives~=nil then pcall(Run._SyncPlayerVars,Run,b.ply) end
    if LOD.CryptoDirector then pcall(LOD.CryptoDirector.Sync,LOD.CryptoDirector,b.ply) end
    return true,receipt
end

-- Small immediate native mutations are provisional until the durable receipt
-- commits. Each caller supplies exact-value/entry compensation; never undo a
-- replacement body, another effect, or a later unrelated resource mutation.
function T.Provisional(b,options,native)
    if not b.current() then return false,'This event or Hero has changed.' end
    local ran,accepted,reason=pcall(native.perform)
    if not ran or not accepted then
        pcall(native.rollback)
        return false,ran and reason or 'The service failed. Nothing spent.'
    end
    local prior=options.validate
    options.validate=function() return native.validate() and (not prior or prior()) end
    local settled,ok,result=pcall(T.Commit,b,options)
    if not settled or not ok then
        pcall(native.rollback)
        return false,settled and result or 'The service failed. Nothing spent.'
    end
    return true,result
end
