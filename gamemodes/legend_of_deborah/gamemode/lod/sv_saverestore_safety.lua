LOD = LOD or {}
LOD.SaveRestoreSafety = LOD.SaveRestoreSafety or {}

local Safety = LOD.SaveRestoreSafety

-- The Source save system serializes every scripted entity's Lua table. NextBot
-- runtime state necessarily contains unsupported userdata (NextBot,
-- CLuaLocomotion) and a behaviour coroutine, which produces one warning per
-- field per hostile during any engine save. Deborah runs are procedural and do
-- not support Source quicksave restoration, so persist an empty Lua table for
-- transient combat entities while leaving every unrelated entity untouched.
local TRANSIENT_COMBAT_CLASS = {
    lod_hostile = true,
    lod_soldier_bolt = true,
    lod_bio_bolt = true
}

if saverestore and saverestore.SaveEntity and not Safety.Installed then
    Safety.Installed = true
    Safety.BaseSaveEntity = saverestore.SaveEntity

    function saverestore.SaveEntity(ent, save)
        if IsValid(ent) and TRANSIENT_COMBAT_CLASS[ent:GetClass()] then
            save:StartBlock("EntityTable")
            saverestore.WriteTable({}, save)
            save:EndBlock()
            return
        end

        return Safety.BaseSaveEntity(ent, save)
    end
end

concommand.Add("lod_saverestore_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local counts = {}
    for class in pairs(TRANSIENT_COMBAT_CLASS) do
        counts[#counts + 1] = class .. "=" .. #ents.FindByClass(class)
    end
    table.sort(counts)

    local text = string.format("installed=%s transient={%s}",
        tostring(Safety.Installed == true), table.concat(counts, ", "))
    print("[LOD:SAVERESTORE] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end)
