LOD = LOD or {}
LOD.HeroesOfLegend = LOD.HeroesOfLegend or {}

local Heroes = LOD.HeroesOfLegend
Heroes.Entries = Heroes.Entries or {}

if CLIENT and net and net.Receive then
    net.Receive("LOD_HeroesOfLegend_Sync", function()
        local entries = net.ReadTable and net.ReadTable() or nil
        if type(entries) == "table" then
            Heroes.Entries = entries
            if Heroes.SortEntries then
                Heroes:SortEntries(Heroes.Entries)
            end
        end
    end)
end
