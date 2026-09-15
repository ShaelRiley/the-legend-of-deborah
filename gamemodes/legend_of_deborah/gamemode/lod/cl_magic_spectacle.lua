-- Original elemental choreography. The separate MagicArea renderer owns range.
-- No emitters, dynamic lights, entities or timers: work is bounded per live cast.
LOD.MagicSpectacle={}
local S=LOD.MagicSpectacle
local glow=Material('sprites/light_glow02_add')
local smoke=Material('particle/particle_smokegrenade')
local flat=LOD.MagicArea.Material
local sounds={fire='ambient/fire/ignite.wav',ice='physics/glass/glass_impact_bullet4.wav',
    earth='physics/concrete/boulder_impact_hard3.wav',electric='ambient/energy/zap7.wav',
    dark='ambient/levels/citadel/weapon_disintegrate2.wav',light='ambient/energy/weld1.wav',raw='ambient/energy/zap1.wav'}
function S:Begin(fx)
    -- Impacts alone trigger sound. Limit simultaneous multiplayer reports.
    if CurTime()<(self.NextSound or 0) then return end
    self.NextSound=CurTime()+.12
    local explosive=fx.form=='bomb' or fx.form=='missile' or fx.form=='blast'
    sound.Play(explosive and 'ambient/explosions/explode_4.wav' or sounds[fx.content] or sounds.raw,
        fx.destination,explosive and 78 or 68,fx.content=='dark' and 80 or 105,.55)
end
local function sprite(p,w,h,c) render.SetMaterial(glow);render.DrawSprite(p,w,h,c) end
local function ray(a,b,w,c) render.SetMaterial(glow);render.DrawBeam(a,b,w,0,1,c) end
local function direction(i,n)
    local a=i*2.39996323
    local z=(i/n)*1.5-.35
    return Vector(math.cos(a),math.sin(a),z):GetNormalized()
end
function S:Draw(fx,age,low)
    if age>=.9 then return end
    local t=math.Clamp(age/.9,0,1)
    local fade=(1-t)^2
    local c=LOD.MagicArea.Colors[fx.content] or LOD.MagicArea.Colors.raw
    local ink=Color(c.r,c.g,c.b,math.floor(230*fade))
    local white=Color(255,250,225,math.floor(230*fade))
    local p=fx.destination
    local explosive=fx.form=='bomb' or fx.form=='missile' or fx.form=='blast'
    local extent=explosive and math.min(110,math.max(36,(fx.radius or 0)*.55)) or 36
    local n=low and 4 or 12
    if fx.form=='summon' then
        -- An ascending double helix assembles the summon rather than detonating it.
        for i=1,n do
            local a=i/n*math.pi*4+t*7
            local q=p+Vector(math.cos(a)*24*(1-t),math.sin(a)*24*(1-t),i/n*65)
            sprite(q,12,20,ink)
        end
    end
    if explosive then
        -- A brief hot core, rapidly expanding lobes and rising smoke give the
        -- detonation a physical sequence. None of these rings claim a hit radius.
        sprite(p,extent*(.4+3*t),extent*(.4+3*t),Color(c.r,c.g,c.b,math.floor(180*fade)))
        sprite(p,extent*(1-t),extent*(1-t),white)
        for i=1,(low and 3 or 7) do
            local d=direction(i,7)
            local q=p+d*extent*t+Vector(0,0,35*t*t)
            if t<.45 then sprite(q,extent*(.3+t),extent*(.4+t),ink) end
            render.SetMaterial(smoke)
            render.DrawSprite(q+Vector(0,0,20*t),extent*(.3+t),extent*(.3+t),Color(70,65,75,math.floor(65*math.sin(t*math.pi))))
        end
    end
    for i=1,n do
        local d=direction(i,n)
        local q=p+d*extent*(.15+1.6*t)
        if fx.content=='fire' then
            q=q+Vector(0,0,extent*t*t)
            sprite(q,18*(1-t)+3,40*(1-t)+4,ink)
            ray(q-d*9,q,2,white) -- incandescent embers fan out and rise
        elseif fx.content=='earth' then
            q=p+d*extent*t+Vector(0,0,extent*(3*t-3*t*t))
            render.SetMaterial(flat)
            render.DrawBox(q,Angle(i*31+t*170,i*71,t*120),Vector(-3,-3,-5),Vector(3,3,5),ink)
        elseif fx.content=='ice' then
            local tip=q+d*(15+12*(1-t))
            ray(q-d*9,tip,3,white)
            ray(q+Vector(4,0,0),tip,2,ink);ray(q-Vector(4,0,0),tip,2,ink)
        elseif fx.content=='electric' then
            local previous=p
            for j=1,4 do
                local f=j/4
                local nextPoint=p+d*extent*f*(.8+t)+Vector(math.sin(i*7+j*3+math.floor(age*20))*9,math.cos(i+j*8)*9,0)
                ray(previous,nextPoint,j==1 and 3 or 1.5,ink);previous=nextPoint
            end
            sprite(previous,9,9,white)
        elseif fx.content=='dark' then
            local a=i/n*math.pi*2+t*9
            local r=extent*(1-t)
            q=p+Vector(math.cos(a)*r,math.sin(a)*r,(i%3-1)*r*.6)
            ray(q,q+Vector(-math.sin(a),math.cos(a),.3)*18,6,ink)
            sprite(p,28*(1-t),28*(1-t),Color(90,35,130,math.floor(180*fade)))
        elseif fx.content=='light' then
            q=p+Vector(d.x*extent*t,d.y*extent*t,extent*t)
            ray(q-Vector(0,0,extent*(1-t)),q+Vector(0,0,extent*(1-t)),3,ink)
            ray(q-Vector(8,0,0),q+Vector(8,0,0),2,white)
            sprite(q,13,13,white)
        else
            ray(q-d*18*(1-t),q,4,ink)
            sprite(q,9,9,white)
        end
    end
    if fx.form=='beam' then
        -- Travel accents follow the actual endpoint; the core stays cyan.
        for i=1,(low and 2 or 6) do
            local f=(t*3+i/6)%1
            sprite(fx.origin+(fx.destination-fx.origin)*f,12,12,ink)
        end
    elseif fx.shape==2 then
        -- Secondary blooms originate inside affected cells, never an invented disc.
        for i=1,math.min(#fx.tiles,low and 2 or 6) do
            local q=fx.tiles[i].center+Vector(0,0,12+35*t)
            sprite(q,35*(1-t),65*(1-t),ink)
        end
    end
end
