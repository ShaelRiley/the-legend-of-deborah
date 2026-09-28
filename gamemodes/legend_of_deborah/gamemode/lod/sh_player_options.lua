LOD.PlayerOptions=LOD.PlayerOptions or {}
local O=LOD.PlayerOptions
local function alwaysRun(p) return p.GetInfoNum and p:GetInfoNum("lod_always_run",0)~=0 end
if CLIENT then O.AlwaysRun=CreateClientConVar("lod_always_run","0",true,true,"Run normally; hold your sprint key to walk",0,1) end
function O:WantsSprint(p)
    local held=p:KeyDown(IN_SPEED)
    if LOD.SoldierMovement and LOD.SoldierMovement:Active(p) then return false end
    if alwaysRun(p) then return not held end
    return held
end
function O:ApplyMove(p,m)
    if not alwaysRun(p) or p:GetMoveType()~=MOVETYPE_WALK
        or LOD.SoldierMovement and LOD.SoldierMovement:Active(p) then return end
    local held=p:KeyDown(IN_SPEED)
    local from=held and p:GetRunSpeed() or p:GetWalkSpeed()
    local to=held and p:GetWalkSpeed() or p:GetRunSpeed()
    if from<=0 or to<=0 then return end
    -- Change only the locomotion cap, before existing status/feat restrictions.
    -- Leave IN_SPEED untouched: Shift+Use and every other modifier still work.
    m:SetMaxSpeed(m:GetMaxSpeed()*to/from)
    m:SetMaxClientSpeed(m:GetMaxClientSpeed()*to/from)
end
