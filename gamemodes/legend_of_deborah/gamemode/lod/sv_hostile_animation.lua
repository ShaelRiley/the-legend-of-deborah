-- One model-aware activity resolver for every hostile, including retreat.
LOD.HostileAnimation = LOD.HostileAnimation or {}
local A = LOD.HostileAnimation
local rejected = {reference=true, ragdoll=true, bindpose=true, bind_pose=true, tpose=true, t_pose=true}
local weaponHolds = {
    weapon_crowbar="_MELEE", weapon_lod_crowbar="_MELEE", weapon_lod_wand="_MAGIC",
    weapon_pistol="_PISTOL", weapon_357="_REVOLVER", weapon_smg1="_SMG1",
    weapon_ar2="_AR2", weapon_shotgun="_SHOTGUN", weapon_crossbow="_CROSSBOW"
}
function A:PlayerHold(e, model)
    if not e.LODSkeletonHero or (model or e:GetModel())~="models/player/skeleton.mdl" then return nil end
    local fallen=e.LODFallenHero
    if fallen then return weaponHolds[fallen.weaponClass] or "" end
    local class=e.LODProgressionState and e.LODProgressionState.classId
    return class=="rogue" and "_SMG1" or class=="wizard" and "_MAGIC" or "_FIST"
end
local function movingActivity(activity)
    return activity==ACT_RUN or activity==ACT_WALK or activity==ACT_RUN_AIM_RIFLE
end
local function attackActivity(activity)
    return activity==ACT_MELEE_ATTACK1 or activity==ACT_RANGE_ATTACK1 or activity==ACT_RANGE_ATTACK_SMG1
end
function A:Valid(e, seq)
    if type(seq)~="number" or seq<0 then return false end
    local name=string.lower(e:GetSequenceName(seq) or "")
    return name~="" and not rejected[name] and not name:find("reference",1,true)
end
function A:Resolve(e, activity)
    local model=e:GetModel()
    local razor=e.LODArchetypeId=="razor" and model=="models/manhack.mdl"
    local hold=self:PlayerHold(e,model)
    if e.LODAnimationModel~=model or e.LODAnimationRazor~=razor or e.LODAnimationHold~=hold then
        e.LODAnimationModel=model;e.LODAnimationRazor=razor;e.LODAnimationHold=hold;e.LODAnimationCache={}
    end
    local cache=e.LODAnimationCache
    if cache[activity]~=nil then return cache[activity] or nil end
    local moving=movingActivity(activity)
    if hold then
        -- GMod's player rig uses HL2MP activities, not the controllers' NPC
        -- activities. Attack gestures are overlays; never use one as a base
        -- sequence or fall back to a reference/aim-only NPC pose.
        local role=activity==ACT_WALK and "WALK" or moving and "RUN" or "IDLE"
        local candidates={}
        local function add(act) if act~=nil then candidates[#candidates+1]=act end end
        if activity==ACT_DIESIMPLE or activity==ACT_DIEBACKWARD then add(ACT_GMOD_DEATH) end
        add(_G["ACT_HL2MP_"..role..hold]);add(_G["ACT_HL2MP_"..role])
        add(_G["ACT_HL2MP_IDLE"..hold]);add(ACT_HL2MP_IDLE)
        for _,act in ipairs(candidates) do
            local seq=e:SelectWeightedSequence(act)
            if self:Valid(e,seq) then cache[activity]=seq;return seq end
        end
        cache[activity]=false
        return nil
    end
    -- Stock Manhack ACT_IDLE is its packed/inactive pose, not a hover. Keep
    -- the deployed rotor flying during holds and the existing charge tell.
    local desired=razor and (activity==ACT_IDLE or activity==ACT_RANGE_ATTACK1) and ACT_FLY or activity
    local candidates={desired}
    local function add(v) if v~=nil then candidates[#candidates+1]=v end end
    if moving then add(ACT_RUN_AIM_RIFLE);add(ACT_RUN);add(ACT_WALK) end
    for _,act in ipairs(candidates) do
        local seq=e:SelectWeightedSequence(act)
        if self:Valid(e,seq) then cache[activity]=seq;return seq end
    end
    -- Some stock devices expose named cycles but no matching ACT metadata.
    local names=razor and {"fly","idle"} or activity==ACT_CLIMB_UP and {"climb","climb_up","climbwall"} or moving and {"run_all","run","walk_all","walk","fly","idle"} or (activity==ACT_RANGE_ATTACK1 and {"fire","fire1","shoot","attack","attack1","range_attack1"} or {"idle","idle01","idle1","idle_subtle","fly"})
    for _,name in ipairs(names) do
        local seq=e:LookupSequence(name)
        if self:Valid(e,seq) then cache[activity]=seq;return seq end
    end
    for _,act in ipairs({ACT_IDLE_ANGRY_SMG1 or ACT_IDLE,ACT_IDLE}) do
        local seq=e:SelectWeightedSequence(act)
        if self:Valid(e,seq) then cache[activity]=seq;return seq end
    end
    -- Last resort is a named, non-reference idle cycle; never sequence zero by fiat.
    for _,name in ipairs(e.GetSequenceList and e:GetSequenceList() or {}) do
        if string.lower(name):find("idle",1,true) then
            local seq=e:LookupSequence(name)
            if self:Valid(e,seq) then cache[activity]=seq;return seq end
        end
    end
    cache[activity]=false
end
function A:Apply(e, activity, force)
    activity=activity or ACT_IDLE
    local seq=self:Resolve(e,activity)
    if not seq then return false end -- never send -1 / reference to the engine
    local changed=e.LODCurrentActivity~=activity
    e.LODCurrentActivity=activity
    -- Several NPC requests map to the same complete player sequence. Their
    -- aliases must not restart that cycle between AI ticks and BodyUpdate.
    if force or (changed and not e.LODAnimationHold) or e:GetSequence()~=seq or e:GetPlaybackRate()==0 then
        e:ResetSequence(seq);e:SetPlaybackRate(1)
    end
    if (force or changed) and attackActivity(activity) then self:PlayerAttack(e) end
    return true
end
function A:PlayerAttack(e)
    local hold=self:PlayerHold(e)
    if not hold or e.LODDead or not e.AddGestureSequence then return false end
    -- Resolve refreshes the model/held-weapon cache without changing the body.
    self:Resolve(e,ACT_IDLE)
    local cache=e.LODAnimationCache
    if cache.attack==nil then
        cache.attack=false
        local act=_G["ACT_HL2MP_GESTURE_RANGE_ATTACK"..hold]
        local seq=act and e:SelectWeightedSequence(act)
        if self:Valid(e,seq) then cache.attack=seq end
    end
    if not cache.attack then return false end
    e:AddGestureSequence(cache.attack,true)
    return true
end
function A:UpdatePlayerBody(e)
    if not self:PlayerHold(e) then return false end
    if not e.LODDead then
        local state=LOD.RunManager and LOD.RunManager.State
        local held=CurTime()<(e.LODHitStunUntil or 0) or state and state.SimulationFrozen
        local moving=not held and (e.LODMotionSpeed or 0)>0
        if not held then
            -- Use the controller's exact request (including Soldier run-aim),
            -- so AI and BodyUpdate cannot restart equivalent cycles in turn.
            if moving then self:Move(e) else self:Apply(e,ACT_IDLE) end
        end
        -- Motion V2 explicitly faces its travel direction and suppresses native
        -- locomotor velocity. Drive the player's 9-way blend from that authority,
        -- not BodyMoveXY (which would see zero velocity and stop the legs).
        e:SetPoseParameter("move_x",moving and 1 or 0)
        e:SetPoseParameter("move_y",0)
    end
    e:FrameAdvance()
    return true
end
function A:Move(e)
    if not e._SetActivity or e.LODDead or CurTime()<(e.LODHitStunUntil or 0) then return end
    local id=e.LODArchetypeId
    local activity=(id=="soldier" or id=="blitzer" or id=="sniper" or id=="flamer")
        and (ACT_RUN_AIM_RIFLE or ACT_RUN) or (e.LODConfig and e.LODConfig.activity or ACT_WALK)
    e:_SetActivity(activity)
end
