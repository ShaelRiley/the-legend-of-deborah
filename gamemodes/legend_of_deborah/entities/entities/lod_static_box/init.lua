AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local function rotatedAABB(mins, maxs, ang)
    local yaw = math.rad(ang.y or 0)
    local c = math.cos(yaw)
    local s = math.sin(yaw)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    local xs = {mins.x, maxs.x}
    local ys = {mins.y, maxs.y}
    for _, x in ipairs(xs) do
        for _, y in ipairs(ys) do
            local rx = x * c - y * s
            local ry = x * s + y * c
            minX = math.min(minX, rx)
            minY = math.min(minY, ry)
            maxX = math.max(maxX, rx)
            maxY = math.max(maxY, ry)
        end
    end

    return Vector(minX, minY, mins.z), Vector(maxX, maxY, maxs.z)
end

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")

    local mins, maxs = self:GetBoxMins(), self:GetBoxMaxs()
    local collisionMins, collisionMaxs = rotatedAABB(mins, maxs, self:GetAngles())

    -- These are immutable world-geometry surrogates, not simulated props.
    -- SOLID_BBOX + collision bounds gives players/NPC traces an authoritative
    -- static surface without consuming a PhysCollide for every floor, wall,
    -- stair step, or rail. The bounds are converted to a world-aligned AABB so
    -- the 0/90-degree authored rotations still match the rendered geometry.
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetSolidFlags(0)
    self:SetCollisionBounds(collisionMins, collisionMaxs)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:DrawShadow(false)

    self.LODCollisionReady = true
end

function ENT:IsLODCollisionReady()
    return self.LODCollisionReady == true
end
