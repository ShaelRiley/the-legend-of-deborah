-- Checkpoint G Protected Regression Gate Harness (AG-010R1)
-- Executed headlessly via Lua 5.4 / run_lua54.py

LOD = LOD or {}
LOD.RPG = LOD.RPG or {}

local mockTime = 1000

local function mockGMod()
    SERVER = true
    CLIENT = false
    unpack = unpack or table.unpack

    DeriveGamemode = function() end
    GM = GM or {}

    Vector = function(x, y, z)
        local v = {x = x or 0, y = y or 0, z = z or 0}
        setmetatable(v, {
            __add = function(a, b) return Vector((a.x or 0) + (b.x or 0), (a.y or 0) + (b.y or 0), (a.z or 0) + (b.z or 0)) end,
            __sub = function(a, b) return Vector((a.x or 0) - (b.x or 0), (a.y or 0) - (b.y or 0), (a.z or 0) - (b.z or 0)) end
        })
        return v
    end
    Angle = function(p, y, r) return {p = p or 0, y = y or 0, r = r or 0} end
    Color = function(r, g, b, a) return {r = r or 255, g = g or 255, b = b or 255, a = a or 255} end

    local metatables = {}
    FindMetaTable = FindMetaTable or function(name)
        if not metatables[name] then metatables[name] = {} end
        return metatables[name]
    end

    util = util or {}
    util.AddNetworkString = util.AddNetworkString or function() end
    util.CRC = util.CRC or function(v) return tostring(v) end
    util.IsValidModel = util.IsValidModel or function() return true end

    net = net or {}
    net.Receive = net.Receive or function() end
    net.Start = net.Start or function() end
    net.WriteTable = net.WriteTable or function() end
    net.WriteString = net.WriteString or function() end
    net.WriteUInt = net.WriteUInt or function() end
    net.Send = net.Send or function() end
    net.Broadcast = net.Broadcast or function() end

    local hookTable = {}
    hook = hook or {}
    hook.Add = function(event, name, func)
        hookTable[event] = hookTable[event] or {}
        hookTable[event][name] = func
    end
    hook.Remove = function(event, name)
        if hookTable[event] then hookTable[event][name] = nil end
    end
    hook.GetTable = function()
        return hookTable
    end
    hook.Run = function(event, ...)
        local handlers = hookTable[event]
        if handlers then
            for name, fn in pairs(handlers) do
                local res = fn(...)
                if res ~= nil then return res end
            end
        end
    end
    hook.Call = function(event, gamemode, ...)
        return hook.Run(event, ...)
    end

    concommand = concommand or {}
    concommand.Add = concommand.Add or function() end
    concommand.Remove = concommand.Remove or function() end
    concommand.GetTable = concommand.GetTable or function() return {} end
    RunConsoleCommand = RunConsoleCommand or function() end

    ents = ents or {
        Create = function() return {} end,
        FindByClass = function() return {} end,
        FindInBox = function() return {} end,
        FindInSphere = function() return {} end
    }
    weapons = weapons or {
        Get = function() return {} end,
        GetStored = function() return {} end,
        Register = function() end
    }
    sound = sound or {
        Add = function() end,
        Play = function() end
    }
    physenv = physenv or {
        SetGravity = function() end,
        GetGravity = function() return Vector(0,0,-600) end
    }
    navmesh = navmesh or {}

    FCVAR_ARCHIVE = FCVAR_ARCHIVE or 0
    local function makeConVar(defaultVal)
        local val = defaultVal or "0"
        return {
            GetInt = function() return tonumber(val) or 0 end,
            GetFloat = function() return tonumber(val) or 0.0 end,
            GetString = function() return tostring(val) end,
            GetBool = function() return (tonumber(val) or 0) ~= 0 or val == "1" or val == "true" end,
            SetBool = function(self, b) val = b and "1" or "0" end,
            SetString = function(self, s) val = tostring(s) end,
            SetInt = function(self, i) val = tostring(i) end
        }
    end

    CreateConVar = CreateConVar or function(name, default)
        return makeConVar(default)
    end
    GetConVar = GetConVar or function(name)
        return makeConVar("1")
    end

    CurTime = CurTime or function() return mockTime end
    SysTime = SysTime or function() return mockTime end

    os = os or {}
    os.time = os.time or function() return 1700000000 end

    IsValid = IsValid or function(v) return v ~= nil and type(v) == "table" and v._isValid == true end
    isentity = isentity or function(v) return type(v) == "table" and v._isEntity == true end
    isfunction = isfunction or function(v) return type(v) == "function" end
    istable = istable or function(v) return type(v) == "table" end
    isstring = isstring or function(v) return type(v) == "string" end
    isnumber = isnumber or function(v) return type(v) == "number" end

    math.Clamp = math.Clamp or function(v, min, max) return math.max(min, math.min(max, v)) end
    string.Trim = string.Trim or function(v) return string.match(v, "^%s*(.-)%s*$") end

    table.Count = table.Count or function(t)
        local count = 0
        for _ in pairs(t or {}) do count = count + 1 end
        return count
    end
    table.Copy = table.Copy or function(v)
        if type(v) ~= "table" then return v end
        local copy = {}
        for k, item in pairs(v) do copy[k] = table.Copy(item) end
        return copy
    end

    team = team or {SetUp = function() end}
    player = player or {GetAll = function() return {} end}
    timer = timer or {
        Simple = function(delay, cb) if cb then cb() end end,
        Create = function() end,
        Remove = function() end,
        Exists = function() return false end
    }
    game = game or {GetMap = function() return "gm_flatgrass" end}
    resource = resource or {AddFile = function() end, AddWorkshop = function() end}
    scripted_ents = scripted_ents or {Register = function() end, Get = function() return {} end, GetStored = function() return {} end}
    ErrorNoHalt = ErrorNoHalt or function() end

    file = file or {
        Exists = function(path, pathID) return false end,
        Read = function(path, pathID) return nil end,
        Write = function(path, content) end,
        CreateDir = function(dir) end
    }

    AddCSLuaFile = AddCSLuaFile or function() end

    local loadedIncludes = {}
    include = include or function(path)
        local normPath = path:lower()
        if loadedIncludes[normPath] then return end
        loadedIncludes[normPath] = true

        local fullPath = "gamemodes/legend_of_deborah/gamemode/" .. path
        local f = io.open(fullPath, "rb")
        if not f then
            fullPath = "gamemodes/legend_of_deborah/gamemode/lod/" .. path
            f = io.open(fullPath, "rb")
        end
        if not f then error("Cannot open include file: " .. path) end
        local code = f:read("*a")
        f:close()
        local fn, err = load(code, path)
        if not fn then error("Load error in " .. path .. ": " .. tostring(err)) end
        fn()
    end
end

mockGMod()

-- Load standard gamemode init chain
dofile("gamemodes/legend_of_deborah/gamemode/init.lua")

local Effects = assert(LOD.RPG and LOD.RPG.FeatEffectSystem, "FeatEffectSystem must exist")

if isfunction(Effects.InstallAR2RateOfFireAuthorityWrappers) then
    Effects.InstallAR2RateOfFireAuthorityWrappers()
end

if isfunction(Effects.InstallMagnumBurstSizeBridge) then
    Effects.InstallMagnumBurstSizeBridge()
end

print("=== CHECKPOINT G PROTECTED REGRESSION HARNESS (AG-010R1) ===")

local failures = 0

local function runValidator(name, fn)
    if not fn then
        print("[FAIL] " .. name .. " (validator unavailable)")
        failures = failures + 1
        return
    end
    local ok, errs = fn(Effects)
    if ok then
        print("[PASS] " .. name)
    else
        print("[FAIL] " .. name .. " (" .. tostring(errs and table.concat(errs, "; ") or "error") .. ")")
        failures = failures + 1
    end
end

runValidator("Dice / Exploding Dice", Effects.ValidateExplodingDice)
runValidator("Reload Cadence", Effects.ValidateReloadCadence)
runValidator("Rate of Fire", Effects.ValidateRateOfFireCadence)
runValidator("Authored Burst Size", Effects.ValidateBurstSizeFamily)
runValidator("SMG Heat", Effects.ValidateSMGHeatFamily)
runValidator("Tetris / Russian Asset", Effects.ValidateSingletonFamilies)

if LOD.RPGValidation and LOD.RPGValidation.Run then
    local ok, errs = LOD.RPGValidation:Run(false)
    if ok then
        print("[PASS] Overall RPG Subsystem Validation")
    else
        print("[FAIL] Overall RPG Subsystem Validation (" .. tostring(errs and table.concat(errs, "; ") or "error") .. ")")
        failures = failures + 1
    end
end

if failures > 0 then
    error(string.format("Checkpoint G protected regressions FAILED with %d failure(s)", failures))
else
    print("CHECKPOINT_G_PROTECTED_REGRESSIONS_PASS — All 6 mandatory protected regression families verified cleanly.")
end
