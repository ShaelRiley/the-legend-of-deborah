local E = assert(LOD.Equipment)
E.Definitions.summon_card = {
    id="summon_card", name="Summon Card", slots={"throwable"}, throwable=true,
    drinkable=true, effect="summon_hero", maxStack=3,
    model="models/props_lab/clipboard.mdl", heldScale=.35,
    heldColor=Color(235,220,175),
    prompt="LMB: SUMMON NEARBY   RMB: SUMMON HERE",
    description="Choose another active Hero. Throw to bring them to a safe adjacent square; consume to bring them to your square or its nearest safe equivalent. Closed gates still apply."
}
