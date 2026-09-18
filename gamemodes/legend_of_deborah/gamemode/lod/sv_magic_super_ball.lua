-- Swept, server-owned ricochets. The stock sent_ball sprite/sound is cosmetic;
-- no edible sandbox ball, native physics callbacks or independent damage path.
local F=LOD.MagicForms
function F:SuperBallCount(caster)
    local count=0
    for ent,owner in pairs(self.ActiveSuperBalls) do
        if not IsValid(ent) then self.ActiveSuperBalls[ent]=nil
        elseif owner==caster then count=count+1 end
    end
    return count
end
function F:SyncSuperBalls(caster)
    if IsValid(caster) then caster:SetNW2Int('LOD_SuperBallRemaining',math.max(0,self.Tuning.SuperBall.maxActive-self:SuperBallCount(caster))) end
end
function F:InitSuperBall(ent)
    local t=self.Tuning.SuperBall
    ent.LODBall={expires=CurTime()+t.lifetime,bounces=0,hits=0,lastHit={},riders={},nextSound=0,
        rng=LOD.RNG.New(LOD.Seeds.Derive(ent.LODLevelSeed or 1,'super_ball:'..ent.LODCaster:EntIndex()..':'..ent.LODCastContext.castSerial))}
    self.ActiveSuperBalls[ent]=ent.LODCaster
    self:SyncSuperBalls(ent.LODCaster)
end
function F:RetireSuperBall(ent)
    local caster=self.ActiveSuperBalls[ent]
    self.ActiveSuperBalls[ent]=nil;ent.LODBall=nil
    if caster then self:SyncSuperBalls(caster) end
end
function F:StepSuperBall(ent,dt,filter)
    local b,t=ent.LODBall,self.Tuning.SuperBall
    local run=LOD.RunManager and LOD.RunManager.State
    local caster=ent.LODCaster
    if not b or CurTime()>=b.expires or not IsValid(caster) or not caster:Alive()
        or caster:GetNW2Bool('LOD_Staged',false) or run and (run.Failed or run.LevelCleared or run.SimulationFrozen)
        or b.bounces>=t.bounces or b.hits>=t.hits then ent:Remove();return end
    ent.LODVelocity=ent.LODVelocity+Vector(0,0,-t.gravity)*dt
    local remaining=dt
    for _=1,t.steps do
        if remaining<=0 then break end
        local origin=ent:GetPos()
        local tr=util.TraceHull({start=origin,endpos=origin+ent.LODVelocity*remaining,
            mins=Vector(-t.radius,-t.radius,-t.radius),maxs=Vector(t.radius,t.radius,t.radius),mask=MASK_SOLID,filter=filter})
        if tr.StartSolid or tr.AllSolid or tr.HitSky then ent:Remove();return end
        ent:SetPos(tr.HitPos)
        if not tr.Hit then break end
        b.bounces=b.bounces+1
        local target=tr.Entity
        if IsValid(target) and CurTime()>=(b.lastHit[target] or 0)
            and self:SuperBallHit(ent,target,origin,b.riders[target]) then
            b.lastHit[target]=CurTime()+t.perTargetDelay;b.hits=b.hits+1
            -- One Content rider attempt per damaged target per committed cast.
            if ent.LODBallLastDamaged then b.riders[target]=true end
        end
        if b.bounces>=t.bounces or b.hits>=t.hits then ent:Remove();return end
        local normal=tr.HitNormal:GetNormalized()
        if normal:LengthSqr()<.5 then ent:Remove();return end
        local direction=ent.LODVelocity:GetNormalized()
        local reflected=direction-normal*(2*direction:Dot(normal))
        local jitter=Vector(b.rng:Int(-100,100),b.rng:Int(-100,100),b.rng:Int(-100,100))*(t.jitter/100)
        local outgoing=(reflected+jitter):GetNormalized()
        -- Chaos never sends the ball back into the surface it just struck.
        if outgoing:Dot(normal)<.15 then outgoing=(outgoing+normal*(.15-outgoing:Dot(normal))):GetNormalized() end
        ent.LODVelocity=outgoing*t.speed;ent.LODDirection=outgoing
        ent:SetPos(tr.HitPos+normal*t.separation)
        remaining=remaining*(1-math.Clamp(tr.Fraction or 0,0,1))
        if CurTime()>=b.nextSound then
            b.nextSound=CurTime()+.12
            ent:EmitSound('garrysmod/balloon_pop_cute.wav',65,120+b.bounces%19,.35)
        end
    end
    -- Unconsumed distance in a cramped corner is discarded, never teleported.
    ent:NextThink(CurTime());return true
end
local function clear(caster)
    for ent,owner in pairs(F.ActiveSuperBalls) do
        if not caster or owner==caster then
            if IsValid(ent) then ent:Remove() end
            F:RetireSuperBall(ent)
        end
    end
end
hook.Add('PlayerDisconnected','LOD_SuperBallDisconnect',clear)
hook.Add('PlayerDeath','LOD_SuperBallDeath',function(ply) clear(ply) end)
hook.Add('PreCleanupMap','LOD_SuperBallCleanup',function() clear() end)
hook.Add('ShutDown','LOD_SuperBallShutdown',function() clear() end)
