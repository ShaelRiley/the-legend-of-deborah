include("shared.lua")

function ENT:Draw()
    if self:GetNW2Bool("LOD_CashTarget",false) then
        self:DrawModel()
        cam.Start3D2D(self:GetPos()+Vector(0,0,48),Angle(0,EyeAngles().y-90,90),.2)
            draw.RoundedBox(4,-140,-48,280,105,Color(20,22,24,235))
            draw.SimpleText("$", "DermaLarge",0,-20,Color(145,220,125),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            draw.SimpleText("SECURE THE BAG", "DermaDefaultBold",0,24,Color(240,196,94),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        cam.End3D2D()
        return
    end
    if self:GetNW2Bool("LOD_RescueCheer",false) and not self:GetNW2Bool("LOD_RescueCheerSequence",false) then
        -- Models without a cheer sequence still visibly celebrate. Bone angles
        -- are cosmetic only, with no changes to her server hull or placement.
        local clap=math.sin(CurTime()*8)*12
        for _,side in ipairs({"L","R"}) do
            local sign=side=="L" and 1 or -1
            local upper=self:LookupBone("ValveBiped.Bip01_"..side.."_UpperArm")
            local fore=self:LookupBone("ValveBiped.Bip01_"..side.."_Forearm")
            if upper then self:ManipulateBoneAngles(upper,Angle(0,sign*(50+clap),-55)) end
            if fore then self:ManipulateBoneAngles(fore,Angle(0,sign*65,0)) end
        end
    end
    if LOD.Damsels and LOD.Damsels.DrawActor then LOD.Damsels:DrawActor(self,false) else self:DrawModel() end
end
