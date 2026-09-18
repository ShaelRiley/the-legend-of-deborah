-- Uses the existing swept projectile and shared damage/FX authorities.
local F=LOD.MagicForms
function F:InitWatermelon(ent)
    local rng=LOD.CombatRolls:_RNG('watermelon-bounces:'..tostring(ent.LODCastContext.castSerial))
    local count=rng:Int(1,6) -- count die; never an exploding damage die
    ent.LODMelon={limit=count,bounces=0,expires=CurTime()+self.Tuning.Watermelon.lifetime,lastHit={},riders={}}
    if LOD.RPGPresentation then
        LOD.RPGPresentation:Event(ent.LODCaster,'roll','WATERMELON — 1d6 = '..count..' bounces',
            {event='watermelon_bounces',sides=6,rolls={count},total=count,cast_serial=ent.LODCastContext.castSerial})
    end
end
function F:StepWatermelon(ent,dt,filter)
    local b,t=ent.LODMelon,self.Tuning.Watermelon
    local caster,run=ent.LODCaster,LOD.RunManager.State
    if not b or not IsValid(caster) or not caster:Alive() or caster:GetNW2Bool('LOD_Staged',false)
        or run.Failed or run.LevelCleared or run.SimulationFrozen then ent:Remove();return end
    if CurTime()>=b.expires or ent.LODTravelled>=ent.LODMaximumTravel then self:ProjectileImpact(ent);return end
    ent.LODVelocity=ent.LODVelocity+Vector(0,0,-t.gravity)*dt
    local remaining=dt
    for _=1,t.steps do
        if remaining<=0 then break end
        local origin=ent:GetPos()
        local tr=util.TraceHull({start=origin,endpos=origin+ent.LODVelocity*remaining,
            mins=Vector(-t.radius,-t.radius,-t.radius),maxs=Vector(t.radius,t.radius,t.radius),mask=MASK_SOLID,filter=filter})
        if tr.HitSky then ent:Remove();return end
        -- An embedded spawn has no legal area origin; do not damage through cover.
        if tr.StartSolid or tr.AllSolid then self:BroadcastFX('watermelon',ent.LODContentId,origin,origin,caster);ent:Remove();return end
        ent.LODTravelled=ent.LODTravelled+(tr.HitPos-origin):Length()
        ent:SetPos(tr.HitPos)
        if not tr.Hit then break end
        local normal=tr.HitNormal:GetNormalized()
        if normal:LengthSqr()<.5 then self:ProjectileImpact(ent,tr);return end
        -- Count only incoming contacts. Repeated zero-fraction callbacks on the
        -- same face cannot spend bounces or multiply damage while moving away.
        if ent.LODVelocity:Dot(normal)>=0 then
            ent:SetPos(tr.HitPos+normal*t.separation);break
        end
        b.bounces=b.bounces+1
        local target=tr.Entity
        if self:TargetIsOpponent(caster,target) and CurTime()>=(b.lastHit[target] or 0)
            and self:LineOfEffect(caster,target,origin) then
            b.lastHit[target]=CurTime()+t.hitDelay
            local form=table.Copy(LOD.RPG.MagicForms.watermelon);form.damageDice=1
            local content=LOD.RPG.MagicContents[ent.LODContentId]
            if content and b.riders[target] then content=table.Copy(content);content.rider=nil end
            local before=target:Health()
            self:_ApplyDamage(caster,caster,target,form,content,ent.LODCastContext,ent.LODVelocity:GetNormalized())
            if not IsValid(target) or target:Health()<before then b.riders[target]=true end
        end
        if b.bounces>=b.limit then self:ProjectileImpact(ent,tr);return end
        self:BroadcastFX('watermelon_bounce',ent.LODContentId,origin,tr.HitPos,caster)
        local velocity=ent.LODVelocity-normal*(2*ent.LODVelocity:Dot(normal))
        velocity=velocity*t.restitution
        if normal.z>.65 then velocity.z=math.max(t.minLift,velocity.z) end
        ent.LODVelocity=velocity;ent.LODDirection=velocity:GetNormalized()
        ent:SetPos(tr.HitPos+normal*t.separation)
        remaining=remaining*(1-math.Clamp(tr.Fraction or 0,0,1))
    end
    ent:NextThink(CurTime());return true
end
