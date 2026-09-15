include('shared.lua')
local stone=Material('models/props_wasteland/rockgranite02a')
local glow=CreateMaterial('LOD_HolyDebbieGlow','UnlitGeneric',{
    ['$basetexture']='sprites/light_glow02',['$additive']='1',['$translucent']='1',
    ['$vertexcolor']='1',['$vertexalpha']='1',['$ignorez']='0'})
local wings
local function wingMesh()
    if wings then return wings end
    local vertices={}
    local function tri(a,b,c,normal)
        for i,p in ipairs({a,b,c}) do vertices[#vertices+1]={pos=p,normal=normal,u=i==2 and 1 or 0,v=i==3 and 1 or 0} end
    end
    for _,side in ipairs({-1,1}) do
        for feather=0,7 do
            local root=Vector(-6,side*(9+feather*.9),53+feather*2)
            local tip=Vector(-10,side*(47-feather*2.5),51+feather*7)
            local edge=Vector(-10,tip.y-side*5,tip.z-6)
            tri(root,tip,edge,Vector(-1,0,0));tri(root,edge,tip,Vector(1,0,0))
        end
    end
    wings=Mesh();wings:BuildFromTriangles(vertices);return wings
end
function ENT:Draw()
    -- Client animation clocks can advance an otherwise frozen server sequence.
    local sequence=self:GetNW2Int('LOD_StatueSequence',-1)
    if sequence>=0 then self:SetSequence(sequence) end
    self:SetPlaybackRate(0);self:SetCycle(self:GetNW2Float('LOD_StatueCycle',0))
    self:SetupBones();self:DrawModel()
    if self:GetPos():DistToSqr(EyePos())>1024*1024 then return end
    local transform=Matrix();transform:SetTranslation(self:GetPos());transform:SetAngles(self:GetAngles())
    transform:SetScale(Vector(1.2,1.2,1.2))
    render.SetMaterial(stone);cam.PushModelMatrix(transform);wingMesh():Draw();cam.PopModelMatrix()
    local blue=self:LocalToWorld(Vector(10,-27,84));local gold=self:LocalToWorld(Vector(10,27,84))
    render.SetMaterial(glow)
    render.DrawSprite(blue,74,98,Color(120,180,255,55))
    render.DrawSprite(gold,74,98,Color(255,215,145,45))
    local low=GetConVar('lod_reduced_effects')
    if (not low or not low:GetBool()) and CurTime()>=(self.LODNextHolyLight or 0) then
        self.LODNextHolyLight=CurTime()+.2
        for i,p in ipairs({blue,gold}) do
            local light=DynamicLight(24000+self:EntIndex()*2+i)
            if light then
                light.pos=p;light.r=i==1 and 120 or 255;light.g=i==1 and 180 or 215;light.b=i==1 and 255 or 145
                light.brightness=.7;light.Decay=400;light.Size=150;light.DieTime=CurTime()+.4
            end
        end
    end
end
hook.Add('ShutDown','LOD_HolyStatueMeshCleanup',function() if wings then wings:Destroy();wings=nil end end)
