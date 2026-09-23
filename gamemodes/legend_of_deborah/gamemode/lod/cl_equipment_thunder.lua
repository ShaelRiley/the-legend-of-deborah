-- One bounded record per charging actor. Depth-tested geometry keeps cover
-- intact; reduced effects retains the same readable warning, without particles.
local active=setmetatable({}, {__mode="k"})
local beam=Material("cable/blue_elec")
local glow=Material("sprites/light_glow02_add")
local color=Color(120,210,255,230)
net.Receive("LOD_ThunderChargeFX",function()
    local actor=net.ReadEntity()
    local origin,endpoint=net.ReadVector(),net.ReadVector()
    local starts,ends=net.ReadFloat(),net.ReadFloat()
    if IsValid(actor) then active[actor]={origin=origin,endpoint=endpoint,starts=starts,ends=ends} end
end)
hook.Add("PostDrawTranslucentRenderables","LOD_ThunderCharge",function(depth,sky)
    if depth or sky then return end
    local eye=EyePos()
    for actor,record in pairs(active) do
        if not IsValid(actor) or CurTime()>=record.ends
            or CurTime()>record.starts and actor:GetNW2Float("LOD_ThunderUntil",0)<=CurTime() then
            active[actor]=nil
        elseif actor:GetPos():DistToSqr(eye)<=2048^2 then
            local warning=CurTime()<record.starts
            local a=warning and record.origin+Vector(0,0,8) or actor:WorldSpaceCenter()
            local b=warning and record.endpoint+Vector(0,0,8)
                or a-(record.endpoint-record.origin):GetNormalized()*64
            render.SetMaterial(beam);render.DrawBeam(a,b,warning and 6 or 12,0,1,color)
            render.SetMaterial(glow);render.DrawSprite(a,warning and 32 or 48,warning and 32 or 48,color)
        end
    end
end)
