LOD = LOD or {}
LOD.RPGKillerInstinct = LOD.RPGKillerInstinct or {}
local Killer = LOD.RPGKillerInstinct
local NET_TARGET = "LOD_RPGKillerInstinctTarget"
local HALO_COLOR = Color(255, 45, 45, 255)

net.Receive(NET_TARGET, function()
    local target = net.ReadEntity()
    Killer.Target = IsValid(target) and target or nil
end)

hook.Add("PreDrawHalos", "LOD_RPGKillerInstinctHalo", function()
    local target = Killer.Target
    if not IsValid(target) then
        Killer.Target = nil
        return
    end
    halo.Add({target}, HALO_COLOR, 2, 2, 1, true, false)
end)

hook.Add("EntityRemoved", "LOD_RPGKillerInstinctRemoved", function(ent)
    if Killer.Target == ent then Killer.Target = nil end
end)
