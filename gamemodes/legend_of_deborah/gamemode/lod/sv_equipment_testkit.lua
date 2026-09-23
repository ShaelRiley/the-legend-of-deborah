-- One finite, unranked runtime setup. Normal loot remains independently seeded.
local E,Run=LOD.Equipment,LOD.RunManager
local function allowed(ply)
    local cv=GetConVar("lod_developer_mode")
    return cv and cv:GetBool() and IsValid(ply) and ply:IsAdmin() and E:CanAct(ply)
end
local function withProperty(family,property,start)
    for seed=start,start+999 do
        local item=E:Generate(seed,100,family)
        for _,record in ipairs(item.properties) do if record.id==property and record.amount>0 then return item end end
    end
end
local function catalogTestkit(ply)
    if not allowed(ply) then return end
    Run:MarkUnranked("equipment_catalog_testkit")
    E:ClearTransient(ply)
    local ps=Run:GetPlayerState(ply)
    local state=E:Ensure(ps)
    for _,record in ipairs({{"boots","move_quickstep",10001,"feet"},{"ring","move_rebuff",20001,"left_hand"},
        {"ring","ability_str",21001,"right_hand"},{"shield","block",30001,"left_arm"}}) do
        local item=assert(withProperty(record[1],record[2],record[3]))
        if not state.items[item.id] then E:AcquireWearable(state,item,true,record[4]) end
        E:Equip(state,item.id,record[4])
    end
    for _,id in ipairs({"healing_potion","stink_bomb"}) do
        local count=state.items[id] and state.items[id].count or 0
        if count<3 then E:AddConsumable(state,id,3-count) end
    end
    local item=E:Generate(40001,100,"gloves")
    local trace=util.TraceLine({start=ply:GetShootPos(),endpos=ply:GetShootPos()+ply:GetAimVector()*90,filter=ply})
    LOD.LootDirector:SpawnPickup(Run:IdentityOf(ply),trace.HitPos,"wearable",{item=item},{})
    ps.magic=100;LOD.Magic:_Sync(ply,ps)
    ply:SetHealth(math.max(1,math.floor(ply:GetMaxHealth()/2)))
    E:Deactivate(ply);E:Sync(ply)
    E:Report(ply,"EQUIPMENT TEST — Quickstep ↑↑↑; Rebuff ←↓→; shield; both consumable stacks. Compare the gloves with E; I opens equipment.","equipment_catalog_testkit")
    print("[LOD:EQUIPMENT] catalog testkit: owner="..tostring(Run:IdentityOf(ply)).." unranked=true; generated D100 gear, actual dungeon unchanged")
end
concommand.Add("lod_equipment_catalog_testkit",catalogTestkit)
concommand.Add("lod_equipment_catalog_status",function(ply)
    if not allowed(ply) then return end
    local ps=Run:GetPlayerState(ply)
    local abilities,moves,block=E:Contributions(ps.equipment)
    local slots={}
    for _,slot in ipairs(E.SlotOrder) do
        local item=E:Equipped(ps.equipment,slot)
        slots[#slots+1]=slot.."="..(item and E:ItemName(item) or "empty")
    end
    local line=string.format("[LOD:EQUIPMENT] block=%.0f%% quickstep=%s rebuff=%s STR=%+d DEX=%+d CON=%+d INT=%+d WIS=%+d CHA=%+d magic=%.1f | %s",
        block*100,tostring(moves.quickstep==true),tostring(moves.rebuff==true),abilities.str,abilities.dex,abilities.con,
        abilities.int,abilities.wis,abilities.cha,ps.magic or 0,table.concat(slots,"; "))
    print(line);ply:ChatPrint(line)
end)

concommand.Add("lod_equipment_economy_testkit",function(ply)
    if not allowed(ply) then return end
    catalogTestkit(ply)
    for i,class in ipairs(E.WeaponFamilies) do
        local item=E:Generate(60000+i,100,class,"testkit:"..tostring(Run.State.RunId)..":"..class)
        if not E:Equipped(Run:GetPlayerState(ply).equipment,class)
            or E:Equipped(Run:GetPlayerState(ply).equipment,class).id~=item.id then
            assert(E:AcquireWorldItem(ply,item,true),"Could not grant equipment test weapon")
        end
    end
    for i,depth in ipairs({1,25,100}) do
        local item=E:Generate(71000+i,depth,"weapon_357","comparison:"..depth..":"..tostring(Run.State.RunId))
        local offset=ply:GetAimVector()*100+ply:EyeAngles():Right()*((i-2)*45)
        local trace=util.TraceLine({start=ply:GetShootPos(),endpos=ply:GetShootPos()+offset,filter=ply})
        LOD.LootDirector:SpawnPickup(Run:IdentityOf(ply),trace.HitPos,"wearable",{item=item},{})
    end
    ply:SelectWeapon("weapon_357");E:Sync(ply)
    E:Report(ply,"PROCEDURAL ECONOMY TEST — all six weapons; D1/D25/D100 revolver comparisons nearby. Fire, switch weapons, compare with E, then inspect I.","equipment_economy_testkit")
end)
concommand.Add("lod_equipment_economy_status",function(ply)
    if not allowed(ply) then return end
    E:Sync(ply)
    local state=Run:GetPlayerState(ply).equipment
    print("[LOD:EQUIPMENT-ECONOMY] active="..tostring(state.activeWeaponClass).." version="..E.EconomyVersion)
    local seen={}
    for _,slot in ipairs(E.SlotOrder) do
        local item=E:Equipped(state,slot)
        if item and not seen[item.id] then
            seen[item.id]=true
            print("[LOD:EQUIPMENT-ITEM] "..slot.." | "..E:ItemName(item).." | value="..E:Value(item).." | "..E:Description(item))
        end
    end
end)

concommand.Add("lod_fighting_streets_testkit",function(ply)
    if not allowed(ply) then return end
    Run:MarkUnranked("fighting_streets_testkit")
    E:ClearTransient(ply)
    local ps=Run:GetPlayerState(ply)
    local state=E:Ensure(ps)
    local item
    for _,owned in pairs(state.items) do
        if owned.definitionId=="fighting_gloves" then item=owned;break end
    end
    if not item then
        item=E:NewItem(ply,"fighting_gloves","fighting-streets-testkit")
        if not E:AcquireWearable(state,item,true) then
            E:Report(ply,"Make one inventory space for the technique gloves.","special_move_rejected");return
        end
    end
    E:Equip(state,item.id,"left_hand")
    E:Deactivate(ply);E:RefreshDerived(ply,ps);E:Sync(ply)
    ps.magic=100;LOD.Magic:_Sync(ply,ps)
    E:Report(ply,"FIGHTING STREETS TEST — Ember Fist ← ↓ →; Cinder Rise → ↓ →. Both hands equipped; 100 Magic; run unranked.","fighting_streets_testkit")
end)
