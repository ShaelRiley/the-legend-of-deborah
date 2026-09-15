-- Production generation, damage and rendering; Source boundaries are mocked.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
-- Restore the real element RNG delegate after the equipment fixture's scripted saves.
dofile(root..'sv_rpg_status_elements.lua')
dofile(root..'sv_character_progression.lua')
dofile(root..'sv_human_soldier_progression.lua')
local CPS,RPG,Status=LOD.CharacterProgressionSystem,LOD.RPG,LOD.RPGStatusElements
local count,seen=0,{}
for seed=1,12000 do
    local state,replay={},{}
    CPS:AssignMonsterElement(state,seed);CPS:AssignMonsterElement(replay,seed)
    assert(state.currentElement==replay.currentElement,'seed replay')
    local element=state.currentElement
    CPS:AssignMonsterElement(state,seed+100000)
    assert(state.currentElement==element,'typed AND untyped incarnations cannot reroll')
    if element then
        count=count+1;seen[element]=(seen[element] or 0)+1
        assert(state.elementalWeaknesses[1]==RPG.ElementOpposites[element])
    end
end
assert(count>3700 and count<4300,'one-third distribution: '..count)
for _,element in ipairs(RPG.Elements) do assert((seen[element] or 0)>530,'all six types reachable') end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
for seed=1,60 do
    local rolled=CPS:GenerateMonsterProgression('soldier',seed,6,35,'ai')
    local soldier=CPS:GenerateMonsterProgression('soldier',seed,6,35,'human_soldier')
    assert(rolled.currentElement==soldier.currentElement and rolled.classId==soldier.classId)
    local assign=CPS.AssignMonsterElement;CPS.AssignMonsterElement=function() end
    local baseline=CPS:GenerateMonsterProgression('soldier',seed,6,35,'ai')
    CPS.AssignMonsterElement=assign
    rolled.currentElement=nil;rolled.elementalWeaknesses={};rolled.monsterElementAssigned=nil
    assert(same(rolled,baseline),'affinity does not perturb existing progression rolls')
end
local target=env.actor('elemental',true)
for _,element in ipairs(RPG.Elements) do
    target.LODProgressionState.currentElement=element
    target.LODProgressionState.elementalWeaknesses={} -- opposition derives from identity too
    for _,attack in ipairs(RPG.Elements) do
        for index=1,8 do
            local amount,result=Status:ResolveElementDamage(100,nil,target,{element=attack},
                {Int=function() return index end})
            local expected=attack==element and 'resistance'
                or attack==RPG.ElementOpposites[element] and 'weakness' or 'neutral'
            assert(result.kind==expected,element..' vs '..attack)
            local multiplier=expected=='resistance' and 1-index*.11
                or expected=='weakness' and 1+index*.11 or 1
            assert(math.abs(amount-100*multiplier)<.00001)
        end
    end
    assert(Status:ResolveElementDamage(100,nil,target,{element='raw'})==100)
end
target.LODProgressionState=nil;target.LODArchetypeId='soldier'
local attached=CPS:AttachMonsterProgression(target,7,6)
assert(attached and target.nw.LOD_MonsterClass==attached.classId)
assert(target.nw.LOD_MonsterElement==(attached.currentElement or ''))
assert(CPS:AttachMonsterProgression(target,8,6)==attached,'duplicate admission preserves identity')
target.nw.LOD_MonsterElement='fire';env.hooks.LOD_MonsterAuraRetire(target)
assert(target.nw.LOD_MonsterElement=='','corpse aura retired')
local ply=env.actor('controller');local hero=ply.LODProgressionState
local soldier=LOD.SoldierProgression:Attach(ply,7,35,6)
assert(ply.nw.LOD_MonsterClass==soldier.classId)
assert(LOD.SoldierProgression:Attach(ply,8,35,6)==soldier)
assert(LOD.SoldierProgression:Retire(ply))
assert(ply.nw.LOD_MonsterClass=='' and ply.nw.LOD_MonsterElement=='')
assert(ply.LODProgressionState==hero and hero.currentElement==nil,'Hero identity stays isolated')

-- Render actual presentation functions with finite geometry counters.
local hooks={};hook.Add=function(_,id,fn) hooks[id]=fn end
CreateMaterial=function(_,_,parameters) assert(parameters['$ignorez']=='0');return {} end
Material=function() return {} end
local modulation={.8,.7,.6};local sprites,labels=0,0
render={GetColorModulation=function() return table.unpack(modulation) end,
    SetColorModulation=function(r,g,b) modulation={r,g,b} end,
    SetMaterial=function() end,DrawSprite=function() sprites=sprites+1 end}
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
EyePos=function() return Vector() end
local low=false;GetConVar=function() return {GetBool=function() return low end} end
LOD.MagicArea={Colors={fire=Color(255,80,20)}}
local now=100;CurTime=function() return now end
scripted_ents={GetStored=function() end}
dofile(root..'cl_watcher_polish.lua')
dofile(root..'cl_monster_identity.lua')
local M=LOD.MonsterIdentity
function target:GetNW2String(k,default) return self.nw[k] or default end
function target:GetNoDraw() return self.hidden==true end
function target:GetModel() return self.model or 'models/zombie/classic.mdl' end
function target:WorldSpaceCenter() return Vector(0,0,40) end
function target:DrawModel() self.drawModulation={table.unpack(modulation)} end
for _,class in ipairs({'fighter','rogue','wizard'}) do
    target.nw.LOD_MonsterClass=class;M:DrawBody(target)
    assert(same(modulation,{.8,.7,.6}),'render state restored')
    local c=M.Tints[class]
    assert(same(target.drawModulation,{.8*c[1],.7*c[2],.6*c[3]}),'archetype modulation composed')
end
target.nw.LOD_MonsterElement='fire';M:DrawAura(target,1);assert(sprites==3)
low=true;sprites=0;M:DrawAura(target,1);assert(sprites==2)
target.hidden=true;sprites=0;M:DrawAura(target,1);assert(sprites==0);target.hidden=false
EyePos=function() return Vector(2000,0,0) end
M:DrawAura(target,1);assert(sprites==0);EyePos=function() return Vector() end
target.nw.LOD_MonsterElement='';M:DrawAura(target,1);assert(sprites==0)
target.nw.LOD_MonsterElement='fire'
target.model='models/combine_scanner.mdl';target.nw.LOD_Archetype='watcher'
target.nw.LOD_Watcher=true;target.nw.LOD_WatcherInvisibleUntil=110
M:DrawAura(target,1);assert(sprites==0,'cloaked aura hidden')
function ply:GetEyeTrace() return {Entity=target} end
LocalPlayer=function() return ply end
ScrW=function() return 1280 end;ScrH=function() return 720 end
draw={SimpleTextOutlined=function(text) labels=labels+1;assert(text:find('WEAK TO ICE',1,true)) end}
LOD.UI={}
hooks.LOD_MonsterElementCaption();assert(labels==0,'cloaked aimed text hidden')
now=111;hooks.LOD_MonsterElementCaption();assert(labels==1)
LOD.UI.ActivePage='equipment';hooks.LOD_MonsterElementCaption();assert(labels==1)
ply.GetNW2String=target.GetNW2String;ply.GetNoDraw=target.GetNoDraw
ply.WorldSpaceCenter=target.WorldSpaceCenter;ply.GetModel=target.GetModel
ply.nw.LOD_IsSoldier=true;ply.nw.LOD_MonsterClass='rogue';ply.nw.LOD_MonsterElement='fire'
hooks.LOD_SoldierClassTint(ply);assert(modulation[1]==.8*.86)
hooks.LOD_SoldierClassTintReset(ply);assert(same(modulation,{.8,.7,.6}))
ply.nw.LOD_IsSoldier=false;sprites=0
hooks.LOD_SoldierClassTint(ply);hooks.LOD_SoldierClassTintReset(ply)
assert(same(modulation,{.8,.7,.6}) and sprites==0,'Hero presentation isolated')
print('MONSTER_IDENTITY_PASS: '..count..'/12000 typed; seed isolation, six-type matrix, incarnation lifecycle, tint restoration, cloak and bounded aura')
