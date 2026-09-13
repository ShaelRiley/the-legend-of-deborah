include("shared.lua")

if surface and surface.CreateFont then
    surface.CreateFont("LOD_BoardTitle", {
        font = "DejaVu Sans",
        size = 42,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("LOD_BoardEntry", {
        font = "DejaVu Sans",
        size = 24,
        weight = 700,
        antialias = true
    })
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-100, -100, -20), Vector(100, 100, 150))
end

function ENT:Draw()
    local pos = self:GetPos()
    local ang = self:GetAngles()

    local boardAng = Angle(ang.p, ang.y, ang.r)
    boardAng:RotateAroundAxis(boardAng:Up(), 90)
    boardAng:RotateAroundAxis(boardAng:Forward(), 90)

    local scale = 0.1
    local width = 800
    local height = 500
    local boardOffset = pos + ang:Forward() * 2 + Vector(0, 0, 50)

    if cam and cam.Start3D2D then
        cam.Start3D2D(boardOffset, boardAng, scale)
            surface.SetDrawColor(20, 24, 28, 240)
            surface.DrawRect(-width * 0.5, -20, width, height)
            surface.SetDrawColor(180, 140, 60, 255)
            surface.DrawOutlinedRect(-width * 0.5, -20, width, height, 4)

            draw.SimpleTextOutlined("HEROES OF LEGEND", "LOD_BoardTitle",
                0, 10, Color(245, 215, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))

            draw.SimpleTextOutlined("Top 10 Completed Party Runs", "LOD_BoardEntry",
                0, 58, Color(180, 190, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))

            surface.SetDrawColor(180, 140, 60, 150)
            surface.DrawLine(-width * 0.4, 90, width * 0.4, 90)

            local entries = LOD and LOD.HeroesOfLegend and LOD.HeroesOfLegend.Entries or {}
            local startY = 105
            local lineHeight = 35

            for i = 1, 10 do
                local entry = entries[i]
                local text
                if entry then
                    local formatted = LOD.HeroesOfLegend:FormatEntry(entry)
                    text = string.format("%d. %s", i, formatted)
                else
                    text = string.format("%d. ---", i)
                end

                local color = entry and Color(240, 240, 235) or Color(100, 110, 120)
                draw.SimpleTextOutlined(text, "LOD_BoardEntry",
                    -width * 0.42, startY + (i - 1) * lineHeight, color,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
            end
        cam.End3D2D()
    end
end

function ENT:DrawTranslucent()
    self:Draw()
end
