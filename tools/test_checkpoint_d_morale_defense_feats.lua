-- Defensive Nerve feats are retired, while the underlying Morale save survives.
dofile("tools/test_checkpoint_d_closure.lua")
local C,E=LOD.RPG.IdentityCatalog.OrdinaryFeats,LOD.RPG.FeatEffectSystem
assert(C.CHA_NERVE_1==nil and C.CHA_NERVE_2==nil)
local d={};E:ApplyDerived({featIds={"CHA_NERVE_1","CHA_NERVE_2"}},d)
assert(d.moraleSaveBonus==nil or d.moraleSaveBonus==0,"retired IDs cannot add save bonuses")
assert(type(LOD.RPGStatusElements.AttemptMorale)=="function","shared Morale remains")
print("NERVE_REMOVAL_PASS: retired ranks unregistered and inert; Morale retained")
