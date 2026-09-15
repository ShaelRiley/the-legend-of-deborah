-- Size feats change the model/hitboxes, never the legal player movement hull.
-- SetHull/SetHullDuck are not networked; prediction must install the same values.
LOD.PlayerScaleCollision={}
local C=LOD.PlayerScaleCollision
local mins=Vector(-16,-16,0)
local standing=Vector(16,16,72)
local ducked=Vector(16,16,36)
function C:Bounds(ply)
    return mins,ply:Crouching() and ducked or standing
end
function C:Preserve(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    ply:SetHull(mins,standing)
    ply:SetHullDuck(mins,ducked)
end
function C:CanScale(ply,scale)
    -- A conservative occupied-volume test also covers native scale expansion.
    -- Never move/teleport the actor to make a requested scale fit.
    local low,high=self:Bounds(ply)
    local extent=math.max(1,scale)
    local pos=ply:GetPos()
    local tr=util.TraceHull({start=pos,endpos=pos,mins=low*extent,maxs=high*extent,
        filter=ply,mask=MASK_PLAYERSOLID,collisiongroup=COLLISION_GROUP_PLAYER_MOVEMENT})
    return not tr.StartSolid and not tr.AllSolid and not tr.Hit
end
hook.Add('SetupMove','LOD_PlayerScaleLegalHull',function(ply)
    -- Reinstate explicit hulls before both predicted and authoritative movement.
    -- This is intentionally independent of delayed RPG/NW2 snapshots.
    C:Preserve(ply)
end)
