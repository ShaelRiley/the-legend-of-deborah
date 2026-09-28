local e=dofile('tools/music_test_fixture.lua');local check=e.check
CLIENT=true;LOD.SoldierMovement={Active=function(_,p) return p.soldier==true end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_player_options.lua')
local p={setting=0,held=false}
function p:GetInfoNum() return self.setting end
function p:KeyDown() return self.held end
function p:GetMoveType() return MOVETYPE_WALK end
function p:GetRunSpeed() return 200 end
function p:GetWalkSpeed() return 100 end
for _,setting in ipairs({0,1}) do for _,held in ipairs({false,true}) do
 p.setting=setting;p.held=held
 local initial=held and 200 or 100
 local m={max=initial*.33,client=initial*.33}
 function m:GetMaxSpeed() return self.max end;function m:SetMaxSpeed(v) self.max=v end
 function m:GetMaxClientSpeed() return self.client end;function m:SetMaxClientSpeed(v) self.client=v end
 LOD.PlayerOptions:ApplyMove(p,m)
 local sprint=setting==1 and not held or setting==0 and held
 check(LOD.PlayerOptions:WantsSprint(p)==sprint,'logical modifier inversion')
 check(math.abs(m.max-(sprint and 200 or 100)*.33)<.001,'crouch/other native restrictions preserved')
 check(p.held==held,'physical modifier unchanged for Shift+Use')
end end
p.soldier=true;check(not LOD.PlayerOptions:WantsSprint(p),'Soldiers gain no sprint')
print('PLAYER_OPTIONS PASS '..e.checks)
