LOD = LOD or {}
LOD.VictoryCelebration = LOD.VictoryCelebration or {}

local Celebration = LOD.VictoryCelebration
local RunManager = LOD.RunManager
local MazeBuilder = LOD.MazeBuilder
local MC = LOD.Config and LOD.Config.Maze
if not RunManager or not MC then return end

local CELEBRATION_SECONDS = 6.5
local BALLOON_LIFETIME = 11
local BALLOON_COUNT = 12
local BALLOON_MODEL = "models/maxofs2d/balloon_classic.mdl"
local BALLOON_COLORS = {
    Color(238, 88, 88),
    Color(76, 156, 238),
    Color(244, 205, 76),
    Color(104, 205, 124),
    Color(202, 102, 224),
    Color(245, 137, 61)
}

util.AddNetworkString("LOD_VictoryCelebration")

Celebration.Stats = Celebration.Stats or {starts = 0, balloons = 0}
Celebration.ActiveUntil = Celebration.ActiveUntil or 0

local function activeDeborah()
    for _, ent in ipairs(ents.FindByClass("lod_deborah")) do
        if IsValid(ent) then return ent end
    end
end

local function celebrationCenter(ply)
    local deborah = activeDeborah()
    if IsValid(deborah) then return deborah:GetPos() + Vector(0, 0, 42), deborah end
    if IsValid(ply) then return ply:GetPos() + Vector(0, 0, 42), nil end
    return MC.Origin + Vector(0, 0, 64), nil
end

local function registerTemporary(ent)
    if IsValid(ent) and MazeBuilder and MazeBuilder._Register then
        MazeBuilder:_Register(ent)
    end
end

local function spawnBalloon(center, index)
    if not util.IsValidModel(BALLOON_MODEL) then return nil end
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return nil end

    local ring = ((index - 1) / math.max(1, BALLOON_COUNT)) * math.pi * 2
    local radius = 48 + ((index * 37) % 105)
    local spawnZ = center.z + math.min(220, MC.LevelHeight * 0.62) + ((index * 19) % 32)
    ent:SetModel(BALLOON_MODEL)
    ent:SetPos(Vector(
        center.x + math.cos(ring) * radius,
        center.y + math.sin(ring) * radius,
        spawnZ))
    ent:SetAngles(Angle(math.Rand(-8, 8), math.Rand(0, 359), math.Rand(-8, 8)))
    ent:SetSkin((index - 1) % 4)
    ent:SetColor(BALLOON_COLORS[((index - 1) % #BALLOON_COLORS) + 1])
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
    ent:Spawn()
    ent:Activate()
    ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    ent:SetModelScale(math.Rand(0.84, 1.16), 0)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(1)
        phys:EnableGravity(false)
        phys:SetDamping(0.7, 1.6)
        phys:SetVelocity(Vector(math.Rand(-22, 22), math.Rand(-22, 22), math.Rand(-32, -18)))
        phys:AddAngleVelocity(Vector(math.Rand(-15, 15), math.Rand(-15, 15), math.Rand(-15, 15)))
    end

    registerTemporary(ent)
    timer.Simple(BALLOON_LIFETIME, function()
        if IsValid(ent) then ent:Remove() end
    end)
    Celebration.Stats.balloons = (Celebration.Stats.balloons or 0) + 1
    return ent
end

function Celebration:Start(rescuer)
    local center, deborah = celebrationCenter(rescuer)
    local now = CurTime()
    self.ActiveUntil = now + CELEBRATION_SECONDS
    self.Stats.starts = (self.Stats.starts or 0) + 1

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and RunManager:IsActivePlayer(ply) then
            ply:SetNW2Float("LOD_VictoryCelebrationUntil", self.ActiveUntil)
            local cheer = _G.ACT_GMOD_TAUNT_CHEER or _G.ACT_GMOD_GESTURE_WAVE
            if cheer and ply.AnimRestartGesture then
                ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, cheer, true)
            end
        end
    end

    for index = 1, BALLOON_COUNT do spawnBalloon(center, index) end

    net.Start("LOD_VictoryCelebration")
    net.WriteVector(center)
    net.WriteFloat(CELEBRATION_SECONDS)
    net.WriteEntity(IsValid(deborah) and deborah or NULL)
    net.Broadcast()
end

hook.Add("StartCommand", "LOD_VictoryCelebrationMovementLock", function(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end
    if CurTime() >= ply:GetNW2Float("LOD_VictoryCelebrationUntil", 0) then return end
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

-- Decorate the existing authoritative level-clear path. Intermission Tetris is
-- loaded first and remains the transition owner; this wrapper only begins the
-- audiovisual celebration after that same CompleteLevel call succeeds.
if not RunManager.LODVictoryCelebrationWrapped then
    RunManager.LODVictoryCelebrationWrapped = true
    local baseCompleteLevel = RunManager.CompleteLevel
    function RunManager:CompleteLevel(ply)
        local completed = baseCompleteLevel(self, ply)
        if completed then Celebration:Start(ply) end
        return completed
    end
end

concommand.Add("lod_victory_celebration_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end
    local line = string.format("starts=%d balloons=%d active=%s remaining=%.1fs modelValid=%s",
        Celebration.Stats.starts or 0,
        Celebration.Stats.balloons or 0,
        tostring(CurTime() < (Celebration.ActiveUntil or 0)),
        math.max(0, (Celebration.ActiveUntil or 0) - CurTime()),
        tostring(util.IsValidModel(BALLOON_MODEL)))
    print("[LOD:VICTORY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
