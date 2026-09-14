-- One client-only accent lane. The authoritative feed remains the event/history
-- authority; these short ornaments never change rules, input, view or visibility.
LOD.AdventurePresentation = LOD.AdventurePresentation or {}
local A = LOD.AdventurePresentation
local volume = CreateClientConVar("lod_adventure_volume", "0.65", true, false, "Volume of original discovery and celebration accents", 0, 1)
local reduced = CreateClientConVar("lod_reduced_effects", "0", true, false, "Reduce optional decorative motion and confetti", 0, 1)
local white = Color(255, 244, 207)
local glow = CreateMaterial("lod_discovery_glint_depth", "UnlitGeneric", {
    ["$basetexture"] = "sprites/light_glow02", ["$additive"] = "1",
    ["$vertexcolor"] = "1", ["$vertexalpha"] = "1", ["$ignorez"] = "0"
})
A.nextCue, A.assetExists = {}, {}
surface.CreateFont("LOD_AdventureAside", {font = "Trebuchet MS", size = 16, weight = 600, antialias = true})
function A:Reduced() return reduced:GetBool() end
function A:Reset()
    if IsValid(self.soundOwner) and self.soundPath then self.soundOwner:StopSound(self.soundPath) end
    self.soundOwner, self.soundPath, self.soundUntil, self.soundPriority = nil, nil, 0, 0
    self.active, self.nextCue = nil, {}
end
function A:Play(index, visual, variant)
    local spec = LOD.AdventureCues[index]
    local ply, now = LocalPlayer(), CurTime()
    if not spec or not IsValid(ply) then return false end
    if now < (self.nextCue[index] or 0) then return false end
    self.nextCue[index] = now + (index == 7 and .18 or .65)
    local sounded = false
    if now >= (self.soundUntil or 0) or spec.priority > (self.soundPriority or 0) then
        if self.soundPath and IsValid(self.soundOwner) then self.soundOwner:StopSound(self.soundPath) end
        local path = "legend_of_deborah/adventure/" .. (spec.sound or spec.id) .. ".wav"
        if self.assetExists[path] == nil then self.assetExists[path] = file.Exists("sound/" .. path, "GAME") end
        if self.assetExists[path] and volume:GetFloat() > 0 then
            ply:EmitSound(path, 0, 100, volume:GetFloat(), CHAN_AUTO)
            self.soundOwner, self.soundPath = ply, path
            self.soundPriority, self.soundUntil = spec.priority, now + spec.duration
            sounded = true
        end
    end
    if visual and spec.caption then
        -- No offscreen backlog: new lower-priority accents cannot displace a key.
        if not self.active or now >= self.active.endsAt or spec.priority >= self.active.priority then
            self.active = {index = index, priority = spec.priority, started = now,
                endsAt = now + spec.duration, variant = math.Clamp(tonumber(variant) or 0, 0, 3)}
        end
    end
    return sounded
end
function A:OnFeedback(entry)
    if entry.family == "danger" or entry.family == "soldier" then self:Reset(); return false end
    if not entry.cue or entry.cue == 0 then return false end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return false end
    return self:Play(entry.cue, true, entry.cueVariant)
end
-- Called from the item's existing render path: no world scans or hidden-object
-- outlines, and the additive sprite explicitly obeys normal scene depth.
function A:Glint(position, phase, tint)
    if self:Reduced() or position:DistToSqr(EyePos()) > 900 * 900 then return end
    local pulse = math.max(0, math.sin(CurTime() * 1.8 + phase)) ^ 10
    if pulse < .05 then return end
    tint = tint or white
    render.SetMaterial(glow)
    local color = Color(tint.r, tint.g, tint.b, math.floor(170 * pulse))
    render.DrawSprite(position, 3, 18 * pulse, color)
    render.DrawSprite(position, 18 * pulse, 3, color)
end
local function line(x1,y1,x2,y2,color)
    surface.SetDrawColor(color);surface.DrawLine(x1,y1,x2,y2)
end
hook.Add("HUDPaint", "LOD_AdventureAccent", function()
    local item, ply, now = A.active, LocalPlayer(), CurTime()
    if IsValid(ply) and not ply:Alive() and A.soundPath then A:Reset(); return end
    if not item then return end
    if now >= item.endsAt or not IsValid(ply) or not ply:Alive() then A.active = nil return end
    if (LOD.UI and LOD.UI.ActivePage) or (LOD.VictoryCelebrationClient and now < (LOD.VictoryCelebrationClient.endsAt or 0)) then return end
    local spec = LOD.AdventureCues[item.index]
    local age, left = now - item.started, item.endsAt - now
    local alpha = math.floor(220 * math.min(1, age/.12, left/.35))
    local x,y = ScrW()*.5, ScrH()*.18
    local bob = A:Reduced() and 0 or math.sin(math.min(age/.5,1)*math.pi)*9
    y = y - bob
    local tint = Color(246,210,117,alpha)
    local card = LOD.Config.Progression.Cards[item.variant]
    if item.index == 1 and card then tint = Color(card.color.r,card.color.g,card.color.b,alpha) end
    if item.index == 1 or item.index == 4 then
        -- A miniature shipping-container/access-card seal, not a HUD panel.
        surface.SetDrawColor(tint);surface.DrawOutlinedRect(x-23,y-15,46,30,2)
        for i=-2,2 do line(x+i*7,y-10,x+i*7,y+10,tint) end
        if item.index == 1 and card then
            draw.SimpleTextOutlined(card.letter,"LOD_AdventureAside",x+35,y-7,tint,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,alpha))
        end
    elseif item.index == 2 then
        local gap = A:Reduced() and 12 or math.min(1,age/.4)*16
        for _,sign in ipairs({-1,1}) do
            line(x+sign*(8+gap),y-16,x+sign*(8+gap),y+16,tint)
            line(x+sign*(8+gap),y-16,x+sign*(22+gap),y-16,tint)
        end
        line(x-8,y,x+9,y,tint);line(x+9,y,x+3,y-6,tint);line(x+9,y,x+3,y+6,tint)
    else
        for _,sign in ipairs({-1,1}) do
            line(x,y+14,x+sign*24,y+8,tint);line(x+sign*24,y+8,x+sign*24,y-12,tint)
            line(x+sign*24,y-12,x,y-6,tint)
        end
        line(x,y-6,x,y+14,tint)
    end
    if not A:Reduced() then
        for i=0,5 do
            local theta=i*math.pi/3
            local r=34+math.min(age,.6)*20
            line(x+math.cos(theta)*r,y+math.sin(theta)*r,x+math.cos(theta)*(r+4),y+math.sin(theta)*(r+4),tint)
        end
    end
    draw.SimpleTextOutlined(spec.caption,"LOD_AdventureAside",x,y+43,Color(239,229,201,alpha),
        TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,alpha))
end)
hook.Add("PreCleanupMap", "LOD_AdventureReset", function() A:Reset() end)
hook.Add("ShutDown", "LOD_AdventureStop", function() A:Reset() end)
