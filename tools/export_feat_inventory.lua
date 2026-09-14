-- Export the final production include graph, not a second model of the registry.
dofile('tools/test_checkpoint_d_closure.lua')
local function json(value)
    if type(value) == 'string' then
        return '"' .. value:gsub('[%z\1-\31\\"]', function(c)
            return string.format('\\u%04x', string.byte(c))
        end) .. '"'
    end
    if type(value) == 'number' or type(value) == 'boolean' then return tostring(value) end
    if type(value) ~= 'table' then return 'null' end
    local entries = {}
    for key, item in pairs(value) do
        if type(item) ~= 'function' then entries[#entries + 1] = json(tostring(key)) .. ':' .. json(item) end
    end
    return '{' .. table.concat(entries, ',') .. '}'
end
local catalog = LOD.RPG.IdentityCatalog
print('FEAT_INVENTORY_JSON=' .. json({ordinary=catalog.OrdinaryFeats,
    fallback=catalog.FallbackFeats,capstones=catalog.ClassCapstones}))
