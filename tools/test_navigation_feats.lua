-- Actual canonical eligibility and derived-state authorities.
dofile('tools/test_map_movement.lua')
local CPS,E=LOD.CharacterProgressionSystem,LOD.RPG.FeatEffectSystem
local feats=LOD.RPG.IdentityCatalog.OrdinaryFeats
local compass,finder=assert(feats.WIS_INTERNAL_COMPASS),assert(feats.WIS_MAP_FINDER)
assert(compass.displayName=='Internal Compass' and compass.abilityRequirements.wis==15)
assert(finder.displayName=='Map Finder' and finder.abilityRequirements.wis==13)
local state=CPS:NewProgressionState('navigation','hero')
state.actorType='hero';state.capabilityTags={'minimap'};state.featIds={}
for _,pair in ipairs({{compass,15},{finder,13}}) do
 local def,gate=pair[1],pair[2]
 assert(#def.prerequisiteFeatIds==0 and not def.repeatableFallback)
 state.featQualificationAbilities.wis=gate-1;assert(not CPS:_FeatEligible({},state,def),'gate admitted a low score')
 state.featQualificationAbilities.wis=gate;assert(CPS:_FeatEligible({},state,def),'exact threshold rejected')
 state.featIds={def.featId};assert(not CPS:_FeatEligible({},state,def),'duplicate feat offered')
 state.featIds={};state.actorType='ai';assert(not CPS:_FeatEligible({},state,def),'unsupported AI granted navigation UI')
 state.actorType='hero'
end
local d={breadcrumbCells=10}
E:ApplyDerived({featIds={'WIS_INTERNAL_COMPASS','WIS_MAP_FINDER','WIS_CARTOGRAPHER','WIS_FRUGAL_MAP'}},d)
assert(d.internalCompassEnabled and d.mapFinderEnabled and d.breadcrumbCells==18)
assert(d.mapDrainFeatMultiplier==.75,'new feats changed the normal map cost')
local plain={breadcrumbCells=10};E:ApplyDerived({featIds={}},plain)
assert(not plain.internalCompassEnabled and not plain.mapFinderEnabled and plain.breadcrumbCells==10)
local onlyFinder={breadcrumbCells=10};E:ApplyDerived({featIds={'WIS_MAP_FINDER'}},onlyFinder)
assert(onlyFinder.mapFinderEnabled and not onlyFinder.internalCompassEnabled,'finder revealed breadcrumb privilege')
local schema=LOD.RPG.Schema or LOD.RPG
assert(compass.requiredCapabilityTags[1]=='minimap' and finder.requiredCapabilityTags[1]=='minimap')
print('NAVIGATION_FEATS_PASS: exact WIS15/WIS13 gates; no prerequisites/duplicates/unsupported AI; distinct owned effects; Cartographer and Frugal coexist; no extra range/cost')
