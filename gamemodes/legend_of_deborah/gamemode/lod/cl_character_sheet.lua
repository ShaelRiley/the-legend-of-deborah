LOD = LOD or {}
LOD.CharacterSheet = LOD.CharacterSheet or {}

local Sheet = LOD.CharacterSheet
local PAPER = Color(244, 237, 218)
local PAPER_LIGHT = Color(251, 247, 233)
local INK = Color(32, 32, 29)
local RED = Color(170, 61, 50)
local BLUE = Color(55, 91, 145)
local PEACH = Color(237, 201, 162)
local GOLD = Color(199, 154, 57)
local MUTED = Color(112, 104, 91)

surface.CreateFont("LOD_SheetTitle", {
    font = "DejaVu Sans Condensed", size = 38, weight = 1000, antialias = true
})
surface.CreateFont("LOD_SheetHeading", {
    font = "DejaVu Sans Condensed", size = 24, weight = 1000, antialias = true
})
surface.CreateFont("LOD_SheetSubheading", {
    font = "DejaVu Sans Condensed", size = 18, weight = 900, antialias = true
})
surface.CreateFont("LOD_SheetBody", {
    font = "Georgia", size = 17, weight = 500, antialias = true
})
surface.CreateFont("LOD_SheetSmall", {
    font = "Georgia", size = 14, weight = 500, antialias = true
})
surface.CreateFont("LOD_SheetKey", {
    font = "DejaVu Sans", size = 14, weight = 1000, antialias = true
})

local function label(parent, text, font, color)
    local item = vgui.Create("DLabel", parent)
    item:SetText(text or "")
    item:SetFont(font or "LOD_SheetBody")
    item:SetTextColor(color or INK)
    item:SetWrap(true)
    return item
end

local function sectionTitle(parent, text, x, y, width)
    local item = label(parent, string.upper(text), "LOD_SheetHeading", RED)
    item:SetPos(x, y)
    item:SetWide(width)
    item:SizeToContentsY()
    return item
end

local function paperPanel(parent)
    local panel = vgui.Create("DPanel", parent)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, PAPER_LIGHT)
        surface.SetDrawColor(105, 91, 70, 55)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    return panel
end

local function makeChoiceButton(parent, text, callback)
    local button = vgui.Create("DButton", parent)
    button:SetText(string.upper(text))
    button:SetFont("LOD_SheetKey")
    button:SetTextColor(PAPER_LIGHT)
    button.Paint = function(self, w, h)
        local color = self:IsEnabled() and (self:IsHovered() and BLUE or RED) or MUTED
        draw.RoundedBox(2, 0, 0, w, h, color)
    end
    button.DoClick = function(self)
        self:SetEnabled(false)
        surface.PlaySound("buttons/button14.wav")
        callback()
    end
    return button
end

local function portraitPanel(parent, snapshot)
    local portrait = vgui.Create("DModelPanel", parent)
    portrait:SetModel(snapshot.model or "models/player/kleiner.mdl")
    portrait:SetFOV(25)
    portrait:SetAnimated(false)
    portrait:SetAmbientLight(Color(105, 91, 72))
    portrait:SetDirectionalLight(BOX_FRONT, Color(255, 213, 165))
    portrait:SetDirectionalLight(BOX_TOP, Color(170, 185, 210))
    portrait:SetColor(Color(255, 255, 255))
    local basePaint = portrait.Paint
    portrait.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(30, 32, 36))
        basePaint(self, w, h)
        surface.SetDrawColor(RED)
        surface.DrawOutlinedRect(0, 0, w, h, 3)
    end
    portrait.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, 25, 0))
        if self.LODPortraitFramed then return end
        local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
        local head = bone and select(1, ent:GetBonePosition(bone)) or Vector(0, 0, 64)
        self:SetLookAt(head + Vector(0, 0, -2))
        self:SetCamPos(head + Vector(48, 8, 3))
        self.LODPortraitFramed = true
        for _, flexName in ipairs({"smile", "right_smile", "left_smile"}) do
            local flex = ent:GetFlexIDByName(flexName)
            if flex and flex >= 0 then ent:SetFlexWeight(flex, 0.65) end
        end
    end
    return portrait
end

local function addIdentityTrait(parent, trait, x, y, width)
    local panel = paperPanel(parent)
    panel:SetPos(x, y)
    panel:SetSize(width, 156)

    local category = label(panel, string.upper(trait.tableType) .. " / " .. trait.categoryName,
        "LOD_SheetSubheading", BLUE)
    category:SetPos(12, 8)
    category:SetWide(width - 24)

    local perk = label(panel, trait.perkDisplayName, "LOD_SheetBody", RED)
    perk:SetPos(12, 32)
    perk:SetWide(width - 24)

    local effect = label(panel, trait.mechanicalEffect, "LOD_SheetSmall", INK)
    effect:SetPos(12, 58)
    effect:SetSize(width - 24, 42)

    local flavor = label(panel, trait.flavorText, "LOD_SheetSmall", MUTED)
    flavor:SetPos(12, 105)
    flavor:SetSize(width - 24, 44)
    return panel
end

local function addAbilityRow(parent, ability, x, y, width)
    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(x, y)
    panel:SetSize(width, 42)
    panel.Paint = function(self, w, h)
        surface.SetDrawColor(167, 156, 136, 150)
        for dot = 0, w, 7 do surface.DrawRect(dot, h - 1, 3, 1) end
    end

    local left = label(panel, ability.label, "LOD_SheetSubheading", BLUE)
    left:SetPos(0, 8)
    left:SetSize(48, 28)
    local mod = ability.modifier >= 0 and ("+" .. ability.modifier) or tostring(ability.modifier)
    local score = label(panel, tostring(ability.score) .. "  (" .. mod .. ")", "LOD_SheetSubheading", INK)
    score:SetPos(52, 8)
    score:SetSize(100, 28)
    local role = label(panel, ability.role, "LOD_SheetSmall", MUTED)
    role:SetPos(158, 10)
    role:SetSize(width - 158, 24)
    local tip = string.format("Base %d + growth %d + Fighter Training %d + identity %d + feat %d",
        ability.base, ability.growth, ability.fighterTraining, ability.identity, ability.feat)
    panel:SetTooltip(tip)
end

local CLASS_CARDS = {
    fighter = {
        title = "Fighter", subtitle = "STR / CON | Hero d10",
        body = "Fighter Training grants one additional STR-or-CON point every Level, beginning with the Primary favored ability."
    },
    rogue = {
        title = "Rogue", subtitle = "DEX / CHA | Hero d8",
        body = "Every Rogue-owned damage die can explode. Rogue d6 and SUPER-d12 thresholds are easier to trigger."
    },
    wizard = {
        title = "Wizard", subtitle = "INT / WIS | Hero d6",
        body = "Diverts 2% of otherwise-final HP damage per Level into Magic damage while Magic remains available."
    }
}

local function addClassChoices(parent, snapshot, x, y, width)
    local gap = 12
    local cardWidth = math.floor((width - gap * 2) / 3)
    for index, classId in ipairs({"fighter", "rogue", "wizard"}) do
        local data = CLASS_CARDS[classId]
        local card = paperPanel(parent)
        card:SetPos(x + (index - 1) * (cardWidth + gap), y)
        card:SetSize(cardWidth, 176)
        local title = label(card, data.title, "LOD_SheetHeading", RED)
        title:SetPos(12, 10)
        title:SetSize(cardWidth - 24, 30)
        local sub = label(card, data.subtitle, "LOD_SheetSmall", BLUE)
        sub:SetPos(12, 45)
        sub:SetSize(cardWidth - 24, 22)
        local body = label(card, data.body, "LOD_SheetSmall", INK)
        body:SetPos(12, 70)
        body:SetSize(cardWidth - 24, 58)
        local choose = makeChoiceButton(card, "Commit " .. data.title, function()
            net.Start("LOD_RPG_ChooseClass")
            net.WriteString(classId)
            net.SendToServer()
        end)
        choose:SetPos(12, 138)
        choose:SetSize(cardWidth - 24, 28)
    end
end

local function addFeatCards(parent, snapshot, x, y, width)
    local offers = snapshot.featDraft and snapshot.featDraft.offers or {}
    local gap = 12
    local cardWidth = math.floor((width - gap * 2) / 3)
    for index, feat in ipairs(offers) do
        local card = paperPanel(parent)
        card:SetPos(x + (index - 1) * (cardWidth + gap), y)
        card:SetSize(cardWidth, 246)
        if feat.selected then
            card.Paint = function(self, w, h)
                draw.RoundedBox(2, 0, 0, w, h, Color(248, 225, 194))
                surface.SetDrawColor(GOLD)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            end
        end
        local title = label(card, feat.displayName, "LOD_SheetSubheading", feat.selected and RED or BLUE)
        title:SetPos(12, 10)
        title:SetSize(cardWidth - 24, 30)
        local req = label(card, feat.eligibilityText or "", "LOD_SheetSmall", MUTED)
        req:SetPos(12, 40)
        req:SetSize(cardWidth - 24, 22)
        local effect = label(card, feat.effect or "", "LOD_SheetSmall", INK)
        effect:SetPos(12, 67)
        effect:SetSize(cardWidth - 24, 132)

        if snapshot.featDraft.resolved then
            local state = label(card, feat.selected and "SELECTED" or "NOT SELECTED",
                "LOD_SheetKey", feat.selected and RED or MUTED)
            state:SetPos(12, 211)
            state:SetSize(cardWidth - 24, 25)
        else
            local choose = makeChoiceButton(card, "Choose " .. feat.displayName, function()
                net.Start("LOD_RPG_ChooseFeat")
                net.WriteString(feat.featId)
                net.SendToServer()
            end)
            choose:SetPos(12, 208)
            choose:SetSize(cardWidth - 24, 28)
        end
    end
end

function Sheet:Close()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame = nil
end

function Sheet:Open(requestFresh)
    if requestFresh ~= false then
        net.Start("LOD_RPG_RequestSheet")
        net.SendToServer()
    end
    self:Close()

    local snapshot = self.Snapshot
    local frame = vgui.Create("DFrame")
    self.Frame = frame
    frame:SetSize(math.min(1180, ScrW() - 36), math.min(740, ScrH() - 36))
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    -- PlayerButtonDown opens this keyboard-focused frame during the originating
    -- P event. Do not let DFrame consume that same event as an immediate close.
    frame.LODAcceptToggleAt = RealTime() + 0.15
    frame.OnKeyCodePressed = function(_, code)
        if code == KEY_ESCAPE
            or (code == KEY_P and RealTime() >= frame.LODAcceptToggleAt)
        then
            Sheet:Close()
        end
    end
    frame.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(18, 19, 21, 248))
        draw.RoundedBox(2, 8, 8, w - 16, h - 16, PAPER)
        surface.SetDrawColor(RED)
        surface.DrawRect(8, 8, w - 16, 6)
        surface.SetDrawColor(BLUE)
        surface.DrawRect(8, h - 14, w - 16, 6)
    end

    local close = makeChoiceButton(frame, "Close [P]", function() Sheet:Close() end)
    close:SetPos(frame:GetWide() - 126, 22)
    close:SetSize(104, 28)

    if not snapshot then
        local loading = label(frame, "Retrieving the server-authoritative Character Sheet...",
            "LOD_SheetHeading", BLUE)
        loading:SetPos(40, 80)
        loading:SetSize(frame:GetWide() - 80, 50)
        return
    end

    local title = label(frame, "THE LEGEND OF DEBORAH / CHARACTER SHEET", "LOD_SheetTitle", RED)
    title:SetPos(28, 20)
    title:SetSize(frame:GetWide() - 180, 46)

    local readyText = snapshot.requiredChoicesComplete
        and (snapshot.deploymentComplete and "DEPLOYED" or "READY FOR DEPLOYMENT")
        or "STAGING INCOMPLETE"
    local ready = label(frame, readyText, "LOD_SheetKey",
        snapshot.requiredChoicesComplete and BLUE or RED)
    ready:SetPos(frame:GetWide() - 330, 57)
    ready:SetSize(300, 24)
    ready:SetContentAlignment(6)

    local body = vgui.Create("DScrollPanel", frame)
    body:SetPos(24, 84)
    body:SetSize(frame:GetWide() - 48, frame:GetTall() - 112)
    local canvas = body:GetCanvas()
    canvas:SetTall(930)
    canvas.Paint = function(_, w, h)
        surface.SetDrawColor(80, 66, 41, 12)
        for y = 0, h, 5 do surface.DrawRect(0, y, w, 1) end
    end

    local leftWidth = math.min(360, math.floor((body:GetWide() - 24) * 0.34))
    local rightX = leftWidth + 24
    local rightWidth = body:GetWide() - rightX - 18

    local portrait = portraitPanel(canvas, snapshot)
    portrait:SetPos(0, 0)
    portrait:SetSize(150, 150)

    local name = label(canvas, snapshot.fullDisplayName, "LOD_SheetHeading", INK)
    name:SetPos(164, 5)
    name:SetSize(leftWidth - 164, 62)
    local avatar = label(canvas, "Avatar: " .. tostring(snapshot.avatarDescriptor),
        "LOD_SheetSmall", MUTED)
    avatar:SetPos(164, 70)
    avatar:SetSize(leftWidth - 164, 38)
    local level = label(canvas,
        string.format("LEVEL %d  /  %s", snapshot.level, snapshot.className or "CLASS UNCOMMITTED"),
        "LOD_SheetSubheading", BLUE)
    level:SetPos(164, 112)
    level:SetSize(leftWidth - 164, 30)

    sectionTitle(canvas, "Identity Traits", 0, 164, leftWidth)
    for index, trait in ipairs(snapshot.identityTraits or {}) do
        addIdentityTrait(canvas, trait, 0, 198 + (index - 1) * 166, leftWidth)
    end

    sectionTitle(canvas, "Level-1 Record", 0, 708, leftWidth)
    local record = paperPanel(canvas)
    record:SetPos(0, 742)
    record:SetSize(leftWidth, 126)
    local recordText = string.format(
        "Starting HP: %d\nXP: %d\nLives: %d\nDungeon Level: %d",
        snapshot.startingHP or 100, snapshot.xp or 0, snapshot.lives or 0,
        snapshot.dungeonLevel or 1)
    local recordLabel = label(record, recordText, "LOD_SheetBody", INK)
    recordLabel:SetPos(12, 10)
    recordLabel:SetSize(leftWidth - 24, 108)

    sectionTitle(canvas, snapshot.classId and ("Class / " .. snapshot.className) or "Choose One Class",
        rightX, 0, rightWidth)
    if not snapshot.classId then
        addClassChoices(canvas, snapshot, rightX, 40, rightWidth)
    else
        local classPanel = paperPanel(canvas)
        classPanel:SetPos(rightX, 40)
        classPanel:SetSize(rightWidth, 92)
        local classLine = label(classPanel,
            string.format("%s  /  favored %s  /  Hero progression d%d",
                snapshot.className,
                table.concat((function()
                    local result = {}
                    if snapshot.primaryAbility then result[#result + 1] = string.upper(snapshot.primaryAbility) end
                    for _, ability in ipairs(snapshot.secondaryAbilities or {}) do
                        if #result < 2 then result[#result + 1] = string.upper(ability) end
                    end
                    return result
                end)(), " + "),
                snapshot.classHitDie or 0),
            "LOD_SheetSubheading", BLUE)
        classLine:SetPos(12, 10)
        classLine:SetSize(rightWidth - 24, 28)
        local passive = label(classPanel, snapshot.classPassive or "", "LOD_SheetSmall", INK)
        passive:SetPos(12, 40)
        passive:SetSize(rightWidth - 24, 45)
    end

    local abilityY = snapshot.classId and 150 or 234
    sectionTitle(canvas, "Abilities", rightX, abilityY, rightWidth)
    for index, ability in ipairs(snapshot.abilities or {}) do
        addAbilityRow(canvas, ability, rightX, abilityY + 38 + (index - 1) * 42, rightWidth)
    end

    local featY = abilityY + 306
    sectionTitle(canvas, snapshot.classId and "Locked Level-1 Feat Draft" or "Level-1 Feat Draft",
        rightX, featY, rightWidth)
    if not snapshot.classId then
        local hint = label(canvas,
            "Commit a class first. The server will then generate and store one deterministic three-card ordinary feat draft.",
            "LOD_SheetBody", INK)
        hint:SetPos(rightX, featY + 42)
        hint:SetSize(rightWidth, 58)
    elseif snapshot.featDraft then
        addFeatCards(canvas, snapshot, rightX, featY + 40, rightWidth)
        local fingerprint = label(canvas,
            "Locked draft seed " .. tostring(snapshot.featDraft.rngSeed)
                .. " / closing, death, reconnect, and dungeon transition do not reroll these cards.",
            "LOD_SheetSmall", MUTED)
        fingerprint:SetPos(rightX, featY + 294)
        fingerprint:SetSize(rightWidth, 42)
    end

    canvas:SetTall(math.max(790, featY + 350))
end

local function inputIsBusy()
    return gui.IsConsoleVisible() or (chat.IsTyping and chat.IsTyping())
end

local function toggleSheet()
    local now = RealTime()
    if (Sheet.NextToggleAt or 0) > now then return end
    Sheet.NextToggleAt = now + 0.15
    if IsValid(Sheet.Frame) then Sheet:Close() else Sheet:Open(true) end
end

net.Receive("LOD_RPG_Snapshot", function()
    local snapshot = net.ReadTable()
    if not istable(snapshot) then return end
    Sheet.Snapshot = snapshot

    if IsValid(Sheet.Frame) then
        Sheet:Open(false)
    elseif not snapshot.requiredChoicesComplete
        and Sheet.AutoOpenedFor ~= snapshot.portraitCacheKey
    then
        Sheet.AutoOpenedFor = snapshot.portraitCacheKey
        timer.Simple(0.15, function()
            if Sheet.Snapshot == snapshot and not IsValid(Sheet.Frame) then Sheet:Open(false) end
        end)
    end
end)

hook.Add("PlayerButtonDown", "LOD_CharacterSheetP", function(ply, button)
    if ply ~= LocalPlayer() or button ~= KEY_P or inputIsBusy() then return end
    toggleSheet()
end)

-- Some client/input configurations dispatch a bound key through PlayerBindPress
-- but not PlayerButtonDown. This remains event-driven and the debounce prevents
-- one physical press observed by both hooks from toggling the sheet twice.
hook.Add("PlayerBindPress", "LOD_CharacterSheetPBindingFallback", function(ply, _, pressed)
    if ply ~= LocalPlayer() or not pressed or inputIsBusy()
        or not input.IsKeyDown(KEY_P)
    then
        return
    end
    toggleSheet()
end)

-- The server's first spawn snapshot may precede this receiver on a listen-server
-- client. Request one after client entities initialize so incomplete characters
-- reliably receive their automatic sheet without any recurring polling.
hook.Add("InitPostEntity", "LOD_CharacterSheetInitialSnapshot", function()
    timer.Simple(0.5, function()
        if not IsValid(LocalPlayer()) then return end
        net.Start("LOD_RPG_RequestSheet")
        net.SendToServer()
    end)
end)

concommand.Add("lod_character_sheet", function()
    toggleSheet()
end)

hook.Add("ShutDown", "LOD_CharacterSheetClose", function() Sheet:Close() end)
