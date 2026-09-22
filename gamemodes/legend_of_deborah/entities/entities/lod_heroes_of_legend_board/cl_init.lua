include("shared.lua")

if surface and surface.CreateFont then
    surface.CreateFont("LOD_BoardTitle", {
        font = "DejaVu Sans Condensed",
        size = 42,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("LOD_BoardEntry", {
        font = "Georgia",
        size = 24,
        weight = 700,
        antialias = true
    })
end

function ENT:Initialize()
    self:SetRenderBounds(Vector(-100, -100, -20), Vector(100, 100, 150))
end

function ENT:Draw()
    local stakeholders=self:GetNW2Bool("LOD_Stakeholders",false)
    local pos = self:GetPos()
    local ang = self:GetAngles()

    local boardAng = Angle(ang.p, ang.y, ang.r)
    boardAng:RotateAroundAxis(boardAng:Up(), 90)
    boardAng:RotateAroundAxis(boardAng:Forward(), 90)

    local scale = 0.1
    -- Match the mirror surface: 64 x 132 world units, aligned at its top.
    local width = 640
    local height = 1320
    local boardOffset = pos + ang:Forward() * 4.8 + Vector(0, 0, 135)

    if cam and cam.Start3D2D then
        cam.Start3D2D(boardOffset, boardAng, scale)
            local UI=LOD and LOD.UI
            if UI then
                local C=UI.Colors
                UI:Paper(-width*0.5,-20,width,height,C.red,255,8)
                draw.SimpleText(stakeholders and "STAKEHOLDERS" or "HEROES OF LEGEND","LOD_BoardTitle",0,4,C.red,TEXT_ALIGN_CENTER)
                local entries=stakeholders and (LOD.Stakeholders or {}) or (LOD.HeroesOfLegend and LOD.HeroesOfLegend.Entries or {})
                if self.LODBoardEntries ~= entries then
                    self.LODBoardEntries=entries
                    self.LODBoardPages={{}}
                    surface.SetFont("LOD_BoardEntry")
                    local function append(line)
                        local pages=self.LODBoardPages
                        if not stakeholders and #pages[#pages]>=math.floor((height-180)/30) then pages[#pages+1]={} end
                        pages[#pages][#pages[#pages]+1]=line
                    end
                    for i=1,(stakeholders and math.max(1,#entries) or 10) do
                        if stakeholders and i>1 and (i-1)%10==0 then self.LODBoardPages[#self.LODBoardPages+1]={} end
                        local entry=entries[i]
                        local text=entry and LOD.HeroesOfLegend:FormatEntry(entry) or "---"
                        if stakeholders and entry then
                            local name=""
                            for char in entry.name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                                if surface.GetTextSize(name..char.."…")>width-110 then name=name.."…";break end
                                name=name..char
                            end
                            append(tostring(i)..". "..name)
                            append("    "..entry.value.." $DEB")
                            text=nil
                        end
                        if text then
                        local line=tostring(i)..". "
                        for token in text:gmatch("%S+%s*") do
                            if surface.GetTextSize(line..token)>width-64 then append(line);line="    " end
                            -- Do not let long unbroken Steam names leave the paper.
                            for char in token:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                                if surface.GetTextSize(line..char)>width-64 then append(line);line="    " end
                                line=line..char
                            end
                        end
                        append(line)
                        end
                    end
                end
                local pages=self.LODBoardPages
                local page=math.floor(CurTime()/12)%#pages+1
                draw.SimpleText((stakeholders and "$DEB + DFT VALUE / " or "PARTY RUNS / ").."PAGE "..page.." OF "..#pages,
                    "LOD_BoardEntry",0,60,C.blue,TEXT_ALIGN_CENTER)
                for i,line in ipairs(pages[page]) do
                    draw.SimpleText(line,"LOD_BoardEntry",-width*0.5+32,105+(i-1)*30,C.ink)
                end
                draw.SimpleText(stakeholders and "All qualifying holders / 10 per page" or "Highest rescue count first / pages turn automatically",
                    "LOD_SheetSmall",0,height-50,C.muted,TEXT_ALIGN_CENTER)
            end
        cam.End3D2D()
    end
end

function ENT:DrawTranslucent()
    self:Draw()
end

