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

local function wrappedTextHeight(text, font, width)
    surface.SetFont(font)
    local _, lineHeight = surface.GetTextSize("Ag")
    lineHeight = math.max(lineHeight + 2, 1)
    local lineCount = 0

    for hardLine in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        if hardLine == "" then
            lineCount = lineCount + 1
        else
            local current = ""
            for word in hardLine:gmatch("%S+") do
                local candidate = current == "" and word or (current .. " " .. word)
                local candidateWidth = surface.GetTextSize(candidate)
                if current ~= "" and candidateWidth > width then
                    lineCount = lineCount + 1
                    current = word
                else
                    current = candidate
                end
            end
            if current ~= "" then lineCount = lineCount + 1 end
        end
    end

    return math.max(lineHeight, lineCount * lineHeight)
end

local function fitWrapped(item, width, minimumHeight)
    item:SetWide(width)
    local height = math.max(
        wrappedTextHeight(item:GetText(), item:GetFont(), width),
        minimumHeight or 0)
    item:SetTall(height)
    return height
end

local function sectionTitle(parent, text, x, y, width)
    local item = label(parent, string.upper(text), "LOD_SheetHeading", RED)
    item:SetPos(x, y)
    item:SetWrap(false)
    item:SetSize(width, 30)
    return item, 30
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
    panel:SetWide(width)
    local contentWidth = width - 24
    local cursorY = 10

    local category = label(panel, string.upper(trait.tableType) .. " / " .. trait.categoryName,
        "LOD_SheetSubheading", BLUE)
    category:SetPos(12, cursorY)
    cursorY = cursorY + fitWrapped(category, contentWidth, 22) + 5

    local perk = label(panel, trait.perkDisplayName, "LOD_SheetBody", RED)
    perk:SetPos(12, cursorY)
    cursorY = cursorY + fitWrapped(perk, contentWidth, 21) + 10

    local effect = label(panel, trait.mechanicalEffect, "LOD_SheetSmall", INK)
    effect:SetPos(12, cursorY)
    cursorY = cursorY + fitWrapped(effect, contentWidth, 18) + 12

    local flavor = label(panel, trait.flavorText, "LOD_SheetSmall", MUTED)
    flavor:SetPos(12, cursorY)
    cursorY = cursorY + fitWrapped(flavor, contentWidth, 18) + 12

    local height = math.max(146, cursorY)
    panel:SetTall(height)
    return panel, height
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
    local cards = {}
    local cardHeight = 176
    for index, classId in ipairs({"fighter", "rogue", "wizard"}) do
        local data = CLASS_CARDS[classId]
        local card = paperPanel(parent)
        card:SetPos(x + (index - 1) * (cardWidth + gap), y)
        card:SetWide(cardWidth)
        local title = label(card, data.title, "LOD_SheetHeading", RED)
        title:SetPos(12, 10)
        local titleHeight = fitWrapped(title, cardWidth - 24, 30)
        local sub = label(card, data.subtitle, "LOD_SheetSmall", BLUE)
        sub:SetPos(12, 10 + titleHeight + 5)
        local subHeight = fitWrapped(sub, cardWidth - 24, 18)
        local body = label(card, data.body, "LOD_SheetSmall", INK)
        local bodyY = 10 + titleHeight + 5 + subHeight + 8
        body:SetPos(12, bodyY)
        local bodyHeight = fitWrapped(body, cardWidth - 24, 54)
        local choose = makeChoiceButton(card, "Commit " .. data.title, function()
            net.Start("LOD_RPG_ChooseClass")
            net.WriteString(classId)
            net.SendToServer()
        end)
        choose:SetSize(cardWidth - 24, 28)
        cards[#cards + 1] = {panel = card, footer = choose}
        cardHeight = math.max(cardHeight, bodyY + bodyHeight + 50)
    end
    for _, card in ipairs(cards) do
        card.panel:SetTall(cardHeight)
        card.footer:SetPos(12, cardHeight - 38)
    end
    return cardHeight
end

local function addFeatCards(parent, snapshot, x, y, width)
    local offers = snapshot.featDraft and snapshot.featDraft.offers or {}
    local gap = 12
    local cardWidth = math.floor((width - gap * 2) / 3)
    local cards = {}
    local cardHeight = 246
    for index, feat in ipairs(offers) do
        local card = paperPanel(parent)
        card:SetPos(x + (index - 1) * (cardWidth + gap), y)
        card:SetWide(cardWidth)
        if feat.selected then
            card.Paint = function(self, w, h)
                draw.RoundedBox(2, 0, 0, w, h, Color(248, 225, 194))
                surface.SetDrawColor(GOLD)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            end
        end
        local title = label(card, feat.displayName, "LOD_SheetSubheading", feat.selected and RED or BLUE)
        title:SetPos(12, 10)
        local titleHeight = fitWrapped(title, cardWidth - 24, 26)
        local req = label(card, feat.eligibilityText or "", "LOD_SheetSmall", MUTED)
        req:SetPos(12, 10 + titleHeight + 5)
        local reqHeight = fitWrapped(req, cardWidth - 24, 18)
        local effect = label(card, feat.effect or "", "LOD_SheetSmall", INK)
        local effectY = 10 + titleHeight + 5 + reqHeight + 12
        effect:SetPos(12, effectY)
        local effectHeight = fitWrapped(effect, cardWidth - 24, 90)

        local footer
        if snapshot.featDraft.resolved then
            footer = label(card, feat.selected and "SELECTED" or "NOT SELECTED",
                "LOD_SheetKey", feat.selected and RED or MUTED)
            footer:SetSize(cardWidth - 24, 25)
        else
            footer = makeChoiceButton(card, "Choose " .. feat.displayName, function()
                net.Start("LOD_RPG_ChooseFeat")
                net.WriteString(feat.featId)
                net.WriteUInt(snapshot.featDraft.earnedAtLevel or 1, 5)
                net.SendToServer()
            end)
            footer:SetSize(cardWidth - 24, 28)
        end
        cards[#cards + 1] = {panel = card, footer = footer}
        cardHeight = math.max(cardHeight, effectY + effectHeight + 52)
    end
    for _, card in ipairs(cards) do
        card.panel:SetTall(cardHeight)
        card.footer:SetPos(12, cardHeight - 38)
    end
    return cardHeight
end

local function addOwnedFeatLedger(parent, snapshot, x, y, width)
    local panel = paperPanel(parent)
    panel:SetPos(x, y)
    panel:SetWide(width)
    local contentWidth = width - 24
    local cursorY = 10
    local owned = snapshot.ownedFeats or {}

    if #owned == 0 then
        local empty = label(panel, "No ordinary feats committed.", "LOD_SheetSmall", MUTED)
        empty:SetPos(12, cursorY)
        cursorY = cursorY + fitWrapped(empty, contentWidth, 20) + 10
    else
        for _, feat in ipairs(owned) do
            local stacks = (feat.stackCount or 1) > 1 and ("  x" .. feat.stackCount) or ""
            local title = label(panel, feat.displayName .. stacks, "LOD_SheetSubheading", BLUE)
            title:SetPos(12, cursorY)
            cursorY = cursorY + fitWrapped(title, contentWidth, 22) + 3
            local effect = label(panel, feat.effect or "", "LOD_SheetSmall", INK)
            effect:SetPos(12, cursorY)
            cursorY = cursorY + fitWrapped(effect, contentWidth, 18) + 9
        end
    end

    panel:SetTall(cursorY)
    return cursorY
end

local function addHitDieLedger(parent, snapshot, x, y, width)
    local panel = paperPanel(parent)
    panel:SetPos(x, y)
    panel:SetWide(width)
    local contentWidth = width - 24
    local cursorY = 10
    local rolls = snapshot.hitDieRolls or {}

    if #rolls == 0 then
        local empty = label(panel, "No progression die is rolled at Level 1.", "LOD_SheetSmall", MUTED)
        empty:SetPos(12, cursorY)
        cursorY = cursorY + fitWrapped(empty, contentWidth, 20) + 10
    else
        for _, roll in ipairs(rolls) do
            local values = {}
            for index, value in ipairs(roll.values or {}) do values[index] = tostring(value) end
            local text = string.format("L%d  %s [%s]  %+d CON  =  +%d HP%s",
                roll.level, roll.formula, table.concat(values, "+"), roll.conBonus or 0,
                roll.hpGain or 1, roll.capped and " (CHAIN CAPPED)" or "")
            local row = label(panel, text, "LOD_SheetSmall", roll.capped and RED or INK)
            row:SetPos(12, cursorY)
            cursorY = cursorY + fitWrapped(row, contentWidth, 18) + 3
        end
        local summary = label(panel,
            string.format("Stored roll subtotal: %d  /  current CON bonus per gained Level: %+d",
                snapshot.rolledHitPointSubtotal or 0, snapshot.hpConBonusPerLevel or 0),
            "LOD_SheetSmall", MUTED)
        summary:SetPos(12, cursorY + 4)
        cursorY = cursorY + 4 + fitWrapped(summary, contentWidth, 20) + 10
    end

    panel:SetTall(cursorY)
    return cursorY
end

local function addCapstoneCards(parent, snapshot, x, y, width)
    local offers = snapshot.capstoneDraft and snapshot.capstoneDraft.offers or {}
    local gap = 12
    local cardWidth = math.floor((width - gap * 2) / 3)
    local cards = {}
    local cardHeight = 210

    for index, feat in ipairs(offers) do
        local card = paperPanel(parent)
        card:SetPos(x + (index - 1) * (cardWidth + gap), y)
        card:SetWide(cardWidth)
        if feat.selected then
            card.Paint = function(self, w, h)
                draw.RoundedBox(2, 0, 0, w, h, Color(248, 225, 194))
                surface.SetDrawColor(GOLD)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            end
        end

        local title = label(card, feat.displayName, "LOD_SheetSubheading", feat.selected and RED or BLUE)
        title:SetPos(12, 10)
        local titleHeight = fitWrapped(title, cardWidth - 24, 26)
        local effect = label(card, feat.effect or "", "LOD_SheetSmall", INK)
        local effectY = 10 + titleHeight + 10
        effect:SetPos(12, effectY)
        local effectHeight = fitWrapped(effect, cardWidth - 24, 100)

        local footer
        if snapshot.capstoneDraft.resolved then
            footer = label(card, feat.selected and "SELECTED" or "NOT SELECTED",
                "LOD_SheetKey", feat.selected and RED or MUTED)
            footer:SetSize(cardWidth - 24, 25)
        else
            footer = makeChoiceButton(card, "Choose " .. feat.displayName, function()
                net.Start("LOD_RPG_ChooseCapstone")
                net.WriteString(feat.featId)
                net.SendToServer()
            end)
            footer:SetSize(cardWidth - 24, 28)
        end
        cards[#cards + 1] = {panel = card, footer = footer}
        cardHeight = math.max(cardHeight, effectY + effectHeight + 52)
    end

    for _, card in ipairs(cards) do
        card.panel:SetTall(cardHeight)
        card.footer:SetPos(12, cardHeight - 38)
    end
    return cardHeight
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
    local nameHeight = fitWrapped(name, leftWidth - 164, 48)
    local avatar = label(canvas, "Avatar: " .. tostring(snapshot.avatarDescriptor),
        "LOD_SheetSmall", MUTED)
    local avatarY = 5 + nameHeight + 6
    avatar:SetPos(164, avatarY)
    local avatarHeight = fitWrapped(avatar, leftWidth - 164, 20)
    local level = label(canvas,
        string.format("LEVEL %d  /  %s", snapshot.level, snapshot.className or "CLASS UNCOMMITTED"),
        "LOD_SheetSubheading", BLUE)
    local levelY = avatarY + avatarHeight + 7
    level:SetPos(164, levelY)
    local levelHeight = fitWrapped(level, leftWidth - 164, 26)

    local leftY = math.max(166, levelY + levelHeight + 16)
    local _, identityTitleHeight = sectionTitle(canvas, "Identity Traits", 0, leftY, leftWidth)
    leftY = leftY + identityTitleHeight + 8
    for _, trait in ipairs(snapshot.identityTraits or {}) do
        local _, traitHeight = addIdentityTrait(canvas, trait, 0, leftY, leftWidth)
        leftY = leftY + traitHeight + 10
    end

    local _, recordTitleHeight = sectionTitle(canvas, "Campaign Record", 0, leftY + 6, leftWidth)
    leftY = leftY + 6 + recordTitleHeight + 8
    local record = paperPanel(canvas)
    record:SetPos(0, leftY)
    record:SetWide(leftWidth)
    local xpLine = snapshot.xpForNextLevel
        and string.format("XP: %d / %d", snapshot.xp or 0, snapshot.xpForNextLevel)
        or string.format("XP: %d / MAX", snapshot.xp or 0)
    local recordText = string.format(
        "Starting HP: %d\nCurrent HP: %d / %d\n%s\nLives: %d\nDungeon Level: %d",
        snapshot.startingHP or 100, snapshot.currentHP or 0, snapshot.maxHP or 100,
        xpLine, snapshot.lives or 0, snapshot.dungeonLevel or 1)
    if snapshot.healthRegenEnabled then
        recordText = recordText .. string.format(
            "\nHealth Regen: %.2f HP/s to %d%% MaxHP",
            snapshot.healthRegenRatePerSecond or 0,
            math.floor((snapshot.healthRegenCeilingFraction or 0) * 100 + 0.5))
    end
    if (snapshot.breadcrumbFeatBonusCells or 0) > 0 or snapshot.frugalMapEnabled then
        recordText = recordText .. string.format(
            "\nNavigation: %d breadcrumb cells / %.2f Magic/s map drain",
            snapshot.breadcrumbCells or 6, snapshot.mapDrainRatePerSecond or (100 / 15))
    end
    if (snapshot.ammoRegenFloorRank or 0) > 0 then
        local families = {}
        for _, profile in ipairs(snapshot.ammoRegenFamilies or {}) do
            families[#families + 1] = string.format("%s %d/%d",
                profile.label or "Ammo", profile.floor or 0, profile.cap or 0)
        end
        recordText = recordText .. string.format("\nAmmo Regen: %d%% floor%s",
            math.floor((snapshot.ammoRegenFloorFraction or 0) * 100 + 0.5),
            #families > 0 and (": " .. table.concat(families, ", ")) or "")
    end
    local recordLabel = label(record, recordText, "LOD_SheetBody", INK)
    recordLabel:SetPos(12, 10)
    local recordHeight = fitWrapped(recordLabel, leftWidth - 24, 112) + 20
    record:SetTall(recordHeight)
    leftY = leftY + recordHeight + 16

    local _, hpTitleHeight = sectionTitle(canvas, "Progression HP", 0, leftY, leftWidth)
    leftY = leftY + hpTitleHeight + 8
    leftY = leftY + addHitDieLedger(canvas, snapshot, 0, leftY, leftWidth)
    local leftBottom = leftY

    local rightY = 0
    local _, classTitleHeight = sectionTitle(canvas,
        snapshot.classId and ("Class / " .. snapshot.className) or "Choose One Class",
        rightX, rightY, rightWidth)
    rightY = rightY + classTitleHeight + 8
    if not snapshot.classId then
        rightY = rightY + addClassChoices(canvas, snapshot, rightX, rightY, rightWidth)
    else
        local classPanel = paperPanel(canvas)
        classPanel:SetPos(rightX, rightY)
        classPanel:SetWide(rightWidth)
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
        local classLineHeight = fitWrapped(classLine, rightWidth - 24, 26)
        local passive = label(classPanel, snapshot.classPassive or "", "LOD_SheetSmall", INK)
        passive:SetPos(12, 10 + classLineHeight + 8)
        local passiveHeight = fitWrapped(passive, rightWidth - 24, 36)
        local classPanelHeight = 10 + classLineHeight + 8 + passiveHeight + 12
        classPanel:SetTall(classPanelHeight)
        rightY = rightY + classPanelHeight
    end

    rightY = rightY + 18
    local _, abilityTitleHeight = sectionTitle(canvas, "Abilities", rightX, rightY, rightWidth)
    rightY = rightY + abilityTitleHeight + 6
    for _, ability in ipairs(snapshot.abilities or {}) do
        addAbilityRow(canvas, ability, rightX, rightY, rightWidth)
        rightY = rightY + 42
    end

    rightY = rightY + 18
    local _, ownedTitleHeight = sectionTitle(canvas,
        string.format("Ordinary Feats / %d of %d", snapshot.ordinaryFeatsCommitted or 0,
            snapshot.featSlotsGranted or 0),
        rightX, rightY, rightWidth)
    rightY = rightY + ownedTitleHeight + 8
    rightY = rightY + addOwnedFeatLedger(canvas, snapshot, rightX, rightY, rightWidth)

    rightY = rightY + 18
    local draftLevel = snapshot.featDraft and snapshot.featDraft.earnedAtLevel or 1
    local draftHeading
    if not snapshot.classId then
        draftHeading = "Level-1 Feat Draft"
    elseif snapshot.featDraft and not snapshot.featDraft.resolved then
        draftHeading = string.format("Level-%d Feat Available / %d Pending",
            draftLevel, snapshot.pendingFeatCount or 1)
    else
        draftHeading = string.format("Locked Level-%d Feat Draft", draftLevel)
    end
    local _, featTitleHeight = sectionTitle(canvas,
        draftHeading,
        rightX, rightY, rightWidth)
    rightY = rightY + featTitleHeight + 8
    if not snapshot.classId then
        local hint = label(canvas,
            "Commit a class first. The server will then generate and store one deterministic three-card ordinary feat draft.",
            "LOD_SheetBody", INK)
        hint:SetPos(rightX, rightY)
        rightY = rightY + fitWrapped(hint, rightWidth, 42)
    elseif snapshot.featDraft then
        local featCardHeight = addFeatCards(canvas, snapshot, rightX, rightY, rightWidth)
        rightY = rightY + featCardHeight + 12
        local fingerprint = label(canvas,
            "Locked draft seed " .. tostring(snapshot.featDraft.rngSeed)
                .. " / closing, death, reconnect, and dungeon transition do not reroll these cards.",
            "LOD_SheetSmall", MUTED)
        fingerprint:SetPos(rightX, rightY)
        rightY = rightY + fitWrapped(fingerprint, rightWidth, 20)
    end

    if snapshot.capstoneDraft then
        rightY = rightY + 18
        local _, capTitleHeight = sectionTitle(canvas, "Level-20 Class Capstone",
            rightX, rightY, rightWidth)
        rightY = rightY + capTitleHeight + 8
        rightY = rightY + addCapstoneCards(canvas, snapshot, rightX, rightY, rightWidth)
    end

    canvas:SetTall(math.max(body:GetTall(), leftBottom, rightY) + 24)
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
