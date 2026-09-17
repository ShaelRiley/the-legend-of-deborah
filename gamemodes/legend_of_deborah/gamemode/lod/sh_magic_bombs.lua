-- Single catalog for throwable damage and condition bombs. Gameplay uses the
-- same Forms damage/area resolver and Status API as learned spells and weapons.
local E=LOD.Equipment
E.BombTuning={radius=144,damageDice=2,damageSides=6}
E.BombTypes={}
E.StatusOrder={'immolated','poisoned','bleeding','held','muted','arcane_shattered','intimidated','morale_flee','clumsy','reckless'}
E.StatusPresentation={
 immolated={label='IMMOLATED',key='Immolated',color={255,95,35},sound='ambient/fire/ignite.wav'},
 poisoned={label='POISONED',key='Poisoned',color={90,205,75},sound='npc/barnacle/barnacle_digesting1.wav'},
 bleeding={label='BLEEDING',key='Bleeding',color={200,40,55},sound='physics/flesh/flesh_impact_bullet1.wav'},
 clumsy={label='CLUMSY',key='Clumsy',color={225,165,75},sound='buttons/button10.wav'},
 muted={label='MUTED',key='Muted',color={200,190,225},sound='ambient/energy/zap1.wav'},
 held={label='HELD',key='Held',color={90,200,255},sound='physics/glass/glass_impact_bullet1.wav'},
 reckless={label='RECKLESS',key='Reckless',color={245,120,150},sound='ambient/energy/zap2.wav'},
 arcane_shattered={label='SHIELD SHATTERED',key='ArcaneShattered',color={175,90,245},sound='physics/glass/glass_impact_bullet2.wav'},
 intimidated={label='INTIMIDATED',key='Intimidated',color={230,205,60},sound='ambient/energy/zap3.wav'},
 morale_flee={label='FLEEING',key='MoraleFlee',color={230,205,60},sound='ambient/energy/zap3.wav'}
}
local function add(id,label,element,status)
    local key='bomb_'..id
    E.BombTypes[#E.BombTypes+1]=key
    E.Definitions[key]={name=label..' Bomb',slots={'throwable'},throwable=true,drinkable=false,maxStack=3,
        effect='magic_bomb',element=element,status=status,model='models/Combine_Helicopter/helicopter_bomb01.mdl',
        description='Throw: directional impact detonates a 144-unit area; solid cover blocks it. '..(status and 'Attempts '..label..' through the normal save.' or label..' magic damage.')}
end
for _,element in ipairs({'raw','earth','fire','dark','ice','light','electric'}) do add(element,element:sub(1,1):upper()..element:sub(2),element) end
add('physical','Physical',nil)
for _,id in ipairs({'clumsy','immolated','poisoned','bleeding','muted','held','reckless','arcane_shattered','intimidated'}) do
    add(id,E.StatusPresentation[id].label,'raw',id)
end
E.Definitions.healing_potion.description='Drink to restore up to 25 HP and cure all negative conditions, or throw to remedy the first allied Hero hit.'
