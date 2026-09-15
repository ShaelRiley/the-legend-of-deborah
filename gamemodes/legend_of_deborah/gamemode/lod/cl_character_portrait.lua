-- Shared Character Sheet / live HUD face. One client model per visible surface.
LOD.CharacterPortrait={}
local P=LOD.CharacterPortrait
local aliases={
    smile={'smile','right_smile','left_smile','right_corner_puller','left_corner_puller'},
    brow={'right_lowerer','left_lowerer','brow_lowerer'},
    blink={'blink','right_blink','left_blink'},
    jaw={'jaw_drop'},
    tired={'right_inner_raiser','left_inner_raiser'},
    pain={'right_cheek_raiser','left_cheek_raiser','right_upper_raiser','left_upper_raiser'}
}
function P:Discover(ent)
    local names={}
    for i=0,ent:GetFlexNum()-1 do names[string.lower(ent:GetFlexName(i) or '')]=i end
    local flex={}
    for role,list in pairs(aliases) do
        flex[role]={}
        for _,name in ipairs(list) do if names[name]~=nil then flex[role][#flex[role]+1]=names[name] end end
    end
    return flex
end
function P:Configure(panel,model)
    if panel.LODModel==model and IsValid(panel:GetEntity()) then return end
    panel.LODModel=model;panel:SetModel(model)
    local ent=panel:GetEntity()
    if not IsValid(ent) then return end
    -- Avoid DModelPanel's player-model alias substitution changing the face.
    ent:SetModel(model)
    if ent.SetModelName then ent:SetModelName(model) end
    ent:SetAngles(Angle(0,25,0));ent:SetupBones()
    panel.LODHeadBone=ent:LookupBone('ValveBiped.Bip01_Head1')
    panel.LODHead=panel.LODHeadBone and select(1,ent:GetBonePosition(panel.LODHeadBone)) or Vector(0,0,64)
    panel.LODFlex=self:Discover(ent);panel.LODNextPose=0
    panel:SetLookAt(panel.LODHead+Vector(0,0,-2))
    panel:SetCamPos(panel.LODHead+Vector(48,8,3))
end
function P:Pose(panel,ent,pose,now)
    if now<(panel.LODNextPose or 0) then return end
    panel.LODNextPose=now+1/30
    pose=pose or {};local fatigue=math.Clamp(pose.fatigue or 0,0,1)
    local hurt=pose.mode=='hurt';local attack=pose.mode=='attack'
    local movement=not pose.reduced and (pose.walk or 0) or 0
    local breath=not pose.reduced and (math.sin(now*6)+1)*.5 or 0
    local weights={smile=attack and .9 or pose.sheet and .65 or 0,
        brow=hurt and .8 or attack and .45 or .18,
        blink=hurt and .75 or fatigue*.25,
        jaw=hurt and .3 or attack and .18 or fatigue*(.08+breath*.2),
        tired=fatigue*.6,pain=hurt and .8 or 0}
    for role,ids in pairs(panel.LODFlex or {}) do
        for _,id in ipairs(ids) do ent:SetFlexWeight(id,weights[role] or 0) end
    end
    if panel.LODHeadBone then
        ent:ManipulateBoneAngles(panel.LODHeadBone,Angle(fatigue*10,0,hurt and -6 or 0))
    end
    local bob=math.sin(now*9)*1.2*movement
    panel:SetLookAt(panel.LODHead+Vector(0,0,-2+bob))
end
function P:Create(parent,model)
    local panel=vgui.Create('DModelPanel',parent)
    panel:SetFOV(25);panel:SetAnimated(false)
    panel:SetAmbientLight(Color(105,91,72))
    panel:SetDirectionalLight(BOX_FRONT,Color(255,213,165))
    panel:SetDirectionalLight(BOX_TOP,Color(170,185,210))
    panel:SetColor(Color(255,255,255))
    panel:SetMouseInputEnabled(false);panel:SetKeyboardInputEnabled(false)
    self:Configure(panel,model or 'models/player/kleiner.mdl')
    panel.LayoutEntity=function(p,ent) P:Pose(p,ent,p.LODPose,RealTime()) end
    return panel
end
