local E, Run = assert(LOD.Equipment), assert(LOD.RunManager)

function E:UseResurrectionFeather(ply)
    if not self:CanAct(ply) or not self:IsActive(ply)
        or not Run.State.BuildReady or CurTime() < (self.NextUse[ply] or 0) then return false end
    local ps = Run:GetPlayerState(ply)
    if not ps or ps.eliminated or (ps.lives or 0) <= 0 then return false end
    if LOD.CampaignTimeout and LOD.CampaignTimeout:Expire() then return false end
    local state = self:Ensure(ps)
    local item, id = self:Equipped(state, "throwable")
    if not item or item.definitionId ~= "resurrection_feather" then return false end
    local targetId, target = LOD.LootDirector:_OldestEliminatedTeammate(Run:IdentityOf(ply))
    if not targetId then
        self:Report(ply, "FEATHER — no eligible Hero in the Hero Queue", "feather_failed")
        return false
    end
    local ok, disposition = Run:ReviveIdentity(targetId, function()
        return self:Consume(state, id)
    end)
    if not ok then return false end
    self.NextUse[ply] = CurTime() + self.UseCooldown
    self:Sync(ply)
    LOD.Audio:Emit(ply, "confirm")
    local name = target.characterName or "a teammate"
    self:Report(ply, "FEATHER — restored " .. name .. " with 1 life"
        .. (disposition == "waiting" and " — waiting for a Hero slot" or ""), "feather_revive")
    local teammate = Run:ConnectedPlayerForIdentity(targetId)
    if IsValid(teammate) then
        self:Report(teammate, "RESURRECTED — 1 life restored", "feather_restored")
    end
    return true
end

concommand.Add("lod_feather_testkit", function(ply)
    local dev = GetConVar("lod_developer_mode")
    if not dev or not dev:GetBool() or not IsValid(ply) or not ply:IsAdmin() or not E:CanAct(ply) then return end
    Run:MarkUnranked("feather_testkit")
    local state = E:Ensure(Run:GetPlayerState(ply))
    local count = state.items.resurrection_feather and state.items.resurrection_feather.count or 0
    if count < 3 then E:Grant(ply, "resurrection_feather", 3-count) end
    E:Equip(state, "resurrection_feather", "throwable")
    E:Activate(ply)
    E:Report(ply, "FEATHER TEST — LMB/RMB revives the oldest eligible queued Hero with 1 life.", "feather_testkit")
end)
