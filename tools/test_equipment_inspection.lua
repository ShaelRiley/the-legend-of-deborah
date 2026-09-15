-- Real server/client comparison transport with bounded Source/net doubles.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_rng.lua');dofile(root..'sh_equipment.lua');dofile(root..'sh_equipment_catalog.lua')
dofile(root..'sh_equipment_economy.lua')
local E=LOD.Equipment
local now=10
CurTime=function() return now end
IsValid=function(x) return type(x)=='table' and x.valid==true end
LOD.RunManager={State={LevelSeed=4},IdentityOf=function(_,p) return p.identity end}
LOD.UI={Colors={}}
local hooks={}
hook={Add=function(_,id,fn) hooks[id]=fn end}
Color=function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
util={AddNetworkString=function() end}
local handlers,sends,requests={},0,0
local readEntity,readItem,sentEntity,sentItem,recipient
net={Receive=function(name,fn) handlers[name]=fn end,Start=function() end,
    ReadEntity=function() return readEntity end,ReadTable=function() return readItem end,
    WriteEntity=function(v) sentEntity=v end,WriteTable=function(v) sentItem=v end,
    Send=function(p) sends=sends+1;recipient=p end,SendToServer=function() requests=requests+1 end}
local distance=0
local pos={DistToSqr=function() return distance end}
local owner={valid=true,identity='owner',GetPos=function() return pos end}
E.CanAct=function(_,p) return p==owner and not p.disabled end
local function pickup(item)
    return {valid=true,GetClass=function() return 'lod_loot_pickup' end,GetPos=function() return pos end,
        LODLootPayload={item=item},LODLootOwnerIdentity='owner',LODLootLevelSeed=4,
        SetNW2String=function() error('Full items must never use NW2 strings') end}
end
dofile(root..'sv_equipment_wearables.lua')
local server=handlers.LOD_EquipmentInspect
local item=E:Generate(9,999,'weapon_357',string.rep('context',20))
local ent=pickup(item);E:SyncPickup(ent);readEntity=ent
assert(ent.LODItemViewReady)
server(16,owner)
assert(sends==1 and recipient==owner and sentEntity==ent and sentItem==item)
server(16,owner);assert(sends==1,'Requests are throttled')
now=11;server(17,owner);assert(sends==1,'Oversized request rejected')
assert(not E:SendPickupView({valid=true,identity='other'},ent))
ent.LODLootOwnerIdentity='other';assert(not E:SendPickupView(owner,ent));ent.LODLootOwnerIdentity='owner'
distance=129^2;assert(not E:SendPickupView(owner,ent));distance=0
ent.LODLootLevelSeed=3;assert(not E:SendPickupView(owner,ent));ent.LODLootLevelSeed=4
ent.LODCollected=true;assert(not E:SendPickupView(owner,ent));ent.LODCollected=nil
ent.LODLootExpiresAt=10;assert(not E:SendPickupView(owner,ent));ent.LODLootExpiresAt=nil
owner.disabled=true;assert(not E:SendPickupView(owner,ent));owner.disabled=nil
assert(sends==1,'Invalid queries never disclose items')
dofile(root..'cl_equipment.lua')
local client=handlers.LOD_EquipmentInspect
assert(not E:PickupView(ent) and requests==1)
E:PickupView(ent);assert(requests==1)
now=12;E:PickupView(ent);assert(requests==2,'Retry after unavailable response')
readEntity,readItem=ent,sentItem;client()
assert(E:PickupView(ent)==item and requests==2,'Full authoritative record cached without a reroll')
-- Recycled indices/new PVS entity objects cannot inherit a previous view.
local nextEnt=pickup(item);now=13
assert(not E:PickupView(nextEnt) and requests==3)
readEntity,readItem=nextEnt,{version=2};client();assert(not nextEnt.LODItemView)
readItem=item;client();assert(E:PickupView(nextEnt).name==item.name)
-- An object no longer valid at delivery cannot acquire a cached record.
nextEnt.valid=false;nextEnt.LODItemView=nil;client();assert(not nextEnt.LODItemView)
print('EQUIPMENT_INSPECTION_PASS: full records; owner/range/lifecycle/size/rate guards; retry/cache/recycled entity safety')

-- Actual HUD hook: stationary inspection formats once instead of once per frame.
local measures,descriptions,draws=0,0,{}
local screenWidth=1024
ScrW=function() return screenWidth end;ScrH=function() return 768 end
surface={SetFont=function() end,GetTextSize=function(text) measures=measures+1;return #text*6,12 end}
draw={RoundedBox=function() end,SimpleText=function(text) draws[#draws+1]=text end}
owner.Alive=function() return true end
owner.GetEyeTrace=function() return {Entity=ent} end
LocalPlayer=function() return owner end
local describe=E.Description
function E:Description(...) descriptions=descriptions+1;return describe(self,...) end
local hud=hooks.LOD_EquipmentComparison
hud();local firstMeasures,firstDescriptions=measures,descriptions
local firstLines=table.concat(draws,'\n')
assert(firstMeasures>0 and firstDescriptions>0)
for _=1,600 do draws={};hud();assert(table.concat(draws,'\n')==firstLines) end
assert(measures==firstMeasures and descriptions==firstDescriptions,'No text allocations/measurements on cache hits')
local function rebuild(change)
    local before=measures;change();hud();assert(measures>before,'Changed comparison must rebuild')
end
rebuild(function() screenWidth=640 end)
-- Receiver replaces snapshot; a new equipped ring changes the comparison text.
LOD.Spellbook={};istable=function(x) return type(x)=='table' end
local ring=E:Generate(12,20,'ring','owned')
readItem={items={[ring.id]=ring},slots={left_hand=ring.id}}
rebuild(function() handlers.LOD_EquipmentSnapshot() end)
rebuild(function() ent.LODItemView=E:Generate(42,5,'boots','new-view') end)
rebuild(function() ent=pickup(item);ent.LODItemView=item end)
rebuild(function() hooks.LOD_EquipmentComparisonCleanup() end)
distance=129^2;draws={};hud();assert(#draws==0);distance=0
rebuild(function() end)
LOD.UI.ActivePage='book';draws={};hud();assert(#draws==0);LOD.UI.ActivePage=nil
rebuild(function() end)
print('EQUIPMENT_HUD_CACHE_PASS: 601 identical frames, one layout; snapshot/item/entity/width/cleanup invalidation; range/UI guards')
