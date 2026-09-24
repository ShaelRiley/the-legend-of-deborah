-- LOD-WAND-001. Native weapon delivery; shared item, class, Beam and rider authorities.
local E,Rules,Forms=assert(LOD.Equipment),assert(LOD.RPGAbilityRules),assert(LOD.MagicForms)
local Rolls,Status=assert(LOD.CombatRolls),assert(LOD.RPGStatusElements)
local family="weapon_lod_wand"

function Rules:TryArcaneItemUse(actor)
    local derived=self:Derived(actor) or {}
    local threshold=math.Clamp(math.floor((derived.arcaneItemUseChance or 0)*100+.5),0,100)
    if threshold==0 then return false,nil,0 end
    if threshold==100 then return true,nil,100 end
    -- Utility dice deliberately bypass RollActorDamage and all Boom modifiers.
    local roll=Rolls:_RNG("arcane-item-use"):Int(1,100)
    local success=roll<=threshold
    Rolls:_Send(actor,3,string.format("ARCANE ITEM — d100 %d / need ≤%d: %s",roll,threshold,success and "SUCCESS" or "FAILED"),
        "magic",{event="arcane_item_use",roll=roll,threshold=threshold,success=success})
    return success,roll,threshold
end

function E:WandSourceValid(ply,weapon,context)
    return IsValid(ply) and IsValid(weapon) and weapon:GetOwner()==ply and ply:GetActiveWeapon()==weapon
        and weapon:GetClass()==family and self:MoveAttackValid(ply,context)
        and LOD.RunManager.State.BuildReady
end

function E:FireWand(ply,weapon)
    if not self:CanAct(ply) or not IsValid(weapon) or weapon:GetClass()~=family
        or weapon:GetOwner()~=ply or ply:GetActiveWeapon()~=weapon then return false end
    local binding=self:BindMoveSource(ply,{family=family})
    if not binding then return false end
    local context={moveBinding=binding}
    if not self:WandSourceValid(ply,weapon,context) then return false end
    -- A current native attack attempt reveals even if class/status/charges deny it.
    if self.EndCloak then self:EndCloak(ply,"Wand attempt") end
    if self.EndStatue then self.StatueInputAt[ply]=CurTime();self:EndStatue(ply,"Wand attempt") end
    local item,session=binding.source,binding.session
    local def=self.Definitions[family]
    if CurTime()<(session.cooldowns.wand or 0) then return false end
    if not Status:CanInitiateMagic(ply) or not Status:CanInitiateAttack(ply) then return false end
    local derived=Rules:Derived(ply) or {}
    if not derived.canActivateWandsScrolls or (derived.arcaneItemUseChance or 0)<=0 then
        self:Report(ply,"Wand — this class cannot activate arcane items","wand_class");return false
    end
    if not self:ValidateWearable(item) or item.charges<=0 then
        self:Report(ply,"Wand — no charges remaining; cannot reload","wand_empty");return false
    end
    if ply:GetAimVector():LengthSqr()<.000001 then return false end
    local form=table.Copy(LOD.RPG.MagicForms.beam)
    form.damageDice=3 -- current charged-weapon contract; ordinary Spellbook is untouched
    local snapshot=self:CaptureAttack(ply,family)
    local content=table.Copy(LOD.RPG.MagicContents[snapshot.element])
    if not content then return false end
    content.rider=nil -- shared procedural weapon riders supply this item's status chances
    context=Forms:_NewContext(ply,form,content)
    context.moveBinding=binding;context.wand=true;context.equipmentSnapshot=snapshot
    context.sourceValid=function() return E:WandSourceValid(ply,weapon,context) end
    if not context.sourceValid() then return false end
    -- Single synchronous commit. Charges belong to this exact record through restores/swaps.
    item.charges=item.charges-1
    session.cooldowns.wand=CurTime()+def.cooldown
    local success=Rules:TryArcaneItemUse(ply)
    self:Sync(ply)
    self:Report(ply,string.format("Wand — %s · %d/%d charges · 0 Magic",success and "BEAM" or "FAILED USE",item.charges,def.maxCharges),"wand_use")
    if not success or not context.sourceValid() then return false end
    context.castSerial=Forms:_NextCastSerial(ply)
    local primed,attackObservation
    if Rules.CommitAttack then primed,attackObservation=Rules:CommitAttack(ply,true) end
    context.aceBonus=primed and 1 or 0
    if LOD.Audio then LOD.Audio:Emit(ply,"cast") end
    local fired=Forms:_CastBeam(ply,form,content,context)
    if fired and attackObservation and Rules.ObserveCommittedAttack then Rules:ObserveCommittedAttack(ply,attackObservation) end
    return fired
end
