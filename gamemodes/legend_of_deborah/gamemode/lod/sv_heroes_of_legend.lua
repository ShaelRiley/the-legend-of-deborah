LOD = LOD or {}
LOD.HeroesOfLegend = LOD.HeroesOfLegend or {}

local Heroes = LOD.HeroesOfLegend
Heroes.DATA_PATH = "the_legend_of_deborah/heroes_of_legend.json"
Heroes.Entries = Heroes.Entries or {}
Heroes.NextCompletionOrder = Heroes.NextCompletionOrder or 1

if SERVER and util and util.AddNetworkString then
    util.AddNetworkString("LOD_HeroesOfLegend_Sync")
end

function Heroes:Initialize()
    self.Entries = {}
    self.NextCompletionOrder = 1
    self:Load()
end

function Heroes:Load()
    if not file or not file.Exists then return end
    if not file.Exists(self.DATA_PATH, "DATA") then
        self.Entries = {}
        self.NextCompletionOrder = 1
        return
    end

    local jsonStr = file.Read(self.DATA_PATH, "DATA")
    if not jsonStr or jsonStr == "" then
        self.Entries = {}
        self.NextCompletionOrder = 1
        return
    end

    local data = util and util.JSONToTable and util.JSONToTable(jsonStr) or nil
    if not data or type(data) ~= "table" then
        self.Entries = {}
        self.NextCompletionOrder = 1
        return
    end

    self.Entries = data.entries or {}
    self:SortEntries(self.Entries)
    self:_Truncate()

    local maxSeq = 0
    for _, entry in ipairs(self.Entries) do
        local seq = tonumber(entry.completionOrder) or 0
        if seq > maxSeq then maxSeq = seq end
    end

    local savedSeq = tonumber(data.nextCompletionOrder) or 1
    self.NextCompletionOrder = math.max(savedSeq, maxSeq + 1)
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
    if not runData or not runData.runId then return nil end

    local runIdStr = tostring(runData.runId)
    local existingEntry = nil
    for _, entry in ipairs(self.Entries) do
        if tostring(entry.runId) == runIdStr then
            existingEntry = entry
            break
        end
    end

    if existingEntry then
        local newRescues = tonumber(runData.rescueCount) or 0
        if newRescues > (tonumber(existingEntry.rescueCount) or 0) then
            existingEntry.rescueCount = newRescues
        end
        if runData.partyMembers then
            existingEntry.partyMembers = runData.partyMembers
        end
        self:SortEntries(self.Entries)
        self:Save()
        self:SyncAll()
        return existingEntry
    end

    local newEntry = {
        runId = runIdStr,
        rescueCount = tonumber(runData.rescueCount) or 0,
        partyMembers = runData.partyMembers or {"Unknown Heroes"},
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

function Heroes:SyncAll(ply)
    if not SERVER or not net or not net.Start then return end
    net.Start("LOD_HeroesOfLegend_Sync")
    if net.WriteTable then
        net.WriteTable(self.Entries)
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
