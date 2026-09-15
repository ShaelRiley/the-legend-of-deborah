local C,Run,E,Store=LOD.CryptoDirector,LOD.RunManager,LOD.Equipment,LOD.CryptoStore
local function weak() return setmetatable({}, {__mode='k'}) end
C.Damage=weak();C.PendingDeath=weak()
local function sourceOf(target,info)
    local pending=target.LODPendingDamageAttribution
    local source=pending and pending.attacker or info:GetAttacker()
    if IsValid(source) and source.LODSummonedSeeker then source=source.LODCaster end
    return source
end
function C:ReconcileWounds(ply)
    local id=self:Account(ply);if not id then return nil end
    local s=self:LevelState();local w=s.wounds[id] or {amount=0,hp=ply:Health()}
    -- Unattributed healing (regen, self-potion, Tetris) removes debt but earns
    -- no contribution. Reconcile before every damage/heal, not in a Think loop.
    w.amount=math.max(0,w.amount-math.max(0,ply:Health()-w.hp));w.hp=ply:Health()
    s.wounds[id]=w;return w
end
function C:BeginDamage(target,info,before)
    if not self:Ranked() or Run.State.LevelCleared or not IsValid(target) then return end
    local source=sourceOf(target,info)
    if not IsValid(source) or source==target then return end
    local heroTarget=target:IsPlayer() and not Run:IsSoldierControl(target) and Run:IsActivePlayer(target)
    if heroTarget then self:ReconcileWounds(target) end
    local hostile=LOD.FactionManager:IsEnemyCombatant(source)
    local enemyTarget=LOD.FactionManager:IsEnemyCombatant(target)
    local id=self:Account(source)
    if id then self:Participate(source) end
    local row={run=Run.State,level=Run.State.Level,target=target,source=source,id=id,before=before,
        heroTarget=heroTarget,hostile=hostile,enemyTarget=enemyTarget,soldier=id and Run:IsSoldierControl(source)}
    self.Damage[info]=row
    if heroTarget then self.PendingDeath[target]=row end
end
function C:FinishDamage(row,taken)
    if not row or row.done or row.run~=Run.State or row.level~=Run.State.Level then return end
    row.done=true
    if self.PendingDeath[row.target]==row and row.target:Health()>0 then self.PendingDeath[row.target]=nil end
    if not taken or not self:Ranked() then return end
    local damage=math.min(math.max(0,row.before),math.max(0,row.before-row.target:Health()))
    if damage<=0 then return end
    local s=self:LevelState()
    if row.id and not row.soldier and row.enemyTarget and s.heroes[row.id]~=nil then
        s.heroes[row.id]=s.heroes[row.id]+damage
    end
    if row.heroTarget then
        local victim=self:Account(row.target)
        if victim then
            local w=s.wounds[victim] or {amount=0}
            if row.hostile then w.amount=w.amount+damage end
            w.hp=row.target:Health();s.wounds[victim]=w
            if row.soldier then
                local credits=s.damageToHeroes[victim] or {};s.damageToHeroes[victim]=credits
                credits[row.id]=(credits[row.id] or 0)+damage
            end
        end
    end
end
function C:HeroLifeConsumed(ply,attacker)
    if not self:Ranked() then return end
    local id=self:Account(ply);if not id then return end
    local row=self.PendingDeath[ply]
    self:FinishDamage(row,true)
    self.PendingDeath[ply]=nil
    local s=self:LevelState();local credits=s.damageToHeroes[id] or {}
    s.damageToHeroes[id]=nil;s.wounds[id]=nil
    -- A self/admin death cannot cash a prior incidental Soldier hit.
    if attacker==ply or not row or row.level~=Run.State.Level or row.run~=Run.State
        or row.before<=0 or row.target:Health()>0 then return end
    local total=0;for _,amount in pairs(credits) do total=total+amount end
    if total<=0 then return end
    s.eliminations=s.eliminations+1
    for soldier,amount in pairs(credits) do s.soldiers[soldier]=(s.soldiers[soldier] or 0)+amount/total end
    for _,p in ipairs(player.GetAll()) do if s.soldiers[self:Account(p)] then self:Sync(p) end end
end
local damage=GM.EntityTakeDamage
function GM:EntityTakeDamage(target,info)
    local before=IsValid(target) and target:Health() or 0
    local result=damage(self,target,info)
    if result~=true then C:BeginDamage(target,info,before) end
    return result
end
hook.Add('PostEntityTakeDamage','LOD_CryptoEffectiveDamage',function(target,info,taken)
    local row=C.Damage[info]
    if row and row.target==target then C:FinishDamage(row,taken);C.Damage[info]=nil end
end)
local heal=E.Heal
function E:Heal(source,target,amount)
    local eligible=C:Ranked() and C:Account(target) and not Run:IsSoldierControl(target)
    local w=eligible and C:ReconcileWounds(target)
    local before=IsValid(target) and target:Health() or 0
    local ok=heal(self,source,target,amount)
    if w and IsValid(target) then
        local restored=math.max(0,target:Health()-before)
        local credit=math.min(w.amount,restored)
        w.amount=math.max(0,w.amount-restored);w.hp=target:Health()
        local id=C:Account(source)
        if id and source~=target and not Run:IsSoldierControl(source) and Run:IsActivePlayer(source) then
            C:Participate(source)
            local s=C:LevelState();s.heroes[id]=(s.heroes[id] or 0)+credit
        end
    end
    return ok
end
local advance=LOD.CharacterProgressionSystem.AdvanceHeroToLevel
function LOD.CharacterProgressionSystem:AdvanceHeroToLevel(ply,level)
    local ok,err=advance(self,ply,level)
    if ok then C:CheckMilestones(ply) end
    return ok,err
end
local attach=LOD.SoldierProgression.Attach
function LOD.SoldierProgression:Attach(ply,...)
    local state,err=attach(self,ply,...)
    if state then C:Participate(ply) end
    return state,err
end
local deploy=LOD.StagingDeployment._ExecuteDeploymentTransition
function LOD.StagingDeployment:_ExecuteDeploymentTransition(ply,...)
    local result=deploy(self,ply,...)
    C:Participate(ply);C:CheckMilestones(ply)
    return result
end
hook.Add('PlayerSpawn','LOD_CryptoSpawn',function(ply)
    C.PendingDeath[ply]=nil
    timer.Simple(0,function()
        if not IsValid(ply) then return end
        if C:Ranked() then C:ReconcileWounds(ply) end
        C:Participate(ply);C:CheckMilestones(ply);C:Sync(ply)
    end)
end)
hook.Add('PlayerDisconnected','LOD_CryptoDisconnect',function(ply) C.PendingDeath[ply]=nil end)
-- Preserve a failed rescue settlement until the existing advancement loop retries
-- it. One DB attempt per second; never silently advance past an unpaid rescue.
local complete=Run.CompleteLevel
function Run:CompleteLevel(ply)
    for _,p in ipairs(player.GetAll()) do C:Participate(p) end
    local ok=complete(self,ply)
    if ok and C:Ranked() then C:Settle() end
    return ok
end
local nextLevel=Run.AdvanceLevel
function Run:AdvanceLevel()
    if C:Ranked() and self.State.LevelCleared then
        local s=C:LevelState()
        if not s.settled then
            if CurTime()<(s.nextRetry or 0) then return false end
            s.nextRetry=CurTime()+1
            C:Settle()
            if not s.settled then return false end
        end
    end
    return nextLevel(self)
end
