-- Campaign objectives are data, independent from the entity used to depict them.
LOD.Damsels = LOD.Damsels or {}
local D = LOD.Damsels
D.Version='damsels-20261012-lore'
D.CashModel = 'models/props_c17/BriefCase001a.mdl'
D.Models = {
    'models/Humans/Group01/Female_01.mdl', 'models/Humans/Group01/Female_02.mdl',
    'models/Humans/Group01/Female_03.mdl', 'models/Humans/Group01/Female_04.mdl',
    'models/Humans/Group01/Female_06.mdl', 'models/Humans/Group01/Female_07.mdl'
}
D.Letter = 'To the rescuers: All twenty damsels, liberated. Impeccable work. I shall continue for the love of the game. Henceforth I am stealing cash. Come rescue that. — Gordon the Warden'
-- Four quartets, then a final trio: Deborah deliberately has no rhyme family.
local rows = {
    {'Nessa',1,'ammo','weapon_pistol',{"Pistol ammunition. Bessa calls my inventories dreary. Yet everyone likes discovering that dreary has saved them a magazine.","Bessa plans the celebration; I count who gets home. Here is pistol ammunition. Give me another person to count.","Tessa prefers decisive exits. I prefer stocked ones. Take this pistol ammunition; perhaps you can satisfy us both."}},
    {'Bessa',1,'ammo','weapon_smg1',{"SMG ammunition! Nessa says enthusiasm requires a budget. I say a budget should occasionally sound enthusiastic.","Nessa worries I spend too freely. She means ammunition, mostly. Take some for your SMG; spend it getting everybody home.","Belle promised we could celebrate once nobody was bleeding. SMG ammunition for you. I am doing my part to shorten the guest list of emergencies."}},
    {'Tessa',1,'ammo','weapon_shotgun',{"Shotgun shells. Odessa likes six carefully chosen arguments. I prefer the discussion to conclude.","Odessa says patience wins disputes. Certainly. Take these shotgun shells in case patience encounters a locked personality.","Nessa has counted these shotgun shells twice. I trust her. I trust you to make the third count unnecessary."}},
    {'Odessa',1,'ammo','weapon_357',{"Revolver ammunition. Tessa calls deliberation a luxury. Precision is how I keep a luxury affordable.","Tessa and I disagree about volume, never about getting people home. Six persuasive revolver rounds should clarify that distinction.","Nessa has impeccable accounts. I admire a person who can tell a missing round from a missing promise. Revolver ammunition, with my confidence."}},
    {'Nell',2,'ammo','weapon_ar2',{"AR2 ammunition. Gordon filed it under security. I have revised the beneficiary. Belle approves of changes that produce fewer patients.","Belle says I cannot requisition a decent night's sleep. An intolerable gap in the system. I can, however, supply your AR2.","Neil dislikes unauthorized departures. I dislike his definitions of authorization. These AR2 rounds have changed departments."}},
    {'Belle',2,'heal',25,{"Hold still; let me mend some of that damage. Nell treats rest like a missing form. I keep telling her she already qualifies.","A little healing. Nessa counts supplies; I count people who return. We agree that you should improve our figures.","Nell would requisition sunshine if she found the right department. Until then, come here. I can at least tend those wounds."}},
    {'Estelle',2,'cure',0,{"Let me clear those afflictions. Mirabelle calls them interesting. Interesting is a condition I prefer to study from across the room.","Mirabelle and I agree that mysteries deserve attention. We disagree about keeping them in your bloodstream. Leave the afflictions with me.","Belle patches the damage; I remove its lingering acquaintances. We make a useful distinction. Come here for a cure."}},
    {'Mirabelle',2,'magic',25,{"A little magic restored. Estelle says curiosity needs supervision. I maintain that supervision could use a little curiosity.","Estelle has never met a mystery she would not label. I love her for it. Here is some magic for the unlabelled ones.","Nell finds supplies where nobody thought to look. I try the same approach with ideas. Take a little magic; surprise us both."}},
    {'May',3,'equipment','gloves',{"Gloves for you. Faye checks the finish; I check the seams. Between us, we prefer useful things to grand promises.","Faye says care should be visible. I say it should survive use. These gloves are our modest argument in both directions.","Kay will wear out any road you give her. I admire that. Take these gloves; there is still work worth putting your hands to."}},
    {'Faye',3,'equipment','ring',{"A ring. May makes care tangible. I like that about her; so many people only make it audible.","May says small things deserve good workmanship. A ring makes a remarkably portable reminder that I agree.","Cora insists that a promise is not an asset. Quite right. Take this ring; I prefer giving you something that actually exists."}},
    {'Kay',3,'equipment','boots',{"Boots! Desiree calls my departures abrupt. I call them departures. We both prefer them to appointments with Gordon.","Desiree has the poise; I have the route out. Take these boots and borrow whichever quality the next room requires.","May checks every stitch before I wear a pair out. She deserves a more patient friend. Boots for you; perhaps you qualify."}},
    {'Desiree',3,'equipment','headwear',{"Headwear. Kay trusts her feet to get her out of trouble. I prefer protecting the part that decides where they go.","Kay has taught me that a brisk exit can be perfectly dignified. Take this headwear; let good judgment travel with you.","Colleen understands that dignity can be practical. Gordon understands neither word. Here is some headwear for your next encounter with his opinions."}},
    {'Jean',4,'equipment','vest',{"A vest. Colleen says useful clothes may also be handsome. I will concede the point once you come back wearing them.","Colleen has an eye for a good line. I have an eye for what might get through it. This vest is a compromise we both like.","Maureen calls protection a shared responsibility. Sensible woman. Take a vest; sharing begins with having something to contribute."}},
    {'Colleen',4,'equipment','trousers',{"Trousers. Jean thinks a garment's finest quality is surviving. I agree, but I refuse to make survival look apologetic.","Jean hides excellent workmanship beneath talk of necessity. Take these trousers. I am determined that somebody should appreciate the result.","Desiree and I believe dignity is portable. Gordon appears to believe it requires a spotlight. Trousers for the less expensive interpretation."}},
    {'Maureen',4,'equipment','shield',{"A shield. Josephine worries I take on too much. I intend to prove I can pass something useful to another pair of hands.","Josephine prepares for emergencies; I try to make them smaller. Take this shield. We would both appreciate your cooperation.","Jean believes in an extra layer. I believe in something between you and the blow. A shield should settle our entirely friendly argument."}},
    {'Josephine',4,'consumable','healing_potion',{"A healing potion. Maureen says she can take another blow. I would prefer she discover another hobby.","Maureen looks after everybody else. Somebody has to remember her, too. Here is a healing potion; preparedness is a form of affection.","Belle likes an unhurried recovery. So do I. This healing potion is for occasions when the labyrinth declines to share our taste."}},
    {'Dora',5,'full_heal',0,{"Let me heal you fully. Cora keeps the fund solvent; I try to keep its people whole. Both accounts matter.","Eleonora believes in second chances. I believe they should begin with fewer wounds. Come here; let me restore your health completely.","Cora worries that I spend myself too freely. She is looking after me, so I listen. Now let me give you a full healing."}},
    {'Cora',5,'deb',{min=25,max=75},{"Some $DEB from the rescue fund. Dora reminds me that a balanced account means little if nobody survives to use it.","Eleonora and I disagree about acceptable risks. We agree that people deserve another try. Take this $DEB; make yours a considered one.","Faye likes promises you can hold. I like aid you can actually spend. Here is your $DEB disbursement; no speech required."}},
    {'Eleonora',5,'life',1,{"One more life. Cora calls caution a virtue. I agree; I simply refuse to let a mistake become somebody's entire biography.","Dora makes a new start feel possible. I try to make it available. Take another life, and be kinder to yourself this time.","Cora wants every chance accounted for. I want every person to have one. Another life for you; help us both sleep easier."}},
    {'Deborah',nil,'abundance',1,{"The Hermit was Hector, our self-appointed director. He took a refuge built by people helping one another and cast us as his supporting characters. You broke that arrangement. Nessa's supplies, Belle's care, Cora's accounts: those were always their work, freely offered. This refuge belongs to its people now. Gordon has sent an encore: he is stealing the fund's cash because he cannot bear the curtain coming down. Cash means stolen money, not another captive. Beyond Level 20, recover the bags and bring our resources home. Separately, Abundance remains your gift: one DFT each day. Nobody owes Hector another performance.","Hector hid behind the Hermit's smile. Useful advice did not give him ownership of anybody's story. Our network made this place a refuge; you helped us reclaim it. Cora will keep the books, Dora will keep caring, and the others will offer their own gifts on their own terms. Gordon, predictably, has chosen an encore. His letter says he is stealing cash now. There is no person called Cash to rescue: from Level 21 onward, secure the stolen bags. The rescue story is won; recovering our resources can continue. Abundance is separate: one DFT each day. A gift is allowed to be a gift."}}
}
D.Definitions = {}
for level, row in ipairs(rows) do
    D.Definitions[level] = {level=level, name=row[1], family=row[2], reward=row[3], parameter=row[4],
        recolor=level<=16, modelIndex=(level-1)%#D.Models+1,
        idle=({'LineIdle01','idle_subtle','idle01','Idle01'})[(level-1)%4+1],
        dialogue=row[5],
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
