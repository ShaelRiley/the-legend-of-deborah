LOD = LOD or {}
LOD.RPGWisInformation = LOD.RPGWisInformation or {}
local Information = LOD.RPGWisInformation
local NET_OMNISCIENCE = "LOD_RPGWisOmniscience"

Information.Omniscience = Information.Omniscience or nil

-- Observes the same serial-deduplicated event used by live text and history.
-- Position is a detection-time bearing, never an ongoing enemy reveal/tracker.
function Information:OnFeedback(entry)
    if entry.family=="life" or entry.family=="soldier" or entry.family=="danger" then
        self.Awareness=nil
    end
    local ply=LocalPlayer()
    if entry.family~="awareness" or not entry.position or not IsValid(ply) or not ply:Alive() then return end
    self.Awareness={position=entry.position,expires=CurTime()+1.25}
end

function Information:AwarenessScreenPoint(ply, position, width, height)
    local delta=position-ply:EyePos()
    local yaw=math.rad(ply:EyeAngles().y)
    local forward=delta.x*math.cos(yaw)+delta.y*math.sin(yaw)
    local right=delta.x*math.sin(yaw)-delta.y*math.cos(yaw)
    local length=math.max(0.001,math.sqrt(forward*forward+right*right))
    return width*.5+right/length*width*.43, height*.5-forward/length*height*.38
end

hook.Add("HUDPaint","LOD_SpatialAwarenessLight",function()
    local notice=Information.Awareness
    if not notice then return end
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or CurTime()>=notice.expires then
        Information.Awareness=nil;return
    end
    local x,y=Information:AwarenessScreenPoint(ply,notice.position,ScrW(),ScrH())
    local strength=math.min(1,(notice.expires-CurTime())/.4)
    local color=LOD.UI.HUDRoles.awareness
    draw.NoTexture()
    for layer=3,1,-1 do
        local r=layer*6
        surface.SetDrawColor(color.r,color.g,color.b,math.floor(strength*(layer==1 and 230 or 40)))
        surface.DrawPoly({{x=x,y=y-r},{x=x+r,y=y},{x=x,y=y+r},{x=x-r,y=y}})
    end
end)

local function clearAwareness() Information.Awareness=nil end
hook.Add("PostCleanupMap","LOD_SpatialAwarenessClear",clearAwareness)
hook.Add("ShutDown","LOD_SpatialAwarenessShutdown",clearAwareness)

net.Receive(NET_OMNISCIENCE, function()
    local target = net.ReadEntity()
    if not IsValid(target) then
        Information.Omniscience = nil
        return
    end
    Information.Omniscience = {
        target = target,
        type = net.ReadString(),
        level = net.ReadUInt(8),
        class = net.ReadString(),
        hp = net.ReadInt(16),
        maxHP = net.ReadUInt(16)
    }
end)

local function hostileIdentityAnchor(ent)
    local authority = LOD.HostileIdentityPresentation
    if authority and authority.AnchorFor then
        local x, y = authority:AnchorFor(ent)
        if x and y then return x, y end
    end
    local top = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z + 18)):ToScreen()
    return top.x, top.y
end

hook.Add("HUDPaint", "LOD_RPGWisOmniscience", function()
    local data = Information.Omniscience
    local ply = LocalPlayer()
    if not IsValid(ply) or not data or not IsValid(data.target) then return end
    if not LOD.NearLook:Qualifies(ply,data.target,4096) then return end

    local x, y = hostileIdentityAnchor(data.target)
    draw.SimpleText(tostring(data.type), "DermaDefaultBold", x, y,
        color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(string.format("LEVEL %d / CLASS %s", data.level or 1, tostring(data.class or "Hostile")),
        "DermaDefault", x, y + 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format("HP %d/%d", data.hp or 0, data.maxHP or 0),
        "DermaDefault", x, y + 16, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)

