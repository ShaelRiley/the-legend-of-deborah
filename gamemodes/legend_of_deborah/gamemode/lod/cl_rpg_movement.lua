-- Mirror the server-resolved locomotion multiplier for client prediction.
-- No client ownership/cost decisions: the server still resolves every move.
hook.Add("SetupMove","LOD_PredictedVoluntarySpeed",function(ply,move)
    if ply~=LocalPlayer() or not ply:Alive() then return end
    if LOD.PlayerOptions then LOD.PlayerOptions:ApplyMove(ply,move) end
    local soldier=LOD.SoldierMovement
    local rooted=soldier and soldier:PrepareMove(ply,move)
    local multiplier=ply:GetNW2Float("LOD_VoluntaryMovementMultiplier",1)
    move:SetForwardSpeed(move:GetForwardSpeed()*multiplier)
    move:SetSideSpeed(move:GetSideSpeed()*multiplier)
    move:SetMaxClientSpeed(move:GetMaxClientSpeed()*multiplier)
    move:SetMaxSpeed(move:GetMaxSpeed()*multiplier)
    move:SetMaxSpeed(math.min(520,move:GetMaxSpeed()))
    move:SetMaxClientSpeed(math.min(520,move:GetMaxClientSpeed()))
    local F=LOD.FeatMovement
    if not rooted and F and ply:GetMoveType()==MOVETYPE_WALK and ply:WaterLevel()<2
        and not ply:InVehicle() and not ply:IsFrozen() then
        local ground=ply:OnGround()
        local back=ply:GetNW2Float("LOD_BackpedalMovementMultiplier",1)
        if ground and not move:KeyDown(IN_JUMP) and move:GetForwardSpeed()<0 and back>1 then F.Scale(move,back) end
        local bonus=ply:GetNW2Float(ground and "LOD_HasteMovementMultiplier" or "LOD_SpringHeelAirMultiplier",1)
        if bonus>1 then F.Scale(move,bonus) end
        local strafe=ply:GetNW2Float("LOD_StrafeSpeedMultiplier",1)
        if strafe>1 and move:GetSideSpeed()~=0 then F.Strafe(move,strafe) end
    end
    if rooted then soldier:ApplyRoot(ply,move) end
end)
