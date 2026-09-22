-- EyeTrace preserves occlusion; each semantic row owns its vertical space.
hook.Add('HUDPaint','LOD_TeammateIdentity',function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or LOD.UI.ActivePage then return end
    local tr=ply:GetEyeTrace();local target=tr and tr.Entity
    if not IsValid(target) or not target:IsPlayer() or target==ply or not target:Alive()
        or target:GetNW2Bool('LOD_IsSoldier',false)~=ply:GetNW2Bool('LOD_IsSoldier',false) then return end
    local character=target:GetNW2String('LOD_HeroName',target:GetNW2String('LOD_Character',''))
    local rows={{target:Nick(),'identity'},
        {tostring(target:Health())..' / '..tostring(target:GetMaxHealth())..' HP','prose'},
        {'as '..character,'character'}}
    local width=math.min(480,ScrW()*.6);local y=ScrH()*.5+30
    surface.SetFont('LOD_HUD_Small')
    for _,row in ipairs(rows) do
        local line=''
        local function emit()
            LOD.UI:HUDText(line,'LOD_HUD_Small',ScrW()*.5-width*.5,y,
                LOD.UI.HUDRoles and LOD.UI.HUDRoles[row[2]] or LOD.UI.Roles[row[2]],TEXT_ALIGN_LEFT)
            y=y+20;line=''
        end
        for char in row[1]:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
            if surface.GetTextSize(line..char)>width then emit() end
            line=line..char
        end
        emit()
    end
end)
