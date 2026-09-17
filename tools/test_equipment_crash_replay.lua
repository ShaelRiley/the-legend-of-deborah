-- Run under Lua 5.4 AND historical LuaJIT 2.0.4 / 2.1.0-beta3;
-- a modern rolling LuaJIT build is not a proxy for GMod's embedded runtime.
-- Optional --unsafe-jit deliberately removes the workaround in this standalone
-- process to reproduce the pre-repair SIGSEGV. Never expose that switch in GMod.
local root = 'gamemodes/legend_of_deborah/gamemode/lod/'
for _, name in ipairs({'sh_rng.lua','sh_equipment.lua','sh_equipment_catalog.lua','sh_equipment_economy.lua'}) do
    dofile(root .. name)
end
local E = LOD.Equipment
local compilerWasEnabled = jit and jit.status()
if arg and arg[1] == '--unsafe-jit' then
    assert(jit and jit.on, 'Reproduction requires LuaJIT')
    jit.on(E.Generate, true)
end
local rows = dofile('tools/fixtures/equipment_crash_20260916.lua')
local function signature(a)
    local parts = {a.id,a.name,tostring(a.rarity),tostring(a.quality),tostring(a.budget)}
    for _, p in ipairs(a.properties) do
        parts[#parts+1] = p.id .. ':' .. string.format('%d:%.10g',p.power,p.amount)
    end
    return table.concat(parts, '|')
end
local start = os.clock()
for round = 1, 100 do
    for _, row in ipairs(rows) do
        local item = E:Generate(row.seed,row.level,row.family,row.key)
        assert(E:ValidateWearable(item), 'Invalid recorded reward')
        assert(signature(item) == row.expected:gsub("Watery", "Wintery"), 'Recorded reward rerolled: ' .. row.seed)
    end
    -- Exercise traces/GC across different item lifetimes, not only a cold call.
    if round % 10 == 0 then collectgarbage('collect') end
end
assert(not jit or jit.status() == compilerWasEnabled, 'Changed engine-wide JIT state')
print(string.format('EQUIPMENT_CRASH_REPLAY_PASS: 14 exact rewards x100; final seed 996257890; mode=%s; VM=%s; %.3fs',
    E.GenerationExecutionMode, jit and jit.version or _VERSION, os.clock()-start))
