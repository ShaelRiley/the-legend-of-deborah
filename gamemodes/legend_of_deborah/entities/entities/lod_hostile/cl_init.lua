include("shared.lua")

local aimMaterial = Material("cable/redlaser")
local LASER_WIDTH = 2.5
local SIGHT_FORWARD_OFFSET = 18
local SIGHT_DOWN_OFFSET = 10
local SIGHT_SIDE_OFFSET = 2
local SOLDIER_HAND_BONE = "ValveBiped.Bip01_R_Hand"
local SOLDIER_LASER_COLOR = Color(255, 80, 60, 220)
local BLITZER_LASER_COLOR = Color(80, 220, 100, 220)

-- Motion V2 owns world-space placement: an ordinary hostile entity origin sits
-- on the graph-authored walking surface (+ a tiny safety lift), and explicit
-- stair/leap motion changes that world position deliberately. Visual variance
-- therefore needs only one invariant: the LOWEST point of the rendered model
-- must remain at the entity origin for every scale. The old hard-coded 24-unit
-- humanoid pivot came from the retired Source-ground-locomotion architecture and
-- could push some models visibly into the deck; Deadcrab could likewise extend
-- downward through an upper-floor slab.
--
-- This uses cached model bounds only. There are no traces or hostile-list scans
-- in Draw(), preserving Motion V2's recovered frame-time performance.

local function visualModelBounds(ent)
    if util.GetModelBounds then
        local mins, maxs = util.GetModelBounds(ent:GetModel())
        if mins and maxs then return mins, maxs end
    end
    return Vector(-16, -16, 0), Vector(16, 16, 72)
end

local function applyVisualScale(ent)
    local size = math.Clamp(ent:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
    local motionV2 = ent:GetNW2Bool("LOD_MotionV2", false)
    local model = ent:GetModel() or ""
    local signature = string.format("%s:%.4f:%s", model, size, tostring(motionV2))
    if ent.LODLastClientVisualScale == signature then
        return size, ent.LODVisualVerticalCompensation or 0
    end
    ent.LODLastClientVisualScale = signature

    local mins, maxs = visualModelBounds(ent)

    -- Under Motion V2, local Z=0 is the authoritative visual foot plane. Scale
    -- the complete model, then translate its scaled minimum-Z back to that plane.
    -- This works for humanoids and Deadcrab alike and remains valid while a
    -- Deadcrab is airborne because the entity origin itself follows the leap.
    local verticalCompensation
    if motionV2 then
        verticalCompensation = -(mins.z * size)
    else
        -- Defensive legacy fallback for any entity created before Motion V2's
        -- network flag arrives. Preserve the model's native minimum-Z plane.
        verticalCompensation = mins.z * (1 - size)
    end
    ent.LODVisualVerticalCompensation = verticalCompensation

    local matrix = Matrix()
    matrix:Scale(Vector(size, size, size))
    matrix:SetTranslation(Vector(0, 0, verticalCompensation))
    ent:EnableMatrix("RenderMultiply", matrix)

    ent:SetRenderBounds(
        Vector(mins.x * size, mins.y * size, mins.z * size + verticalCompensation),
        Vector(maxs.x * size, maxs.y * size, maxs.z * size + verticalCompensation)
    )
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
            -- Defensive fallback for models lacking the standard right-hand bone.
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

    -- Treat the visible origin as a weapon-mounted laser emitter rather than the
    -- actor's hand bone: forward along the committed shot line, lowered onto the
    -- rifle body, and nudged slightly inward. The server uses matching offsets for
    -- projectile spawn so visual warning and physical shot remain coherent.
    local muzzlePos = handPos
        + direction * SIGHT_FORWARD_OFFSET
        - ent:GetUp() * SIGHT_DOWN_OFFSET
        - ent:GetRight() * SIGHT_SIDE_OFFSET

    return muzzlePos, source, rawPos
end

function ENT:Draw()
    local size, verticalCompensation = applyVisualScale(self)
    self:DrawModel()
    local archetype = self:GetNW2String("LOD_Archetype", "")
    if archetype ~= "soldier" and archetype ~= "blitzer" then return end
    if not self:GetNW2Bool("LOD_SoldierTelegraph", false) then return end

    local aim = self:GetNW2Vector("LOD_SoldierAim", vector_origin)
    if aim == vector_origin then return end

    local startPos = renderedMuzzlePosition(self, size, verticalCompensation, aim)
    local aimDelta = aim - startPos
    local aimDistance = aimDelta:Length()
    if aimDistance <= 0.001 then return end
    local direction = aimDelta / aimDistance

    -- The beam and projectile now share one contract: both converge on the frozen
    -- world-space aim point captured at beam-on. Stop the rendered beam just shy
    -- of that point so a player-targeted ray does not cross the first-person near
    -- plane and reappear as a misleading leg/crotch segment.
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

            local size, verticalCompensation = applyVisualScale(hostile)
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
