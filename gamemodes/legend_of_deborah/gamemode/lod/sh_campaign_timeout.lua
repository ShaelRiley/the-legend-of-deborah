LOD = LOD or {}
LOD.CampaignTimeout = LOD.CampaignTimeout or {}
local T = LOD.CampaignTimeout
T.Duration = 1800
T.Reveal = 0.5
T.Collapse = 5.5
T.Settle = 7
T.ManualRestartDelay = 5
T.AutoRestartDelay = 20
T.PhysicsLimit = 24
T.Message = "LOD_CampaignClock"

function T:Remaining(clock, now)
    if not clock or not clock.deadline then return self.Duration end
    return math.max(0, clock.deadline - now)
end

function T:ReleaseAt(pos, center, radius)
    return self.Reveal + math.Clamp((pos.x - center.x) / math.max(radius, 1) + 0.5, 0, 1) * 3
end

-- Cosmetic transforms use immutable coordinates and absolute sequence time.
-- No accumulated integration error, per-container timers, or client physics.
function T:ContainerPose(pos, ang, center, radius, ground, elapsed, index)
    local lift = 180 * math.Clamp(elapsed / 0.5, 0, 1)
    local t = math.max(0, elapsed - self:ReleaseAt(pos, center, radius)) * 2
    local seed = (index * 16807 % 2147483647) % 997 / 997
    local dx, dy = pos.x - center.x, pos.y - center.y
    local length = math.max(1, math.sqrt(dx * dx + dy * dy))
    local travel = math.min(t, 3) * (90 + seed * 120)
    local floor = ground + 64 + seed * 90
    local z = t == 0 and (pos.z + lift) or math.max(floor, pos.z + lift - 300 * t * t)
    local fall = math.Clamp(t / 3, 0, 1)
    local bounce = t > 3 and math.sin((t - 3) * 3) * 35 * math.max(0, 1 - (t - 3) / 2) or 0
    return Vector(pos.x + dx / length * travel, pos.y + dy / length * travel, z + math.abs(bounce)),
        Angle(ang.p + (seed - 0.5) * 170 * fall, ang.y + (seed - 0.5) * 100 * fall, ang.r + 90 * fall)
end

-- Stock gm_flatgrass FLATSIGN brush center, transformed out of its 16x
-- 3D skybox (sky_camera origin 32,0,-15040). No map asset is redistributed.
T.FlattywoodSign = Vector(-82108, 3781, -6272)
T.CameraFOV = 110
T.CameraFar = 160000 -- includes the apparent 3D-skybox sign ~90k units away
function T:Camera(center, radius)
    -- Stand opposite the sign, with the prison between camera and backdrop.
    -- A 40-degree downward pitch approximates the requested 45-degree view
    -- while retaining the sign above the prison inside the letterboxed frame.
    local dx,dy=center.x-self.FlattywoodSign.x,center.y-self.FlattywoodSign.y
    local length=math.max(1,math.sqrt(dx*dx+dy*dy))
    local distance=math.max(1200,radius)*1.6
    return center + Vector(dx/length*distance,dy/length*distance,distance*math.tan(math.rad(40)))
end

-- Absolute-time editorial cuts, shared by PVS and client camera. Each exterior
-- stays within a prison radius; the last low shot keeps rubble before the sign.
function T:CinematicView(center, radius, ground, elapsed, interior)
    local r=math.max(256,radius)
    local bearing=center-self.FlattywoodSign;bearing.z=0;bearing:Normalize()
    local side=Vector(-bearing.y,bearing.x,0)
    local base=Vector(center.x,center.y,ground)
    if elapsed<1.2 and interior then
        return interior, center+Vector(0,0,80), 85
    elseif elapsed<2.6 then
        local u=math.Clamp((elapsed-1.2)/1.4,0,1)
        return base+bearing*r*.82+side*r*(.35-u*.18)+Vector(0,0,160),center,85
    elseif elapsed<4 then
        local u=math.Clamp((elapsed-2.6)/1.4,0,1)
        return base-side*r*.85+bearing*r*.25+Vector(0,0,140+u*220),center,90
    elseif elapsed<5.5 then
        return base-bearing*r*.8+side*r*.25+Vector(0,0,450),center+Vector(0,0,40),95
    end
    local u=math.Clamp((elapsed-5.5)/1.5,0,1)
    local pos=base+bearing*r*(.8-.08*u)+Vector(0,0,220-40*u)
    return pos,self.FlattywoodSign,90
end
