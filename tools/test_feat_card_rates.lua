-- Live CON recovery rates must survive the shared card text and real snapshot.
-- Reuse the production catalog/progression harness; only Source boundaries are fake.
dofile("tools/test_snapshot_delivery.lua")
local C,RPG=LOD.CharacterProgressionSystem,LOD.RPG
local expected={
 {id="CON_REGEN_11",rate="1",ceiling="22",base=.01},
 {id="CON_REGEN_22",rate="1.5",ceiling="44",base=.015},
 {id="CON_REGEN_33",rate="2",ceiling="66",base=.02}
}
local function checkText(text,row)
 assert(text:find("regenerate "..row.rate.."% MaxHP per second",1,true),
  row.id.." must display its authored "..row.rate.."% rate: "..text)
 assert(text:find("Add "..row.ceiling.."% MaxHP",1,true),"recovery ceiling changed")
end
for _,row in ipairs(expected) do
 local p=RPG.IdentityCatalog.OrdinaryFeats[row.id].effectParams
 assert(p.baseMaxHPPerSecond==row.base,"presentation fix must preserve actual healing rate")
 checkText(p.description,row)
end
local hero=player.GetAll()[1]
local ps=LOD.RunManager:GetPlayerState(hero)
ps.progressionState=nil
local state=C:InitializeHero(LOD.RunManager,ps,{id="card-rate",name="Card Rate Hero",model=ps.model,presentationSex="male"})
assert(C:CommitClass(hero,"rogue"))
state.featIds={"CON_REGEN_11","CON_REGEN_22","CON_REGEN_33"}
state.featStackCounts={CON_REGEN_11=1,CON_REGEN_22=1,CON_REGEN_33=1}
ps.progressionState=state;C:_RecomputeProgressionState(state)
local snapshot=assert(C:BuildClientSnapshot(hero),"real initialized Hero snapshot required")
local owned={}
for _,item in ipairs(snapshot.ownedFeats) do owned[item.featId]=item end
for _,row in ipairs(expected) do
 assert(owned[row.id],"owned recovery rank missing from production snapshot")
 checkText(owned[row.id].effect,row)
end
print("FEAT_CARD_RATES_PASS: authored1/1.5/2percent rates and22/44/66percent ceilings reach real owned-feat snapshots; healing parameters unchanged")
