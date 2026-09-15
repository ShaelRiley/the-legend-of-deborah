-- Class tint is separate from elemental glow and preserves archetype paint.
LOD.MonsterIdentity={}
local M=LOD.MonsterIdentity
M.Tints={fighter={1,1,1},rogue={.86,1,.90},wizard={.92,.86,1}}
local glow=CreateMaterial('LOD_MonsterElementGlow','UnlitGeneric',{
    ['$basetexture']='sprites/light_glow02',['$additive']='1',['$translucent']='1',
    ['$vertexcolor']='1',['$vertexalpha']='1',['$ignorez']='0'
})
local function active(ent)
    return IsValid(ent) and not ent:GetNoDraw()
        and (not LOD.WatcherPolishFX or not LOD.WatcherPolishFX.IsVisible or LOD.WatcherPolishFX:IsVisible(ent))
        and (not ent:IsPlayer() or ent:Alive() and ent:GetNW2Bool('LOD_IsSoldier',false))
end
function M:Tint(ent)
    return self.Tints[ent:GetNW2String('LOD_MonsterClass','')] or self.Tints.fighter
end
function M:DrawBody(ent)
    local r,g,b=render.GetColorModulation()
    local c=self:Tint(ent)
    render.SetColorModulation(r*c[1],g*c[2],b*c[3])
    ent:DrawModel()
    render.SetColorModulation(r,g,b)
end
function M:DrawAura(ent,size)
    if not active(ent) then return end
    local c=LOD.MagicArea.Colors[ent:GetNW2String('LOD_MonsterElement','')]
    if not c or ent:GetPos():DistToSqr(EyePos())>1600*1600 then return end
    size=size or 1
    local center=ent:GetPos()+(ent:WorldSpaceCenter()-ent:GetPos())*size
    local radius=math.Clamp(19*size,10,40)
    local cv=GetConVar('lod_reduced_effects');local low=cv and cv:GetBool()
    local count=low and 2 or 3
    local phase=low and 0 or CurTime()*1.4
    render.SetMaterial(glow)
    local color=Color(c.r,c.g,c.b,70)
    for i=1,count do
        local a=phase+i*math.pi*2/count
        local point=center+Vector(math.cos(a)*radius,math.sin(a)*radius,low and 0 or math.sin(a*2)*radius*.35)
        render.DrawSprite(point,20*size,28*size,color)
    end
end
-- Human Soldiers share the same class/element profile as AI Soldiers.
local modulation=setmetatable({},{__mode='k'})
hook.Add('PrePlayerDraw','LOD_SoldierClassTint',function(ply)
    if not active(ply) or not ply:GetNW2Bool('LOD_IsSoldier',false) then return end
    local r,g,b=render.GetColorModulation();modulation[ply]={r,g,b}
    local c=M:Tint(ply);render.SetColorModulation(r*c[1],g*c[2],b*c[3])
end)
hook.Add('PostPlayerDraw','LOD_SoldierClassTintReset',function(ply)
    local c=modulation[ply]
    if c then render.SetColorModulation(c[1],c[2],c[3]);modulation[ply]=nil end
    M:DrawAura(ply)
end)
-- Element words make the aura readable without relying solely on color. This
-- reveals no level, HP or class text from the Omniscience feat's private readout.
hook.Add('HUDPaint','LOD_MonsterElementCaption',function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or (LOD.UI and LOD.UI.ActivePage) then return end
    local tr=ply:GetEyeTrace();local ent=tr and tr.Entity
    if not active(ent) or ent:GetPos():DistToSqr(ply:GetPos())>1600*1600 then return end
    local element=ent:GetNW2String('LOD_MonsterElement','')
    local opposite=LOD.RPG.ElementOpposites[element]
    if not opposite then return end
    local text=string.upper(element)..' / RESISTS '..string.upper(element)..' / WEAK TO '..string.upper(opposite)
    draw.SimpleTextOutlined(text,'DermaDefault',ScrW()*.5,ScrH()*.5+64,
        color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,220))
end)
