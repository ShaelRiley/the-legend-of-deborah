-- One model-aware activity resolver for every hostile, including retreat.
LOD.HostileAnimation = LOD.HostileAnimation or {}
local A = LOD.HostileAnimation
local rejected = {reference=true, ragdoll=true, bindpose=true, bind_pose=true, tpose=true, t_pose=true}
function A:Valid(e, seq)
    if type(seq)~="number" or seq<0 then return false end
    local name=string.lower(e:GetSequenceName(seq) or "")
    return name~="" and not rejected[name] and not name:find("reference",1,true)
end
function A:Resolve(e, activity)
    local model=e:GetModel()
    if e.LODAnimationModel~=model then e.LODAnimationModel=model;e.LODAnimationCache={} end
    local cache=e.LODAnimationCache
    if cache[activity]~=nil then return cache[activity] or nil end
    local moving=activity==ACT_RUN or activity==ACT_WALK or activity==ACT_RUN_AIM_RIFLE
    local candidates={activity}
    local function add(v) if v~=nil then candidates[#candidates+1]=v end end
    if moving then add(ACT_RUN_AIM_RIFLE);add(ACT_RUN);add(ACT_WALK) end
    for _,act in ipairs(candidates) do
        local seq=e:SelectWeightedSequence(act)
        if self:Valid(e,seq) then cache[activity]=seq;return seq end
    end
    -- Some stock devices expose named cycles but no matching ACT metadata.
    local names=activity==ACT_CLIMB_UP and {"climb","climb_up","climbwall"} or moving and {"run_all","run","walk_all","walk","fly","idle"} or (activity==ACT_RANGE_ATTACK1 and {"fire","fire1","shoot","attack","attack1","range_attack1"} or {"idle","idle01","idle1","idle_subtle","fly"})
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
    if force or e.LODCurrentActivity~=activity or e:GetSequence()~=seq or e:GetPlaybackRate()==0 then
        e.LODCurrentActivity=activity
        e:ResetSequence(seq);e:SetPlaybackRate(1)
    end
    return true
end
function A:Move(e)
    if not e._SetActivity or e.LODDead or CurTime()<(e.LODHitStunUntil or 0) then return end
    local id=e.LODArchetypeId
    local activity=(id=="soldier" or id=="blitzer" or id=="sniper" or id=="flamer")
        and (ACT_RUN_AIM_RIFLE or ACT_RUN) or (e.LODConfig and e.LODConfig.activity or ACT_WALK)
    e:_SetActivity(activity)
end
