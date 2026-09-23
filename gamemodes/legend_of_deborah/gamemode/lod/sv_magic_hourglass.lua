-- LOD-HOURGLASS-001: finite item transaction through the existing shared clock.
local E,Run,Rolls=assert(LOD.Equipment),assert(LOD.RunManager),assert(LOD.CombatRolls)

function E:HourglassSourceValid(ply,context)
    local weapon=context and context.weapon
    if not IsValid(ply) or not IsValid(weapon) or weapon:GetOwner()~=ply or ply:GetActiveWeapon()~=weapon
        or weapon:GetClass()~=self.WeaponClass or not self:MoveAttackValid(ply,context) then return false end
    local ps=context.moveBinding.session.ps
    return ps.deploymentComplete and not ps.eliminated and (ps.lives or 0)>0
        and context.moveBinding.source.definitionId=="magic_hourglass"
        and CurTime()>=(self.NextUse[ply] or 0)
end

function E:UseMagicHourglass(ply)
    if not self:CanAct(ply) or not self:IsActive(ply) then return false end
    local binding=self:BindMoveSource(ply,{family="magic_hourglass"})
    if not binding then return false end
    local context={moveBinding=binding,weapon=ply:GetActiveWeapon()}
    if not self:HourglassSourceValid(ply,context) then return false end
    local clock=LOD.CampaignTimeout
    if not clock then return false end
    local first,second
    local ok=clock:TryExtend(clock:ExtensionBinding(),function()
        if not self:HourglassSourceValid(ply,context) or not self:Consume(binding.state,binding.itemId) then return nil end
        self.NextUse[ply]=CurTime()+self.UseCooldown
        -- Utility dice never enter damage, exploding dice, Boom or ability scaling.
        local rng=Rolls:_RNG("magic-hourglass")
        first,second=rng:Int(1,4),rng:Int(1,4)
        return (first+second)*60
    end)
    if not ok then
        self:Report(ply,"HOURGLASS — requires a live dungeon clock; no item spent","hourglass_rejected")
        return false
    end
    self:Sync(ply)
    LOD.Audio:Emit(ply,"confirm")
    Rolls:_Send(ply,3,string.format("MAGIC HOURGLASS — 2d4 [%d + %d]: +%d minutes for the party",first,second,first+second),
        "resource",{event="hourglass_use",first=first,second=second,minutes=first+second,seconds=(first+second)*60})
    return true
end

concommand.Add("lod_hourglass_testkit",function(ply)
    local dev=GetConVar("lod_developer_mode")
    if not dev or not dev:GetBool() or not IsValid(ply) or not ply:IsAdmin() or not E:CanAct(ply) then return end
    Run:MarkUnranked("hourglass_testkit")
    local state=E:Ensure(Run:GetPlayerState(ply))
    local count=state.items.magic_hourglass and state.items.magic_hourglass.count or 0
    if count<3 then E:Grant(ply,"magic_hourglass",3-count) end
    E:Equip(state,"magic_hourglass","throwable");E:Activate(ply)
    E:Report(ply,"HOURGLASS TEST — LMB/RMB: spend one for 2d4 party minutes. Compare both HUD clocks and Die Log. Run unranked.","hourglass_testkit")
end)
