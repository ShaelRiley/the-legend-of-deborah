-- Exercise the loaded client authority at the native killicon boundary. Source
-- AddAlias copies a registered entry; missing GetSize/Draw inserts default and
-- warns. This gate catches first-death registration without suppressing errors.
local registry={default={width=32,height=32},crossbow_bolt={width=24,height=12},
    weapon_pistol={width=18,height=12}}
local warnings={}
killicon={
    AddAlias=function(name,alias) registry[name]=registry[alias] end,
    Exists=function(name) return registry[name]~=nil end,
    GetSize=function(name)
        if not registry[name] then
            warnings[#warnings+1]="Warning: killicon not found '"..name.."'"
            registry[name]=registry.default
        end
        local t=registry[name];return t.width,t.height
    end}
local getSize=killicon.GetSize
killicon.Draw=function(_,_,name) return getSize(name) end
local draw=killicon.Draw
LOD={}
scripted_ents={GetStored=function() end}
hook={Add=function() end}
concommand={Add=function() end}
local source=arg and arg[1] or 'gamemodes/legend_of_deborah/gamemode/lod/cl_hostile_presentation_safety.lua'
dofile(source)
assert(killicon.Exists('lod_soldier_bolt') and killicon.Exists('lod_hostile'),
    'Known hostile inflictors must have registered kill icons before the first death')
local w,h=killicon.GetSize('lod_soldier_bolt')
assert(w==24 and h==12,'Soldier projectile should use existing stock bolt icon')
w,h=killicon.Draw(0,0,'lod_hostile');assert(w==32 and h==32)
assert(#warnings==0,'Known native deaths must not trigger a missing-icon warning')
assert(registry.lod_soldier_bolt==registry.crossbow_bolt and registry.lod_hostile==registry.default)
assert(registry.weapon_pistol.width==18 and killicon.GetSize==getSize and killicon.Draw==draw,
    'Do not replace stock icon lookup/rendering or change unrelated icons')
dofile(source)
killicon.GetSize('lod_soldier_bolt');killicon.Draw(0,0,'lod_hostile')
assert(#warnings==0,'Reload preserves known icon registrations')
assert(not killicon.Exists('unknown_test_inflictor'))
killicon.Draw(0,0,'unknown_test_inflictor')
assert(#warnings==1 and warnings[1]:find('unknown_test_inflictor',1,true),
    'Unknown-class warnings must remain observable')
local function read(path) local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
assert(read('gamemodes/legend_of_deborah/gamemode/cl_init.lua'):find('include("lod/cl_hostile_presentation_safety.lua")',1,true))
assert(read('gamemodes/legend_of_deborah/gamemode/init.lua'):find('AddCSLuaFile("lod/cl_hostile_presentation_safety.lua")',1,true))
print('HOSTILE_KILL_ICONS_PASS: stock bolt/generic icons before first death and reload; unchanged stock functions/foreign icons; unknown-class warning retained; existing client distribution')
