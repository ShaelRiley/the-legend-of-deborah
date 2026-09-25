local H=dofile('tools/test_bestiary_b20.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua')
local D,Run=H.D,H.Run
local totals={plans=0,encounters=0,discretionary=0,specialists=0,unique=0,ready4=0,homes4=0}
local basics={shambler=true,runner=true,soldier=true}
for i=1,16 do
 local seed=i*7919
 Run.State={CampaignSeed=seed,CampaignEpoch=1,RunId=1,Level=1}
 H.setParty(1)
 local g=H.prepare(seed,1);Run.State.GatesOpen={false,false,false,false}
 local p=H.build(g);H.bounds(p)
 local unique,n,s,homes=0,0,0,0;local seen={}
 for k,c in pairs(g.Cells) do if p.tags[k].sector==4 and D:PacingAllows(p,c) then homes=homes+1 end end
 for _,enc in ipairs(p.encounters) do
  if not enc.objective then n=n+1 end
  for id,count in pairs(enc.composition) do
   if not basics[id] then s=s+count;seen[id]=true end
  end
 end
 for id in pairs(seen) do unique=unique+1 end
 totals.plans=totals.plans+1;totals.encounters=totals.encounters+#p.encounters
 totals.discretionary=totals.discretionary+n;totals.specialists=totals.specialists+s;totals.unique=totals.unique+unique
 totals.ready4=totals.ready4+(p.pacing.sectors[4].status=='ready' and 1 or 0);totals.homes4=totals.homes4+homes
 print(string.format('POPULATION seed=%d theme=%s encounters=%d discretionary=%d other_bodies=%d other_ids=%d sector4=%s homes4=%d',seed,p.ecology.theme,#p.encounters,n,s,unique,p.pacing.sectors[4].status,homes))
end
print('TOTALS '..H.serial(totals))
