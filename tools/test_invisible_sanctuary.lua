local oldArg=arg[1];arg[1]='--runtime'
local H=dofile('tools/test_bestiary_b29.lua');arg[1]=oldArg
local S,g,N=H.S,H.graph,LOD.MazeNavigator
local a=H.actor('sanctuary-test',1)
local enemy=H.actor('sanctuary-enemy',4,true)
a:SetPos(N:CellCenter(g.Start)+Vector(0,0,12))
local notes={}
LOD.RPGPresentation={CombatEvent=function(_,target,source,family,text,fields)
    notes[#notes+1]={target,source,family,text,fields}
end}
local function info(source,amount)
    return {GetAttacker=function() return source end,GetDamage=function(i) return i.amount end,
        SetDamage=function(i,n) i.amount=n end,SetDamageForce=function() end,amount=amount}
end
local incoming=info(enemy,10);assert(S:DamageGate(a,incoming) and incoming.amount==0 and #notes==1)
local outgoing=info(a,10);assert(S:DamageGate(enemy,outgoing) and outgoing.amount==0 and #notes==2)
local proxy={valid=true,owner=a,IsPlayer=function() return false end,GetOwner=function(e) return e.owner end}
assert(S:DamageGate(enemy,info(proxy,10)) and #notes==3)
assert(S:DamageGate(a,info(enemy,0)) and #notes==3,'zero native damage spam')
for _=1,100 do assert(not S:CombatAllowed(a,enemy)) end
assert(#notes==3,'spatial/acquisition queries emitted notes')
for _,note in ipairs(notes) do
    assert(note[3]=='sanctuary' and note[4]=='Combat is nullified in the sanctuary zone.')
    assert(note[5].event=='sanctuary_combat_nullified')
end
local callbacks={}
IN_ATTACK=1
hook.Add=function(event,id,fn) callbacks[event..'/'..id]=fn end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_entry_safety.lua')
local press=assert(callbacks['KeyPress/LOD_EntrySanctuaryAttackNotice'])
press(a,2);assert(#notes==3,'nonattack input logged combat')
press(a,IN_ATTACK);assert(#notes==4,'early primary-attack refusal had no note')
press(enemy,IN_ATTACK);assert(#notes==4,'attack outside sanctuary got a note')
local removed={}
hook={Remove=function(event,id) removed[event..'/'..id]=true end,
    Add=function() error('invisible sanctuary registered a visual hook') end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_entry_safety.lua')
assert(removed['PostDrawTranslucentRenderables/LOD_EntrySanctuaryBoundary'])
assert(removed['HUDPaint/LOD_EntrySanctuaryCaption'])
print('INVISIBLE_SANCTUARY_PASS: incoming/outgoing/proxy damage nullified; exact logger notes; no zero/query spam; old visual hooks removed')
