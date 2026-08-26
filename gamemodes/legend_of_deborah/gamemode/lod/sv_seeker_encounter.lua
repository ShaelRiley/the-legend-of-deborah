LOD = LOD or {}

local EncounterDirector = LOD.EncounterDirector
local WanderingDirector = LOD.WanderingDirector
local EC = LOD.Config and LOD.Config.Encounter
local Navigator = LOD.MazeNavigator

if not EncounterDirector or not EC or not Navigator then return end

if not EncounterDirector.LODSeekerSpawnInstalled then
    EncounterDirector.LODSeekerSpawnInstalled = true
    local baseSpawnEncounter = EncounterDirector._SpawnEncounter

    function EncounterDirector:_SpawnEncounter(encounter)
        local seekerCount = encounter and encounter.composition and (encounter.composition.seeker or 0) or 0
        if seekerCount <= 0 then return baseSpawnEncounter(self, encounter) end
        if encounter.spawned or encounter.cleared then return true end

        local total = 0
        for _, count in pairs(encounter.composition or {}) do total = total + count end
        local reserve = WanderingDirector and WanderingDirector.GetDeficitReservation
            and WanderingDirector:GetDeficitReservation() or 0
        if self:GetActiveCount() + total + reserve > EC.ActiveHostileCeiling then return false end

        encounter.composition.seeker = nil
        local ok = baseSpawnEncounter(self, encounter)
        encounter.composition.seeker = seekerCount
        if not ok then return false end

        local center = Navigator:CellCenter(encounter.cell) + Vector(0, 0, 8)
        for index = 1, seekerCount do
            local ent = ents.Create("lod_hostile")
            if IsValid(ent) then
                ent.LODArchetypeId = "seeker"
                ent.LODHomeCellKey = encounter.cellKey
                ent.LODEncounterId = encounter.id
                ent.LODEncounterOrdinal = 700000 + encounter.id * 100 + index
                ent.LODActivated = true
                ent:SetPos(center + Vector((index - 1) * 34, 40, 0))
                ent:Spawn()
                ent:Activate()
                encounter.entities[#encounter.entities + 1] = ent
                self.Entities[#self.Entities + 1] = ent
            end
        end

        encounter.spawned = true
        encounter.activated = true
        return true
    end
end
