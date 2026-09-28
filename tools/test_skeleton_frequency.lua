local F=dofile('tools/event_expansion_fixture.lua')
local R,D=F.R,F.D
local totals={before=0,after=0};local maxDry=0
for campaign=1,64 do
 local histories={before=R:NewHistory(),after=R:NewHistory()}
 local dry=0
 for level=1,20 do
  local seed=LOD.Seeds.DeriveLevel(LOD.Seeds.Derive(556677,'skeleton-sample:'..campaign),level)
  local counts={}
  for _,mode in ipairs({'before','after'}) do
   local ctx={history=histories[mode],skeletonPriority=mode=='after'}
   local a,n,diag=R:Select(seed,level,ctx)
   local again,m=R:Select(seed,level,ctx)
   assert(table.concat(a,',')==table.concat(again,',') and n==m)
   counts[mode]=n
   assert(n==#a and n==LOD.RNG.New(LOD.Seeds.Derive(seed,'dungeon-events:count:v1')):Int(1,4))
   local found,seen=false,{}
   for slot,id in ipairs(a) do
    assert(not seen[id]);seen[id]=true
    assert((R.Definitions[id].rare==true)==(slot==4))
    if id=='skeleton_blockade' then found=true end
    assert(id~='bribe_blockade')
   end
   if found then totals[mode]=totals[mode]+1 end
   if mode=='after' then
    dry=found and 0 or dry+1;maxDry=math.max(maxDry,dry)
    assert(dry<=2,'Three successfully populated dungeons without skeletons')
    if diag.skeletonPriority then assert(a[1]=='skeleton_blockade') end
   end
   histories[mode]=R:HistoryAfter(histories[mode],a,level)
  end
  assert(counts.before==counts.after,'Skeleton priority inflated total density')
 end
end
assert(totals.after>totals.before*2 and totals.after>=1280*.60)
-- Physical proofs on the full current catalog, not a retired-Bribe fixture.
local built,blocked=0,0
F.Run.State.Level=1
for seed=1,20 do
  local plan,g=F.Build(seed)
  if plan then
   local instance
   for _,i in ipairs(plan.instances) do if i.archetype=='skeleton_blockade' or i.archetypeId=='skeleton_blockade' then instance=i end end
   if instance then
    assert(IsValid(instance.hostile) and IsValid(instance.barrier),'Natural skeleton selection did not create both native resources')
   -- F.Prove exercises all-closed approach, ordered keys/rescue and reservations.
    F.Prove(g,plan);built=built+1
   end
   assert(not R.Definitions.bribe_blockade)
  else blocked=blocked+1 end
end
assert(built>=5,'Priority skeletons lack naturally feasible production builds')
D:Cleanup('skeleton frequency gate')
print(string.format('SKELETON_FREQUENCY_PASS: baseline=%d/1280 updated=%d/1280 maxAbsences=%d fullCatalogBuilds=%d rejected=%d; exact d4, rare slot, unique types, no Bribe',totals.before,totals.after,maxDry,built,blocked))
