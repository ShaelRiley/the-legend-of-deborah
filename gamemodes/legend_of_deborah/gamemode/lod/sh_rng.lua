LOD = LOD or {}
LOD.RNG = LOD.RNG or {}
LOD.Seeds = LOD.Seeds or {}

local MOD = 2147483647
local MUL = 16807

local RNG = {}
RNG.__index = RNG

local function normalize(seed)
    seed = math.floor(math.abs(tonumber(seed) or 1))
    seed = seed % (MOD - 1)
    if seed < 1 then seed = 1 end
    return seed
end

local function hashLabel(seed, label)
    local h = normalize(seed)
    label = tostring(label or "")
    for i = 1, #label do
        h = (h * 131 + string.byte(label, i)) % MOD
        if h == 0 then h = 1 end
    end
    return h
end

function LOD.RNG.New(seed)
    return setmetatable({state = normalize(seed)}, RNG)
end

function RNG:NextRaw()
    self.state = (self.state * MUL) % MOD
    return self.state
end

function RNG:Float(minimum, maximum)
    minimum = minimum or 0
    maximum = maximum or 1
    local unit = (self:NextRaw() - 1) / (MOD - 1)
    return minimum + (maximum - minimum) * unit
end

function RNG:Int(minimum, maximum)
    if maximum < minimum then minimum, maximum = maximum, minimum end
    local span = maximum - minimum + 1
    return minimum + math.floor(self:Float(0, 1) * span)
end

function RNG:Chance(probability)
    return self:Float() < probability
end

function RNG:Pick(list)
    if not list or #list == 0 then return nil end
    return list[self:Int(1, #list)]
end

function RNG:Shuffle(list)
    for i = #list, 2, -1 do
        local j = self:Int(1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

function RNG:Derive(label)
    return LOD.RNG.New(hashLabel(self.state, label))
end

function LOD.Seeds.Normalize(seed)
    return normalize(seed)
end

function LOD.Seeds.Derive(seed, label)
    return hashLabel(seed, label)
end

function LOD.Seeds.DeriveLevel(campaignSeed, level)
    return hashLabel(campaignSeed, "level:" .. tostring(level))
end
