local D=LOD.Damsels
D.Materials=D.Materials or {}
local appearanceRevision='native-material-v2'
-- Named inputs for successive bits of the engine's $flags integer:
-- https://wiki.facepunch.com/gmod/Material_Flags
local materialFlags={
    '$debug','$no_fullbright','$no_draw','$use_in_fillrate_mode','$vertexcolor','$vertexalpha',
    '$selfillum','$additive','$alphatest','$multipass','$znearer','$model','$flat','$nocull',
    '$nofog','$ignorez','$decal','$envmapsphere','$noalphamod','$envmapcameraspace',
    '$basealphaenvmapmask','$translucent','$normalmapalphaenvmapmask','$softwareskin',
    '$opaquetexture','$envmapmode','$nodecal','$halflambert','$wireframe','$allowalphatocoverage'
}
local compiledFields={['$flags']=true,['$flags2']=true,['$flags_defined']=true,['$flags_defined2']=true}
local function materialValues(source)
    local raw=source:GetKeyValues() or {}
    local values,matrices={},{}
    for key,value in pairs(raw) do
        if not compiledFields[key] then
            local kind=type(value)
            if kind=='ITexture' then
                local name=value:GetName()
                if not value:IsError() and name~='' and name~='error' then values[key]=name end
            elseif kind=='Vector' then
                values[key]=string.format('[%.9g %.9g %.9g]',value.x,value.y,value.z)
            elseif kind=='VMatrix' then matrices[key]=value
            else values[key]=value end
        end
    end
    -- Compiled bookkeeping is not a VMT declaration. Reconstruct its actual
    -- named flags before shader initialization; flags2 is derived by Source.
    local flags=tonumber(raw['$flags']) or 0
    for index,name in ipairs(materialFlags) do
        if math.floor(flags/2^(index-1))%2==1 then values[name]='1' end
    end
    return values,matrices
end
function D:ApplyAppearance(ent,level,seed)
    local def=self.Definitions[level]
    if not def or not def.recolor then return end
    local cacheKey=appearanceRevision..':'..tostring(seed)..':'..level..':'..ent:GetModel()
    if ent.LODDamselAppearance==cacheKey then return end
    ent.LODDamselAppearance=cacheKey
    local cloth,accent=self:Palette(seed,def.family)
    ent.LODDamselAccent=accent
    for index,path in ipairs(ent:GetMaterials() or {}) do
        local lower=string.lower(path)
        -- Citizen face sheets are separate. Do not tint faces, eyes or teeth.
        if lower:find('sheet',1,true) and not lower:find('head',1,true) and not lower:find('face',1,true) then
            local id=appearanceRevision..':'..path..':'..cloth.r..':'..cloth.g..':'..cloth.b
            local material=self.Materials[id]
            if not material then
                local source=Material(path);local texture=source:GetTexture('$basetexture')
                if texture then
                    local values,matrices=materialValues(source)
                    values['$basetexture']=texture:GetName();values['$model']='1'
                    values['$color2']=string.format('[%f %f %f]',cloth.r/255,cloth.g/255,cloth.b/255)
                    material=CreateMaterial('LOD_Damsel_'..util.CRC(id),source:GetShader() or 'VertexLitGeneric',values)
                    for key,matrix in pairs(matrices) do material:SetMatrix(key,matrix) end
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
        if staged then draw.SimpleText(level==20 and '[E]  TALK / ABUNDANCE' or '[E]  TALK','DermaDefaultBold',0,30,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
    cam.End3D2D()
end
net.Receive('LOD_DamselState',function()
    local seed,level,highest=net.ReadUInt(31),net.ReadDouble(),net.ReadDouble()
    local rescued={};for i=1,20 do rescued[i]=net.ReadBool() end
    local cash=net.ReadDouble()
    -- Optional tail preserves older mounted state packets during installation.
    local epoch=net.BytesLeft and net.BytesLeft()>=4 and net.ReadUInt(32) or 0
    D.Campaign={seed=seed,epoch=epoch,level=level,highest=highest,rescued=rescued,cash=cash}
    LOD.ClientState=LOD.ClientState or {}
    LOD.ClientState.RescueTarget=D:Target(level)
end)
local function dialogueLabels(parent,text,font,color,bottomMargin)
    -- Native Label truncates at 1023 bytes, even inside a scroll canvas. Keep
    -- every authored byte in bounded labels, preferring paragraph boundaries.
    text=tostring(text or '')
    local first=1
    repeat
        local last=math.min(first+1022,#text)
        if last<#text then
            local paragraph=text:sub(first,last):match('.*()\n\n')
            if paragraph then last=first+paragraph end
            -- Never cut before a UTF-8 continuation byte.
            local nextByte=text:byte(last+1)
            while nextByte and nextByte>=128 and nextByte<=191 do
                last=last-1;nextByte=text:byte(last+1)
            end
        end
        local label=vgui.Create('DLabel',parent);label:Dock(TOP)
        label:DockMargin(0,0,8,last==#text and bottomMargin or 0)
        label:SetFont(font);label:SetTextColor(color)
        label:SetWrap(true);label:SetAutoStretchVertical(true)
        label:SetText(text:sub(first,last))
        first=last+1
    until first>#text
end
function D:ShowDialogue(level,line,result)
    if IsValid(self.DialogueFrame) then self.DialogueFrame:Remove() end
    local def=self.Definitions[level]
    local frame=vgui.Create('DFrame');self.DialogueFrame=frame
    local guideTalk=level==31 or level==30
    local speaker=guideTalk and (level==30 and 'Hector the Director' or 'Dungeon Hermit')
        or (def and def.name or 'Gordon the Warden')
    local width=math.min(760,ScrW()-32);local height=math.min(400,ScrH()-32)
    frame:SetSize(width,height);frame:SetPos((ScrW()-width)/2,math.max(16,ScrH()-height-42))
    frame:SetTitle('');frame:SetDraggable(false);frame:MakePopup()
    frame.Paint=function(_,w,h)
        surface.SetDrawColor(22,25,25,248);surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(210,170,82,255);surface.DrawOutlinedRect(0,0,w,h,2)
    end
    local portrait=vgui.Create('DModelPanel',frame);portrait:SetPos(14,36);portrait:SetSize(124,160)
    portrait:SetModel(guideTalk and 'models/player/monk.mdl' or (def and self:Model(def) or 'models/Humans/Group01/male_04.mdl'))
    portrait:SetFOV(26);portrait:SetCamPos(Vector(46,0,64));portrait:SetLookAt(Vector(0,0,65))
    portrait.LayoutEntity=function(_,ent)
        ent:SetAngles(Angle(0,0,0))
        if guideTalk and LOD.FriendlyIdle then LOD.FriendlyIdle:Apply(ent,'hermit',true) end
    end
    if def then self:ApplyAppearance(portrait.Entity,level,self.Campaign and self.Campaign.seed or 1) end
    if guideTalk and IsValid(portrait.Entity) then portrait.Entity:SetColor(Color(196,60,60)) end
    local showPortrait=width>=560 and height>=270
    portrait:SetVisible(showPortrait)
    local textX=showPortrait and 152 or 16
    local name=vgui.Create('DLabel',frame);name:SetPos(textX,22);name:SetSize(width-textX-18,30)
    name:SetFont(width<500 and 'DermaDefaultBold' or 'DermaLarge')
    name:SetTextColor(Color(240,196,94));name:SetText(speaker)
    -- Native scroll canvas owns the long text; invitation and actual grant
    -- receipt stay separate. Auto-stretch uses Derma's wrapped text measurement.
    local scroll=vgui.Create('DScrollPanel',frame);scroll:SetPos(textX,60);scroll:SetSize(width-textX-18,height-104)
    dialogueLabels(scroll,line,'DermaDefaultBold',Color(236,231,214),16)
    dialogueLabels(scroll,result,'DermaDefault',Color(240,196,94),12)
    local done=vgui.Create('DButton',frame);done:SetPos(width-104,height-30);done:SetSize(88,22);done:SetText('Close')
    done.DoClick=function() frame:Close() end
    frame.OnKeyCodePressed=function(_,key) if key==KEY_E or key==KEY_ESCAPE or key==KEY_SPACE then frame:Close() end end
    local campaign=self.Campaign
    local seed,epoch,dungeon=campaign and campaign.seed,campaign and campaign.epoch,campaign and campaign.level
    local guide,guideLabel
    if guideTalk then
        for _,ent in ipairs(ents.FindByClass('lod_staging_prop')) do
            if ent.GetStageKind and ent:GetStageKind()==1 then
                guide,guideLabel=ent,ent:GetStageLabel();break
            end
        end
    end
    frame.Think=function()
        local ply=LocalPlayer();local current=self.Campaign
        if not IsValid(ply) or not ply:Alive() or not ply:GetNW2Bool('LOD_Staged',false)
            or ply:GetNW2Bool('LOD_Deployed',false)
            or (seed and (not current or current.seed~=seed or current.epoch~=epoch or current.level~=dungeon))
            or (guide and (not IsValid(guide) or guide:GetStageLabel()~=guideLabel)) then frame:Close() end
    end
    frame.OnRemove=function() if self.DialogueFrame==frame then self.DialogueFrame=nil end end
end
net.Receive('LOD_DamselDialogue',function() D:ShowDialogue(net.ReadUInt(5),net.ReadString(),net.ReadString()) end)
hook.Add('HUDPaint','LOD_DamselCampaignRecord',function()
    local c=D.Campaign;local ply=LocalPlayer()
    if not c or not IsValid(ply) or not ply:GetNW2Bool('LOD_Staged',false) or (LOD.UI and LOD.UI.ActivePage) then return end
    local n=0;for _,rescued in ipairs(c.rescued) do if rescued then n=n+1 end end
    draw.SimpleText(string.format('%d / 20 RESCUED   •   HIGHEST LEVEL %d%s',n,c.highest,c.cash>0 and ('   •   '..c.cash..' BAGS RECOVERED') or ''),
        'DermaDefaultBold',ScrW()/2,76,Color(240,196,94),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP)
end)
