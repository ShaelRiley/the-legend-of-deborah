-- Version labels are not evidence that GMod's embedded compiler is safe.
-- Check the actual module-load boundary, including unknown/future labels.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local nativeJit=jit
local enabled=nativeJit and nativeJit.status()
local corpus=dofile('tools/fixtures/equipment_crash_20260916.lua')
local function signature(item)
    local out={item.id,item.name,tostring(item.rarity),tostring(item.quality),tostring(item.budget)}
    for _,p in ipairs(item.properties) do out[#out+1]=p.id..':'..string.format('%d:%.10g',p.power,p.amount) end
    return table.concat(out,'|')
end
local cases={
    {label='2.0.4',version_num=20004},
    {label='2.1.0-beta3',version_num=20100},
    {label='future',version_num=29999},
    {label='string',version_num='20100'},
    {label='unknown'},
    {label='no compiler',unavailable=true},
    {label='no jit library',absent=true}
}
for _,realm in ipairs({'server','client'}) do
    SERVER,CLIENT=realm=='server',realm=='client'
    for _,case in ipairs(cases) do
        LOD={}
        local calls={}
        jit=not case.absent and {version_num=case.version_num} or nil
        if jit and not case.unavailable then
            jit.off=function(fn,recursive,...)
                assert(type(fn)=='function' and recursive==true and select('#',...)==0,
                    'Must disable only the generator and its closures, never the global compiler')
                calls[#calls+1]=fn
                if nativeJit then nativeJit.off(fn,recursive) end
            end
        end
        for _,name in ipairs({'sh_rng.lua','sh_equipment.lua','sh_equipment_catalog.lua','sh_equipment_economy.lua'}) do
            dofile(root..name)
        end
        local E=LOD.Equipment
        local guarded=not case.absent and not case.unavailable
        assert(#calls==(guarded and 1 or 0),'Guard skipped VM '..case.label)
        if guarded then
            assert(calls[1]==E.Generate and E.GenerationExecutionMode=='interpreter-generator')
        else
            assert(E.GenerationExecutionMode=='default')
            -- The simulated no-compiler cases still run safely on a native test VM.
            if nativeJit then nativeJit.off(E.Generate,true) end
        end
        assert(LOD.RuntimeReceipts.equipment_generator=='generator-jit-20260917-01')
        for _,row in ipairs(corpus) do
            local item=E:Generate(row.seed,row.level,row.family,row.key)
            assert(E:ValidateWearable(item))
            assert(signature(item)==row.expected:gsub('Watery','Wintery'),'Guard rerolled '..case.label)
        end
        assert(#calls==(guarded and 1 or 0),'Compiler mode toggled per reward')
    end
end
jit=nativeJit
assert(not jit or jit.status()==enabled,'Engine-wide compiler state changed')
print('EQUIPMENT_JIT_GUARD_PASS: both realms, seven VM capability cases, exact recorded items, function-only load-time guard')
