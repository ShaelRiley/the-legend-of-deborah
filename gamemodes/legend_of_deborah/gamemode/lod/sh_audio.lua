-- One semantic vocabulary. Server feedback is recipient-local: four players
-- hearing one reward must not emit four positional copies of the same sound.
LOD.Audio=LOD.Audio or {}
local A=LOD.Audio
A.Version='feedback-20260919-01'
A.Cues={}
local names={'hit_confirm','spatial_awareness','loot_spawn','loot_pickup','confirm','deny','dialogue','gift',
    'status','status_clear','resist','weakness','proc','danger','life','soldier','progress','life_lost','last_life',
    'respawn','objective_clear','map_open','map_close','gps','dice_explode','aim_lock','heat_warm','heat_near',
    'weapon_ready','ar2_warning','enemy_warning','tetris_rotate','tetris_move','tetris_drop','tetris_clear','tetris_end',
    'diversion','feedback','status_poisoned','status_immolated','status_held','status_muted','status_intimidated',
    'portal_depart','portal_arrive','cast','summon_attack','boss_arrive','item_discard','heal','status_reckless','status_clumsy','status_shattered','status_confused','summon_arrive','summon_depart','enemy_defeated','boss_taunt','cloud_step','statue_transform'}
for index,id in ipairs(names) do
    A.Cues[id]={index=index,path='legend_of_deborah/feedback/'..id..'.wav',volume=.65,cooldown=.12}
end
A.Cues.hit_confirm.volume=.5;A.Cues.hit_confirm.cooldown=.045
A.Cues.enemy_defeated.volume=.5;A.Cues.enemy_defeated.cooldown=.12
A.Cues.boss_taunt.cooldown=2
A.Cues.spatial_awareness.cooldown=.8
A.Cues.loot_spawn.cooldown=.22;A.Cues.loot_spawn.volume=.5
A.Next=A.Next or {}
A.Recipients=A.Recipients or setmetatable({}, {__mode='k'})
function A:Path(id) return assert(self.Cues[id],'Unknown LoD audio cue '..tostring(id)).path end
function A:Muted()
    if SERVER then
        local s=LOD.RunManager and LOD.RunManager.State
        return self.Building==true or not s or not s.BuildReady
    end
    return GetGlobalBool('LOD_GenerationSilent',true)
end
function A:Play(id,volume)
    local cue=self.Cues[id]
    if not cue or self:Muted() or CurTime()<(self.Next[id] or 0) then return false end
    local ply=LocalPlayer();if not IsValid(ply) then return false end
    self.Next[id]=CurTime()+cue.cooldown
    -- Per-mechanic spacing bounds rapid hits without taking over weapon channels.
    ply:EmitSound(cue.path,0,100,(volume or 1)*cue.volume,CHAN_AUTO)
    return true
end
function A:ToPlayer(ply,id,volume)
    local cue=self.Cues[id]
    if not cue or self:Muted() or not IsValid(ply) then return false end
    local times=self.Recipients[ply] or {};self.Recipients[ply]=times
    if CurTime()<(times[id] or 0) then return false end
    times[id]=CurTime()+cue.cooldown
    net.Start('LOD_AudioCue');net.WriteUInt(cue.index,6);net.WriteFloat(volume or 1);net.Send(ply)
    return true
end
function A:At(pos,id,radius)
    if self:Muted() then return end
    radius=radius or 950
    for _,ply in ipairs(player.GetAll()) do
        local distance=ply:GetPos():Distance(pos)
        if distance<radius then self:ToPlayer(ply,id,math.max(.15,1-distance/radius)) end
    end
end
function A:Emit(ent,id)
    if SERVER then
        if IsValid(ent) and ent:IsPlayer() then return self:ToPlayer(ent,id) end
        if IsValid(ent) then return self:At(ent:GetPos(),id) end
    else return self:Play(id) end
end
if SERVER then
    util.AddNetworkString('LOD_AudioCue')
    for _,cue in pairs(A.Cues) do resource.AddFile('sound/'..cue.path) end
else
    net.Receive('LOD_AudioCue',function()
        local id=names[net.ReadUInt(6)];local volume=net.ReadFloat()
        if id then A:Play(id,math.Clamp(volume,0,1)) end
    end)
end
-- Stops engine-owned initialization, not just the explicit musical cue layer.
hook.Add('EntityEmitSound','LOD_GenerationSoundBarrier',function(data)
    if A:Muted() then return false end
end)
