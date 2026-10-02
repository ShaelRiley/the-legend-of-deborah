-- Shared arithmetic for server authority and client prediction. These helpers
-- only modify voluntary CMoveData wish axes/caps: never actual/base velocity.
LOD = LOD or {}; LOD.FeatMovement = LOD.FeatMovement or {}
local F = LOD.FeatMovement
function F.ResolveStrafeInput(forward,side,maxSpeed,maxClientSpeed,multiplier)
    local length=math.sqrt(forward*forward+side*side)
    local cap=maxSpeed
    if maxClientSpeed>0 then cap=math.min(cap,maxClientSpeed) end
    if length==0 or side==0 or cap<=0 or multiplier<=1 then
        return forward,side,maxSpeed,maxClientSpeed,1
    end
    local scale=math.min(1,cap/length)
    forward,side=forward*scale,side*scale
    local ordinary=math.sqrt(forward*forward+side*side)
    side=side*multiplier
    local ratio=math.sqrt(forward*forward+side*side)/ordinary
    return forward,side,maxSpeed*ratio,maxClientSpeed*ratio,ratio
end
function F.Scale(move,multiplier)
    move:SetForwardSpeed(move:GetForwardSpeed()*multiplier)
    move:SetSideSpeed(move:GetSideSpeed()*multiplier)
    move:SetMaxSpeed(move:GetMaxSpeed()*multiplier)
    move:SetMaxClientSpeed(move:GetMaxClientSpeed()*multiplier)
end
function F.Strafe(move,multiplier)
    local f,s,m,c=F.ResolveStrafeInput(move:GetForwardSpeed(),move:GetSideSpeed(),
        move:GetMaxSpeed(),move:GetMaxClientSpeed(),multiplier)
    move:SetForwardSpeed(f);move:SetSideSpeed(s);move:SetMaxSpeed(m);move:SetMaxClientSpeed(c)
end
