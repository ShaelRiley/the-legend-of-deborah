-- Authored mechanical packages over the existing version-2 equipment authority.
-- A package is not a new slot, weapon entity, affix tier or random permutation.
local E=assert(LOD.Equipment)
E.BigLootBaseline=45
E.Archetypes,E.ArchetypeOrder={},{}
local function words(value)
    local out={};for word in value:gmatch("[^,]+") do out[#out+1]=word end;return out
end
local familyMotifs={
    scavenger={"scavenged","industrial"},soldier={"military","defensive"},
    medic={"medical","expedition"},occultist={"occult","elemental"},
    dockworker={"industrial","scavenged"},courier={"mobility","expedition"},
    warden={"military","occult"},veteran={"expedition","defensive"},
    anomaly={"unstable","elemental"},survivor={"scavenged","medical"},
    hunter={"military","expedition"},pilgrim={"occult","expedition"}
}
local function add(base,id,name,family,element,signature,drawback,description,rarity,level)
    local def=assert(E.Definitions[base]);assert(not E.Archetypes[id],"Duplicate archetype "..id)
    rarity=rarity or 1
    local row={id=id,name=name,base=base,slot=def.slots[1],family=family,element=element,
        signature=words(signature),drawback=drawback,description=description,
        minimumRarity=rarity,minLevel=level or (base=="weapon_ar2" and 3 or base=="weapon_357" and 2 or 1),
        weight=({80,35,9})[rarity],motifs=assert(familyMotifs[family]),tags={}}
    local tagged={}
    local function tag(value) if not tagged[value] then tagged[value]=true;row.tags[#row.tags+1]=value end end
    tag(family);tag(element)
    for _,motif in ipairs(row.motifs) do tag(motif) end
    for _,pid in ipairs(row.signature) do
        local p=assert(E.EconomyProperties[pid],"Unknown signature "..pid)
        if p.rider then tag("status");tag(p.rider) end
        if p.ward then tag("defensive");tag("elemental") end
        if p.save or pid=="defense" or pid=="block" or pid=="dodge" then tag("defensive") end
        if pid=="movement" or pid=="move_quickstep" or pid=="push_resist" then tag("mobility") end
        if pid:find("regen",1,true) then tag("recovery") end
        if pid:find("summon",1,true) then tag("summon") end
        if pid=="map_efficiency" or pid=="breadcrumb" then tag("exploration") end
        if pid=="physical" or pid=="injured" or pid=="still" then tag("physical") end
        if pid=="magic" or pid=="charged" then tag("arcane") end
    end
    E.Archetypes[id]=row;E.ArchetypeOrder[#E.ArchetypeOrder+1]=id
end

-- Headwear: reconnaissance, resource posture and specialized protection.
add("headwear","surveyors_lantern","Surveyor's Lantern","scavenger","electric","breadcrumb,map_efficiency","defense","Follow a longer remembered route with cheaper map use; the open frame sacrifices physical protection.")
add("headwear","triage_visor","Triage Visor","medic","light","regen_ceiling,save_con","physical","Recover between engagements and resist bodily conditions; its medical focus blunts physical attacks.")
add("headwear","capacitor_cowl","Capacitor Cowl","occultist","electric","charged,magic_regen","movement","Bank Magic for empowered casts and replenish it faster; the capacitor slows repositioning.")
add("headwear","hush_hood","Hush Hood","warden","dark","proc_muted,save_int","regen_rate","Silence targets while guarding your own condition saves; reduced recovery makes prolonged exchanges costly.")
add("headwear","quarry_helmet","Quarry Helmet","dockworker","earth","push_resist,ward_earth","save_dex","Hold position against force and Earth attacks; the rigid harness makes DEX saves worse.")
add("headwear","watchmans_lens","Watchman's Lens","hunter","ice","still,proc_clumsy","movement","Stop to shoot and destabilize the target; slower movement makes the firing position a commitment.")
add("headwear","dread_circlet","Dread Circlet","occultist","dark","proc_intimidated,ability_cha","defense","Pair intimidation attempts with CHA investment; its exposed construction increases physical danger.")
add("headwear","oathkeepers_mask","Oathkeeper's Mask","pilgrim","light","save_wis,ward_dark","magic_regen","Protect judgment and resist Dark damage at the cost of slower Magic recovery.")
add("headwear","cracked_crown","Cracked Crown","anomaly","fire","summon_cap,injured","save_wis","Command another summon while turning low health into physical offense; poor WIS saves punish reckless use.",2)
add("headwear","dispatch_goggles","Dispatch Goggles","courier","electric","ability_int,movement","push_resist","Trade anchoring for a quicker, INT-led scouting build.")

-- Body armor: trade safety, pressure, sustain and elemental commitments.
add("vest","infirmary_coat","Infirmary Coat","medic","light","regen_ceiling,regen_rate","movement","Raise the recovery ceiling and accelerate recovery; retreat must begin early because the coat slows movement.")
add("vest","ballast_vest","Ballast Vest","dockworker","earth","defense,push_resist","magic_regen","Hold a physical front line without being displaced; Magic replenishes more slowly.")
add("vest","glass_furnace","Glass Furnace","anomaly","fire","magic,charged","defense","Spend a well-filled Magic reserve on powerful spells while accepting greater physical damage.",2)
add("vest","last_rescuer_coat","Last Rescuer's Coat","survivor","light","injured,regen_ceiling","magic","Low health strengthens physical retaliation, then recovery narrows that window; spell damage pays the cost.")
add("vest","warden_insulation","Warden Insulation","warden","electric","ward_electric,save_con","movement","Resist Electric pressure and bodily conditions while surrendering chase speed.")
add("vest","scavengers_apron","Scavenger's Apron","scavenger","earth","ability_con,breadcrumb","save_cha","Survive longer detours and remember more of them; CHA saves become a liability.")
add("vest","duelists_webbing","Duelist's Webbing","veteran","ice","dodge,physical","push_resist","Combine evasion with physical pressure, but forced movement can break the duel.")
add("vest","cinder_sheath","Cinder Sheath","occultist","fire","ward_fire,proc_immolated","weak_ice","Press burning targets behind Fire resistance; Ice remains the deliberate counter.")
add("vest","mourning_mantle","Mourning Mantle","pilgrim","dark","summon_duration,ward_dark","regen_rate","Keep summons alive longer under Dark pressure; your own recovery is slower.")
add("vest","hunters_brigandine","Hunter's Brigandine","hunter","ice","still,defense","movement","Establish a protected stationary firing position at the expense of pursuit.")

-- Legwear: the positional half of a build.
add("trousers","couriers_wraps","Courier's Wraps","courier","electric","movement,save_dex","physical","Move and resist DEX conditions while sacrificing direct physical force.")
add("trousers","dockside_greaves","Dockside Greaves","dockworker","earth","push_resist,ability_str","save_int","Anchor a STR-led advance; mental conditions remain an exploitable weakness.")
add("trousers","escape_webbing","Escape Webbing","survivor","ice","dodge,breadcrumb","regen_rate","Evade while remembering escape routes; successful disengagement does not grant quick recovery.")
add("trousers","siege_trousers","Siege Trousers","soldier","earth","still,push_resist","magic","Refuse displacement while making stationary physical attacks; this stance trades away spell damage.")
add("trousers","hotwire_chaps","Hotwire Chaps","anomaly","electric","movement,charged","save_con","Carry a full Magic reserve into fast repositioning; bodily conditions can derail the plan.")
add("trousers","pilgrims_kilt","Pilgrim's Kilt","pilgrim","light","map_efficiency,save_wis","defense","Spend less on navigation and resist WIS conditions, but avoid trading physical hits.")
add("trousers","suture_leggings","Suture Leggings","medic","light","regen_rate,save_dex","magic_regen","Recover faster when another source permits regeneration and guard DEX saves; Magic recovery suffers.")
add("trousers","sapper_overalls","Sapper Overalls","scavenger","fire","ward_fire,push_out","save_cha","Shove threats away under Fire pressure; CHA conditions threaten the improvised harness.")
add("trousers","nightwatch_slacks","Nightwatch Slacks","warden","dark","proc_held,save_wis","movement","Pin opponents while guarding WIS saves; the wearer is slower too.")
add("trousers","bloodrun_breeches","Bloodrun Breeches","veteran","fire","injured,movement","regen_rate","Turn a wounded retreat into mobile physical retaliation; slower recovery prolongs both opportunity and danger.")

-- Footwear: movement choices without bypassing maze or native traversal laws.
add("boots","runner_relay","Runner Relay","courier","electric","move_quickstep,magic_regen","physical","Refill the Magic used by Quickstep; accepting weaker physical blows makes escape its primary role.")
add("boots","bulkhead_treads","Bulkhead Treads","dockworker","earth","move_quickstep,push_resist","movement","Dash out of trouble and resist displacement, but ordinary travel is deliberately slower.")
add("boots","smokejump_soles","Smokejump Soles","soldier","fire","move_quickstep,ward_fire","weak_ice","Use Quickstep through Fire-heavy fights; Ice punishes this specialized escape kit.")
add("boots","grave_stride","Grave Stride","occultist","dark","move_quickstep,summon_duration","regen_rate","Reposition while persistent summons hold pressure; personal recovery is slower.")
add("boots","measured_retreat","Measured Retreat","veteran","ice","move_quickstep,still","defense","Alternate committed stationary shots with a Quickstep exit; being caught costs extra physical damage.")
add("boots","scout_springs","Scout Springs","scavenger","electric","movement,breadcrumb","save_con","Explore and retain a longer route memory, but guard against bodily conditions.")
add("boots","icehook_boots","Icehook Boots","hunter","ice","ward_ice,push_resist","magic_regen","Hold terrain against Ice and displacement; Magic reserves take longer to replenish.")
add("boots","wounded_hare","Wounded Hare","survivor","light","move_quickstep,injured","save_wis","Dash into or away from low-health physical opportunities; weak WIS saves make overcommitment costly.")
add("boots","surge_sandals","Surge Sandals","anomaly","electric","movement,proc_push","defense","Chase and repel opponents at the cost of physical protection.")
add("boots","field_medic_steps","Field Medic Steps","medic","light","movement,regen_ceiling","magic","Reach safety and recover beyond your ordinary ceiling; spell damage is reduced.")

-- Rings compete with one another and with two-handed glove occupancy.
add("ring","riot_seal","Riot Seal","warden","earth","move_rebuff,proc_reckless","save_cha","Combine Rebuff with weapon Reckless attempts; your own CHA saves become vulnerable.")
add("ring","circuit_loop","Circuit Loop","occultist","electric","move_rebuff,magic_regen","defense","Replenish Rebuff's resource cost while accepting less physical protection.")
add("ring","field_triage_ring","Field Triage Ring","medic","light","move_rebuff,regen_ceiling","physical","Create space with Rebuff, then recover; sustained physical offense is weaker.")
add("ring","undertow_band","Undertow Band","anomaly","ice","move_rebuff,push_out","weak_fire","Build around stronger displacement through Rebuff and ordinary Push; Fire is its counter.")
add("ring","summoners_collateral","Summoner's Collateral","pilgrim","dark","summon_cap,magic_regen","regen_rate","Fund a larger summon group with faster Magic recovery while neglecting your own healing.",2)
add("ring","blood_price","Blood Price","survivor","fire","injured,proc_bleeding","defense","Stay wounded to empower physical strikes that can inflict Bleeding; return damage is more dangerous.")
add("ring","stillwater_loop","Stillwater Loop","hunter","ice","still,proc_held","movement","Pin targets with attacks from a stationary position; slower travel makes repositioning deliberate.")
add("ring","quarantine_seal","Quarantine Seal","medic","earth","proc_poisoned,save_con","magic","Apply Poisoned while resisting bodily conditions; direct spell offense pays the price.")
add("ring","glass_command","Glass Command","occultist","dark","summon_cap,magic","defense","Add summon capacity and spell force with a physical-defense liability.",2)
add("ring","cartographers_oath","Cartographer's Oath","scavenger","electric","breadcrumb,save_int","physical","Navigate with longer memory and INT saves while surrendering physical output.")
add("ring","ash_tithe","Ash Tithe","pilgrim","fire","proc_immolated,magic_regen","weak_ice","Feed Magic recovery while weapons attempt Immolated; Ice weakness is the tithe.")
add("ring","wardens_veto","Warden's Veto","warden","light","proc_arcane_shattered,save_wis","regen_rate","Challenge magical protection and guard WIS saves; wearers recover health more slowly.")

-- Gloves consume both hand slots and receive the existing doubled budget.
add("gloves","riveters_grip","Riveter's Grip","dockworker","earth","physical,push_out","magic","Combine physical force and displacement, sacrificing spell damage.")
add("gloves","surgeons_grip","Surgeon's Grip","medic","light","proc_bleeding,regen_ceiling","save_str","Cause Bleeding and recover between operations; opposing Push contests expose a weak grip.")
add("gloves","voltage_knuckles","Voltage Knuckles","anomaly","electric","proc_clumsy,charged","defense","Destabilize with weapons before spending a charged Magic reserve; fragile protection demands timing.")
add("gloves","hangmans_mittens","Hangman's Mittens","warden","dark","proc_held,push_out","movement","Hold an opponent, then exploit displacement; the gloves make ordinary movement slower.")
add("gloves","plague_handlers","Plague Handlers","occultist","earth","proc_poisoned,ward_earth","weak_light","Deliver Poisoned through weapons under Earth protection; Light is the deliberate weakness.")
add("gloves","duelists_tape","Duelist's Tape","veteran","ice","ability_dex,physical","push_resist","Pair DEX with physical attacks but concede resistance to displacement.")
add("gloves","cinder_workers","Cinder Workers","dockworker","fire","proc_immolated,ability_str","magic_regen","Support STR-led burning strikes while slowing Magic replenishment.")
add("gloves","hex_catchers","Hex Catchers","pilgrim","light","save_int,save_wis","movement","Commit both hands to mental-condition protection and accept slower positioning.")
add("gloves","prison_breakers","Prison Breakers","scavenger","electric","proc_arcane_shattered,proc_push","defense","Strip protection and force space with weapon riders; the hands provide no safe defensive default.",2)
add("gloves","last_hand","Last Hand","survivor","dark","injured,proc_intimidated","regen_rate","Use wounded physical pressure to threaten morale; slower recovery makes the brink last longer.")

-- Shields keep the canonical left-arm slot and Fighter strength interaction.
add("shield","bulkhead_buckler","Bulkhead Buckler","dockworker","earth","block,push_resist","movement","Combine Block with anchoring while moving more slowly.")
add("shield","ambulance_panel","Ambulance Panel","medic","light","block,regen_ceiling","physical","Block during withdrawal and recover afterward; the medical panel reduces physical aggression.")
add("shield","riot_capacitor","Riot Capacitor","soldier","electric","block,magic_regen","save_dex","Protect against eligible hits and replenish Magic, but worsen DEX condition saves.")
add("shield","duelists_screen","Duelist's Screen","veteran","ice","block,dodge","push_resist","Split protection across the existing Block and Dodge authorities; forced movement remains dangerous.")
add("shield","furnace_door","Furnace Door","dockworker","fire","block,ward_fire","weak_ice","Block physical attacks behind Fire resistance while accepting Ice weakness.")
add("shield","prison_mirror","Prison Mirror","warden","light","block,proc_arcane_shattered","defense","Block or shatter an opponent's protection; an unblocked physical hit is more punishing.")
add("shield","hermits_partition","Hermit's Partition","pilgrim","dark","block,summon_duration","movement","Hold your own line while summons persist; relocation is slow.")
add("shield","defiant_sign","Defiant Sign","survivor","earth","block,injured","regen_rate","Turn Block into room for a wounded counteroffensive; recovery is intentionally slower.")
add("shield","couriers_cover","Courier's Cover","courier","electric","block,movement","magic_regen","Carry eligible-hit protection into a moving fight at the cost of Magic recovery.")
add("shield","quarantine_shutter","Quarantine Shutter","medic","earth","block,save_con","weak_dark","Guard bodily saves and Block while exposing a Dark weakness.")

-- Pistol: economical control and versatile pressure, six stable alternatives.
add("weapon_pistol","checkpoint_whistle","Checkpoint Whistle","soldier","light","proc_intimidated,still","movement","Stop to apply physical pressure and morale attempts; carrying this firing posture slows movement.")
add("weapon_pistol","couriers_sidearm","Courier's Sidearm","courier","electric","proc_clumsy,movement","defense","Disrupt pursuit while staying mobile; its active grip leaves less physical protection.")
add("weapon_pistol","clinic_receipt","Clinic Receipt","medic","light","proc_bleeding,save_con","physical","Trade direct damage for Bleeding attempts and bodily-condition protection.")
add("weapon_pistol","lockkeepers_note","Lockkeeper's Note","warden","dark","proc_held,map_efficiency","magic_regen","Hold a pursuer while mapping an exit; Magic regenerates more slowly while held.")
add("weapon_pistol","hollow_promise","Hollow Promise","anomaly","fire","proc_reckless,injured","regen_rate","Wounded physical attacks carry Reckless attempts; slower healing extends the risky posture.")
add("weapon_pistol","surveyor_sidearm","Surveyor Sidearm","scavenger","earth","proc_push,breadcrumb","magic","Make space and remember the route while sacrificing spell damage.")

-- Crowbar: close pressure with distinguishable condition and resource trades.
add("weapon_lod_crowbar","dockside_argument","Dockside Argument","dockworker","earth","proc_push,physical","magic_regen","Use close physical force to push opponents away, trading away Magic recovery.")
add("weapon_lod_crowbar","icebreakers_hook","Icebreaker's Hook","hunter","ice","proc_held,ability_str","movement","Pin with a STR-led close attack; slower movement makes the initial approach matter.")
add("weapon_lod_crowbar","cinder_prybar","Cinder Prybar","scavenger","fire","proc_immolated,injured","defense","Commit wounded physical force to burning strikes and accept a fragile counterattack window.")
add("weapon_lod_crowbar","graveyard_lever","Graveyard Lever","occultist","dark","proc_poisoned,summon_duration","save_con","Apply Poisoned while summons persist; bodily saves become more vulnerable in melee.")
add("weapon_lod_crowbar","wardens_eraser","Warden's Eraser","warden","electric","proc_arcane_shattered,physical","magic","Strip magical protection with physical pressure at the cost of direct spell strength.")
add("weapon_lod_crowbar","surgical_lever","Surgical Lever","medic","light","proc_bleeding,regen_rate","push_resist","Inflict Bleeding and improve already-enabled recovery; enemy displacement can break contact.")

-- Shotgun: occupancy, danger and recovery around the existing pellet contract.
add("weapon_shotgun","eviction_notice","Eviction Notice","warden","earth","proc_push,still","movement","Commit a stationary blast to displacement; slower movement makes exits worth planning.")
add("weapon_shotgun","riot_lullaby","Riot Lullaby","soldier","dark","proc_intimidated,defense","magic_regen","Pressure morale with a protected firing stance; Magic recovery is reduced.")
add("weapon_shotgun","furnace_sneeze","Furnace Sneeze","dockworker","fire","proc_immolated,ward_fire,physical","weak_ice","Mix Fire protection and physical burning pressure; Ice counters the furnace.",2)
add("weapon_shotgun","quarantine_bell","Quarantine Bell","medic","earth","proc_poisoned,regen_ceiling","movement","Spread Poisoned attempts, then recover after disengaging; movement is slower.")
add("weapon_shotgun","broken_overture","Broken Overture","anomaly","electric","proc_arcane_shattered,injured","defense","Exploit wounded physical pressure to break protection while accepting dangerous return hits.")
add("weapon_shotgun","tangled_exit","Tangled Exit","survivor","ice","proc_held,dodge","physical","Favor holding attempts and evasion over raw physical damage when escaping close pressure.")

-- SMG: sustained tactical pressure; riders still deduplicate per attack/target.
add("weapon_smg1","dispatch_static","Dispatch Static","courier","electric","proc_muted,movement","regen_rate","Move while pressuring enemy casting; health recovery is the sacrificed resource.")
add("weapon_smg1","dockyard_hail","Dockyard Hail","dockworker","earth","proc_push,push_resist","magic","Repel targets without giving up anchoring; direct spell damage declines.")
add("weapon_smg1","clinic_stapler","Clinic Stapler","medic","light","proc_bleeding,magic_regen","physical","Trade physical output for Bleeding attempts and replenished Magic.")
add("weapon_smg1","contraband_fume","Contraband Fume","scavenger","dark","proc_poisoned,map_efficiency","defense","Combine Poisoned pressure with cheaper route planning; physical protection is weak while held.")
add("weapon_smg1","prison_jangle","Prison Jangle","warden","ice","proc_reckless,proc_clumsy","save_cha","Contest the opponent's control with two distinct riders while accepting weaker CHA saves.",2)
add("weapon_smg1","expedition_signal","Expedition Signal","veteran","fire","proc_intimidated,breadcrumb","magic_regen","Pressure morale while preserving a longer escape trail; Magic recovery is slower.")

-- Revolver: existing cadence/penetration, distinct held-state commitments.
add("weapon_357","watchtower_verdict","Watchtower Verdict","hunter","ice","proc_arcane_shattered,still","movement","Wait for a stationary physical shot that can shatter protection; carrying it slows travel.")
add("weapon_357","blood_debt","Blood Debt","survivor","fire","proc_bleeding,injured,physical","defense","Commit to wounded physical punishment and Bleeding at the cost of protection.",2)
add("weapon_357","chaplains_doubt","Chaplain's Doubt","pilgrim","light","proc_intimidated,save_wis","magic","Contest morale and protect WIS saves while reducing spell damage.")
add("weapon_357","frozen_receipt","Frozen Receipt","soldier","ice","proc_held,ward_ice","weak_fire","Anchor control attempts behind Ice resistance; Fire remains a direct counter.")
add("weapon_357","arc_inspector","Arc Inspector","occultist","electric","proc_muted,charged","physical","Use Silence attempts to prepare charged spell damage rather than maximize physical shots.")
add("weapon_357","wreckers_clause","Wrecker's Clause","dockworker","earth","proc_push,ability_str","magic_regen","Pair displacement with STR investment; Magic recovery suffers while this tool is held.")

-- Pulse rifle: legal from level 3, with no new magazine/ammo entitlement.
add("weapon_ar2","warden_protocol","Warden Protocol","warden","electric","proc_muted,proc_arcane_shattered","defense","Pressure casting and magical protection through distinct riders while exposing physical defense.",2)
add("weapon_ar2","ash_docket","Ash Docket","soldier","fire","proc_immolated,still","movement","Plant your feet for burning physical pressure, accepting slower transit.")
add("weapon_ar2","escort_array","Escort Array","veteran","light","proc_push,save_wis","physical","Prioritize displacement and WIS protection over direct physical output.")
add("weapon_ar2","plague_regulator","Plague Regulator","occultist","dark","proc_poisoned,charged","regen_rate","Apply Poisoned pressure while retaining Magic for stronger casts; healing is slower.")
add("weapon_ar2","icebound_order","Icebound Order","hunter","ice","proc_clumsy,ward_ice","weak_fire","Destabilize enemies while resisting Ice; Fire targets the specialization.")
add("weapon_ar2","riot_remnant","Riot Remnant","anomaly","earth","proc_reckless,physical","save_cha","Pair physical pressure with Reckless attempts and accept vulnerability in CHA saves.")

-- Wands retain finite charges and the existing class-use check.
add("weapon_lod_wand","surge_auditor","Surge Auditor","occultist","electric","proc_arcane_shattered,magic","defense","Spend finite wand charges on spell force and shattering attempts; physical defense is weaker.",2)
add("weapon_lod_wand","quietus_probe","Quietus Probe","warden","dark","proc_muted,summon_cap","regen_rate","Carry extra summon capacity alongside muting wand pressure; personal recovery is slower.",2)
add("weapon_lod_wand","infirmary_probe","Infirmary Probe","medic","light","proc_clumsy,regen_ceiling","physical","Use finite-charge disruption while enabling more recovery; physical attacks are reduced.")
add("weapon_lod_wand","cinder_beacon","Cinder Beacon","pilgrim","fire","proc_immolated,summon_duration","weak_ice","Pair burning wand pressure with lasting summons, accepting Ice weakness.")
add("weapon_lod_wand","held_breath","Held Breath","anomaly","ice","proc_held,charged,magic","movement","Hold enemies and spend charged Magic pressure from a powerful wand; movement is slower.",3,5)

-- Fail at load time if authored content violates the shared generator's grammar.
local signatures={}
for _,id in ipairs(E.ArchetypeOrder) do
    local a=E.Archetypes[id];local base=E.Definitions[a.base]
    assert(#a.signature>=2 and #a.signature<=3 and E.EconomyProperties["element_"..a.element])
    local drawback=assert(E.EconomyProperties[a.drawback]);assert(drawback.negative or drawback.drawbackOnly)
    local used,groups,rider={}, {},false
    used[a.drawback]=true;if drawback.group then groups[drawback.group]=true end
    for _,pid in ipairs(a.signature) do
        local p=E.EconomyProperties[pid]
        assert(not used[pid] and not p.element and not p.drawbackOnly
            and (not p.family or p.family==a.base) and (not p.group or not groups[p.group]),"Invalid signature "..id)
        used[pid]=true;if p.group then groups[p.group]=true end
        rider=rider or p.rider~=nil
    end
    assert(not base.weapon or rider,"Weapon archetypes must include a rider: "..id)
    local sig={};for _,pid in ipairs(a.signature) do sig[#sig+1]=pid end;table.sort(sig)
    local key=table.concat(sig,"+");assert(not signatures[key],"Repeated mechanical signature: "..id)
    signatures[key]=id
end
assert(#E.ArchetypeOrder==113,"Big Loot authored catalog count changed")

function E:GenerateArchetype(seed,level,id,contextId)
    local a=self.Archetypes[id];if not a then return nil end
    return self:Generate(seed,level,a.base,contextId,id)
end

local validate=E.ValidateWearable
function E:ValidateWearable(item)
    if not validate(self,item) then return false end
    if item.archetypeId==nil then return true end
    local a=self.Archetypes[item.archetypeId]
    if not a or item.version~=2 or item.definitionId~=a.base or item.rarity<a.minimumRarity then return false end
    local positive,negative={},{}
    for _,r in ipairs(item.properties) do
        if r.amount>0 then positive[r.id]=true else negative[r.id]=true end
    end
    if not positive["element_"..a.element] or not negative[a.drawback] then return false end
    for _,pid in ipairs(a.signature) do if not positive[pid] then return false end end
    return true
end
local description=E.Description
function E:Description(item,compact)
    local text=description(self,item,compact)
    local a=item and self.Archetypes[item.archetypeId]
    if not a then return text end
    return a.name.." ["..a.family.."] — "..a.description.."; "..text
end
