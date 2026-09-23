local FX = {}
local localCast
local beamMaterial = Material("trails/laser")
local material = Material("sprites/light_glow02_add")
local A=LOD.MagicArea
local boundaryMaterial=A.Material
local function reduced()
    local cv=GetConVar("lod_reduced_effects")
    return cv and cv:GetBool()
end
local function circle(center, radius, plane, color, width)
    local previous
    for i=0,32 do
        local angle=i/32*math.pi*2
        local a,b=math.cos(angle)*radius,math.sin(angle)*radius
        local point=center+Vector(plane==2 and 0 or a,plane==1 and 0 or (plane==2 and a or b),plane==0 and 0 or b)
        if previous then render.DrawBeam(previous,point,width,0,1,color) end
        previous=point
    end
end
local colors=A.Colors

net.Receive("LOD_MagicFormFX", function()
    local form = net.ReadString()
    local content = net.ReadString()
    local origin = net.ReadVector()
    local destination = net.ReadVector()
    local caster = net.ReadEntity()
    if LOD.StatusPortrait then LOD.StatusPortrait:Attack(caster) end
    local shape=net.ReadUInt(2)
    local radius, edges, tiles = 0, {}, {}
    if shape==1 then
        radius=net.ReadFloat()
    elseif shape==2 then
        local zero=net.ReadVector()
        local size,height=net.ReadFloat(),net.ReadFloat()
        local count=net.ReadUInt(16)
        if count>4096 then return end
        local cells, occupied={},{}
        for i=1,count do
            local x,y,z=net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8)
            cells[i]={x=x,y=y,z=z}
            occupied[x..":"..y..":"..z]=true
        end
        -- Inset floor marks stay visible beside thick container walls.
        -- These identify affected cells, not an invented circular Blast radius.
        local half=size/2-10
        local dirs={{1,0},{0,1},{-1,0},{0,-1}}
        for _,cell in ipairs(cells) do
            local center=zero+Vector(cell.x*size,cell.y*size,cell.z*height+3)
            tiles[#tiles+1]={center=center,size=size}
            for _,d in ipairs(dirs) do
                local neighbor=(cell.x+d[1])..":"..(cell.y+d[2])..":"..cell.z
                do
                    local side=center+Vector(d[1]*half,d[2]*half,0)
                    local tangent=Vector(-d[2]*half,d[1]*half,0)
                    edges[#edges+1]={side-tangent,side+tangent,occupied[neighbor] and 1.5 or 4,not occupied[neighbor]}
                end
            end
        end
    end
    if IsValid(caster) and caster == LocalPlayer() and form ~= "watermelon_bounce" then
        localCast = {form=form,content=content,shape=shape,started=CurTime()}
    end
    -- Long-lived area outlines have a separate small concurrency budget.
    if shape>0 then
        local areas=0
        for i=#FX,1,-1 do
            if FX[i].shape>0 then
                areas=areas+1
                if areas>=4 then table.remove(FX,i) end
            end
        end
    end
    while #FX >= 48 do table.remove(FX,1) end
    FX[#FX + 1] = {
        caster = caster,
        shape=shape, radius=radius, edges=edges, tiles=tiles,
        form = form,
        content = content,
        origin = origin,
        destination = destination,
        started = CurTime(),
        lifetime = shape>0 and 1.15 or 0.9
    }
    if LOD.MagicSpectacle then LOD.MagicSpectacle:Begin(FX[#FX]) end
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_MagicFormPresentation", function(depth, skybox)
    if depth or skybox then return end
    local now = CurTime()
    for i = #FX, 1, -1 do
        local fx = FX[i]
        local age = now - fx.started
        if age >= fx.lifetime then
            table.remove(FX, i)
        else
            local fade = math.Clamp(1 - age / fx.lifetime, 0, 1)
            local progress = 1 - fade
            local c = colors[fx.content] or colors.raw
            if LOD.MagicSpectacle and #FX-i<12 then LOD.MagicSpectacle:Draw(fx,age,reduced()) end
            render.SetMaterial(material)

            if fx.form == "cinder_rise" then
                local rise=math.min(1,age/.3)
                local center=fx.origin+(fx.destination-fx.origin)*rise
                render.DrawBeam(fx.origin,center,12*fade,0,1,Color(c.r,c.g,c.b,150*fade))
                render.DrawSprite(center,26*fade,26*fade,Color(c.r,c.g,c.b,220*fade))
            end
            if fx.form == "cone" then
                local direction=(fx.destination-fx.origin):GetNormalized()
                local angle=direction:Angle();local side,up=angle:Right(),angle:Up()
                local distance=fx.origin:Distance(fx.destination)*math.min(1,age/.25)
                local center=fx.origin+direction*distance
                local radius=distance*math.tan(math.rad(32))
                local last
                for segment=0,24 do
                    local a=segment*math.pi*2/24
                    local point=center+(side*math.cos(a)+up*math.sin(a))*radius
                    if last then render.DrawBeam(last,point,5*fade,0,1,Color(c.r,c.g,c.b,180*fade)) end
                    if segment%6==0 then render.DrawBeam(fx.origin,point,2*fade,0,1,Color(c.r,c.g,c.b,90*fade)) end
                    last=point
                end
            elseif fx.form == "beam" then
                local startPos = fx.origin
                if IsValid(fx.caster) and fx.caster == LocalPlayer() then
                    local eye = LocalPlayer():EyePos()
                    if startPos:DistToSqr(eye) < 1600 then
                        local dir = (fx.destination - startPos):GetNormalized()
                        startPos = startPos + dir * math.min(18,startPos:Distance(fx.destination)*0.25)
                    end
                end
                -- Beam always owns a cyan laser core; Content colors the impact.
                render.SetMaterial(beamMaterial)
                render.DrawBeam(startPos, fx.destination, 18 + 8 * fade, 0, 1,
                    Color(60, 185, 255, math.floor(210 * fade)))
                render.DrawBeam(startPos, fx.destination, 6 + 4 * fade, 0, 1,
                    Color(255, 255, 255, math.floor(240 * fade)))
                render.SetMaterial(material)
                render.DrawSprite(fx.destination, 42 + 45 * progress, 42 + 45 * progress,
                    Color(c.r, c.g, c.b, math.floor(230 * fade)))

            elseif fx.shape>0 then
                render.SetMaterial(boundaryMaterial)
                local ink,fill=A:Ink(c,math.min(1,fade*2))
                local center=fx.shape==1 and fx.destination or fx.origin
                if fx.shape==1 then
                    A:Sphere(center,fx.radius,fill,reduced())
                    -- Three fixed great circles reveal the real 3D blast sphere.
                    -- The small inner pulse is decorative; the outer limit never moves.
                    for plane=0,2 do circle(center,fx.radius,plane,ink,2.5) end
                    if not reduced() then
                        circle(center,fx.radius*math.min(1,age/0.3),0,
                            Color(c.r,c.g,c.b,math.floor(100*fade)),4)
                    end
                else
                    for _,tile in ipairs(fx.tiles) do A:Cell(tile.center,tile.size,fill) end
                    for _,edge in ipairs(fx.edges) do
                        render.DrawBeam(edge[1],edge[2],edge[3],0,1,edge[4] and ink or fill)
                    end
                end
                -- Fixed center marker avoids a camera-following/muzzle illusion.
                render.DrawBeam(center-Vector(9,0,0),center+Vector(9,0,0),3,0,1,ink)
                render.DrawBeam(center-Vector(0,9,0),center+Vector(0,9,0),3,0,1,ink)
                render.SetMaterial(material)
                render.DrawSprite(center,20,20,Color(c.r,c.g,c.b,math.floor(160*fade)))

            else
                render.DrawSprite(fx.destination, 54 + 70 * progress, 54 + 70 * progress,
                    Color(c.r, c.g, c.b, math.floor(210 * fade)))
            end
        end
    end
end)


-- A brief labeled aperture remains visible when a center-aim beam is viewed
-- end-on or the caster is inside Blast's wave. It never represents a hit/range.
hook.Add("HUDPaint","LOD_MagicLocalCast",function()
    if not localCast then return end
    local age=CurTime()-localCast.started
    local duration=localCast.shape>0 and 1.15 or 0.6
    if age>duration then localCast=nil return end
    local alpha=math.floor(210*(1-age/duration))
    local x,y=ScrW()*0.5,ScrH()*0.5
    local radius=24
    surface.SetDrawColor(70,195,255,alpha)
    for _,sign in ipairs({-1,1}) do
        surface.DrawLine(x+sign*radius,y-12,x+sign*radius,y+12)
        surface.DrawLine(x+sign*radius,y+sign*12,x+sign*(radius-8),y+sign*12)
    end
    local label=string.upper(localCast.form:gsub("_"," ")).." / "..string.upper(localCast.content)
    draw.SimpleTextOutlined(label,
        "LOD_SheetKey",x,y+radius+14,Color(230,241,247,alpha),TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,1,Color(20,24,30,alpha))
end)

local function clear() FX={};localCast=nil end
hook.Add("PostCleanupMap","LOD_MagicFormPresentationCleanup",clear)
hook.Add("ShutDown","LOD_MagicFormPresentationShutdown",clear)
