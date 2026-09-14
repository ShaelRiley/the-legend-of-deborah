local FX = {}
local localCast
local beamMaterial = Material("trails/laser")
local material = Material("sprites/light_glow02_add")
local colors = {
    raw = Color(210, 235, 255), earth = Color(194, 156, 88), fire = Color(255, 105, 45),
    dark = Color(125, 72, 170), ice = Color(125, 220, 255), light = Color(255, 245, 170),
    electric = Color(110, 180, 255)
}

net.Receive("LOD_MagicFormFX", function()
    local form = net.ReadString()
    local content = net.ReadString()
    local origin = net.ReadVector()
    local destination = net.ReadVector()
    local caster = net.ReadEntity()
    if IsValid(caster) and caster == LocalPlayer() and (form == "blast" or form == "beam") then
        localCast = {form=form,content=content,started=CurTime()}
    end
    while #FX >= 48 do table.remove(FX,1) end
    FX[#FX + 1] = {
        caster = caster,
        form = form,
        content = content,
        origin = origin,
        destination = destination,
        started = CurTime(),
        lifetime = (form == "beam" or form == "blast") and 0.48 or 0.28
    }
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
            render.SetMaterial(material)

            if fx.form == "beam" then
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

            elseif fx.form == "blast" then
                -- Radial expanding area attack wave originating from caster position
                local center = fx.origin - Vector(0,0,28)
                local radius = 24 + 220 * math.sqrt(progress)
                local alpha = math.floor(220 * fade)
                local segments = 16

                -- Draw radial expanding ring in 3D world space
                local prevPos = center + Vector(radius, 0, 8)
                for seg = 1, segments do
                    local angle = (seg / segments) * math.pi * 2
                    local nextPos = center + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 8)
                    render.DrawBeam(prevPos, nextPos, 14 + 10 * fade, 0, 1,
                        Color(c.r, c.g, c.b, alpha))
                    prevPos = nextPos
                end
                -- Vertical arcs are readable at eye height from inside the pulse.
                for meridian=0,1 do
                    local previous
                    for seg=0,12 do
                        local angle=seg/12*math.pi
                        local nextPos=center+Vector(meridian==0 and math.cos(angle)*radius or 0,
                            meridian==1 and math.cos(angle)*radius or 0,math.sin(angle)*radius)
                        if previous then render.DrawBeam(previous,nextPos,6,0,1,Color(c.r,c.g,c.b,alpha)) end
                        previous=nextPos
                    end
                end
                -- Center shockwave burst sprite
                render.DrawSprite(center + Vector(0, 0, 16), radius * 0.8, radius * 0.8,
                    Color(c.r, c.g, c.b, math.floor(180 * fade)))

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
    if age>0.6 then localCast=nil return end
    local alpha=math.floor(210*(1-age/0.6))
    local x,y=ScrW()*0.5,ScrH()*0.5
    local radius=localCast.form=="blast" and 44+age*80 or 24
    surface.SetDrawColor(70,195,255,alpha)
    for _,sign in ipairs({-1,1}) do
        surface.DrawLine(x+sign*radius,y-12,x+sign*radius,y+12)
        surface.DrawLine(x+sign*radius,y+sign*12,x+sign*(radius-8),y+sign*12)
    end
    draw.SimpleTextOutlined(string.upper(localCast.form).." / "..string.upper(localCast.content),
        "LOD_SheetKey",x,y+radius+14,Color(230,241,247,alpha),TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,1,Color(20,24,30,alpha))
end)
