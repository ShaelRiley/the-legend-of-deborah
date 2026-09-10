if not SERVER then return end

-- Garry's Mod may not expose a method added to the stored scripted-entity table
-- through an already-instantiated NextBot's Lua lookup path. The Bio Blaster
-- wrapper calls _RunBioBlasterTick on the live entity, so bind the canonical
-- stored-class dispatcher onto each lod_hostile instance before its behaviour
-- coroutine gets a chance to run. This is a narrow runtime bridge only; the
-- authoritative implementation remains sv_bioblaster.lua.
local function bindBioDispatcher(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return false end

    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    local dispatch = class and class._RunBioBlasterTick
    if not isfunction(dispatch) then return false end

    if not isfunction(ent._RunBioBlasterTick) then
        ent._RunBioBlasterTick = dispatch
    end
    return true
end

hook.Add("OnEntityCreated", "LOD_BioBlasterInstanceDispatchBridge", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
    timer.Simple(0, function()
        if IsValid(ent) then bindBioDispatcher(ent) end
    end)
end)

-- Defensive coverage for any lod_hostile instance that already exists by the
-- time the map finishes initialization.
hook.Add("InitPostEntity", "LOD_BioBlasterInstanceDispatchBridgeExisting", function()
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        bindBioDispatcher(ent)
    end
end)

concommand.Add("lod_bioblaster_dispatch_bridge_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    local canonical = class and isfunction(class._RunBioBlasterTick) or false
    local live = 0
    local bridged = 0
    for _, ent in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(ent) and ent.LODArchetypeId == "bioblaster" then
            live = live + 1
            if isfunction(ent._RunBioBlasterTick) then bridged = bridged + 1 end
        end
    end

    local passed = canonical and (live == 0 or bridged == live)
    local line = string.format("canonical=%s live=%d bridged=%d result=%s",
        tostring(canonical), live, bridged, passed and "PASS" or "FAIL")
    print("[LOD:BIO-DISPATCH-BRIDGE] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
