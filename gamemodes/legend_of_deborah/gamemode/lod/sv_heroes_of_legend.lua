LOD = LOD or {}
LOD.HeroesOfLegend = LOD.HeroesOfLegend or {}

local Heroes = LOD.HeroesOfLegend
Heroes.DATA_PATH = "the_legend_of_deborah/heroes_of_legend.json"
Heroes.Entries = Heroes.Entries or {}
Heroes.ProcessedRunIds = Heroes.ProcessedRunIds or {}
Heroes.NextCompletionOrder = Heroes.NextCompletionOrder or 1

if SERVER and util and util.AddNetworkString then
    util.AddNetworkString("LOD_HeroesOfLegend_Sync")
end

function Heroes:Initialize()
    self.Entries = {}
    self.ProcessedRunIds = {}
    self.NextCompletionOrder = 1
    self:Load()
end

function Heroes:Load()
    self.Entries = {}
    self.ProcessedRunIds = {}
    self.NextCompletionOrder = 1
    if not file or not file.Exists then return end
    if not file.Exists(self.DATA_PATH, "DATA") then return end

    local jsonStr = file.Read(self.DATA_PATH, "DATA")
    if not jsonStr or jsonStr == "" then return end

    local data = util and util.JSONToTable and util.JSONToTable(jsonStr) or nil
    if not data or type(data) ~= "table" then return end

    local rawEntries = data.entries
    local maxSeq = 0
    if type(rawEntries) == "table" then
        for _, entry in ipairs(rawEntries) do
            if self:IsValidEntry(entry) then
                table.insert(self.Entries, entry)
                self.ProcessedRunIds[entry.runId] = true
                if entry.completionOrder > maxSeq then
                    maxSeq = entry.completionOrder
                end
            end
        end
    end

    self:SortEntries(self.Entries)
    self:_Truncate()

    local savedSeq = math.floor(tonumber(data.nextCompletionOrder) or 1)
    self.NextCompletionOrder = math.max(1, math.max(savedSeq, maxSeq + 1))
end

function Heroes:Save()
    if not file or not file.Write then return end
    if file.CreateDir then
        file.CreateDir("the_legend_of_deborah")
    end
    local payload = {
        nextCompletionOrder = self.NextCompletionOrder,
        entries = self.Entries
    }
    local jsonStr = util and util.TableToJSON and util.TableToJSON(payload, true) or ""
    file.Write(self.DATA_PATH, jsonStr)
end

function Heroes:_Truncate()
    while #self.Entries > self.MAX_ENTRIES do
        table.remove(self.Entries)
    end
end

function Heroes:SubmitRun(runData)
    if not runData or type(runData) ~= "table" then return nil end
    if not runData.runId or type(runData.runId) ~= "string" or runData.runId == "" then return nil end

    local rescues = tonumber(runData.rescueCount)
    if not rescues or rescues < 0 or math.floor(rescues) ~= rescues then return nil end

    if type(runData.partyMembers) ~= "table" or #runData.partyMembers == 0 then return nil end
    for _, member in ipairs(runData.partyMembers) do
        if type(member) ~= "string" or member == "" then return nil end
    end

    local runIdStr = tostring(runData.runId)

    -- BLOCKER 4 & BLOCKER 3: If runId was already processed, record is IMMUTABLE. Idempotent NO-OP!
    if self.ProcessedRunIds[runIdStr] then
        for _, entry in ipairs(self.Entries) do
            if entry.runId == runIdStr then return entry end
        end
        return nil
    end

    self.ProcessedRunIds[runIdStr] = true

    -- BLOCKER 3: Deep copy partyMembers array so external caller table mutation does not alter stored record
    local partyMembersCopy = {}
    for i, member in ipairs(runData.partyMembers) do
        partyMembersCopy[i] = tostring(member)
    end

    self.NextCompletionOrder = math.max(1, math.floor(tonumber(self.NextCompletionOrder) or 1))

    local newEntry = {
        runId = runIdStr,
        rescueCount = rescues,
        highestLevel = math.max(1,math.floor(tonumber(runData.highestLevel) or rescues+1)),
        cashRecovered = math.max(0,math.floor(tonumber(runData.cashRecovered) or 0)),
        partyMembers = partyMembersCopy,
        completionOrder = self.NextCompletionOrder,
        timestamp = os and os.time and os.time() or 0
    }

    self.NextCompletionOrder = self.NextCompletionOrder + 1
    table.insert(self.Entries, newEntry)

    self:SortEntries(self.Entries)
    self:_Truncate()

    self:Save()
    self:SyncAll()

    return newEntry
end

function Heroes:LiveSnapshot()
    local entries=table.Copy(self.Entries)
    local run=LOD.RunManager;local state=run and run.State
    if state and state.Ranked and state.RunId and not state.Finalized and not state.Failed then
        local party={};local identities={}
        for id in pairs(state.PlayedIdentities or {}) do identities[#identities+1]=id end
        table.sort(identities)
        for _,id in ipairs(identities) do
            local ps=state.PlayerState[id]
            if ps then party[#party+1]=LOD.CharacterProgressionSystem:PlayerCharacterText(ps) end
        end
        if #party>0 then
            for i=#entries,1,-1 do if entries[i].runId==state.RunId then table.remove(entries,i) end end
            entries[#entries+1]={runId=state.RunId,rescueCount=state.RescueCount or 0,
                highestLevel=state.HighestLevel or state.Level or 1,cashRecovered=state.CashRecovered or 0,
                partyMembers=party,completionOrder=self.NextCompletionOrder,inProgress=true}
        end
    end
    self:SortEntries(entries)
    while #entries>self.MAX_ENTRIES do table.remove(entries) end
    return entries
end

function Heroes:SyncAll(ply)
    if not SERVER or not net or not net.Start then return end
    net.Start("LOD_HeroesOfLegend_Sync")
    if net.WriteTable then
        net.WriteTable(self:LiveSnapshot())
    end
    if ply then
        if net.Send then net.Send(ply) end
    else
        if net.Broadcast then net.Broadcast() end
    end
end

if SERVER and hook and hook.Add then
    hook.Add("Initialize", "LOD_HeroesOfLegend_Init", function()
        Heroes:Initialize()
    end)
    hook.Add("PlayerInitialSpawn", "LOD_HeroesOfLegend_SyncOnJoin", function(ply)
        Heroes:SyncAll(ply)
    end)
end

Heroes:Initialize()

local nextLive=0
hook.Add("Think","LOD_HeroesLiveSnapshot",function()
    if CurTime()<nextLive then return end
    nextLive=CurTime()+2
    local fingerprint=util.TableToJSON(Heroes:LiveSnapshot())
    if fingerprint~=Heroes.LiveFingerprint then Heroes.LiveFingerprint=fingerprint;Heroes:SyncAll() end
end)
