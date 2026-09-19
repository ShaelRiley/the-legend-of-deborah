-- Shared dimensions for the inverted, scaled Barnacle body used by the Nodule.
-- Native movement and hitscan both use the visible body, never a humanoid hull.
LOD.HostileShapes={}
function LOD.HostileShapes:NoduleBounds(ent)
    local size=math.Clamp(ent:GetNW2Float('LOD_SizeScale',1),.33,1.33)
    local lo,hi=util.GetModelBounds(ent:GetModel())
    lo,hi=lo or Vector(-16,-16,-64),hi or Vector(16,16,0)
    -- RenderMultiply rotates by pitch 180, then lifts by original max Z.
    -- A conservative yaw-independent horizontal extent covers all orientations.
    local radius=math.max(math.abs(lo.x),math.abs(hi.x),math.abs(lo.y),math.abs(hi.y))*size
    return Vector(-radius,-radius,0),Vector(radius,radius,(hi.z-lo.z)*size)
end
