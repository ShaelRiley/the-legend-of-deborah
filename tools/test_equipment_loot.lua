SERVER,CLIENT=true,false
function CurTime() return 10 end
function IsValid(a) return type(a)=='table' and a.valid~=false end
function math.Clamp(v,a,b) return math.max(a,math.min(b,v)) end
function Color(...) return {...} end
function Vector(...) return {...} end
function table.Copy(x) if type(x)~='table' then return x end local out={};for k,v in pairs(x) do out[k]=table.Copy(v) end;return out end
local hooks={}
hook={Add=function(e,id,f) hooks[e..id]=f end}
timer={Simple=function() end,Create=function() end}
concommand={Add=function() end}
util={AddNetworkString=function() end}
net={Receive=function() end,Start=function() end,WriteTable=function() end,Send=function() end}
scripted_ents={GetStored=function() return nil end}
local Run={State={LevelSeed=7,Level=51},ApplyPlayerState=function() end}
local owner={id='owner',ps={magic=100}}
local stranger={id='stranger',ps={magic=100}}
for _,p in ipairs({owner,stranger}) do
    function p:IsPlayer() return true end
    function p:Alive() return true end
    function p:EmitSound() end
    function p:ChatPrint() end
end
function Run:GetPlayerState(p) return p.ps end
function Run:IdentityOf(p) return p.id end
function Run:IsActivePlayer() return true end
function Run:IsSoldierControl(p) return p.soldier end
LOD={RunManager=Run,MazeBuilder={},RPGPresentation={Event=function() end}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_rng.lua');dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
LOD.Audio=dofile('tools/audio_test_double.lua')
dofile(root..'sv_loot_director.lua');dofile(root..'sv_equipment.lua');dofile(root..'sv_equipment_wearables.lua')
local E,Loot=LOD.Equipment,LOD.LootDirector
E.Sync=function() end -- snapshots are transport; collection path below is production
local function pickup(seed,family,id)
    local item=E:Generate(seed,51,family)
    return {LODLootOwnerIdentity='owner',LODLootLevelSeed=7,LODLootKind='wearable',
        LODLootStaticId=id,LODLootPayload={item=item}},item
end
local ent,item=pickup(1,'ring','static-one')
assert(not Loot:Collect(ent,stranger,true),'Cannot steal owner pickup')
assert(Loot:Collect(ent,owner,false),'Free slot auto-equips')
assert(owner.ps.equipment.items[item.id] and ent.LODCollected)
assert(not Loot:Collect(ent,owner,true),'Consumed entity cannot duplicate')
local second,ring=pickup(2,'ring','static-two');assert(Loot:Collect(second,owner,false))
local gloves,paired=pickup(3,'gloves','static-three')
assert(not Loot:Collect(gloves,owner,false),'Touch cannot replace occupied items')
assert(not gloves.LODCollected and not gloves.LODCollecting)
owner.soldier=true;assert(not Loot:Collect(gloves,owner,true));owner.soldier=false
assert(Loot:Collect(gloves,owner,true),'One native Use acceptance commits whole swap')
assert(owner.ps.equipment.items[item.id] and owner.ps.equipment.items[ring.id])
assert(owner.ps.equipment.slots.left_hand==paired.id and owner.ps.equipment.slots.right_hand==paired.id)
local replay=pickup(3,'gloves','static-three');assert(not Loot:Collect(replay,owner,true),'Consumed static identity cannot respawn')
local late=pickup(4,'boots','static-four');Run.State.LevelSeed=8
assert(not Loot:Collect(late,owner,true),'Old dungeon entity cannot grant')
print('EQUIPMENT_LOOT_PASS: real Collect ownership, automatic free-slot grant, native Use acceptance, atomic glove swap, replay/static identity and dungeon rejection')
