local D=LOD.Damsels
D.Materials=D.Materials or {}
function D:ApplyAppearance(ent,level,seed)
    local def=self.Definitions[level]
    if not def or not def.recolor then return end
    local cacheKey=tostring(seed)..':'..level..':'..ent:GetModel()
    if ent.LODDamselAppearance==cacheKey then return end
    ent.LODDamselAppearance=cacheKey
    local cloth,accent=self:Palette(seed,def.family)
    ent.LODDamselAccent=accent
    for index,path in ipairs(ent:GetMaterials() or {}) do
        local lower=string.lower(path)
        -- Citizen face sheets are separate. Do not tint faces, eyes or teeth.
        if lower:find('sheet',1,true) and not lower:find('head',1,true) and not lower:find('face',1,true) then
            local id=path..':'..cloth.r..':'..cloth.g..':'..cloth.b
            local material=self.Materials[id]
            if not material then
                local source=Material(path);local texture=source:GetTexture('$basetexture')
                if texture then
                    local values=table.Copy(source:GetKeyValues() or {})
                    values['$basetexture']=texture:GetName();values['$model']='1'
                    values['$color2']=string.format('[%f %f %f]',cloth.r/255,cloth.g/255,cloth.b/255)
                    material=CreateMaterial('LOD_Damsel_'..util.CRC(id),source:GetShader() or 'VertexLitGeneric',values)
                    self.Materials[id]=material
                end
            end
            if material then ent:SetSubMaterial(index-1,'!'..material:GetName()) end
        end
    end
end
function D:DrawActor(ent,staged)
    local level=ent:GetNW2Int('LOD_DamselLevel',1)
    self:ApplyAppearance(ent,level,ent:GetNW2Int('LOD_DamselSeed',1))
    ent:DrawModel()
    if ent:GetPos():DistToSqr(EyePos())>650^2 then return end
    if staged then
        local sight=ent:WorldSpaceCenter()-EyePos()
        if sight:LengthSqr()>220^2 or sight:GetNormalized():Dot(EyeAngles():Forward())<.90 then return end
    end
    local def=self.Definitions[level];if not def then return end
    local pos=ent:GetPos()+Vector(0,0,82);local ang=Angle(0,EyeAngles().y-90,90)
    cam.Start3D2D(pos,ang,.1)
        draw.RoundedBox(3,-125,-24,250,staged and 70 or 48,Color(20,22,24,225))
        draw.SimpleText(string.upper(def.name),'DermaLarge',0,0,Color(240,196,94),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        if staged then draw.SimpleText(level==20 and '[E]  ABUNDANCE' or '[E]  TALK','DermaDefaultBold',0,30,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
    cam.End3D2D()
end
net.Receive('LOD_DamselState',function()
    local seed,level,highest=net.ReadUInt(31),net.ReadDouble(),net.ReadDouble()
    local rescued={};for i=1,20 do rescued[i]=net.ReadBool() end
    local cash=net.ReadDouble()
    D.Campaign={seed=seed,level=level,highest=highest,rescued=rescued,cash=cash}
    LOD.ClientState=LOD.ClientState or {}
    LOD.ClientState.RescueTarget=D:Target(level)
end)
function D:ShowDialogue(level,line,result)
    if IsValid(self.DialogueFrame) then self.DialogueFrame:Remove() end
    local def=self.Definitions[level]
    local frame=vgui.Create('DFrame');self.DialogueFrame=frame
    local width=math.min(700,ScrW()-32);local height=math.min(235,ScrH()-32)
    frame:SetSize(width,height);frame:SetPos((ScrW()-width)/2,ScrH()-height-42)
    frame:SetTitle('');frame:SetDraggable(false);frame:MakePopup()
    frame.Paint=function(_,w,h)
        surface.SetDrawColor(22,25,25,248);surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(210,170,82,255);surface.DrawOutlinedRect(0,0,w,h,2)
    end
    local portrait=vgui.Create('DModelPanel',frame);portrait:SetPos(14,36);portrait:SetSize(124,160)
    portrait:SetModel(def and self:Model(def) or 'models/Humans/Group01/male_04.mdl')
    portrait:SetFOV(26);portrait:SetCamPos(Vector(46,0,64));portrait:SetLookAt(Vector(0,0,65))
    portrait.LayoutEntity=function(_,ent) ent:SetAngles(Angle(0,0,0)) end
    if def then self:ApplyAppearance(portrait.Entity,level,self.Campaign and self.Campaign.seed or 1) end
    local name=vgui.Create('DLabel',frame);name:SetPos(152,22);name:SetSize(width-170,30)
    name:SetFont('DermaLarge');name:SetTextColor(Color(240,196,94));name:SetText(def and def.name or 'Gordon the Warden')
    local dialogue=vgui.Create('DLabel',frame);dialogue:SetPos(152,60);dialogue:SetSize(width-174,93)
    dialogue:SetFont('DermaDefaultBold');dialogue:SetTextColor(Color(236,231,214));dialogue:SetWrap(true);dialogue:SetText(line)
    local receipt=vgui.Create('DLabel',frame);receipt:SetPos(152,152);receipt:SetSize(width-174,44)
    receipt:SetFont('DermaDefault');receipt:SetTextColor(Color(240,196,94));receipt:SetWrap(true);receipt:SetText(result)
    local done=vgui.Create('DButton',frame);done:SetPos(width-104,height-30);done:SetSize(88,22);done:SetText('Continue')
    done.DoClick=function() frame:Close() end
    frame.OnKeyCodePressed=function(_,key) if key==KEY_E or key==KEY_ESCAPE or key==KEY_SPACE then frame:Close() end end
end
net.Receive('LOD_DamselDialogue',function() D:ShowDialogue(net.ReadUInt(5),net.ReadString(),net.ReadString()) end)
hook.Add('HUDPaint','LOD_DamselCampaignRecord',function()
    local c=D.Campaign;local ply=LocalPlayer()
    if not c or not IsValid(ply) or not ply:GetNW2Bool('LOD_Staged',false) or (LOD.UI and LOD.UI.ActivePage) then return end
    local n=0;for _,rescued in ipairs(c.rescued) do if rescued then n=n+1 end end
    draw.SimpleText(string.format('%d / 20 RESCUED   •   HIGHEST LEVEL %d%s',n,c.highest,c.cash>0 and ('   •   '..c.cash..' BAGS RECOVERED') or ''),
        'DermaDefaultBold',ScrW()/2,76,Color(240,196,94),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
end)
