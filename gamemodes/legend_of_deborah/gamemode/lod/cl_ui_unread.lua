-- Three bounded presentation records, fed only by the existing snapshot receivers.
-- Gameplay ownership and transport scheduling remain server-authoritative.
local UI = LOD.UI
local OWNERS = {sheet="CharacterSheet", book="Spellbook", equipment="Equipment"}
UI.PageUpdates = UI.PageUpdates or {}

local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end
local function selectFields(source, keys)
    local result = {}
    for _, key in ipairs(keys) do result[key] = source[key] end
    return result
end
local SHEET_FIELDS = {"level", "classId", "primaryAbility", "secondaryAbilities",
    "fullDisplayName", "identityTraits", "ownedFeats", "selectedCapstone",
    "featDraft", "capstoneDraft", "pendingFeatCount", "requiredChoicesComplete"}
local ABILITY_FIELDS = {"id", "base", "growth", "fighterTraining", "identity", "feat", "role"}
local function projection(page, snapshot)
    if page == "sheet" then
        local result = selectFields(snapshot, SHEET_FIELDS)
        result.abilities = {}
        for _, ability in ipairs(snapshot.abilities or {}) do
            result.abilities[ability.id] = selectFields(ability, ABILITY_FIELDS)
        end
        -- Soldier growth is exposed through these stable profile fields instead.
        result.baseAbilities, result.growthProfile = snapshot.baseAbilities, snapshot.growthProfile
        return table.Copy(result)
    elseif page == "book" then
        local result = {forms={}, contents={}}
        for _, entry in ipairs(snapshot.forms or {}) do
            if entry.owned then result.forms[entry.id] = true end
        end
        for _, entry in ipairs(snapshot.contents or {}) do
            if entry.owned then result.contents[entry.id] = true end
        end
        return result
    else
        local result = {items={}, storageCapacity=snapshot.storageCapacity}
        for id, item in pairs(snapshot.items or {}) do
            local copy = table.Copy(item)
            -- Charges are a transient resource; acquiring/removing the Wand is
            -- meaningful, firing one is not. Do not observe slots or ammo pools.
            copy.charges = nil
            result.items[id] = copy
        end
        return result
    end
end
local function integer(value)
    return type(value) == "number" and value >= 1 and value < 2^53
        and value == math.floor(value)
end
function UI:ResetPageUpdates(epoch)
    local retire = self.PageEpoch ~= nil
    self.PageEpoch, self.PageUpdates = epoch, {}
    if not retire then return end
    for _, name in pairs(OWNERS) do
        local owner = LOD[name]
        if owner then
            if owner.Close then owner:Close() end
            owner.Snapshot = name == "Equipment" and {items={}, slots={}} or nil
            if name == "Equipment" then owner.HasSnapshot = false end
            if name == "CharacterSheet" then owner.AutoOpenedFor = nil end
        end
    end
end

-- Validate before overwriting a cache or expanding an equipment delta. Legacy
-- unversioned fixtures/cache data are accepted only before a versioned epoch.
function UI:AdmitPageSnapshot(page, snapshot, delta)
    if not OWNERS[page] or type(snapshot) ~= "table" then return false end
    local meta = snapshot._pageUpdate
    if meta == nil then return self.PageEpoch == nil end
    if type(meta) ~= "table" or not integer(meta.epoch) or not integer(meta.revision) then return false end
    if self.PageEpoch and meta.epoch < self.PageEpoch then return false end
    if not self.PageEpoch or meta.epoch > self.PageEpoch then self:ResetPageUpdates(meta.epoch) end
    local previous = self.PageUpdates[page]
    if previous and previous.revision and meta.revision <= previous.revision then return false end
    if delta and (not previous or meta.base ~= previous.revision) then return false, "baseline" end
    return true
end
function UI:ObservePageSnapshot(page, snapshot)
    local previous = self.PageUpdates[page]
    local current = projection(page, snapshot)
    local meta = snapshot._pageUpdate
    self.PageUpdates[page] = {projection=current, snapshot=snapshot,
        revision=meta and meta.revision, epoch=meta and meta.epoch,
        unread=previous ~= nil and (previous.unread or not equal(current, previous.projection)) or false}
end
function UI:IsPageUnread(page)
    local record = self.PageUpdates[page]
    return record and record.unread == true or false
end

-- PaintOver runs after the panel and its children. Bind only after a page has
-- actually rebuilt; a deferred drag keeps its previous displayed snapshot.
function UI:WatchPageView(panel, page, snapshot, frame)
    panel.LODUnreadView = {page=page, snapshot=snapshot, frame=frame or panel}
    if panel.LODUnreadPaintInstalled then return end
    panel.LODUnreadPaintInstalled = true
    local prior = panel.PaintOver
    panel.PaintOver = function(view, w, h)
        if prior then prior(view, w, h) end
        local binding = view.LODUnreadView
        local record = UI.PageUpdates[binding.page]
        local owner = LOD[OWNERS[binding.page]]
        local window = binding.frame
        if not IsValid(view) or not IsValid(window) or not owner or owner.Frame ~= window
            or UI.ActivePage ~= binding.page or UI:IsMinigameLocked()
            or view.IsVisible and not view:IsVisible()
            or window.IsVisible and not window:IsVisible()
            or not record or record.snapshot ~= binding.snapshot then return end
        record.unread = false
    end
end

-- Paint on the parent, not outside a clipped button. No new panel, timer,
-- polling, animation or per-frame Color allocation is needed.
function UI:UnreadPageLinks(frame, pages, width, y)
    local prior = frame.PaintOver
    frame.PaintOver = function(panel, w, h)
        if prior then prior(panel, w, h) end
        for i, page in ipairs(pages) do
            if UI:IsPageUnread(page[1]) then
                local x = 24 + (i-1)*(width+10) + width/2
                surface.SetDrawColor(UI.Colors.light)
                surface.DrawRect(x-8, y-18, 16, 18)
                draw.SimpleText("!", "LOD_SheetKey", x, y-9, UI.Colors.red,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end
