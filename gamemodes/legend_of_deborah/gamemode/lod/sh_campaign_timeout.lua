LOD = LOD or {}
LOD.CampaignTimeout = LOD.CampaignTimeout or {}
local T = LOD.CampaignTimeout
T.Duration = 1800
T.Reveal = 4
T.Collapse = 12
T.Settle = 22
T.PhysicsLimit = 24
T.Message = "LOD_CampaignClock"

function T:Remaining(clock, now)
    if not clock or not clock.deadline then return self.Duration end
    return math.max(0, clock.deadline - now)
end

function T:ReleaseAt(pos, center, radius)
    return self.Reveal + math.Clamp((pos.x - center.x) / math.max(radius, 1) + 0.5, 0, 1) * 7
end

-- Cosmetic transforms use immutable coordinates and absolute sequence time.
-- No accumulated integration error, per-container timers, or client physics.
function T:ContainerPose(pos, ang, center, radius, ground, elapsed, index)
    local lift = 900 * math.Clamp(elapsed / 2, 0, 1)
    local t = math.max(0, elapsed - self:ReleaseAt(pos, center, radius))
    local seed = (index * 16807 % 2147483647) % 997 / 997
    local dx, dy = pos.x - center.x, pos.y - center.y
    local length = math.max(1, math.sqrt(dx * dx + dy * dy))
    local travel = math.min(t, 3) * (90 + seed * 120)
    local floor = ground + 64 + seed * 90
    local z = t == 0 and (pos.z + lift) or math.max(floor, pos.z + lift - 300 * t * t)
    local fall = math.Clamp(t / 3, 0, 1)
    local bounce = t > 3 and math.sin((t - 3) * 7) * 35 * math.max(0, 1 - (t - 3) / 2) or 0
    return Vector(pos.x + dx / length * travel, pos.y + dy / length * travel, z + math.abs(bounce)),
        Angle(ang.p + (seed - 0.5) * 170 * fall, ang.y + (seed - 0.5) * 100 * fall, ang.r + 90 * fall)
end

function T:Camera(center, radius)
    -- Elevated wide shot fits the entire prison including the extended Warden
    -- wing. Source horizontal FOV=90 also fits narrow 4:3 displays vertically.
    return center + Vector(radius * 0.38, -radius * 0.52, radius * 2.65)
end
