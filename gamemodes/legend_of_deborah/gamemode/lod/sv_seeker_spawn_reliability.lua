LOD = LOD or {}
LOD.SeekerSpawnReliability = LOD.SeekerSpawnReliability or {}

local Reliability = LOD.SeekerSpawnReliability
local Registry = LOD.HostileRegistry
local Motion = LOD.HostileMotionV2

if not Registry or not Motion then return end

Reliability.registered = Reliability.registered or 0
Reliability.snapped = Reliability.snapped or 0

local function ensureSeeker(hostile)
    if not IsValid(hostile) or hostile:GetClass() ~= "lod_hostile"
        or hostile.LODArchetypeId ~= "seeker"
    then
        return false
    end

    -- The Seeker's 20 Hz charge/retreat service deliberately iterates the shared
    -- hostile registry rather than performing its own global entity scan. Generic
    -- OnEntityCreated tracking normally catches every hostile, but test/encounter
    -- code assigns the Seeker archetype around spawn initialization. Enroll the
    -- fully initialized entity explicitly so timing can never make a Seeker exist
    -- in the world without being serviced by its special state machine.
    local alreadyTracked = Registry.set and Registry.set[hostile] == true
    Registry:Track(hostile)
    if not alreadyTracked and Registry.set and Registry.set[hostile] then
        Reliability.registered = (Reliability.registered or 0) + 1
    end

    hostile:SetNW2Bool("LOD_Seeker", true)
    hostile:SetNW2String("LOD_Archetype", "seeker")
    return true
end

local function installInitializeGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODSeekerSpawnReliabilityInstalled then return false end

    class.LODSeekerSpawnReliabilityInstalled = true
    local baseInitialize = class.Initialize

    function class:Initialize()
        baseInitialize(self)
        if not IsValid(self) or self.LODDead then return end
        ensureSeeker(self)
    end
    return true
end

installInitializeGuard()
hook.Add("OnEntityCreated", "LOD_SeekerSpawnReliabilityInstall", function(ent)
    if IsValid(ent) and ent:GetClass() == "lod_hostile" then
        installInitializeGuard()
    end
end)

-- Developer status remains manual/on-demand; there is no recurring audit scan.
concommand.Add("lod_seeker_spawn_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local live = 0
    local tracked = 0
    for _, hostile in ipairs(Registry:List()) do
        if IsValid(hostile) and hostile.LODArchetypeId == "seeker" and not hostile.LODDead then
            live = live + 1
            if Registry.set and Registry.set[hostile] then tracked = tracked + 1 end
        end
    end

    local line = string.format(
        "live=%d tracked=%d explicitRegistrations=%d result=%s",
        live, tracked, Reliability.registered or 0,
        (live > 0 and tracked == live) and "PASS" or "WAITING"
    )
    print("[LOD:SEEKER-SPAWN] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
