-- Export the final production catalog after the existing closure harness loads it.
dofile("tools/test_checkpoint_d_closure.lua")
local function json(v)
    if type(v)=="string" then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
    if type(v)=="number" or type(v)=="boolean" then return tostring(v) end
    if type(v)~="table" then return "null" end
    local keys, out={},{}
    for k,value in pairs(v) do if type(value)~="function" then keys[#keys+1]=k end end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    for _,k in ipairs(keys) do out[#out+1]=json(tostring(k))..":"..json(v[k]) end
    return "{"..table.concat(out,",").."}"
end
local catalog=LOD.RPG.IdentityCatalog
local out={OrdinaryFeats=catalog.OrdinaryFeats,ClassCapstones=catalog.ClassCapstones,
    FallbackFeats=catalog.FallbackFeats,EquipmentProperties=LOD.Equipment.EconomyProperties}
local encoded=json(out)
if arg and arg[1]=="--check" then
    local f=assert(io.open("docs/manual/catalog.json","r"))
    local saved=f:read("*a");f:close()
    assert(saved==encoded,"Manual catalog is stale; run tools/export_manual_catalog.lua and tools/build_manual.py")
    print("PASS: manual reference matches the final production catalog")
else
    local f=assert(io.open("docs/manual/catalog.json","w"))
    f:write(encoded); f:close()
end
