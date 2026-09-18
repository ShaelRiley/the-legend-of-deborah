include("shared.lua")

-- debugwhite ignores the mesh's vertex tint on some renderers (white bombs on
-- Linux/OpenGL). Own a color-capable material for both the iron and fuse.
local iron = CreateMaterial("LOD_BombIronVertexColor", "VertexLitGeneric", {
    ["$basetexture"]="color/white", ["$model"]="1", ["$vertexcolor"]="1"
})
local fuseMaterial = CreateMaterial("LOD_BombFuseVertexColor", "UnlitGeneric", {
    ["$basetexture"]="color/white", ["$vertexcolor"]="1", ["$vertexalpha"]="1"
})
local emberMaterial = Material("sprites/light_glow02_add")
local ironColor, fuseColor = Color(24, 25, 28), Color(245, 221, 156)

function ENT:Initialize()
    -- Include the cosmetic fuse in culling bounds. Server hull/travel stay intact.
    self:SetRenderBounds(Vector(-48,-48,-48),Vector(48,48,48))
end

function ENT:DrawBomb()
    if not self.LODFuseStarted then
        self.LODFuseStarted = CurTime()
    end
    if LOD.LoopAudio then LOD.LoopAudio:Touch("fuse",self,"ambient/gas/steam2.wav",.12,135,55,.35) end
    local origin, angles = self:GetPos(), self:GetAngles()
    local up, right = angles:Up(), angles:Right()
    render.SetMaterial(iron)
    render.DrawSphere(origin, 6, 16, 12, ironColor)
    render.DrawBox(origin+up*5,angles,Vector(-1.8,-1.8,0),Vector(1.8,1.8,2.5),ironColor)
    local root = origin+up*7
    -- Cosmetic burn-down only: impact, flight and detonation remain server-owned.
    local remaining = 1 - 0.65 * math.Clamp((CurTime()-self.LODFuseStarted)/1.6,0,1)
    local bend = root+(up*3+right*1.5)*remaining
    local tip = bend+(up*1.5+right*3)*remaining
    render.SetMaterial(fuseMaterial)
    for segment=0,7 do
        local a,b=segment/8,(segment+1)/8
        local function point(t) return t<.5 and (root+(bend-root)*(t*2)) or (bend+(tip-bend)*((t-.5)*2)) end
        render.DrawBeam(point(a),point(b),1.4,0,1,segment%2==0 and Color(255,230,45) or color_white)
    end
    render.SetMaterial(emberMaterial)
    local pulse = 3 + math.sin(CurTime()*25+self:EntIndex())*0.6
    render.DrawSprite(tip,pulse,pulse,Color(255,185,65))
    -- Three tiny sparks, no particles, extra entities, timer, or dynamic light.
    for i=1,3 do
        local phase = CurTime()*12+i*2.1
        local direction = up*math.sin(phase)+right*math.cos(phase)
        render.DrawBeam(tip+direction*1.2,tip+direction*3,0.5,0,1,Color(255,205,95,200))
    end
end

function ENT:OnRemove()
    if LOD.LoopAudio then LOD.LoopAudio:Stop("fuse",self) end
end

function ENT:Draw()
    if self:GetMagicForm() == "watermelon" then
        self:DrawModel()
        render.SetMaterial(emberMaterial)
        render.DrawSprite(self:GetPos(),22,22,Color(125,240,85,45))
        return
    end
    if self:GetMagicForm() == "bomb" then self:DrawBomb() return end
    local p,c=self:GetPos(),self:GetColor()
    local forward=self:GetAngles():Forward()
    render.SetMaterial(emberMaterial)
    -- The projectile is an enchanted comet, not a stock rocket/crossbow model.
    local width=self:GetMagicForm()=="missile" and 17 or 9
    render.DrawBeam(p-forward*30,p,width,0,1,c)
    render.DrawSprite(p,width*2,width*2,c)
    render.DrawSprite(p,width*.7,width*.7,Color(255,255,255))
    local cv=GetConVar("lod_reduced_effects")
    if not (cv and cv:GetBool()) then
        local up,right=self:GetAngles():Up(),self:GetAngles():Right()
        for i=1,3 do
            local a=CurTime()*12+i*math.pi*2/3
            local q=p+(up*math.cos(a)+right*math.sin(a))*8-forward*12
            render.DrawBeam(q-forward*10,q,2,0,1,c)
        end
    end
end
