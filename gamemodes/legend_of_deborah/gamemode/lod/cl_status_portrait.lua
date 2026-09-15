-- Cosmetic consumer of existing replication; never predicts or applies statuses.
if LOD.StatusPortrait and IsValid(LOD.StatusPortrait.Panel) then LOD.StatusPortrait.Panel:Remove() end
LOD.StatusPortrait={Conditions={},Order={}}
local H,P,UI=LOD.StatusPortrait,LOD.CharacterPortrait,LOD.UI
local reduced=GetConVar('lod_reduced_effects')
function H:RegisterCondition(id,label,key,beneficial)
    if not self.Conditions[id] then self.Order[#self.Order+1]=id end
    self.Conditions[id]={label=label,key=key,beneficial=beneficial==true}
end
for _,row in ipairs({{'immolated','IMMOLATED','Immolated'},{'poisoned','POISONED','Poisoned'},
    {'bleeding','BLEEDING','Bleeding'},{'clumsy','CLUMSY','Clumsy'},{'muted','MUTED','Muted'},
    {'held','HELD','Held'},{'reckless','RECKLESS','Reckless'},
    {'arcane_shattered','SHIELD SHATTERED','ArcaneShattered'},{'intimidated','INTIMIDATED','Intimidated'}}) do
    H:RegisterCondition(row[1],row[2],'LOD_Status'..row[3])
end
function H:Reset()
    self.HP=nil;self.Identity=nil;self.HurtUntil=0;self.AttackUntil=0;self.NextSample=0
    self.Caption=nil;self.Lines=nil;self.Pose=nil;self.WrapText=nil;self.WrapWidth=nil
end
H:Reset()
function H:Attack(ply)
    if ply~=LocalPlayer() or not IsValid(ply) or not ply:Alive() then return end
    self.AttackUntil=RealTime()+.35
end
function H:Sample(ply,snapshot,now)
    local soldier=ply:GetNW2Bool('LOD_IsSoldier',false)
    -- A queued Hero snapshot must never put the previous Hero's face on a Soldier.
    local matching=snapshot and ((snapshot.isSoldier==true)==soldier)
    local model=matching and snapshot.model or ply:GetModel()
    local name=matching and snapshot.fullDisplayName or ply:GetNW2String('LOD_Character','')
    if not name or name=='' then name=soldier and 'Human Soldier' or 'Hero' end
    local identity=tostring(soldier)..':'..tostring(matching and snapshot.portraitCacheKey or model)..':'..name
    local hp=ply:Health()
    if self.Identity~=identity then self:Reset();self.Identity=identity end
    if self.HP and hp<self.HP then self.HurtUntil=now+.45 end
    self.HP=hp
    local labels={};local harmful=false
    for _,id in ipairs(self.Order) do
        local condition=self.Conditions[id]
        if ply:GetNW2Bool(condition.key,false) then
            labels[#labels+1]=condition.label;harmful=harmful or not condition.beneficial
        end
    end
    self.Caption=#labels>0 and table.concat(labels,' / ') or name
    self.Harmful=harmful;self.Affected=#labels>0;self.Model=model
    self.Pose={fatigue=1-math.Clamp(hp/math.max(1,ply:GetMaxHealth()),0,1)}
end
-- Cache wrapping when text or viewport changes; no per-frame layout allocation.
function H:Wrap(text,width)
    if text==self.WrapText and width==self.WrapWidth then return self.Lines end
    surface.SetFont('LOD_HUD_Small')
    local lines,line={},''
    for word in text:gmatch('%S+') do
        local nextLine=line=='' and word or line..' '..word
        if line~='' and surface.GetTextSize(nextLine)>width then lines[#lines+1]=line;line=word
        else line=nextLine end
    end
    if line~='' then lines[#lines+1]=line end
    self.CaptionWidth=0
    for _,wrapped in ipairs(lines) do self.CaptionWidth=math.max(self.CaptionWidth,surface.GetTextSize(wrapped)) end
    self.WrapText=text;self.WrapWidth=width;self.Lines=lines
    return lines
end
function H:Visible(ply)
    if not IsValid(ply) or not ply:Alive() or ply:GetObserverMode()~=OBS_MODE_NONE then return false end
    if not ply:GetNW2Bool('LOD_PlayedIdentity',false) and not ply:GetNW2Bool('LOD_IsSoldier',false) then return false end
    if UI.ActivePage or gui.IsGameUIVisible() then return false end
    if LOD.FieldManual and IsValid(LOD.FieldManual.Frame) then return false end
    if ply:GetNW2Bool('LOD_DeathTetrisActive',false) then return false end
    local state=LOD.ClientState
    return not state or not (state.failed or state.levelCleared)
end
-- Full procedural names live on Equipment; two compact lines fit the HUD.
function H:WeaponCaption(ply,width)
    local weapon=ply:GetActiveWeapon()
    local name=IsValid(weapon) and weapon:GetNW2String('LOD_ItemName','') or ''
    if name=='' and IsValid(weapon) and weapon:GetClass()~='weapon_lod_empty_hands' then
        name=weapon:GetPrintName() or ''
    end
    local key=name..':'..width
    if key==self.WeaponKey then return self.WeaponLines end
    surface.SetFont('DermaDefault')
    local lines,line={},''
    for word in name:gmatch('%S+') do
        local candidate=line=='' and word or line..' '..word
        if surface.GetTextSize(candidate)>width and line~='' then
            lines[#lines+1]=line;line=word
        else line=candidate end
    end
    if line~='' then lines[#lines+1]=line end
    for i=1,math.min(2,#lines) do
        local text=lines[i]
        if surface.GetTextSize(text)>width or (i==2 and #lines>2) then
            while #text>0 and surface.GetTextSize(text..'...')>width do text=text:sub(1,-2) end
            lines[i]=text..'...'
        end
    end
    while #lines>2 do table.remove(lines) end
    self.WeaponKey=key;self.WeaponLines=lines
    return lines
end
function H:Draw()
    local ply=LocalPlayer()
    if not self:Visible(ply) then
        -- Retire the model while hidden. DModelPanel:OnRemove releases its entity.
        if IsValid(self.Panel) then self.Panel:Remove();self.Panel=nil end
        self:Reset();return
    end
    local now=RealTime()
    if now>=(self.NextSample or 0) then
        self:Sample(ply,LOD.CharacterSheet and LOD.CharacterSheet.Snapshot,now)
        self.NextSample=now+.1
    end
    if not self.Pose then return end
    local pose=self.Pose
    pose.mode=now<self.HurtUntil and 'hurt' or now<self.AttackUntil and 'attack' or 'idle'
    pose.reduced=reduced and reduced:GetBool() or false
    pose.walk=ply:OnGround() and math.Clamp(ply:GetVelocity():Length2D()/math.max(1,ply:GetWalkSpeed()),0,1) or 0
    local size=math.Clamp(ScrH()*.12,64,128)
    local magicX,magicY,magicW,magicH=LOD.MagicHUD:Bounds()
    local x,y=magicX+magicW+12,magicY+magicH-size
    local feedLeft=ScrW()-22-math.min(600,ScrW()*.44)
    local weaponX=x+size+10
    local weaponWidth=math.max(48,math.min(300,feedLeft-12-weaponX))
    local weaponLines=self:WeaponCaption(ply,weaponWidth)
    local lines=self:Wrap(self.Caption,math.min(340,ScrW()*.5-44))
    -- Captions grow upward; ailments never displace the face or cover Magic.
    -- Keep their right edge out of the lower-right combat-feed column.
    local textX=math.max(22,math.min(x+(size-self.CaptionWidth)*.5,feedLeft-12-self.CaptionWidth))
    local textY=y-8-#lines*18
    if not IsValid(self.Panel) then
        self.Panel=P:Create(nil,self.Model);self.Panel:SetPaintedManually(true)
    else P:Configure(self.Panel,self.Model) end
    local panel=self.Panel;panel.LODPose=pose
    panel:SetPos(x,y);panel:SetSize(size,size)
    draw.RoundedBox(2,x,y,size,size,Color(20,22,25,180))
    panel:PaintManual()
    local weaponY=y+(size-#weaponLines*14)*.5
    for i,line in ipairs(weaponLines) do
        UI:HUDText(line,'DermaDefault',weaponX,weaponY+(i-1)*14,UI.HUDColor,TEXT_ALIGN_LEFT)
    end
    local color=self.Harmful and Color(255,135,100) or self.Affected and Color(145,230,170) or UI.HUDColor
    for i,line in ipairs(lines) do
        UI:HUDText(line,'LOD_HUD_Small',textX+self.CaptionWidth*.5,textY+(i-1)*18,color,TEXT_ALIGN_CENTER)
    end
end
hook.Add('HUDPaint','LOD_StatusPortrait',function() H:Draw() end)
hook.Add('EntityFireBullets','LOD_PortraitShot',function(ply) H:Attack(ply) end)
hook.Add('DoAnimationEvent','LOD_PortraitMelee',function(ply,event)
    if event==PLAYERANIMEVENT_ATTACK_PRIMARY or event==PLAYERANIMEVENT_ATTACK_SECONDARY then H:Attack(ply) end
end)
hook.Add('ShutDown','LOD_PortraitCleanup',function() if IsValid(H.Panel) then H.Panel:Remove() end end)
