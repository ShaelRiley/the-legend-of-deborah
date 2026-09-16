-- Production client face and HUD with Source/VGUI boundaries only.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local now,created,removed,draws=10,0,0,0
local reduced=false
RealTime=function() return now end
Color=function(...) return {...} end
Angle=function(p,y,r) return {p=p,y=y,r=r} end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
math.Clamp=function(v,a,b) return math.min(b,math.max(a,v)) end
IsValid=function(x) return type(x)=='table' and not x.removed end
GetConVar=function() return {GetBool=function() return reduced end} end
OBS_MODE_NONE=0;BOX_FRONT=1;BOX_TOP=2;PLAYERANIMEVENT_ATTACK_PRIMARY=1;PLAYERANIMEVENT_ATTACK_SECONDARY=2;TEXT_ALIGN_CENTER=1
local width,height=640,480
ScrW=function() return width end;ScrH=function() return height end
local menu=false;gui={IsGameUIVisible=function() return menu end}
local events={};hook={Add=function(_,id,fn) events[id]=fn end}
local labels,positions={},{};LOD={UI={HUDColor={},HUDText=function(_,s,_,x,y)
    labels[#labels+1]=s;positions[#positions+1]={text=s,x=x,y=y}
end}}
surface={SetFont=function() end,GetTextSize=function(s) return #s*7,14 end}
draw={RoundedBox=function() end}
local flexNames={'smile','right_lowerer','blink','jaw_drop','left_inner_raiser','right_cheek_raiser'}
local panel={};panel.__index=panel
function panel:SetModel(model)
    local e={model=model,weights={}}
    function e:GetFlexNum() return #flexNames end
    function e:GetFlexName(id) return flexNames[id+1] end
    function e:SetFlexWeight(id,w) self.weights[id]=w end
    function e:SetModel(m) self.model=m end
    function e:SetModelName(m) self.model=m end
    function e:SetAngles() end
    function e:SetupBones() end
    function e:LookupBone() return 0 end
    function e:GetBonePosition() return Vector(0,0,64) end
    function e:ManipulateBoneAngles(_,a) self.head=a end
    self.ent=e
end
function panel:GetEntity() return self.ent end
function panel:SetLookAt(v) self.look=v end
function panel:SetCamPos(v) self.cam=v end
function panel:SetPos(x,y) self.x=x;self.y=y end
function panel:SetSize(w,h) self.w=w;self.h=h end
function panel:PaintManual() draws=draws+1;self.LayoutEntity(self,self.ent) end
function panel:Remove() self.removed=true;self.ent.removed=true;removed=removed+1 end
for _,fn in ipairs({'SetFOV','SetAnimated','SetAmbientLight','SetDirectionalLight','SetColor',
    'SetMouseInputEnabled','SetKeyboardInputEnabled','SetPaintedManually'}) do panel[fn]=function() end end
vgui={Create=function() created=created+1;return setmetatable({},panel) end}
local ply={hp=100,maximum=100,bools={LOD_PlayedIdentity=true},speed=0,model='models/player/alyx.mdl',observer=0}
function LocalPlayer() return ply end
function ply:GetActiveWeapon() return self.weapon end
function ply:Alive() return self.hp>0 end
function ply:Health() return self.hp end
function ply:GetMaxHealth() return self.maximum end
function ply:GetModel() return self.model end
function ply:GetObserverMode() return self.observer end
function ply:GetNW2Bool(k,d) if self.bools[k]~=nil then return self.bools[k] end return d end
function ply:GetNW2String() return 'Fallback Hero' end
function ply:GetVelocity() return {Length2D=function() return ply.speed end} end
function ply:OnGround() return true end
function ply:GetWalkSpeed() return 200 end
LOD.CharacterSheet={Snapshot={model=ply.model,fullDisplayName='Jane "Steel" Doe',portraitCacheKey='hero1',playerName='DO NOT SHOW'}}
dofile(root..'cl_magic_hud.lua');dofile(root..'cl_character_portrait.lua');dofile(root..'cl_status_portrait.lua')
local P,H=LOD.CharacterPortrait,LOD.StatusPortrait
local function tick() now=now+.11;labels={};positions={};H:Draw() end
local function near(a,b) assert(math.abs(a-b)<1e-6) end
-- Name without the account name; same face/framing as the shared sheet renderer.
tick();assert(H.Caption=='Jane "Steel" Doe' and H.Model==ply.model)
local sheet=P:Create(nil,LOD.CharacterSheet.Snapshot.model);sheet.LODPose={sheet=true};sheet:PaintManual()
assert(sheet.ent.model==H.Panel.ent.model);near(sheet.cam.x,H.Panel.cam.x)
assert(sheet.ent.weights[0]==.65 and H.Panel.ent.weights[0]==0)
local count=created
for _=1,90 do tick() end
assert(created==count,'Retain panel/model during normal HUD frames')
-- Every current ailment remains in the caption, even with all active together.
for _,id in ipairs(H.Order) do ply.bools[H.Conditions[id].key]=true end
tick();assert(H.Harmful and #H.Order==9 and not H.Caption:find('Jane',1,true))
for _,id in ipairs(H.Order) do assert(H.Caption:find(H.Conditions[id].label,1,true)) end
for _,line in ipairs(H.Lines) do assert(surface.GetTextSize(line)<=H.WrapWidth) end
local function checkLayout()
    local mx,my,mw,mh=LOD.MagicHUD:Bounds()
    assert(H.Panel.x>mx+mw and H.Panel.x+H.Panel.w<width,'Face immediately right of Magic')
    near(H.Panel.y+H.Panel.h,my+mh)
    local feedLeft=width-22-math.min(600,width*.44)
    for _,p in ipairs(positions) do
        local textWidth=surface.GetTextSize(p.text)
        if p.text==H.WeaponLines[1] or p.text==H.WeaponLines[2] then
            assert(p.x>=H.Panel.x+H.Panel.w,'Weapon name is right of face')
            assert(p.y>=H.Panel.y and p.y+14<=H.Panel.y+H.Panel.h,'Weapon name is vertically centered on face')
        else
            local half=textWidth*.5
            assert(p.x-half>=0 and p.x+half<feedLeft,'Caption clears screen edge and combat feed')
            assert(p.y>=0 and p.y+18<H.Panel.y,'Status above face')
        end
    end
end
for _,viewport in ipairs({{640,480},{1024,768},{1280,800},{1280,720},{1920,1080},{3440,1440}}) do
    width,height=viewport[1],viewport[2];tick();checkLayout()
    ply.weapon={GetNW2String=function() return 'Deborah’s Wintery Revolver of Holding and Impossible Long Names' end}
    tick();checkLayout();assert(#H.WeaponLines==2)
    ply.weapon=nil
end
assert(events.LOD_MagicReplacesSuitBattery('CHudSecondaryAmmo')==false,'Hide ALT FIRE')
assert(events.LOD_MagicReplacesSuitBattery('CHudAmmo')==nil,'Retain primary ammo')
assert(events.LOD_MagicReplacesSuitBattery('CHudHealth')==nil,'Retain Health')
width,height=640,480;tick()
-- Successful attack event (not held input), damage precedence, expiry and fatigue.
events.LOD_PortraitShot(ply);tick();assert(H.Pose.mode=='attack' and H.Panel.ent.weights[0]==.9)
ply.hp=40;tick();assert(H.Pose.mode=='hurt' and H.Panel.ent.weights[2]==.75)
now=now+1;tick();assert(H.Pose.mode=='idle' and H.Pose.fatigue==.6 and H.Panel.ent.head.p==6)
local jaw=H.Panel.ent.weights[3];tick();assert(H.Panel.ent.weights[3]~=jaw,'Pant while injured')
ply.hp=100;ply.speed=200;tick();local look=H.Panel.look.z;tick();assert(H.Panel.look.z~=look,'Walk bob')
reduced=true;tick();near(H.Panel.look.z,62);tick();near(H.Panel.look.z,62)
-- Future buff registration is presentation only and shares the same surface.
ply.bools={LOD_PlayedIdentity=true,LOD_StatusFutureWard=true}
H:RegisterCondition('future_ward','WARD','LOD_StatusFutureWard',true)
tick();assert(H.Caption=='WARD' and not H.Harmful)
ply.bools.LOD_StatusFutureWard=false;tick();assert(H.Caption=='Jane "Steel" Doe')
-- Hide/releases model; reopening identical caption must rebuild valid cached lines.
menu=true;tick();assert(not H.Panel)
menu=false;tick();assert(IsValid(H.Panel) and #H.Lines>0)
LOD.UI.ActivePage='sheet';tick();assert(not H.Panel);LOD.UI.ActivePage=nil;tick()
ply.hp=0;tick();assert(not H.Panel and H.HP==nil)
ply.hp=100;tick();assert(H.Pose.mode=='idle')
-- Role transitions never borrow stale Hero or Soldier snapshot faces/names.
ply.bools.LOD_IsSoldier=true;ply.model='models/player/combine_soldier.mdl';tick()
assert(H.Model==ply.model and not H.Caption:find('Jane',1,true))
LOD.CharacterSheet.Snapshot={isSoldier=true,model=ply.model,fullDisplayName='Human Soldier'};tick()
assert(H.Caption=='Human Soldier')
ply.bools.LOD_IsSoldier=false;ply.model='models/player/eli.mdl';tick();assert(H.Model==ply.model)
LOD.CharacterSheet.Snapshot={model=ply.model,portraitCacheKey='hero2',fullDisplayName='New Hero'};tick()
assert(H.Caption=='New Hero' and H.Pose.mode=='idle')
ply.observer=4;tick();assert(not H.Panel);ply.observer=0
-- Missing face flexes/head bones remain safe for helmets/custom player models.
flexNames={};local bare=P:Create(nil,'models/player/combine_soldier.mdl');bare.LODHeadBone=nil
bare.LODPose={mode='hurt',fatigue=.5};bare:PaintManual();bare:Remove()
width,height=1280,800;tick();assert(H.Panel.w<=128 and H.Panel.y>0)
events.LOD_PortraitCleanup();assert(H.Panel.removed)
print('STATUS_PORTRAIT_PASS: HP-aligned face, weapon right, shared face, statuses/buffs, damage/attack/fatigue/bob, reduced effects, retained model, wrapping, lifecycle and role isolation')
