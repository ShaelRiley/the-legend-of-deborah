LOD = LOD or {}
LOD.HostileGroundBridge = LOD.HostileGroundBridge or {}

local Bridge = LOD.HostileGroundBridge
local CHECK_INTERVAL = 0.05
local nextCheck = 0

local function bridgeEligible(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return false end
    if hostile.LODArchetypeId == "deadcrab" then return false end
    if hostile.LODActivated == false then return false end
    if math.abs(hostile:GetVelocity().z) > 30 then return false end
    return hostile.loco ~= nil
end

local function supportUnderFeet(hostile)
    local foot = LOD.HumanoidFootOffset or 24
    local pos = hostile:GetPos() + Vector(0, 0, foot)
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 10),
        endpos = pos - Vector(0, 0, 18),
        mask = MASK_NPCSOLID,
        filter = hostile
    })

    if not tr.Hit or tr.StartSolid or not tr.HitNormal or tr.HitNormal.z < 0.65 then return nil end
    if tr.HitWorld then return game.GetWorld() end
    if IsValid(tr.Entity) and tr.Entity:GetClass() == "lod_static_box" then
        local kind = tr.Entity.GetBoxKind and tr.Entity:GetBoxKind() or 0
        if kind == 1 or kind == 2 then return tr.Entity end
    end
    return nil
end

hook.Add("Think", "LOD_HostileGeneratedGroundBridge", function()
    local now = CurTime()
    if now < nextCheck then return end
    nextCheck = now + CHECK_INTERVAL

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if bridgeEligible(hostile) and hostile.loco.IsOnGround and not hostile.loco:IsOnGround() then
            local support = supportUnderFeet(hostile)
            if IsValid(support) then
                local changed = hostile.LODGroundBridgeSupport ~= support
                hostile:SetGroundEntity(support)
                hostile.LODGroundBridgeSupport = support
                hostile.LODGroundBridgeSetCount = (hostile.LODGroundBridgeSetCount or 0) + 1

                -- A bot may already have accumulated Source's stuck state before
                -- the generated support entity is registered. Clear it only when
                -- entering a new support surface; do not churn the flag every tick.
                if changed and hostile.loco.ClearStuck then
                    hostile.loco:ClearStuck()
                    hostile.LODNextRouteRefresh = 0
                    hostile.LODProgressSamplePos = nil
                    hostile.LODProgressSampleTime = nil
                end
            end
        end
    end
end)

concommand.Add("lod_m3_ground_bridge_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        if IsValid(hostile) and hostile.LODHostile and hostile.LODArchetypeId ~= "deadcrab" then
            print(string.format(
                "[LOD:GROUND-BRIDGE] #%d %s locoGround=%s support=%s sets=%d",
                hostile:EntIndex(), tostring(hostile.LODArchetypeId),
                tostring(hostile.loco and hostile.loco.IsOnGround and hostile.loco:IsOnGround() or false),
                IsValid(hostile.LODGroundBridgeSupport) and hostile.LODGroundBridgeSupport:GetClass() or "none",
                hostile.LODGroundBridgeSetCount or 0
            ))
        end
    end
end)
