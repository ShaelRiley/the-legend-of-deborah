LOD.NeilBrutePresentation = {}
local V = LOD.NeilBrutePresentation
local beam = Material("cable/redlaser")
function V:Draw(ent,size)
    local id=ent:GetNW2String("LOD_Archetype","")
    if id=="neil" then
        -- A tiny procedural suitcase has no physics, client entity, model cache
        -- or attachment lifetime. It follows the already-rendered hand matrix.
        local bone=ent:LookupBone("ValveBiped.Bip01_R_Hand")
        local matrix=bone and ent:GetBoneMatrix(bone)
        local pos=matrix and matrix:GetTranslation() or ent:LocalToWorld(Vector(0,-14,28)*size)
        local ang=ent:GetAngles()
        render.SetColorMaterial()
        render.DrawBox(pos-Vector(0,0,10*size),ang,Vector(-10,-3,-9)*size,Vector(10,3,9)*size,Color(24,29,26))
        render.DrawWireframeBox(pos-Vector(0,0,10*size),ang,Vector(-10,-3,-9)*size,Vector(10,3,9)*size,Color(180,190,180),false)
        render.DrawBox(pos,ang,Vector(-4,-1,-2)*size,Vector(4,1,1)*size,Color(110,120,110))
    elseif id=="brute" and ent:GetNW2String("LOD_BrutePhase","")=="windup" then
        local start=ent:GetPos()+Vector(0,0,8)
        local direction=ent:GetNW2Vector("LOD_BruteDirection",Vector(1,0,0))
        local finish=start+direction*ent:GetNW2Float("LOD_BruteTravel",672)
        local tr=util.TraceLine({start=start,endpos=finish,mask=MASK_SOLID,filter=ent})
        finish=tr.Hit and tr.HitPos or finish
        render.SetMaterial(beam)
        render.DrawBeam(start,finish,8,0,1,Color(255,165,65,225))
        render.DrawWireframeSphere(start+Vector(0,0,35*size),42*size,12,6,Color(255,200,100,220),false)
    end
end
