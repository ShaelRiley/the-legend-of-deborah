AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')
include('shared.lua')

-- Citizen sequence indexes vary between mounted model revisions. Pick the
-- folded-arm frame by hand/shoulder geometry rather than assuming an index.
function ENT:FreezeDeborahPose()
    local bones={}
    for _,name in ipairs({'L_UpperArm','R_UpperArm','L_Hand','R_Hand'}) do
        local id=self:LookupBone('ValveBiped.Bip01_'..name)
        if not id then return end
        bones[name]=id
    end
    local best
    for _,name in ipairs({'LineIdle01','LineIdle02','LineIdle03'}) do
        local sequence=self:LookupSequence(name)
        if sequence and sequence>=0 then
            for _,cycle in ipairs({0,.25,.5,.75}) do
                self:ResetSequence(sequence);self:SetCycle(cycle);self:SetupBones()
                local ls=self:GetBonePosition(bones.L_UpperArm)
                local rs=self:GetBonePosition(bones.R_UpperArm)
                local lh=self:GetBonePosition(bones.L_Hand)
                local rh=self:GetBonePosition(bones.R_Hand)
                if ls and rs and lh and rh and ls:DistToSqr(rs)>16 then
                    local side=(ls-rs):GetNormalized()
                    local crossed=(lh-rh):Dot(side)<0
                    local drop=Vector(0,0,10)
                    local score=lh:DistToSqr(rs-drop)+rh:DistToSqr(ls-drop)+(crossed and 0 or 10000)
                    if not best or score<best.score then
                        best={sequence=sequence,cycle=cycle,score=score,crossed=crossed,name=name}
                    end
                end
            end
        end
    end
    if best then
        self:ResetSequence(best.sequence);self:SetCycle(best.cycle)
        self.LODStatuePose=best.name;self.LODStatueArmsCrossed=best.crossed
    end
    self:SetPlaybackRate(0)
    self:SetNW2Int("LOD_StatueSequence",best and best.sequence or self:GetSequence())
    self:SetNW2Float("LOD_StatueCycle",best and best.cycle or 0)
    local scowl={right_lowerer=.8,left_lowerer=.8,right_lid_tightener=.35,left_lid_tightener=.35,
        right_corner_depressor=.35,left_corner_depressor=.35}
    self:SetFlexScale(1)
    for i=0,self:GetFlexNum()-1 do
        self:SetFlexWeight(i,scowl[string.lower(self:GetFlexName(i) or '')] or 0)
    end
    if LOD.RPGTestLog then
        LOD.RPGTestLog:Write('DEBBIE_STATUE_POSE',{model=self:GetModel(),
            sequence=best and best.name or 'unavailable',crossed=best and best.crossed or false})
    end
end

function ENT:Initialize()
    self:SetModel(LOD.Config.Models.Deborah)
    self:SetModelScale(1.2,0)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-20,-20,0),Vector(20,20,89))
    self:SetUseType(SIMPLE_USE)
    self:SetMaterial('models/props_wasteland/rockgranite02a')
    self:SetColor(Color(170,175,180))
    local sequence=self:LookupSequence('LineIdle01')
    if sequence and sequence>=0 then self:ResetSequence(sequence) end
    self:SetCycle(0)
    self:SetPlaybackRate(0)
    -- SetModel/Spawn must finish before native sequence/bone evaluation.
    timer.Simple(0,function() if IsValid(self) then self:FreezeDeborahPose() end end)
end
function ENT:Use(ply)
    if LOD.CryptoDirector then LOD.CryptoDirector:OpenStatue(ply,self) end
end
