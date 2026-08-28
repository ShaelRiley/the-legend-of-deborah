AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
for index = 1, 4 do AddCSLuaFile(string.format("assets/html_%02d.lua", index)) end
for index = 1, 2 do AddCSLuaFile(string.format("assets/page_1_%02d.lua", index)) end
include("shared.lua")

util.AddNetworkString("LOD_OpenFieldManual")

local MANUAL_MODEL = "models/props_lab/clipboard.mdl"
local FALLBACK_MODEL = "models/props_lab/binderblue.mdl"

local function validModel(preferred, fallback)
    if preferred and util.IsValidModel(preferred) then return preferred end
    if fallback and util.IsValidModel(fallback) then return fallback end
    return "models/props_junk/garbage_newspaper001a.mdl"
end

function ENT:Initialize()
    self:SetModel(validModel(MANUAL_MODEL, FALLBACK_MODEL))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-24, -20, 0), Vector(24, 20, 54))
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(255, 255, 255, 0))
    self:DrawShadow(false)
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
    local staging = LOD and LOD.StagingDeployment
    if staging and staging.IsDeployed and staging:IsDeployed(activator) then return end
    if not activator:GetNW2Bool("LOD_Staged", false) then return end

    net.Start("LOD_OpenFieldManual")
    net.Send(activator)
end

LOD = LOD or {}
LOD.StagingManual = LOD.StagingManual or {}
local Manual = LOD.StagingManual

local function registerHutEntity(staging, ent)
    if not IsValid(ent) then return end
    if staging._RegisterHut then
        staging:_RegisterHut(ent)
        return
    end
    staging.HutEntities = staging.HutEntities or {}
    staging.HutEntities[#staging.HutEntities + 1] = ent
end

local function floorPos(staging, side, forwardOffset, wallInset)
    if not staging.HutCenter or not staging.HutAngles then return nil end
    local yaw = Angle(0, staging.HutAngles.y, 0)
    local halfRight = math.max(96, tonumber(staging.HutHalfRight) or 150)
    return staging.HutCenter
        + yaw:Forward() * (forwardOffset or 18)
        + yaw:Right() * side * math.max(32, halfRight - (wallInset or 42))
        + Vector(0, 0, 1)
end

function Manual:Ensure()
    local staging = LOD and LOD.StagingDeployment
    if not staging or not staging.HutCenter or not staging.HutAngles then return false end
    if staging._HutValid and not staging:_HutValid() then return false end

    local yaw = Angle(0, staging.HutAngles.y, 0)

    if not IsValid(self.Entity) then
        local pos = floorPos(staging, -1, 18, 44)
        if pos then
            local ent = ents.Create("lod_field_manual")
            if IsValid(ent) then
                local inward = yaw:Right()
                ent:SetPos(pos)
                ent:SetAngles(inward:Angle())
                ent:Spawn()
                ent:Activate()
                self.Entity = ent
                registerHutEntity(staging, ent)
            end
        end
    end

    if not IsValid(self.MirrorEntity) then
        local pos = floorPos(staging, 1, 0, 5)
        if pos then
            local mirror = ents.Create("lod_staging_mirror")
            if IsValid(mirror) then
                local inward = -yaw:Right()
                mirror:SetPos(pos)
                mirror:SetAngles(inward:Angle())
                mirror:Spawn()
                mirror:Activate()
                self.MirrorEntity = mirror
                registerHutEntity(staging, mirror)
            end
        end
    end

    return IsValid(self.Entity) and IsValid(self.MirrorEntity)
end

local function ensureSoon()
    timer.Simple(0, function()
        if LOD and LOD.StagingManual then LOD.StagingManual:Ensure() end
    end)
end

hook.Add("InitPostEntity", "LOD_StagingManualInit", function()
    timer.Simple(0.75, function()
        local staging = LOD and LOD.StagingDeployment
        if staging and staging.EnsureHut then staging:EnsureHut() end
        if LOD and LOD.StagingManual then LOD.StagingManual:Ensure() end
    end)
end)

-- Cheap resilience for campaign rebuilds: two validity checks every two seconds,
-- with work only when the native staging presentation has been reconstructed.
timer.Create("LOD_StagingManualEnsure", 2, 0, function()
    local staging = LOD and LOD.StagingDeployment
    if not staging or not staging.HutCenter then return end
    if not IsValid(Manual.Entity) or not IsValid(Manual.MirrorEntity) then ensureSoon() end
end)

concommand.Add("lod_staging_manual_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local staging = LOD and LOD.StagingDeployment
    local manualOK = IsValid(Manual.Entity)
    local mirrorOK = IsValid(Manual.MirrorEntity)
    local hutOK = staging and staging._HutValid and staging:_HutValid() or false
    local result = manualOK and mirrorOK and hutOK and "PASS" or "FAIL"
    local line = string.format("manual=%s mirror=%s hut=%s net=ARMED html=ATTACHED-23-PAGE pageSound=ATTACHED result=%s",
        tostring(manualOK), tostring(mirrorOK), tostring(hutOK), result)
    print("[LOD:STAGING-MANUAL] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
