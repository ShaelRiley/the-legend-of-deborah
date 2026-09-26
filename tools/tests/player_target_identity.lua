-- Standalone draw-contract regression. Run from repository root with Lua 5.1+
-- or texlua. This executes the production HUD callback under explicit GMod
-- stubs; it does NOT test native rendering, tracing or network replication.
local source = arg[1] or "gamemodes/legend_of_deborah/gamemode/lod/cl_teammate_identity.lua"
local cases, hooks, draws, viewer, target, width, height, now = {}, {}, {}, nil, nil, 1280, 800, 100
local GLYPH = "[%z\1-\127\194-\244][\128-\191]*"
function Color(r, g, b, a) return {r = r, g = g, b = b, a = a or 255} end
local roles = {identity = Color(120,180,255), character = Color(255,135,115),
    prose = Color(240,232,205), resource = Color(165,235,165),
    objective = Color(255,220,100), danger = Color(255,135,115)}
TEXT_ALIGN_LEFT = 0
hook = {Add = function(event, id, fn) hooks[event] = hooks[event] or {}; hooks[event][id] = fn end}
surface = {SetFont = function(font) assert(font == "LOD_HUD_Small") end}
local measurements = 0
function surface.GetTextSize(text)
    measurements = measurements + 1
    local pixels = 0
    for glyph in text:gmatch(GLYPH) do pixels = pixels + (glyph == " " and 4 or 8) end
    return pixels, 14
end
function IsValid(entity) return type(entity) == "table" and entity.valid ~= false end
function LocalPlayer() return viewer end
function ScrW() return width end
function ScrH() return height end
function CurTime() return now end
local function entity()
    return {valid = true, alive = true, player = true, hp = 100, maximum = 100,
        nickname = "TestUser", strings = {LOD_HeroName = 'Nessa "Bold" Riley'}, bools = {}, floats = {},
        Alive = function(self) return self.alive end,
        IsPlayer = function(self) return self.player end,
        IsDormant = function(self) return self.dormant == true end,
        GetNoDraw = function(self) return self.hidden == true end,
        Health = function(self) return self.hp end,
        GetMaxHealth = function(self) return self.maximum end,
        Nick = function(self) return self.nickname end,
        GetNW2Bool = function(self, key, fallback)
            if self.bools[key] == nil then return fallback end; return self.bools[key]
        end,
        GetNW2String = function(self, key, fallback) return self.strings[key] or fallback end,
        GetNW2Float = function(self, key, fallback) return self.floats[key] or fallback end,
        GetEyeTrace = function() return {Entity = target} end}
end
local function reset()
    hooks, draws, width, height, now, measurements = {}, {}, 1280, 800, 100, 0
    viewer, target = entity(), entity()
    LOD = {UI = {HUDRoles = roles, Roles = roles}}
    function LOD.UI:HUDText(text, font, x, y, color, align)
        draws[#draws + 1] = {text = text, font = font, x = x, y = y, color = color, align = align}
    end
    assert(loadfile(source))()
end
local function check(condition, message) assert(condition, message or "contract failed") end
local function paint()
    draws = {}
    local callback = hooks.HUDPaint and hooks.HUDPaint.LOD_TeammateIdentity
    check(type(callback) == "function", "missing canonical HUD owner")
    callback()
    return draws
end
local function sameColor(a, b)
    return a and b and a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
end
local function twoLines()
    paint()
    check(#draws == 5, "expected three identity spans and two HP spans")
    check(draws[1].y == draws[2].y and draws[2].y == draws[3].y, "identity wrapped")
    check(draws[4].y == draws[5].y and draws[4].y == draws[1].y + 20, "HP row misplaced")
    check(draws[1].y == height * .5 + 24, "crosshair offset")
    return draws
end
local function join(a, b)
    local text = ""; for i = a, b do text = text .. draws[i].text end; return text
end
local function centered(a, b)
    local left = draws[a].x
    local right = draws[b].x + surface.GetTextSize(draws[b].text)
    check(math.abs((left + right) * .5 - width * .5) < .001, "row not centered")
    for i = a, b - 1 do
        check(draws[i + 1].x == draws[i].x + surface.GetTextSize(draws[i].text), "span gap/overlap")
    end
end
local function test(name, fn) cases[#cases + 1] = {name = name, run = fn} end

test("stock target callback suppressed", function()
    check(hooks.HUDDrawTargetID and hooks.HUDDrawTargetID.LOD_HideStockPlayerTargetID() == false)
end)
test("stock remains suppressed with menu open", function()
    LOD.UI.ActivePage = "sheet"; paint(); check(#draws == 0)
    check(hooks.HUDDrawTargetID and hooks.HUDDrawTargetID.LOD_HideStockPlayerTargetID() == false)
end)
test("stock remains suppressed without local player", function()
    viewer = nil; paint(); check(#draws == 0)
    check(hooks.HUDDrawTargetID and hooks.HUDDrawTargetID.LOD_HideStockPlayerTargetID() == false)
end)
test("exact two-line text and independent centering", function()
    twoLines(); check(join(1,3) == 'TestUser as Nessa "Bold" Riley')
    check(join(4,5) == "100/100 HP"); centered(1,3); centered(4,5)
end)
test("identity semantic roles and steady resource fraction", function()
    twoLines()
    for i, role in ipairs({"identity", "prose", "character", "resource", "resource"}) do
        check(draws[i].color == roles[role], "wrong shared role at span " .. i)
    end
end)
for _, sample in ipairs({{120,100,"resource"},{100,100,"resource"},{99,100,"objective"},
    {51,100,"objective"},{50,100,"orange"},{26,100,"orange"},{25,100,"danger"},
    {1,100,"danger"},{1,1,"resource"},{2,3,"objective"},{1,3,"orange"},{5,20,"danger"}}) do
    local hp, maximum, role = sample[1], sample[2], sample[3]
    test("HP band " .. hp .. "/" .. maximum, function()
        target.hp, target.maximum = hp, maximum; twoLines()
        local expected = role == "orange" and Color(255,165,80) or roles[role]
        check(sameColor(draws[5].color, expected), "wrong HP band")
        check(draws[4].color == roles.resource, "fraction changed with HP band")
        check(join(4,5) == hp .. "/" .. maximum .. " HP", "HP values altered")
    end)
end
for _, maximum in ipairs({0,-1}) do
    test("unknown maximum " .. maximum, function()
        target.maximum = maximum; twoLines()
        check(join(4,5) == "100/? HP" and draws[5].color == roles.prose, "invented maximum/full state")
    end)
end
test("changing HP/max does not use stale cached numbers", function()
    twoLines(); target.hp, target.maximum = 10, 40; twoLines()
    check(join(4,5) == "10/40 HP" and draws[5].color == roles.danger)
end)
test("embedded connector and numeric names retain roles", function()
    target.nickname = "123 as 456"; target.strings.LOD_HeroName = "789 as 012"
    twoLines(); check(draws[1].text == "123 as 456" and draws[3].text == "789 as 012")
    check(draws[1].color == roles.identity and draws[3].color == roles.character)
end)
test("control characters and Unicode line separators stay inline", function()
    target.nickname = " A\nB\rC\tD "; target.strings.LOD_HeroName = "E\226\128\168F\226\128\169G"
    twoLines(); check(join(1,3) == "A B C D as E F G")
end)
for _, resolution in ipairs({640,800,1280,1920,3840}) do
    test("long UTF-8 names bounded at width " .. resolution, function()
        width = resolution
        target.nickname = string.rep("猫é", 200); target.strings.LOD_HeroName = string.rep("🧙Æ", 200)
        twoLines(); centered(1,3); centered(4,5)
        local text = join(1,3)
        check(surface.GetTextSize(text) <= math.min(640, width * .8), "header overflow")
        for _, i in ipairs({1,3}) do
            check(draws[i].text:sub(-3) == "…", "missing ellipsis")
            local rebuilt = ""; for glyph in draws[i].text:gmatch(GLYPH) do rebuilt = rebuilt .. glyph end
            check(rebuilt == draws[i].text, "split UTF-8 sequence")
        end
    end)
end
test("short character name returns width to long nickname", function()
    width = 640; target.nickname = string.rep("W",100); target.strings.LOD_HeroName = "A"
    twoLines(); check(draws[3].text == "A" and surface.GetTextSize(draws[1].text) > 256)
end)
test("layout cache invalidates on rename and resize", function()
    twoLines(); target.nickname = "Renamed"; width = 800; twoLines()
    check(draws[1].text == "Renamed"); centered(1,3)
end)
test("long-name layout reused without re-fitting each frame", function()
    target.nickname = string.rep("W",1000); twoLines()
    measurements = 0; twoLines(); check(measurements <= 4, "re-fitted unchanged name")
end)
test("blank procedural name uses existing character field", function()
    target.strings.LOD_HeroName = ""; target.strings.LOD_Character = "Deborah"
    twoLines(); check(draws[3].text == "Deborah")
end)
test("empty names get readable fallbacks", function()
    target.nickname = ""; target.strings = {}; twoLines()
    check(join(1,3) == "Player as Hero")
end)
test("human Soldier uses active role not dormant Hero", function()
    target.bools.LOD_IsSoldier = true; twoLines(); check(join(1,3) == "TestUser as Soldier")
end)
test("Soldier viewer can read visible Hero", function()
    viewer.bools.LOD_IsSoldier = true; twoLines(); check(draws[3].text == 'Nessa "Bold" Riley')
end)
test("two Soldiers get same two-line readout", function()
    viewer.bools.LOD_IsSoldier, target.bools.LOD_IsSoldier = true, true; twoLines()
    check(draws[3].text == "Soldier")
end)
for _, spec in ipairs({
    {"invalid local player", function() viewer.valid = false end},
    {"dead local player", function() viewer.alive = false end},
    {"invalid target", function() target.valid = false end},
    {"dead target", function() target.alive = false end},
    {"occluding prop/NPC", function() target.player = false end},
    {"self target", function() target = viewer end},
    {"no eye-trace entity", function() target = nil end},
    {"missing trace", function() viewer.GetEyeTrace = function() return nil end end},
    {"dormant target", function() target.dormant = true end},
    {"no-draw target", function() target.hidden = true end},
    {"Veil-cloaked target", function() target.floats.LOD_VeilUntil = now + 1 end},
    {"UI unavailable during initialization", function() LOD.UI = nil end}}) do
    test(spec[1], function() spec[2](); paint(); check(#draws == 0, "ineligible target exposed") end)
end
test("expired Veil reveals normally", function()
    target.floats.LOD_VeilUntil = now; twoLines()
end)
test("hot reload replaces hooks instead of duplicating", function()
    assert(loadfile(source))()
    local count = 0; for _ in pairs(hooks.HUDPaint) do count = count + 1 end
    check(count == 1); twoLines()
end)
test("legacy role palette fallback", function()
    LOD.UI.HUDRoles = nil; twoLines(); check(draws[1].color == roles.identity)
end)

local passed, failed = 0, 0
for _, case in ipairs(cases) do
    local ok, err = pcall(function() reset(); case.run() end)
    if ok then passed = passed + 1; print("PASS " .. case.name)
    else failed = failed + 1; print("FAIL " .. case.name .. ": " .. tostring(err)) end
end
print(string.format("PLAYER_TARGET_IDENTITY: %d passed, %d failed (%d cases)", passed, failed, #cases))
os.exit(failed == 0 and 0 or 1)
