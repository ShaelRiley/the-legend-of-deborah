-- Campaign objectives are data, independent from the entity used to depict them.
LOD.Damsels = LOD.Damsels or {}
local D = LOD.Damsels
D.Version='damsels-20260919-01'
D.CashModel = 'models/props_c17/BriefCase001a.mdl'
D.Models = {
    'models/Humans/Group01/Female_01.mdl', 'models/Humans/Group01/Female_02.mdl',
    'models/Humans/Group01/Female_03.mdl', 'models/Humans/Group01/Female_04.mdl',
    'models/Humans/Group01/Female_06.mdl', 'models/Humans/Group01/Female_07.mdl'
}
D.Letter = 'To the rescuers: All twenty damsels, liberated. Impeccable work. I shall continue for the love of the game. Henceforth I am stealing cash. Come rescue that. — Gordon the Warden'
-- Four quartets, then a final trio: Deborah deliberately has no rhyme family.
local rows = {
    {'Nessa',1,'ammo','weapon_pistol','A steady hand deserves a full magazine.'},
    {'Bessa',1,'ammo','weapon_smg1','For when one bullet would be discourteous.'},
    {'Tessa',1,'ammo','weapon_shotgun','Subtlety has its place. That place is elsewhere.'},
    {'Odessa',1,'ammo','weapon_357','Six persuasive arguments. Make them count.'},
    {'Nell',2,'ammo','weapon_ar2','I requisitioned these from our former host.'},
    {'Belle',2,'heal',25,'Hold still. Heroism is leaking out of you.'},
    {'Estelle',2,'cure',0,'Leave the labyrinth’s less charming souvenirs with me.'},
    {'Mirabelle',2,'magic',25,'A little clarity. Try not to spend it all on walls.'},
    {'May',3,'equipment','gloves','These hands have important work ahead of them.'},
    {'Faye',3,'equipment','ring','A small circle of considerable responsibility.'},
    {'Kay',3,'equipment','boots','For a dignified advance. Or a very brisk retreat.'},
    {'Desiree',3,'equipment','headwear','Protect the part that comes up with these plans.'},
    {'Jean',4,'equipment','vest','An extra layer between you and the consequences.'},
    {'Colleen',4,'equipment','trousers','No legend should meet its destiny underdressed.'},
    {'Maureen',4,'equipment','shield','Let something else take the next blow.'},
    {'Josephine',4,'consumable','healing_potion','For an emergency. The labyrinth provides those generously.'},
    {'Dora',5,'full_heal',0,'Take a breath. You have carried enough wounds.'},
    {'Cora',5,'deb',{min=25,max=75},'The rescue fund has approved this modest disbursement.'},
    {'Eleonora',5,'life',1,'One more chance. Please make it a beautiful one.'},
    {'Deborah',nil,'abundance',1,'At last. Abundance is yours: one token, each day. Do try to remain alive.'}
}
D.Definitions = {}
for level, row in ipairs(rows) do
    D.Definitions[level] = {level=level, name=row[1], family=row[2], reward=row[3], parameter=row[4],
        recolor=level<=16, modelIndex=(level-1)%#D.Models+1,
        idle=({'LineIdle01','idle_subtle','idle01','Idle01'})[(level-1)%4+1],
        dialogue={row[5], 'You have my gratitude. '..row[5]},
        frequency=(row[3]=='ammo' or row[3]=='heal' or row[3]=='cure' or row[3]=='magic' or row[3]=='consumable') and 'visit' or 'campaign',
        -- Authored conversational pairs along the perimeter; the center stays open.
        placement={wall=math.floor((level-1)/5)+1, along=({-.72,-.43,-.08,.29,.66})[(level-1)%5+1],
            inset=({38,58,42,62,40})[(level-1)%5+1], yaw=({18,-20,12,-16,0})[(level-1)%5+1]}}
end
function D:Model(def)
    return def.level==20 and LOD.Config.Models.Deborah or self.Models[def.modelIndex]
end
function D:Target(level)
    level=math.max(1,math.floor(tonumber(level) or 1))
    local def=self.Definitions[level]
    if def then return {type='damsel',level=level,name=def.name,definition=level,objective='RESCUE '..string.upper(def.name),
        victory=string.upper(def.name)..' RESCUED'} end
    return {type='cash',level=level,name='Stolen Cash',objective='SECURE THE BAG',victory='CASH RECOVERED'}
end
function D:Palette(seed, family)
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed or 1,'damsel-palette:'..tostring(family)))
    local hue=(rng:Int(0,11)*30+family*17)%360
    return HSVToColor(hue,.48,.82), HSVToColor((hue+165+rng:Int(0,2)*15)%360,.55,.92)
end
function D:Current()
    local state=SERVER and LOD.RunManager and LOD.RunManager.State or LOD.ClientState
    return state and state.RescueTarget or self:Target(state and (state.Level or state.level) or 1)
end

-- Increasing pressure with a finite workload. Actor growth retains its existing
-- 999 cap; these asymptotic factors never reset at the narrative transition.
function D:EndlessPressure(level)
    local beyond=math.max(0,(tonumber(level) or 1)-20)
    local pressure=beyond/(beyond+30)
    return {reinforcement=1-.65*pressure, specialistWeight=1+2*pressure, recovery=1-.35*pressure}
end
