-- Exercise the actual receiver: direct DirectionToken tests miss network batching.
local env=dofile('tools/test_equipment_moves.lua')
local E,p,state=LOD.Equipment,env.player,env.state
assert(E:Equip(state,'boots','feet'))
p.ps.magic=100
local packet,reads=0,0
net.ReadUInt=function(bits) assert(bits==3);reads=reads+1;return packet end
local receive=assert(env.receivers.LOD_SpecialMoveToken)
local function send(token,bits) packet=token;receive(bits or 3,p) end
-- Three separately pressed/released keys can arrive together; they remain ordered.
send(1);send(1);send(1)
assert(p.ps.magic==90,'Three valid UP packets in one server tick must execute Quickstep exactly once')
-- Packet framing does not grant an extra attack or bypass the same cooldown.
send(1);send(1);send(1);assert(p.ps.magic==90,'One cooldown/resource debit')
LOD.RPGAbilityRules:StopVoluntaryDash(p)
for _,bits in ipairs({3,8,9,16}) do
    env.advance(3);send(0);p.ps.magic=100
    send(1,bits);send(1,bits);send(1,bits)
    assert(p.ps.magic==90,'Bounded framing '..bits)
    LOD.RPGAbilityRules:StopVoluntaryDash(p)
end
for _,bits in ipairs({0,1,2,17,65535}) do
    env.advance(3);send(0);send(1);send(1);local before=reads
    send(1,bits);assert(reads==before,'Malformed length must not read')
    send(1);assert(p.ps.magic==90 and #E:MoveSession(p).tokens==1,'Malformed length cancels partial input')
end
for _,token in ipairs({5,6,7}) do
    env.advance(3);send(0);send(1);send(1);send(token);send(1)
    assert(#E:MoveSession(p).tokens==1,'Reserved token cancels partial input')
end
-- Eight-key burst cap, bounded recovery, reset cannot replenish the limiter.
env.advance(3);send(0);send(1);send(1)
for _=1,100 do send(0) end
send(1);assert(#E:MoveSession(p).tokens==0,'Reset spam cannot manufacture credits or splice a recipe')
env.advance(.1);p.ps.magic=100;send(1);send(1);send(1)
assert(p.ps.magic==90,'Ordinary input recovers after bounded refill')
LOD.RPGAbilityRules:StopVoluntaryDash(p)
for _,mode in ipairs({'insufficient','throwable','soldier','dead','unowned'}) do
    env.advance(3);send(0);p.ps.magic=mode=='insufficient' and 9 or 100
    p.throwable=mode=='throwable';p.soldier=mode=='soldier';p.alive=mode~='dead'
    if mode=='unowned' then E:Unequip(state,'feet') end
    local magic=p.ps.magic;send(1);send(1);send(1)
    assert(p.ps.magic==magic and not LOD.RPGAbilityRules.VoluntaryDashes[p],mode)
    p.throwable=false;p.soldier=false;p.alive=true;E:Equip(state,'boots','feet')
end
-- Cold reset does not create an equipment session for an inactive actor.
E:ClearTransient(p);env.advance(3);send(0);assert(not E.MoveSessions[p])
print('EQUIPMENT_TRANSPORT_PASS: batched/padded recipes, one debit/cooldown, bounded overload/reset/refill, malformed input and inactive ownership/resource guards')
