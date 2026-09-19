-- Real completion/advance/build authority through the finite arc and cash levels.
local fixture=dofile('tools/test_dungeon_transition.lua')
local R,hero=fixture.Run,fixture.hero
local D=LOD.Damsels
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local seen,families={},{}
for i,def in ipairs(D.Definitions) do
    assert(not seen[def.name] and def.level==i);seen[def.name]=true
    if def.family then families[def.family]=true end
    assert(def.recolor==(i<=16),'final four must retain stock appearance')
    assert(def.dialogue[1] and def.reward and def.placement and def.idle)
end
assert(table.Count(seen)==20 and table.Count(families)==5)
assert(D.Definitions[1].name=='Nessa' and D.Definitions[2].name=='Bessa' and D.Definitions[3].name=='Tessa' and D.Definitions[4].name=='Odessa')
assert(D.Definitions[20].name=='Deborah' and D.Definitions[20].family==nil)
assert(D:Model(D.Definitions[20])==LOD.Config.Models.Deborah)
HSVToColor=function(h,s,v) return {h=h,s=s,v=v} end
local c,a=D:Palette(42,1);local c2,a2=D:Palette(42,1)
assert(c.h==c2.h and a.h==a2.h and (a.h-c.h)%360>=165 and (a.h-c.h)%360<=195)
player.GetAll=function() return {} end
R._SortedConnectedPlayers=player.GetAll
R.State.HighestLevel=1;R.State.Level=1;R.State.LevelCleared=false;R.State.RescuedDamsels={};R.State.CashRecovered=0
hero.throwGive=false
for level=1,26 do
    assert(R:BuildCurrentLevel())
    assert(R.State.Level==level and R.State.HighestLevel==level)
    local target=R.State.RescueTarget
    assert(target.type==(level<=20 and 'damsel' or 'cash'))
    assert(target.objective==(level<=20 and 'RESCUE '..string.upper(D.Definitions[level].name) or 'SECURE THE BAG'))
    assert(R:CompleteLevel(hero));assert(not R:CompleteLevel(hero),'duplicate victory')
    assert(R.State.RescueCount==math.min(level,20))
    assert(R.State.CashRecovered==math.max(0,level-20))
    assert((R.State.Abundance==true)==(level>=20))
    assert(R:AdvanceLevel())
end
local previous=D:EndlessPressure(20)
for _,level in ipairs({21,22,30,100,10000,1000000}) do
    assert(D:Target(level).type=='cash')
    local p=D:EndlessPressure(level)
    assert(p.reinforcement<previous.reinforcement and p.reinforcement>.35)
    assert(p.recovery<previous.recovery and p.recovery>.65)
    assert(p.specialistWeight>previous.specialistWeight and p.specialistWeight<3)
    previous=p
end
R._PrepareCharacterOrder=function() end;R._ValidateConfiguredModels=function() end
R._DefaultSeed=function() return 17 end;R._DefaultRosterSeed=function() return 18 end
R.CampaignEpoch=1
assert(R:NewCampaign())
assert(R.State.Level==1 and R.State.RescueTarget.name=='Nessa' and next(R.State.RescuedDamsels)==nil)
assert(next(R.State.DamselClaims)==nil and not R.State.Abundance and R.State.CashRecovered==0)
print('DAMSEL_PROGRESSION_PASS: 20 unique names, five families, canonical model, complementary palette, real levels 1–26, no duplicate victory, endless pressure and campaign reset')
