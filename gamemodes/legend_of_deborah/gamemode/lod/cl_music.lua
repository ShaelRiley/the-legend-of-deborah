-- Bounded non-positional score mixer. Native URL requests cannot be cancelled
-- before their callback; tombstones keep those requests counted until return.
if LOD.MusicDirector and LOD.MusicDirector.Stop then LOD.MusicDirector:Stop() end
LOD.MusicDirector=LOD.MusicDirector or {}
local D,M=LOD.MusicDirector,LOD.Music
D.Plans={};D.Channels=D.Channels or {};D.Failures={};D.SeenVictory={};D.Generation=(D.Generation or 0)+1
D.ServerOn=false;D.Serial=D.Serial or 0
D.CueHistory={}
D.Volume=CreateClientConVar("lod_music_volume","0.55",true,false,"Streamed music volume",0,1)
D.Preference=CreateClientConVar("lod_music","1",true,true,"Allow LoD music when the server enables it",0,1)
function D:Enabled()
    local master=GetConVar("lod_music_enabled")
    return self.ServerOn and master and master:GetBool() and self.Preference:GetBool()
end
function D:Stop()
    self.Generation=(self.Generation or 0)+1
    for id,r in pairs(self.Channels or {}) do
        if IsValid(r.channel) then r.channel:Stop() end
        if r.pending then r.stale=true else self.Channels[id]=nil end
    end
    if self.Victory then self.Victory.finished=true;self.SeenVictory[self.Victory.id]=true end
    local accent=LOD.AdventurePresentation
    if accent and accent.soundMusical then accent:Reset() end
    -- Retain logical starts across Off/On; a toggle is not a new block start.
    self.Wanted={}
end
function D:Duck(seconds) self.DuckUntil=math.max(self.DuckUntil or 0,CurTime()+(seconds or 1)) end
function D:Counts()
    local slots,transfers,bytes=0,0,0
    for _,r in pairs(self.Channels) do
        slots=slots+1;bytes=bytes+r.asset.bytes
        if r.pending or IsValid(r.channel) and r.channel:GetBufferedTime()+.025<r.asset.duration then transfers=transfers+1 end
    end
    return slots,transfers,bytes
end
function D:Request(plan,assetId,key)
    key=key or assetId
    if not self:Enabled() or self.Failures[key] then return end
    if self.Channels[key] then return not self.Channels[key].stale and self.Channels[key] or nil end
    local asset=plan and plan.assets[assetId]
    if not asset or not M.Asset(asset) or not M.Origin(plan.origin) then return end
    local slots,transfers=self:Counts()
    if slots>=M.Limits.channels or transfers>=M.Limits.transfers then return end
    local r={asset=asset,key=key,pending=true,generation=self.Generation,gain=0,plan=plan.id,requested=CurTime()}
    self.Channels[key]=r
    sound.PlayURL(plan.origin.."/"..asset.path,"noplay noblock",function(channel,code,message)
        r.pending=false
        if r.stale or r.generation~=self.Generation or not self:Enabled() or self.Channels[key]~=r then
            if IsValid(channel) then channel:Stop() end
            if self.Channels[key]==r then self.Channels[key]=nil end
            return
        end
        if not IsValid(channel) then
            self.Failures[key]=tostring(code)..":"..tostring(message);self.Channels[key]=nil;return
        end
        r.channel=channel
        channel:SetVolume(0);channel:EnableLooping(asset.loop and not asset.cues)
        -- Readiness and seeking are checked later, not inferred from callback.
    end)
    return r
end
function D:Entry(r,role)
    local mode=M.PulseMode(role)
    if not mode or not r.asset.cues then return nil end
    local history=self.CueHistory[r.asset.hash] or {}
    local cue,index=M.Section(r.asset,mode,history[mode],mode=="pulse" and self.CueStrong)
    if not cue then return nil end
    local pos=cue.start
    -- Preserve beat phase where it fits safely inside the required section.
    local anchor
    for _,other in pairs(self.Channels) do
        if other.started and not other.cueTail and IsValid(other.channel) and M.Compatible(r.asset,other.asset)
            and (not anchor or other.gain>anchor.gain) then anchor=other end
    end
    if anchor then
        local aligned=pos+(anchor.channel:GetTime()-r.asset.phase)%(240/r.asset.bpm)
        if cue.finish-aligned>=M.Tuning.cueMinimum then pos=aligned end
    end
    return {mode=mode,start=pos,finish=cue.finish,index=index,origin=cue.start}
end
function D:MarkSection(r,entry)
    r.section=entry;r.entry=nil;r.sectionChecked=nil
    if entry then
        local history=self.CueHistory[r.asset.hash] or {};self.CueHistory[r.asset.hash]=history
        history[entry.mode]=entry.index
    end
end
function D:Candidate(plan,block,role)
    local b=plan and plan.blocks[block]
    for _,candidate in ipairs(b and b.roles[role] or {}) do
        if not self.Failures[candidate.asset] then return candidate end
    end
end
function D:Position(r,plan,role)
    if role=="VICTORY" then return 0 end
    -- Use the corresponding transport position only for a genuinely equal grid.
    for _,other in pairs(self.Channels) do
        if other~=r and other.started and IsValid(other.channel) and M.Compatible(r.asset,other.asset) then
            return other.channel:GetTime()%r.asset.duration
        end
    end
    -- Unrelated recordings use their authored beginning and an envelope handoff.
    return 0
end
function D:Ready(r,plan,role)
    if not r or r.stale or not IsValid(r.channel) then return false end
    if r.started then return true end
    if r.channel.IsBlockStreamed and r.channel:IsBlockStreamed() then
        self.Failures[r.key]="stream is not seekable";r.channel:Stop();self.Channels[r.key]=nil;return false
    end
    if r.asset.cues and (not r.entry or r.entry.mode~=M.PulseMode(role)) then r.entry=self:Entry(r,role) end
    local pos=r.entry and r.entry.start or self:Position(r,plan,role)
    if r.asset.cues and not r.entry then return false end
    r.requiredBuffer=math.min(r.asset.duration,pos+M.Tuning.buffer)
    if r.channel:GetBufferedTime()<r.requiredBuffer then return false end
    if role=="VICTORY" and (not self.Victory or self.Victory.finished or CurTime()>=self.Victory.endsAt) then return false end
    r.channel:SetTime(pos,true);r.channel:EnableLooping(role~="VICTORY" and not r.asset.cues)
    r.channel:Play();r.started=true;r.startedAt=CurTime();r.role=role
    self:MarkSection(r,r.entry)
    if role=="VICTORY" then
        self.Victory.started=true;self.Victory.asset=r.asset.hash;self.Victory.finishedAt=CurTime()+r.asset.duration
        self.SeenVictory[self.Victory.id]=true
    end
    return true
end
function D:SectionVoice(r,plan,role)
    if not r.started or not r.asset.cues then return r end
    local mode=M.PulseMode(role)
    if r.reseek or r.sectionChecked and CurTime()<r.sectionChecked and r.section and r.section.mode==mode then return r end
    r.sectionChecked=CurTime()+M.Tuning.tick
    local remaining=r.section and r.section.finish-r.channel:GetTime() or 0
    local changed=not r.section or r.section.mode~=mode
    if not changed and remaining>M.Tuning.cueLead then return r end
    local id=r.asset.hash;local key=id..":next"
    if self.Channels[id..":tail"] then return r end -- Reuse that voice after its fade.
    local incoming=self:Request(plan,id,key)
    if incoming and (not incoming.entry or incoming.entry.mode~=mode) then incoming.entry=self:Entry(incoming,role) end
    local boundary=M.Tuning.fade+M.Tuning.tick*2
    if not changed and remaining>boundary then return r end
    if incoming and not self.Channels[id..":tail"] and self:Ready(incoming,plan,role) then
        self.Channels[key]=nil;self.Channels[id..":tail"]=r;self.Channels[id]=incoming
        incoming.key=id;incoming.blocks=r.blocks;incoming.logicalBlock=r.logicalBlock;incoming.source=r.source
        r.key=id..":tail";r.retiring=true;r.cueTail=true
        return incoming
    end
    -- Saturated/slow native transfers cannot force a rhythmic dropout/outro.
    -- Fade down, fast-seek an already buffered cue, then fade up, with no fifth
    -- channel. This degraded handoff is deliberately visible in diagnostics.
    local entry=self:Entry(r,role)
    if entry and r.channel:GetBufferedTime()<entry.start+M.Tuning.buffer then
        entry=r.section and r.section.mode==mode and table.Copy(r.section) or nil
        if entry then entry.start=entry.origin end
    end
    if entry and r.channel:GetBufferedTime()>=entry.start+M.Tuning.buffer then
        r.reseek={entry=entry,level=1,phase="out"};r.cueFallbacks=(r.cueFallbacks or 0)+1
    end
    return r
end
function D:SectionEnvelope(r,dt,role)
    local f=r.reseek
    if not f then return 1 end
    if f.entry.mode~=M.PulseMode(role) then
        -- Pressure changed during a fallback. Retarget once; never seek into a
        -- now-forbidden quiet passage after urgent pressure returns.
        local entry=self:Entry(r,role)
        if entry and r.channel:GetBufferedTime()>=entry.start+M.Tuning.buffer then f.entry=entry;f.phase="out"
        else r.reseek=nil;return 1 end
    end
    if f.phase=="out" then
        f.level=math.max(0,f.level-dt/M.Tuning.fade)
        if f.level<=.0001 then
            r.channel:SetVolume(0);r.channel:SetTime(f.entry.start,true);r.channel:Play()
            self:MarkSection(r,f.entry);f.phase="in"
        end
    else
        f.level=math.min(1,f.level+dt/M.Tuning.fade)
        if f.level>=1 then r.reseek=nil end
    end
    return f.level
end
function D:Announce(bid)
    if not bid or bid==self.LastBlock then return end
    self.LastBlock=bid;self.Serial=self.Serial+1
    net.Start("LOD_MusicPlaying");net.WriteUInt(self.Current.sequence or 0,32)
    net.WriteUInt(self.Serial,32);net.WriteString(bid);net.SendToServer()
end
function D:Desired()
    local s=self.Current;if not s then return {},{} end
    local plan=self.Plans[s.plan];local wanted,preload={},{}
    local function item(p,b,r,w) return {plan=p,block=b,role=r,weight=w or 1} end
    local v=self.Victory
    if v and not v.finished then
        local r=v.asset and self.Channels[v.asset]
        if v.started and (CurTime()>=v.finishedAt or not r or not IsValid(r.channel))
            or not v.started and CurTime()>=v.endsAt then v.finished=true
        else return {item(self.Plans[v.plan],v.block,"VICTORY")},{} end
    end
    if s.role=="POST" then
        local nextPlan=self.Plans[s.next];local candidate=self:Candidate(nextPlan,s.nextBlock,"T0")
        local ready=candidate and self.Channels[candidate.asset]
        local nextReady=ready and IsValid(ready.channel) and ready.channel:GetBufferedTime()>=M.Tuning.buffer
        if s.policy~="interlude" and nextReady then return {item(nextPlan,s.nextBlock,"T0")},{} end
        if candidate and s.policy~="interlude" then preload[#preload+1]=item(nextPlan,s.nextBlock,"T0") end
        local role=s.policy=="off" and "T0" or "INTERLUDE"
        if not self:Candidate(plan,s.targets[1] and s.targets[1].block,role) then role="T0" end
        for _,t in ipairs(s.targets or {}) do wanted[#wanted+1]=item(plan,t.block,role,t.weight) end
    else
        for _,t in ipairs(s.targets or {}) do
            if t.block and t.weight>0 then wanted[#wanted+1]=item(plan,t.block,s.role,t.weight) end
        end
        if s.preload and #wanted==1 then preload[#preload+1]=item(plan,wanted[1].block,s.preload,0) end
    end
    return wanted,preload
end
function D:Tick()
    if not self:Enabled() then
        if self.WasEnabled then self:Stop() end
        self.WasEnabled=false;return
    end
    self.WasEnabled=true
    if not self.Current or self.Current.stop then return end
    if self.CueRole~=self.Current.role then
        self.CueStrong=M.RoleLevel(self.Current.role)>M.RoleLevel(self.CueRole)
            or self.CueRole==nil and M.RoleLevel(self.Current.role)>=2
        self.CueRole=self.Current.role
    end
    for id,r in pairs(self.Channels) do
        if not r.pending then
            local stalled=IsValid(r.channel) and r.channel.GetState and GMOD_CHANNEL_STALLED
                and r.channel:GetState()==GMOD_CHANNEL_STALLED
            if stalled then r.stalledAt=r.stalledAt or CurTime() else r.stalledAt=nil end
            if not IsValid(r.channel) or r.stalledAt and CurTime()-r.stalledAt>8 then
                if IsValid(r.channel) then r.channel:Stop() end
                self.Failures[id]="channel ended/stalled";self.Channels[id]=nil
            end
        end
    end
    local wanted,preload=self:Desired();local desired,hold,logical,wantedBlocks={},{},{},{}
    -- Reconcile the desired asset set before opening URLs. Never stack mixers.
    for _,x in ipairs(wanted) do
        if x.block then wantedBlocks[x.block]=true end
        x.candidate=self:Candidate(x.plan,x.block,x.role)
        if x.candidate then hold[x.candidate.asset]=true end
    end
    for _,x in ipairs(preload) do x.candidate=self:Candidate(x.plan,x.block,x.role);if x.candidate then hold[x.candidate.asset]=true end end
    for id,r in pairs(self.Channels) do
        if id==r.asset.hash..":next" and hold[r.asset.hash] then hold[id]=true end
    end
    for id,r in pairs(self.Channels) do
        if not hold[id] and not r.pending and r.gain<=.001 then
            if IsValid(r.channel) then r.channel:Stop() end;self.Channels[id]=nil
        end
    end
    -- A rapid change with four occupied voices first fades one obsolete voice.
    -- It cannot wait forever for a fifth slot while preserving all four old ones.
    local need=false
    for _,x in ipairs(wanted) do if x.candidate and not self.Channels[x.candidate.asset] then need=true end end
    if need and self:Counts()>=M.Limits.channels then
        local quietest
        for id,r in pairs(self.Channels) do
            if not hold[id] and not r.pending and (not quietest or r.gain<quietest.gain) then quietest=r end
        end
        if quietest then quietest.retiring=true end
    end
    for _,x in ipairs(wanted) do
        local c=x.candidate
        if c then
            local r=self:Request(x.plan,c.asset)
            if self:Ready(r,x.plan,x.role) then
                r=self:SectionVoice(r,x.plan,x.role)
                if self.Channels[c.asset..":next"] then hold[c.asset..":next"]=true end
                desired[c.asset]=(desired[c.asset] or 0)+x.weight
                logical[c.asset]=logical[c.asset] or {};logical[c.asset][x.block]=true
                r.source=c.source;r.logicalBlock=x.block;r.role=x.role;r.retiring=nil
            end
        elseif x.role=="VICTORY" and self.Victory then self.Victory.finished=true end
    end
    -- Keep each unready axis's previous valid sound. The aggregate remains bounded.
    local total=0;for _,weight in pairs(desired) do total=total+weight end
    if total<.999 then
        local previousTotal=0
        for id,r in pairs(self.Channels) do if r.started and not r.retiring and not desired[id] and r.role~="VICTORY" then previousTotal=previousTotal+r.gain end end
        for id,r in pairs(self.Channels) do
            if r.started and not r.retiring and not desired[id] and r.role~="VICTORY" and previousTotal>0 then desired[id]=(1-total)*r.gain/previousTotal end
        end
    end
    local dt=math.min(.1,FrameTime());local step=dt/M.Tuning.fade
    local volume=self.Volume:GetFloat()*(CurTime()<(self.DuckUntil or 0) and .3 or 1)
    local audible,reserves={},{}
    for id,r in pairs(self.Channels) do
        if IsValid(r.channel) then
            local buffered=r.channel:GetBufferedTime()
            local target=math.Clamp(desired[id] or 0,0,1)
            r.gain=math.Approach(r.gain,target,step)
            local envelope=self:SectionEnvelope(r,dt,r.role)
            r.channel:SetVolume(r.gain*volume*r.asset.gain*envelope)
            if logical[id] then r.blocks=logical[id] end
            if r.gain>0 and volume>0 then for bid in pairs(r.blocks or {}) do audible[bid]=true end end
            if not hold[id] and r.gain<=.001 then
                self.Channels[id]=nil
                local reserve=r.asset.hash..":next"
                if r.cueTail and hold[r.asset.hash] and not self.Channels[reserve] then
                    -- Alternate the same two buffered voices on later renewals.
                    -- Do not re-download a whole recording for every quiet loop.
                    r.channel:Pause();r.started=false;r.section=nil;r.entry=nil
                    r.cueTail=nil;r.retiring=nil;r.key=reserve;r.gain=0
                    reserves[#reserves+1]={key=reserve,record=r};hold[reserve]=true
                else r.channel:Stop() end
            end
            if buffered>(r.lastBuffer or -1) then r.lastBuffer=buffered;r.bufferProgress=CurTime() end
            if IsValid(r.channel) and not r.started and buffered<(r.requiredBuffer or M.Tuning.buffer)
                and CurTime()-(r.bufferProgress or r.requested)>20 then
                r.channel:Stop();self.Failures[id]="buffer timeout";self.Channels[id]=nil
            end
        end
    end
    for _,reserve in ipairs(reserves) do self.Channels[reserve.key]=reserve.record end
    for bid in pairs(self.Audible or {}) do if wantedBlocks[bid] then audible[bid]=true end end
    if volume>0 then
        for bid in pairs(audible) do if not (self.Audible or {})[bid] then self:Announce(bid) end end
        self.Audible=audible
    end
    -- Optional prefetch only after the foreground's requests have priority.
    for _,x in ipairs(preload) do if x.candidate then self:Request(x.plan,x.candidate.asset) end end
    self.Wanted=wanted
end
net.Receive("LOD_MusicPlan",function()
    local n=net.ReadUInt(16);if n>M.Limits.packetBytes then return end
    local bytes=net.ReadData(n);local raw=util.Decompress(bytes,M.Limits.catalogBytes)
    if not raw or #raw>M.Limits.catalogBytes then return end
    local p=util.JSONToTable(raw)
    if type(p)~="table" or type(p.id)~="string" or #p.id>160 or type(p.assets)~="table"
        or type(p.blocks)~="table" or type(p.floors)~="table" or #p.floors>8 then return end
    for id,a in pairs(p.assets) do if not M.Asset(a) or id~=a.hash then return end end
    if next(p.assets) and not M.Origin(p.origin) then return end
    D.Plans[p.id]=p
end)
net.Receive("LOD_MusicState",function(bits)
    if bits>32768 then return end
    local s=util.JSONToTable(net.ReadString())
    if type(s)~="table" or type(s.sequence)~="number" then return end
    if D.Current and s.sequence<=D.Current.sequence then return end
    if D.Current and s.epoch~=D.Current.epoch then D:Stop();D.LastBlock=nil;D.Audible={};D.SeenVictory={};D.Failures={} end
    D.Current=s
    if s.stop then D:Stop();return end
    if s.role=="POST" and s.canVictory and D:Enabled() and not D.SeenVictory[s.victory]
        and (s.startedAt or 0)>=(D.VictoryAfter or 0) then
        if not D.Victory or D.Victory.id~=s.victory then
            D.Victory={id=s.victory,plan=s.plan,block=s.targets[1].block,endsAt=s.endsAt}
        end
    elseif s.victory and not s.canVictory then D.SeenVictory[s.victory]=true end
    local keep={[s.plan]=true};if s.next then keep[s.next]=true end
    if D.Victory and not D.Victory.finished then keep[D.Victory.plan]=true end
    for id in pairs(D.Plans) do if not keep[id] then D.Plans[id]=nil end end
    if D.Victory and D.Victory.finished and s.role~="POST" then D.Victory=nil end
    if s.role~="POST" and not D.Victory then D.SeenVictory={} end
    local liveAssets={}
    for _,plan in pairs(D.Plans) do for id in pairs(plan.assets) do liveAssets[id]=true end end
    for id in pairs(D.Failures) do if not liveAssets[id:gsub(":next$",""):gsub(":tail$","")] then D.Failures[id]=nil end end
    for id in pairs(D.CueHistory) do if not liveAssets[id] then D.CueHistory[id]=nil end end
end)
net.Receive("LOD_MusicSwitch",function()
    local on=net.ReadBool()
    if on~=D.ServerOn then D.VictoryAfter=CurTime() end
    D.ServerOn=on;if not D:Enabled() then D:Stop() end
end)
cvars.AddChangeCallback("lod_music",function() D.VictoryAfter=CurTime();if not D:Enabled() then D:Stop() end end,"LOD_MusicPreference")
cvars.AddChangeCallback("lod_music_enabled",function() if not D:Enabled() then D:Stop() end end,"LOD_MusicPermission")
hook.Add("Think","LOD_MusicMix",function()
    local ok,err=pcall(D.Tick,D)
    if not ok then D.Error=tostring(err);D:Stop() end
end)
hook.Add("ShutDown","LOD_MusicStop",function() D:Stop() end)
hook.Add("PreCleanupMap","LOD_MusicCleanup",function()
    -- Only an explicit successful transition receipt may survive old-world cleanup.
    if not D.Current or D.Current.role~="POST" or not D.Current.victory then D:Stop() end
end)
concommand.Add("lod_music_client_status",function()
    local slots,transfers,bytes=D:Counts();local channels={}
    for id,r in pairs(D.Channels) do channels[#channels+1]={asset=id,role=r.role,block=r.logicalBlock,
        source=r.source,pending=r.pending,gain=r.gain,buffer=IsValid(r.channel) and r.channel:GetBufferedTime(),
        cueMode=r.section and r.section.mode,cueEnd=r.section and r.section.finish,
        cueSource=r.asset.cues and r.asset.cues.source or "legacy-no-cues",cueFallbacks=r.cueFallbacks,
        position=IsValid(r.channel) and r.channel:GetTime()} end
    print("[LOD:MUSIC] "..util.TableToJSON({enabled=D:Enabled(),plan=D.Current and D.Current.plan,
        channels=channels,slots=slots,transfers=transfers,compressedCeilingBytes=bytes,failures=D.Failures,error=D.Error}))
end)
