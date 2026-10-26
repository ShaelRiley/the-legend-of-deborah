LOD = LOD or {}
local Feed = LOD.CombatRollFeed
local UI = LOD.UI
local FONT, ROW_HEIGHT = "LOD_CombatRoll", 22
local HOLD_SECONDS, FADE_SECONDS, EXPLOSION_FX_SECONDS = 9, 1.4, 0.52
Feed.RowHeight = ROW_HEIGHT
local layoutEpoch = {}
local rasterCache
local function invalidateTextMetrics()
    layoutEpoch = {}
    if rasterCache then rasterCache:Invalidate() end
end
hook.Add("OnScreenSizeChanged", "LOD_CombatRollMetrics", invalidateTextMetrics)
hook.Add("OnReloaded", "LOD_CombatRollMetrics", invalidateTextMetrics)

local function textWidth(text, font)
    surface.SetFont(font or FONT)
    return surface.GetTextSize(text or "")
end

-- Cache once per entry/width. Break overlong identifiers at UTF-8 code points;
-- never paint outside the bounded paper column or split a continuation away.
function Feed:Layout(entry, maxWidth, hud)
    local font = hud and "ChatFont" or FONT
    if entry.layoutWidth == maxWidth and entry.layoutFont == font
        and entry.layoutEpoch == layoutEpoch and entry.layoutText == entry.text
        and entry.layoutSegments == entry.segments and entry.layoutFamily == entry.family
        and entry.lines then return entry.lines, entry.widths end
    local segments = entry.segments
    if not LOD.DieLogger:ValidSegments(segments, entry.text) then
        segments = LOD.DieLogger:Segments(entry.text, entry.family)
    end
    local lines, widths = {{}}, {0}
    local function append(text, role)
        local i = #lines
        local width = textWidth(text, font)
        if widths[i] + width > maxWidth and widths[i] > 0 then
            lines[#lines+1], widths[#widths+1] = {}, 0; i = #lines
        end
        local line = lines[i]
        local last = line[#line]
        if last and last.role == role then last.text = last.text .. text
        else line[#line+1] = {text = text, role = role} end
        widths[i] = widths[i] + width
    end
    for _, span in ipairs(segments) do
        for token in span.text:gmatch("%s*%S+%s*") do
            if textWidth(token, font) <= maxWidth then append(token, span.role)
            else
                for char in token:gmatch("[%z\1-\127\194-\244][\128-\191]*") do append(char, span.role) end
            end
        end
        -- A grammar span can consist entirely of spaces.
        if span.text:match("^%s+$") then append(span.text, span.role) end
    end
    entry.layoutFont = font
    entry.layoutEpoch, entry.layoutText = layoutEpoch, entry.text
    entry.layoutSegments, entry.layoutFamily = entry.segments, entry.family
    entry.layoutWidth, entry.lines, entry.widths = maxWidth, lines, widths
    return lines, widths
end

function Feed:DrawLines(lines, x, y, alpha, first, last, hud)
    local font = hud and "ChatFont" or FONT
    local palette = hud and UI.HUDRoles or UI.Roles
    first, last = first or 1, last or #lines
    local selectedFont
    for i = first, last do
        local cursor = x
        for _, span in ipairs(lines[i]) do
            local base = palette[span.role] or palette.prose
            local color = span.drawColor
            local opacity = alpha or 255
            if not color or span.drawR ~= base.r or span.drawG ~= base.g
                or span.drawB ~= base.b or span.drawAlpha ~= opacity then
                if not color then
                    color = Color(base.r,base.g,base.b,opacity)
                    span.drawColor = color
                else
                    -- Match Color's numeric conversion and upper bound when
                    -- a live palette/fade changes, without a new table.
                    color.r = math.min(tonumber(base.r),255)
                    color.g = math.min(tonumber(base.g),255)
                    color.b = math.min(tonumber(base.b),255)
                    color.a = math.min(tonumber(opacity),255)
                end
                span.drawR, span.drawG, span.drawB, span.drawAlpha = base.r, base.g, base.b, opacity
            end
            if hud then
                selectedFont = UI:HUDText(span.text,font,cursor,y+(i-first)*ROW_HEIGHT,
                    color,nil,nil,span,selectedFont)
            else draw.SimpleText(span.text,font,cursor,y+(i-first)*ROW_HEIGHT,color) end
            -- Measure the coalesced string, not the sum of token widths: native
            -- kerning can change its exact advance. Ownership stays within the
            -- bounded entry/history layout, with no global string cache.
            if span.drawText ~= span.text or span.drawFont ~= font or span.drawEpoch ~= layoutEpoch then
                span.drawWidth = textWidth(span.text, font)
                span.drawText, span.drawFont, span.drawEpoch = span.text, font, layoutEpoch
            end
            cursor = cursor + span.drawWidth
        end
    end
end

-- Only this HUD uses raster reuse. The public DrawLines method remains the
-- ordinary drawing authority for panels, fades and foreign providers.
local drawNativeLines = Feed.DrawLines
local nativeHUDText = UI.HUDText
local nativeText = {draw=surface.DrawText, font=surface.SetFont,
    size=surface.GetTextSize, pos=surface.SetTextPos, color=surface.SetTextColor}
local RASTER_WIDTH, RASTER_HEIGHT, RASTER_SLOTS = 1024, 256, 6
rasterCache = {slots={}, hits=0, builds=0, fallbacks=0}
Feed.HUDRasterCache = rasterCache

function rasterCache:Invalidate()
    for _,slot in ipairs(self.slots) do
        slot.owner, slot.spans, slot.epoch = nil, nil, nil
    end
end

function rasterCache:Prepare()
    if #self.slots == RASTER_SLOTS then return true end
    if not GetRenderTargetEx or not CreateMaterial or not FrameNumber
        or not render or not render.PushRenderTarget or not render.OverrideBlend
        or not render.OverrideAlphaWriteEnable or not cam or not cam.Start2D
        or not DisableClipping or not surface.GetTextPos or not surface.GetTextColor
        or not surface.SetMaterial or not surface.DrawTexturedRectUV
        or not bit or not bit.bor or RT_SIZE_NO_CHANGE==nil
        or MATERIAL_RT_DEPTH_NONE==nil or IMAGE_FORMAT_RGBA8888==nil then return false end
    for i=1,RASTER_SLOTS do
        -- Fixed names reuse the same six engine resources across Lua reloads.
        local texture=GetRenderTargetEx("lod_combat_hud_raster_v1_"..i,
            RASTER_WIDTH,RASTER_HEIGHT,RT_SIZE_NO_CHANGE,MATERIAL_RT_DEPTH_NONE,
            bit.bor(1,4,8),0,IMAGE_FORMAT_RGBA8888)
        local material=CreateMaterial("lod_combat_hud_raster_mat_v1_"..i,"UnlitGeneric",{
            ["$basetexture"]=texture:GetName(),["$translucent"]="1",
            ["$vertexcolor"]="1",["$vertexalpha"]="1",["$ignorez"]="1"})
        self.slots[i]={texture=texture,material=material}
    end
    return true
end

local function rasterMatches(slot,lines,first,last,fx,fy)
    if slot.owner~=lines or slot.first~=first or slot.last~=last
        or slot.fx~=fx or slot.fy~=fy or slot.epoch~=layoutEpoch then return false end
    local count=0
    for i=first,last do
        for _,span in ipairs(lines[i]) do
            count=count+1
            local old=slot.spans[count]
            local color=UI.HUDRoles[span.role] or UI.HUDRoles.prose
            if not old or old.span~=span or old.text~=span.text or old.role~=span.role
                or old.r~=color.r or old.g~=color.g or old.b~=color.b
                or span.drawAlpha~=255 then return false end
        end
    end
    return count==#slot.spans
end

local function rasterFallback(cache,lines,x,y,alpha,first,last)
    cache.fallbacks=cache.fallbacks+1
    return Feed:DrawLines(lines,x,y,alpha,first,last,true)
end
local function paintRaster(slot,lines,x,y,first,last)
    drawNativeLines(Feed,lines,x,y,255,first,last,true)
    slot.textX,slot.textY=surface.GetTextPos()
    local color=surface.GetTextColor()
    slot.r,slot.g,slot.b,slot.a=color.r,color.g,color.b,color.a
end
function rasterCache:Draw(lines,x,y,alpha,first,last)
    -- A provider replacement still receives every draw, including warm entries.
    if Feed.DrawLines~=drawNativeLines or UI.HUDText~=nativeHUDText
        or surface.DrawText~=nativeText.draw or surface.SetFont~=nativeText.font
        or surface.GetTextSize~=nativeText.size or surface.SetTextPos~=nativeText.pos
        or surface.SetTextColor~=nativeText.color or alpha~=255
        or first<1 or last>#lines or last-first>=6 or first>last or x<0 or y<0
        or not self:Prepare() then return rasterFallback(self,lines,x,y,alpha,first,last) end
    local frame=FrameNumber()
    local fx,fy=x-math.floor(x),y-math.floor(y)
    local slot
    for _,candidate in ipairs(self.slots) do
        if not candidate.building and candidate.owner==lines then slot=candidate;break end
    end
    if not slot then
        for _,candidate in ipairs(self.slots) do
            if not candidate.building and candidate.used~=frame then slot=candidate;break end
        end
    end
    if not slot then return rasterFallback(self,lines,x,y,alpha,first,last) end
    local usedThisFrame=slot.used==frame
    slot.used=frame
    if not rasterMatches(slot,lines,first,last,fx,fy) then
        -- A second view/range must not overwrite a texture already submitted in
        -- this frame. Native drawing remains available without a new resource.
        if usedThisFrame then return rasterFallback(self,lines,x,y,alpha,first,last) end
        -- Measure before rendering, so oversized glyphs can never be clipped
        -- into a valid-looking cache entry. Keep coalesced-string kerning.
        surface.SetFont("ChatFont")
        local width,height=0,(last-first+1)*ROW_HEIGHT
        for i=first,last do
            local advance=0
            for _,span in ipairs(lines[i]) do
                local w,h=surface.GetTextSize(span.text)
                advance=advance+w
                height=math.max(height,(i-first)*ROW_HEIGHT+h)
            end
            width=math.max(width,advance)
        end
        width,height=math.ceil(width+fx)+5,math.ceil(height+fy)+5
        if width>RASTER_WIDTH or height>RASTER_HEIGHT then return rasterFallback(self,lines,x,y,alpha,first,last) end
        slot.owner=nil
        slot.building=true
        local epoch=layoutEpoch
        render.PushRenderTarget(slot.texture)
        render.OverrideAlphaWriteEnable(true,true)
        render.Clear(0,0,0,0,true,true)
        cam.Start2D()
        local clipped=DisableClipping(true)
        render.OverrideBlend(true,BLEND_ZERO,BLEND_ZERO,BLENDFUNC_ADD,
            BLEND_ZERO,BLEND_ZERO,BLENDFUNC_ADD)
        surface.SetDrawColor(0,0,0,255)
        surface.DrawRect(0,0,RASTER_WIDTH,RASTER_HEIGHT)
        render.OverrideBlend(true,BLEND_SRC_ALPHA,BLEND_ONE_MINUS_SRC_ALPHA,
            BLENDFUNC_ADD,BLEND_ONE,BLEND_ONE_MINUS_SRC_ALPHA,BLENDFUNC_ADD)
        local ok,err=pcall(paintRaster,slot,lines,2+fx,2+fy,first,last)
        render.OverrideBlend(false)
        DisableClipping(clipped)
        cam.End2D()
        render.OverrideAlphaWriteEnable(false)
        render.PopRenderTarget()
        slot.building=nil
        if not ok then error(err,0) end
        if epoch~=layoutEpoch then return rasterFallback(self,lines,x,y,alpha,first,last) end
        local spans=slot.spans or {}
        local count=0
        for i=first,last do
            for _,span in ipairs(lines[i]) do
                count=count+1
                local row=spans[count] or {};spans[count]=row
                local color=UI.HUDRoles[span.role] or UI.HUDRoles.prose
                row.span,row.text,row.role=span,span.text,span.role
                row.r,row.g,row.b=color.r,color.g,color.b
            end
        end
        for i=#spans,count+1,-1 do spans[i]=nil end
        slot.spans,slot.width,slot.height=spans,width,height
        slot.owner,slot.first,slot.last,slot.fx,slot.fy=lines,first,last,fx,fy
        slot.epoch=epoch
        self.builds=self.builds+1
    else self.hits=self.hits+1 end
    slot.used=frame
    surface.SetDrawColor(255,255,255,255)
    surface.SetMaterial(slot.material)
    render.OverrideBlend(true,BLEND_ONE,BLEND_ONE_MINUS_SRC_ALPHA,
        BLENDFUNC_ADD,BLEND_ONE,BLEND_ONE_MINUS_SRC_ALPHA,BLENDFUNC_ADD)
    surface.DrawTexturedRectUV(math.floor(x)-2,math.floor(y)-2,
        slot.width,slot.height,0,0,slot.width/RASTER_WIDTH,slot.height/RASTER_HEIGHT)
    render.OverrideBlend(false)
    -- DrawText advances the cursor. Preserve its exact final native state for
    -- the acknowledgement callback and subsequent HUD drawing.
    surface.SetFont("ChatFont")
    surface.SetTextColor(slot.r,slot.g,slot.b,slot.a)
    surface.SetTextPos(slot.textX+math.floor(x)-2,slot.textY+math.floor(y)-2)
end
hook.Add("InitPostEntity","LOD_CombatRollRasterPrepare",function() rasterCache:Prepare() end)
hook.Add("PostCleanupMap","LOD_CombatRollRasterCleanup",function() rasterCache:Invalidate() end)

local function drawDiceExplosion(now)
    local fx = Feed.diceExplosion
    if not fx then return end
    local age = now - (fx.created or 0)
    if age >= EXPLOSION_FX_SECONDS then Feed.diceExplosion = nil return end

    local fraction = math.Clamp(age / EXPLOSION_FX_SECONDS, 0, 1)
    local alpha = math.floor(255 * (1 - fraction))
    local cx, cy = ScrW() * 0.5, ScrH() * 0.43
    local radius = 22 + 62 * fraction
    local base
    if fx.kind == 1 then
        base = Color(255, 185, 70, alpha)
    elseif fx.kind == 2 then
        base = Color(255, 225, 135, alpha)
    else
        base = Color(235, 220, 160, alpha)
    end

    surface.SetDrawColor(base)
    surface.DrawCircle(cx, cy, radius, base.r, base.g, base.b, alpha)
    surface.DrawCircle(cx, cy, radius * 0.72, base.r, base.g, base.b, math.floor(alpha * 0.75))
    for index = 0, 11 do
        local angle = (index / 12) * math.pi * 2 + fraction * 0.35
        local inner, outer = radius * 0.78, radius * 1.18
        surface.DrawLine(cx + math.cos(angle) * inner, cy + math.sin(angle) * inner,
            cx + math.cos(angle) * outer, cy + math.sin(angle) * outer)
    end

    local label = (fx.depth or 1) > 1 and "PIERCE DIE EXPLODES!" or "DIE EXPLODES!"
    if (fx.count or 1) > 1 then label = label .. "  x" .. tostring(fx.count) end
    draw.SimpleTextOutlined(label, "LOD_DiceExplosion", cx, cy - 6, base,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(20, 12, 5, math.floor(alpha * 0.92)))
    if (fx.depth or 1) > 1 then
        draw.SimpleTextOutlined("MAGNUM PIERCE +1d12", "LOD_DiceExplosionSmall", cx, cy + 22,
            Color(255, 235, 185, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(20, 12, 5, math.floor(alpha * 0.90)))
    end
end


hook.Add("HUDPaint", "LOD_CombatRollFeed", function()
    local now = CurTime()
    while Feed.entries[1] and now - Feed.entries[1].created > HOLD_SECONDS + FADE_SECONDS do
        table.remove(Feed.entries, 1)
    end
    local right, bottom = ScrW()-22, ScrH()-math.max(110, ScrH()*0.14)
    local width = math.min(600, ScrW()*0.44)
    local top = bottom - ROW_HEIGHT*6
    for index = #Feed.entries,1,-1 do
        local entry = Feed.entries[index]
        local lines = Feed:Layout(entry,width,true)
        local available = math.floor((bottom-top)/ROW_HEIGHT)
        if available < 1 then break end
        local shown = math.min(#lines,available)
        local h = shown*ROW_HEIGHT
        local age = now-entry.created
        local alpha = age <= HOLD_SECONDS and 255 or math.Clamp(255*(1-(age-HOLD_SECONDS)/FADE_SECONDS),0,255)
        rasterCache:Draw(lines,right-width,bottom-h,alpha,1,shown)
        if shown < #lines then
            UI:HUDText("... FULL RECORD: DIE-LOGGER / L", "Default",right,bottom+2,
                UI.HUDColor,TEXT_ALIGN_RIGHT)
        end
        if Feed.AckFeedback then Feed:AckFeedback(entry,1,false) end
        bottom = bottom-h-4
        if shown < #lines then break end
    end
    drawDiceExplosion(now)
end)

concommand.Add("lod_dice_feed_qol_test", function()
    local cv = GetConVar("lod_developer_mode")
    if not cv or not cv:GetBool() then return end
    local text = "(27) DAMAGE — actor → target, via Magic; 1d10! [rolls 10 > 10 > 7 = 27 rolled]"
    local entry = {category=0,text=text,created=CurTime(),family="routine"}
    Feed.entries[#Feed.entries+1] = entry
    if Feed.RetainFeedback then Feed:RetainFeedback(entry) end
    while #Feed.entries > 10 do table.remove(Feed.entries,1) end
end)
