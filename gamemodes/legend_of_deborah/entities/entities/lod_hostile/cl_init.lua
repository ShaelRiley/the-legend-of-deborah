include("shared.lua")

local aimMaterial = Material("cable/redlaser")
local LASER_WIDTH = 2.5
local BARREL_OFFSET = 24
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

local function rawMuzzlePosition(ent)
    local attachment = ent:LookupAttachment("anim_attachment_RH")
    if attachment and attachment > 0 then
        local data = ent:GetAttachment(attachment)
        if data and data.Pos then
            -- Bonemerged prop attachments can exist yet report a world position
            -- near the parent's feet. The host model's right-hand socket is the
            -- stable common datum for Soldier and Blitzer. Both aim activities
            -- face the hostile at its target, so this offset follows the barrel.
            return data.Pos + ent:GetForward() * BARREL_OFFSET, "hand-socket"
        end
    end

    return ent:WorldSpaceCenter() + Vector(0, 0, 12) + ent:GetForward() * 24, "hull-fallback"
end

local function renderedMuzzlePosition(ent, size, verticalCompensation)
    local rawPos, source = rawMuzzlePosition(ent)
    local localPos = ent:WorldToLocal(rawPos) * size
    localPos.z = localPos.z + verticalCompensation
    return ent:LocalToWorld(localPos), source, rawPos
end

function ENT:Draw()
    local size, verticalCompensation = applyVisualScale(self)
    self:DrawModel()
    local archetype = self:GetNW2String("LOD_Archetype", "")
    if archetype ~= "soldier" and archetype ~= "blitzer" then return end
    if not self:GetNW2Bool("LOD_SoldierTelegraph", false) then
        self.LODTelegraphVisualAim = nil
        self.LODTelegraphVisualSerial = nil
        return
    end

    local aim = self:GetNW2Vector("LOD_SoldierAim", vector_origin)
    if aim == vector_origin then return end

    local startPos = renderedMuzzlePosition(self, size, verticalCompensation)
    local visualAim = aim
    local target = self:GetNW2Entity("LOD_SoldierTelegraphTarget")
    local localPlayer = LocalPlayer()
    if IsValid(target) and target == localPlayer then
        -- A ray ending at or near the first-person camera is foreshortened into
        -- a dot or a false downward segment. Project the frozen crosshair ray out
        -- to the hostile's depth instead. This keeps the warning connected to
        -- the muzzle and visually directed toward the committed screen location;
        -- authoritative aim and projectile paths remain the frozen EyePos.
        local serial = self:GetNW2Int("LOD_SoldierTelegraphSerial", 0)
        if self.LODTelegraphVisualSerial ~= serial or not self.LODTelegraphVisualAim then
            local view = self:GetNW2Vector("LOD_SoldierTelegraphView", vector_origin)
            if view == vector_origin then view = target:GetAimVector() end
            local proxyDistance = startPos:Distance(aim)
            self.LODTelegraphVisualAim = aim + view * proxyDistance
            self.LODTelegraphVisualSerial = serial
        end
        visualAim = self.LODTelegraphVisualAim
    end

    local aimDelta = visualAim - startPos
    local aimDistance = aimDelta:Length()
    if aimDistance <= 0.001 then return end

    -- The presentation proxy already lies on the hostile's depth plane. Drawing
    -- all the way to it produces the intended readable screen direction; the old
    -- 160-unit cap reduced that projected ray to a tiny nub at typical ranges.
    render.SetMaterial(aimMaterial)
    local color = archetype == "blitzer" and BLITZER_LASER_COLOR or SOLDIER_LASER_COLOR
    render.DrawBeam(startPos, visualAim, LASER_WIDTH, 0, 1, color)
end

concommand.Add("lod_laser_origin_status", function()
    local soldierCount = 0
    local blitzerCount = 0
    local handSockets = 0
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
            if source == "hand-socket" then
                handSockets = handSockets + 1
            else
                fallbacks = fallbacks + 1
            end
            if originHeight <= math.max(8, 12 * size) then floorOrigins = floorOrigins + 1 end
            print(string.format(
                "[LOD:LASER-ORIGIN] #%d archetype=%s scale=%.3f source=%s originHeight=%.2f scaleCorrection=%.2f width=%.2f",
                hostile:EntIndex(), archetype, size, source, originHeight,
                rawPos:Distance(renderedPos), LASER_WIDTH
            ))
        end
    end

    local total = soldierCount + blitzerCount
    local passed = soldierCount > 0 and blitzerCount > 0 and handSockets == total
        and fallbacks == 0 and floorOrigins == 0
    print(string.format(
        "[LOD:LASER-ORIGIN] soldiers=%d blitzers=%d handSockets=%d fallbacks=%d floorOrigins=%d sharedWidth=%.2f depthProjected=true result=%s",
        soldierCount, blitzerCount, handSockets, fallbacks, floorOrigins,
        LASER_WIDTH, passed and "PASS" or "FAIL"
    ))
end)
