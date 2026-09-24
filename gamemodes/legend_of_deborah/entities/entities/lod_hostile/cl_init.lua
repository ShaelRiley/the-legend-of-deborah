include("shared.lua")

local aimMaterial = Material("cable/redlaser")
local deathMaterial = Material("models/debug/debugwhite")
local LASER_WIDTH = 2.5
local SIGHT_FORWARD_OFFSET = 18
local SIGHT_DOWN_OFFSET = 10
local SIGHT_SIDE_OFFSET = 2
local SOLDIER_HAND_BONE = "ValveBiped.Bip01_R_Hand"
local SOLDIER_LASER_COLOR = Color(255, 80, 60, 220)
local BLITZER_LASER_COLOR = Color(80, 220, 100, 220)
local SEEKER_ROLL_RADIUS = 18
local SEEKER_ROLL_TELEPORT_GUARD = 180

-- Motion V2 owns world-space placement: an ordinary hostile entity origin sits
-- on the graph-authored walking surface (+ a tiny safety lift), and explicit
-- stair/leap motion changes that world position deliberately. Humanoid/deadcrab
-- visuals pin their lowest rendered point to that origin. Device archetypes are
-- different: Scanner is a hovering actor, while Rollermine needs a small visual
-- clearance so model rotation can never appear embedded in the deck.
-- These are presentation offsets only; graph/physics position remains unchanged.
local DEVICE_VISUAL_LIFT = {
    watcher = 42,
    seeker = 8,
    razor = 42
}

local function visualModelBounds(ent)
    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then return mins, maxs end
    end
    return Vector(-16, -16, 0), Vector(16, 16, 72)
end

local function updateSeekerRoll(ent)
    local pos = ent:GetPos()
    local previous = ent.LODSeekerVisualLastPos
    ent.LODSeekerVisualLastPos = Vector(pos.x, pos.y, pos.z)

    if not previous then
        ent.LODSeekerVisualRoll = ent.LODSeekerVisualRoll or 0
        return ent.LODSeekerVisualRoll
    end

    local delta = pos - previous
    delta.z = 0
    local travelled = delta:Length()
    if travelled > 0.01 and travelled <= SEEKER_ROLL_TELEPORT_GUARD then
        local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
        local radius = math.max(8, SEEKER_ROLL_RADIUS * size)
        -- Rotation is distance-derived rather than animation-time-derived: twice
        -- the travel speed naturally produces twice the visible rolling rate.
        ent.LODSeekerVisualRoll = ((ent.LODSeekerVisualRoll or 0)
            + math.deg(travelled / radius)) % 360
        ent.LODSeekerVisualTravelYaw = delta:Angle().y
    end

    return ent.LODSeekerVisualRoll or 0
end

local function applyVisualScale(ent, seekerRoll)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local motionV2 = ent:GetNW2Bool("LOD_MotionV2", false)
    local model = ent:GetModel() or ""
    local archetype = ent:GetNW2String("LOD_Archetype", "")
    if archetype=="bigcrab" then size=2.4+(size-.33) end
    if archetype=="climber" then size=size*.55 end
    local deviceLift = DEVICE_VISUAL_LIFT[archetype] or 0
    if archetype=="warden" and ent:GetNW2Int("LOD_WardenPhase",1)==2 then deviceLift=18*size end
    local roll = archetype == "seeker" and (seekerRoll or 0) or 0
    local signature = string.format("%s:%.4f:%s:%s:%.2f:%.2f",
        model, size, tostring(motionV2), archetype, deviceLift, roll)
    if ent.LODLastClientVisualScale == signature then
        return size, ent.LODVisualVerticalCompensation or 0
    end
    ent.LODLastClientVisualScale = signature

    local mins, maxs = visualModelBounds(ent)

    -- Under Motion V2, local Z=0 is the authoritative physical foot/floor plane.
    -- First compensate scaled model bounds, then add any archetype presentation
    -- lift. The lift never feeds back into movement, traces, routing, or damage.
    local verticalCompensation
    if motionV2 then
        verticalCompensation = -(mins.z * size) + deviceLift
        if archetype=="lurker" then verticalCompensation=-(maxs.z*size) end
    else
        verticalCompensation = mins.z * (1 - size) + deviceLift
    end
    ent.LODVisualVerticalCompensation = verticalCompensation

    local matrix = Matrix()
    matrix:Scale(Vector(size, size, size))
    if archetype=="nodule" then
        matrix:Rotate(Angle(180,0,0))
        verticalCompensation=maxs.z*size
    end
    if archetype == "seeker" and roll ~= 0 then
        -- Motion V2 already yaws the entity toward each actual travel segment.
        -- Local pitch therefore reads as physical forward rolling in the current
        -- direction of motion while leaving the authoritative entity angles flat.
        matrix:Rotate(Angle(roll, 0, 0))
    end
    ent.LODVisualVerticalCompensation=verticalCompensation
    matrix:SetTranslation(Vector(0, 0, verticalCompensation))
    ent:EnableMatrix("RenderMultiply", matrix)

    if archetype == "seeker" then
        -- Rolling can rotate corners outside the model's native axis-aligned
        -- bounds. Use one conservative cached sphere-like bound to prevent cull
        -- popping; this changes no collision or server hull.
        local extent = math.max(
            math.abs(mins.x), math.abs(mins.y), math.abs(mins.z),
            math.abs(maxs.x), math.abs(maxs.y), math.abs(maxs.z)) * size + 12
        ent:SetRenderBounds(
            Vector(-extent, -extent, -extent + verticalCompensation),
            Vector(extent, extent, extent + verticalCompensation))
    elseif archetype == "fusilier" or archetype == "bombardier" or archetype == "halter" or archetype == "pacer" or archetype == "interposer" or archetype == "mourner" then
        -- Range360, body-center aim and bounded source drift fit500.
        ent:SetRenderBounds(Vector(-500,-500,math.min(-500,mins.z*size)),Vector(500,500,math.max(500,maxs.z*size)))
    elseif archetype == "siphoner" or archetype == "accumulator" then
        -- Frozen mark360 + radius64 + bounded source drift4; visual bounds only.
        ent:SetRenderBounds(Vector(-428,-428,math.min(-364,mins.z*size)),Vector(428,428,math.max(412,maxs.z*size)))
    elseif archetype == "exactor" or archetype == "absolver" or archetype == "conductor" then
        ent:SetRenderBounds(Vector(-424,-424,math.min(0,mins.z*size)),Vector(424,424,math.max(112,maxs.z*size)))
    elseif archetype == "listener" or archetype == "shy" then
        ent:SetRenderBounds(Vector(-160,-160,math.min(0,mins.z*size)),Vector(160,160,math.max(80,maxs.z*size)))
    elseif archetype == "censer" or archetype == "trailmaker" then
        -- A frozen 144-unit route plus its largest 64-unit radius fits this
        -- cached bound from every point along the route; no per-frame rebuild.
        ent:SetRenderBounds(Vector(-208,-208,math.min(0,mins.z*size)),
            Vector(208,208,math.max(80,maxs.z*size)))
    elseif archetype == "towline" or archetype == "screenwright" then
        local extent=archetype=="towline" and 352 or 640
        ent:SetRenderBounds(Vector(-extent,-extent,math.min(0,mins.z*size)),
            Vector(extent,extent,math.max(104,maxs.z*size)))
    elseif archetype == "afterburst" or archetype == "outrider" then
        ent:SetRenderBounds(Vector(-144,-144,math.min(0,mins.z*size+verticalCompensation)),
            Vector(144,144,math.max(80,maxs.z*size+verticalCompensation)))
    elseif archetype == "warden" then
        -- Include the broadened citizen and pig-mask ears in client culling.
        -- Cosmetic bounds only: authoritative collision remains unchanged.
        ent:SetRenderBounds(
            Vector((mins.x - 24) * size, (mins.y - 24) * size, mins.z * size + verticalCompensation),
            Vector((maxs.x + 24) * size, (maxs.y + 24) * size, (maxs.z + 16) * size + verticalCompensation))
    else
        ent:SetRenderBounds(
            Vector(mins.x * size, mins.y * size, mins.z * size + verticalCompensation),
            Vector(maxs.x * size, maxs.y * size, maxs.z * size + verticalCompensation)
        )
    end
    return size, verticalCompensation
end

local function rawHandPosition(ent)
    local handBone = ent:LookupBone(SOLDIER_HAND_BONE)
    if handBone then
        local matrix = ent:GetBoneMatrix(handBone)
        local handPos = matrix and matrix:GetTranslation()
        if handPos and handPos ~= ent:GetPos() then
            return handPos, "hand-bone"
        end
    end

    local attachment = ent:LookupAttachment("anim_attachment_RH")
    if attachment and attachment > 0 then
        local data = ent:GetAttachment(attachment)
        if data and data.Pos then
            return data.Pos, "hand-socket"
        end
    end

    return ent:WorldSpaceCenter() + Vector(0, 0, 12), "hull-fallback"
end

local function renderedHandPosition(ent, size, verticalCompensation)
    local rawPos, source = rawHandPosition(ent)
    local localPos = ent:WorldToLocal(rawPos) * size
    localPos.z = localPos.z + verticalCompensation
    return ent:LocalToWorld(localPos), source, rawPos
end

local function renderedMuzzlePosition(ent, size, verticalCompensation, aim)
    local handPos, source, rawPos = renderedHandPosition(ent, size, verticalCompensation)
    local direction = ent:GetForward()
    if aim and aim ~= vector_origin then
        local delta = aim - handPos
        if delta:LengthSqr() > 0.001 then direction = delta:GetNormalized() end
    end

    local muzzlePos = handPos
        + direction * SIGHT_FORWARD_OFFSET
        - ent:GetUp() * SIGHT_DOWN_OFFSET
        - ent:GetRight() * SIGHT_SIDE_OFFSET

    return muzzlePos, source, rawPos
end

function ENT:Draw()
    local deathAt = self:GetNW2Float("LOD_DeathPulseStart", -1)
    local dying = deathAt >= 0
    if not dying and self:GetNW2Bool("LOD_WardenHidden", false) then return end
    local archetype = self:GetNW2String("LOD_Archetype", "")
    if LOD.WardenPresentation then LOD.WardenPresentation:Pose(self) end
    if LOD.NeilBrutePresentation then LOD.NeilBrutePresentation:Pose(self) end
    local seekerRoll = archetype == "seeker" and updateSeekerRoll(self) or 0
    local size, verticalCompensation = applyVisualScale(self, seekerRoll)
    if dying then
        self:DrawModel()
        local pulse = LOD.EnemyDeathPulse(CurTime() - deathAt)
        render.SuppressEngineLighting(true)
        render.MaterialOverride(deathMaterial)
        render.SetColorModulation(1, 0, 0)
        render.SetBlend(pulse)
        self:DrawModel()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.MaterialOverride(nil)
        render.SuppressEngineLighting(false)
        if LOD.EnemyRosterVisual then LOD.EnemyRosterVisual:Remains(self) end
        return
    end
    if LOD.MonsterIdentity then
        LOD.MonsterIdentity:DrawBody(self)
        LOD.MonsterIdentity:DrawAura(self,size)
    else self:DrawModel() end
    if LOD.EnemyRosterVisual then LOD.EnemyRosterVisual:Draw(self,size) end
    if LOD.WardenPresentation then LOD.WardenPresentation:Draw(self,size) end
    if LOD.NeilBrutePresentation then LOD.NeilBrutePresentation:Draw(self,size) end
    if archetype ~= "soldier" and archetype ~= "blitzer" then return end
    if not self:GetNW2Bool("LOD_SoldierTelegraph", false) then return end

    local aim = self:GetNW2Vector("LOD_SoldierAim", vector_origin)
    if aim == vector_origin then return end

    local startPos = renderedMuzzlePosition(self, size, verticalCompensation, aim)
    local aimDelta = aim - startPos
    local aimDistance = aimDelta:Length()
    if aimDistance <= 0.001 then return end
    local direction = aimDelta / aimDistance

    local stopShort = math.min(24, aimDistance * 0.20)
    local visualAim = startPos + direction * math.max(8, aimDistance - stopShort)

    render.SetMaterial(aimMaterial)
    local color = archetype == "blitzer" and BLITZER_LASER_COLOR or SOLDIER_LASER_COLOR
    render.DrawBeam(startPos, visualAim, LASER_WIDTH, 0, 1, color)
end

concommand.Add("lod_laser_origin_status", function()
    local soldierCount = 0
    local blitzerCount = 0
    local handAnchors = 0
    local fallbacks = 0
    local floorOrigins = 0

    for _, hostile in ipairs(ents.FindByClass("lod_hostile")) do
        local archetype = hostile:GetNW2String("LOD_Archetype", "")
        if archetype == "soldier" or archetype == "blitzer" then
            if archetype == "soldier" then soldierCount = soldierCount + 1 end
            if archetype == "blitzer" then blitzerCount = blitzerCount + 1 end

            local size, verticalCompensation = applyVisualScale(hostile, 0)
            local renderedPos, source, rawPos = renderedMuzzlePosition(hostile, size, verticalCompensation)
            local originHeight = renderedPos.z - hostile:GetPos().z
            if source == "hand-bone" or source == "hand-socket" then
                handAnchors = handAnchors + 1
            else
                fallbacks = fallbacks + 1
            end
            if originHeight <= math.max(8, 12 * size) then floorOrigins = floorOrigins + 1 end
            print(string.format(
                "[LOD:LASER-ORIGIN] #%d archetype=%s scale=%.3f source=%s originHeight=%.2f handToSight=%.2f width=%.2f",
                hostile:EntIndex(), archetype, size, source, originHeight,
                rawPos:Distance(renderedPos), LASER_WIDTH
            ))
        end
    end

    local total = soldierCount + blitzerCount
    local passed = soldierCount > 0 and blitzerCount > 0 and handAnchors == total
        and fallbacks == 0 and floorOrigins == 0
    print(string.format(
        "[LOD:LASER-ORIGIN] soldiers=%d blitzers=%d handAnchors=%d fallbacks=%d floorOrigins=%d sharedWidth=%.2f rifleSiteAnchor=true frozenAimPoint=true result=%s",
        soldierCount, blitzerCount, handAnchors, fallbacks, floorOrigins,
        LASER_WIDTH, passed and "PASS" or "FAIL"
    ))
end)
