-- One leased, client-only gun. No AI/physics, remote files or permanent models.
local D=LOD.DamselRevenge
if D.ReleaseVisual then D:ReleaseVisual() end
function D:VisualCurrent(e)
    if not IsValid(e) or e:GetClass()~='lod_deborah' or e:IsDormant()
        or e:GetNW2Bool('LOD_CashTarget',false) or CurTime()>=e:GetNW2Float('LOD_RevengeUntil',0) then return false end
    local spec=self:Firearm(e:GetNW2String('LOD_RevengeGun',''))
    local jail=e:GetNW2Entity('LOD_RevengeJail')
    return spec and IsValid(jail) and jail:GetNW2Entity('LOD_RevengeDamsel')==e
        and CurTime()<jail:GetNW2Float('LOD_RevengePortUntil',0),spec
end
function D:ReleaseVisual()
    local r=self.visual;if not r then return end
    if IsValid(r.model) then r.model:Remove() end
    if IsValid(r.actor) and r.actor.LODRevengeVisual==r then
        -- Release only these owned edits; another pose source may have replaced them.
        for index,pose in pairs(r.bones) do
            local current=r.actor:GetManipulateBoneAngles(index)
            if current and current==pose.applied then r.actor:ManipulateBoneAngles(index,pose.before) end
        end
        r.actor.LODRevengeVisual=nil
    end
    self.visual=nil
end
local bones={
    {'ValveBiped.Bip01_R_UpperArm',Angle(0,-55,-20)},
    {'ValveBiped.Bip01_R_Forearm',Angle(0,-65,0)},
    {'ValveBiped.Bip01_L_UpperArm',Angle(0,40,-45)},
    {'ValveBiped.Bip01_L_Forearm',Angle(0,65,0)}
}
function D:Pose(e)
    local valid,spec=self:VisualCurrent(e)
    if not valid then if self.visual and self.visual.actor==e then self:ReleaseVisual() end;return end
    local r=self.visual
    if r and (r.actor~=e or r.class~=spec.class) then self:ReleaseVisual();r=nil end
    if not r then
        local def=LOD.Equipment.Definitions[spec.class]
        local model=ClientsideModel(def.model,RENDERGROUP_OPAQUE)
        if not IsValid(model) then return end
        model:SetNoDraw(true)
        r={actor=e,class=spec.class,model=model,bones={}};self.visual=r;e.LODRevengeVisual=r
        for _,entry in ipairs(bones) do
            local index=e:LookupBone(entry[1])
            if index then r.bones[index]={before=e:GetManipulateBoneAngles(index),applied=entry[2]} end
        end
    end
    for index,pose in pairs(r.bones) do e:ManipulateBoneAngles(index,pose.applied) end
end
function D:DrawGun(e)
    local r=self.visual
    if not r or r.actor~=e or not IsValid(r.model) or not self:VisualCurrent(e) then return end
    local hand=e:LookupBone('ValveBiped.Bip01_R_Hand')
    local matrix=hand and e:GetBoneMatrix(hand)
    local pos=matrix and matrix:GetTranslation() or e:LocalToWorld(Vector(12,-6,48))
    local aim=e:GetNW2Vector('LOD_RevengeAim',e:GetPos()+e:GetForward()*256+Vector(0,0,52))
    local delta=aim-(e:GetPos()+Vector(0,0,52))
    if delta:LengthSqr()<1 then delta=e:GetForward() end
    local ang=delta:Angle()
    local elapsed=CurTime()-e:GetNW2Float('LOD_RevengeShot',-100)
    local recoil=elapsed>=0 and elapsed<.12 and (1-elapsed/.12) or 0
    ang.p=ang.p-recoil*5
    r.model:SetPos(pos-ang:Forward()*recoil*2);r.model:SetAngles(ang);r.model:DrawModel()
end
-- Same slit dimensions as the two-face server ray proof. Only rendering changes;
-- the existing door collision, lock and overhead barrier remain untouched.
function D:DrawPort(e,origin,mins,maxs,color)
    local actor=e:GetNW2Entity('LOD_RevengeDamsel')
    if e:GetOpened() or not self:VisualCurrent(actor) or actor:GetNW2Entity('LOD_RevengeJail')~=e then return false end
    local width,height=self:PortSize()
    local side=e:GetDoorAxis()==0 and 'y' or 'x'
    local middle=mins.z+self.Config.muzzle
    local function box(lo,hi)
        if hi.x>lo.x and hi.y>lo.y and hi.z>lo.z then render.DrawBox(origin,angle_zero,lo,hi,color) end
    end
    local function copy(v) return Vector(v.x,v.y,v.z) end
    local lo,hi=copy(mins),copy(maxs);hi[side]=-width*.5;box(lo,hi)
    lo,hi=copy(mins),copy(maxs);lo[side]=width*.5;box(lo,hi)
    lo,hi=copy(mins),copy(maxs);lo[side]=-width*.5;hi[side]=width*.5;hi.z=middle-height*.5;box(lo,hi)
    lo,hi=copy(mins),copy(maxs);lo[side]=-width*.5;hi[side]=width*.5;lo.z=middle+height*.5;box(lo,hi)
    return true
end
local nextCheck=0
hook.Add('Think','LOD_DamselRevengeVisualLifetime',function()
    local now=CurTime();if now<nextCheck then return end;nextCheck=now+.2
    if D.visual and not D:VisualCurrent(D.visual.actor) then D:ReleaseVisual() end
end)
hook.Add('PreCleanupMap','LOD_DamselRevengeVisualCleanup',function() D:ReleaseVisual() end)
hook.Add('ShutDown','LOD_DamselRevengeVisualShutdown',function() D:ReleaseVisual() end)
