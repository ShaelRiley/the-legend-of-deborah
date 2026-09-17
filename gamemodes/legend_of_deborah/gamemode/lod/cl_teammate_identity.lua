-- Actual aimed entity, so no team labels through intervening walls.
local cached,parts,lines,key
hook.Add('HUDPaint','LOD_TeammateIdentity',function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or LOD.UI.ActivePage then return end
    local tr=ply:GetEyeTrace();local target=tr and tr.Entity
    if not IsValid(target) or not target:IsPlayer() or target==ply or not target:Alive()
        or target:GetNW2Bool('LOD_IsSoldier',false)~=ply:GetNW2Bool('LOD_IsSoldier',false) then return end
    local character=target:GetNW2String('LOD_Character','')
    if character=='' then return end
    local name=target:Nick();local text=name..' as '..character
    local width=math.min(420,ScrW()*.5);local signature=text..':'..width
    if key~=signature then
        key=signature;lines={{}};parts={{name,'identity'},{' as ','prose'},{character,'character'}}
        surface.SetFont('LOD_HUD_Small');local x=0
        for _,part in ipairs(parts) do
            for char in part[1]:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
                local w=surface.GetTextSize(char)
                if x+w>width then lines[#lines+1]={};x=0 end
                lines[#lines][#lines[#lines]+1]={text=char,x=x,role=part[2]};x=x+w
            end
        end
    end
    for i,line in ipairs(lines) do
        for _,span in ipairs(line) do
            LOD.UI:HUDText(span.text,'LOD_HUD_Small',ScrW()*.5-width*.5+span.x,ScrH()*.5+30+(i-1)*18,
                LOD.UI.HUDRoles and LOD.UI.HUDRoles[span.role] or LOD.UI.Roles[span.role],TEXT_ALIGN_LEFT)
        end
    end
end)
