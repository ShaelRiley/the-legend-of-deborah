-- The existing MusicDirector consumes server plans; MS2 renders bundled MIDI.
if LOD.MusicDirector and LOD.MusicDirector.Stop then LOD.MusicDirector:Stop() end
LOD.MusicDirector=LOD.MusicDirector or {}
local D,M,N=LOD.MusicDirector,LOD.Music,LOD.MusicNative
D.Plans={};D.PlanParts={};D.Payloads={};D.Pages={};D.SeenVictory={};D.Serial=D.Serial or 0
D.Generation=(D.Generation or 0)+1;D.ServerOn=false;D.Ready=false;D.SentAssets={}
D.SeenVictoryOrder={}
D.Volume=CreateClientConVar("lod_music_volume","0.55",true,false,"Procedural music volume",0,1)
D.Preference=CreateClientConVar("lod_music","1",true,true,"Allow local LoD music when the server enables it",0,1)
function D:Enabled()
    local master=GetConVar("lod_music_enabled")
    return self.ServerOn and master and master:GetBool() and self.Preference:GetBool() and self.Volume:GetFloat()>0
end
function D:RememberVictory(id)
    if self.SeenVictory[id] then return end
    self.SeenVictory[id]=true;self.SeenVictoryOrder[#self.SeenVictoryOrder+1]=id
    if #self.SeenVictoryOrder>2 then self.SeenVictory[table.remove(self.SeenVictoryOrder,1)]=nil end
end
function D:Stop()
    self.Generation=(self.Generation or 0)+1
    if IsValid(self.Panel) then self.Panel:Remove() end
    self.Panel=nil;self.Ready=false;self.SentAssets={};self.Synced=nil;self.Payloads={};self.Pages={};self.PlanParts={}
    if self.Victory then self.Victory.finished=true;self:RememberVictory(self.Victory.id) end
    N:Stop()
    local accent=LOD.AdventurePresentation
    if accent and accent.soundMusical then accent:Reset() end
end
function D:Duck(seconds) self.DuckUntil=math.max(self.DuckUntil or 0,CurTime()+(seconds or 1));self.Synced=nil end
function D:Announce(bid)
    if not self:Enabled() or not M.ID(bid) or bid==self.LastBlock then return end
    local allowed=false
    for _,t in ipairs(self.AudibleTargets or {}) do if t.block==bid and t.weight>0 then allowed=true end end
    if not allowed then return end
    self.LastBlock=bid;self.Serial=self.Serial+1
    net.Start("LOD_MusicPlaying");net.WriteUInt(self.Current and self.Current.sequence or 0,32)
    net.WriteUInt(self.Serial,32);net.WriteString(bid);net.SendToServer()
end
function D:Page(name)
    local found=self.Pages[name];if found then found.used=SysTime();return found.notes end
    local raw,err=M.IncludeBundled(name)
    if type(raw)~="string" or #raw>47000 then self.Error=err or "Invalid MIDI note page "..tostring(name);return nil end
    -- Bundled pages also exceed the native key limit despite their small byte
    -- size. Only these trusted local files bypass it; notes are validated below.
    local notes=util.JSONToTable(raw,true)
    if type(notes)~="table" then self.Error="Could not decode MIDI note page "..tostring(name);return nil end
    self.Pages[name]={notes=notes,used=SysTime()}
    if table.Count(self.Pages)>M.Limits.noteCachePages then
        local oldest
        for key,p in pairs(self.Pages) do if key~=name and (not oldest or p.used<self.Pages[oldest].used) then oldest=key end end
        if oldest then self.Pages[oldest]=nil end
    end
    return notes
end
function D:Payload(aid)
    local known=self.Payloads[aid];if known then known.used=SysTime();return known.data end
    local a=self.Catalog and self.Catalog.assets[aid];if not a then return nil end
    local payload={id=a.id,role=a.role,loop=a.loop,clips={}}
    for _,clip in ipairs(a.clips) do
        local page=self:Page(clip.page);local notes=page and page[clip.id]
        if type(notes)~="table" or #notes>M.Limits.clipNotes then self.Error=self.Error or "Missing MIDI phrase "..clip.id;return nil end
        for _,n in ipairs(notes) do
            if type(n)~="table" or #n~=5 or type(n[1])~="number" or n[1]<0 or n[1]>=clip.beats*48
                or type(n[2])~="number" or n[2]<1 or n[2]>clip.beats*48
                or type(n[3])~="number" or n[3]<0 or n[3]>8 or n[3]%1~=0
                or type(n[4])~="number" or n[4]<20 or n[4]>100 or type(n[5])~="number" or n[5]<1 or n[5]>127 then
                self.Error="Invalid MIDI note "..clip.id;return nil
            end
        end
        payload.clips[#payload.clips+1]={id=clip.id,beats=clip.beats,energy=clip.energy,entry=clip.entry,exit=clip.exit,next=clip.next,notes=notes}
    end
    self.Payloads[aid]={data=payload,used=SysTime()}
    if table.Count(self.Payloads)>M.Limits.noteCacheAssets then
        local oldest
        for id,p in pairs(self.Payloads) do if id~=aid and (not oldest or p.used<self.Payloads[oldest].used) then oldest=id end end
        if oldest then self.Payloads[oldest]=nil end
    end
    return payload
end
function D:StartRenderer()
    if IsValid(self.Panel) or SysTime()<(self.RetryAt or 0) then return end
    if not self.Catalog then self.Catalog,self.Error=M.LoadBundled() end
    if not self.Catalog then self.RetryAt=SysTime()+10;return end
    local engineSource,err=M.IncludeBundled("engine.lua")
    if type(engineSource)~="string" then self.Error=err or "Missing MS2 renderer";self.RetryAt=SysTime()+10;return end
    local panel=vgui.Create("DHTML");self.Panel=panel
    if not IsValid(panel) then self.Error="MS2 HTML renderer unavailable";self.RetryAt=SysTime()+10;return end
    local generation=self.Generation
    panel:SetSize(1,1);panel:SetPos(0,0);panel:SetMouseInputEnabled(false);panel:SetKeyboardInputEnabled(false)
    panel:SetAllowLua(false);panel.Paint=function() end
    -- Keep IsVisible true: a hidden DHTML does not process its JavaScript queue.
    panel:SetVisible(true)
    function panel:OnDocumentReady()
        local function live() return generation==D.Generation and D:Enabled() end
        self:AddFunction("lodms2","ready",function(backend)
            if not live() then return end
            D.Ready=true;D.Backend=backend;D.Synced=nil
        end)
        self:AddFunction("lodms2","block",function(bid) if live() then D:Announce(bid) end end)
        self:AddFunction("lodms2","victory",function() if live() and D.Victory then D.Victory.finished=true;D.Synced=nil end end)
        self:AddFunction("lodms2","mix",function(lane,value,pitch) if live() then N:SetMix(lane,value,pitch) end end)
        self:AddFunction("lodms2","volume",function(volume,quality)
            if not live() then return end
            N:SetVolume(math.Clamp(tonumber(volume) or 0,0,1),quality)
        end)
        self:AddFunction("lodms2","drop",function(id) if live() then N:Drop(id) end end)
        self:AddFunction("lodms2","notes",function(raw) if live() then N:Enqueue(raw) end end)
        self:AddFunction("lodms2","stop",function() if live() then N:Stop() end end)
        self:AddFunction("lodms2","stats",function(raw) if live() and type(raw)=="string" and #raw<2000 then D.Stats=util.JSONToTable(raw) end end)
        self:AddFunction("lodms2","error",function(err)
            if not live() then return end
            D.Error=tostring(err):sub(1,512);D.RetryAt=SysTime()+10;D:Stop()
        end)
        self:QueueJavascript("window.lodScore=MS2.attach(lodms2);")
    end
    panel:SetHTML('<!doctype html><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src \'none\'; script-src \'unsafe-inline\'"><script>'..engineSource..'</script>')
    self.ReadyDeadline=SysTime()+5
end
function D:Candidate(plan,bid,role)
    local b=plan and plan.blocks[bid]
    for _,c in ipairs(b and b.roles[role] or {}) do if self.Catalog.assets[c.asset] then return c.asset end end
    if role=="INTERLUDE" then return self:Candidate(plan,bid,"T0") end
end
function D:Desired()
    local s=self.Current;if not s or s.stop then return end
    local plan=self.Plans[s.plan];if not plan then return end
    local role=s.role;local targets=s.targets;local v=self.Victory
    if v and not v.finished then
        local required=12*60/self.Catalog.bpm+.5
        if not v.started and CurTime()+required>v.endsAt then v.finished=true;self:RememberVictory(v.id)
        else plan=self.Plans[v.plan];targets={{block=v.block,weight=1}};role="VICTORY" end
    end
    if role=="POST" then
        local nextPlan=self.Plans[s.next]
        if s.policy=="auto" and nextPlan and s.nextBlock then plan=nextPlan;targets={{block=s.nextBlock,weight=1}} end
        role=s.policy=="off" and "T0" or "INTERLUDE"
    end
    if not plan then return end
    if plan.revision~=self.Catalog.revision then self.Error="MS2 client/server catalog mismatch; install the same build";return end
    local state={targets={},role=role,remaining=s.remaining or -1,expression=s.expression or 0,staged=s.staged,
        seed=plan.seed or 0,bpm=self.Catalog.bpm,quality=self.Quality or 1,
        volume=self.Volume:GetFloat()*(CurTime()<(self.DuckUntil or 0) and .55 or 1)}
    for _,t in ipairs(targets or {}) do
        local aid=t.block and self:Candidate(plan,t.block,role)
        if aid and t.weight>0 then state.targets[#state.targets+1]={block=t.block,asset=aid,weight=t.weight} end
    end
    return state
end
function D:Sync()
    if not self.Ready then return end
    local state=self:Desired();if not state or #state.targets==0 then return end
    local raw=util.TableToJSON(state);if raw==self.Synced then return end
    local sent={}
    for _,t in ipairs(state.targets) do
        if not self.SentAssets[t.asset] then
            local payload=self:Payload(t.asset);if not payload then return end
            self.Panel:QueueJavascript("lodScore.install("..util.TableToJSON(payload)..");")
        end
        sent[t.asset]=true
    end
    self.AudibleTargets=state.targets;self.SentAssets=sent
    self.Panel:QueueJavascript("lodScore.state("..raw..");");self.Synced=raw
    if state.role=="VICTORY" and self.Victory then self.Victory.started=true;self:RememberVictory(self.Victory.id) end
end
function D:Demand(resync)
    local on=self.Preference:GetBool() and self.Volume:GetFloat()>0
    if on==self.DemandOn and not resync then return end
    self.DemandOn=on
    net.Start("LOD_MusicDemand");net.WriteBool(on);net.WriteBool(true);net.WriteBool(resync==true);net.SendToServer()
end
function D:Tick()
    if not self:Enabled() then if self.WasEnabled then self:Stop() end;self.WasEnabled=false;return end
    self.WasEnabled=true
    if SysTime()>=(self.NextTick or 0) then
        self.NextTick=SysTime()+.2
        local frame=engine and engine.AbsoluteFrameTime and engine.AbsoluteFrameTime() or RealFrameTime()
        self.FrameAverage=(self.FrameAverage or frame)*.9+frame*.1
        if self.FrameAverage>M.Tuning.frameLimit then self.RecoverAt=SysTime()+M.Tuning.recovery end
        self.Quality=SysTime()<(self.RecoverAt or 0) and 0 or 1
        self:StartRenderer()
        if not self.Ready and self.ReadyDeadline and SysTime()>self.ReadyDeadline then
            self.Error="MS2 renderer did not initialize";self.RetryAt=SysTime()+10;self:Stop()
        end
        self:Sync()
    end
    if self.Backend=="native" then N:Tick() end
end
net.Receive("LOD_MusicPlan",function()
    if not D:Enabled() then return end
    local id=net.ReadString();local part=net.ReadUInt(16);local total=net.ReadUInt(16);local n=net.ReadUInt(16)
    if #id>160 or total<1 or total>math.ceil(M.Limits.packetBytes/M.Limits.planChunk)
        or part<1 or part>total or n<1 or n>M.Limits.planChunk then return end
    if part==1 then
        if table.Count(D.PlanParts)>=2 then D.PlanParts={} end
        D.PlanParts[id]={next=1,total=total,data={}}
    end
    local receiving=D.PlanParts[id];if not receiving or receiving.next~=part or receiving.total~=total then return end
    receiving.data[part]=net.ReadData(n);receiving.next=part+1;if part~=total then return end
    local bytes=table.concat(receiving.data);D.PlanParts[id]=nil;if #bytes>M.Limits.packetBytes then return end
    local raw=util.Decompress(bytes,M.Limits.packetBytes);if not raw or #raw>M.Limits.packetBytes then return end
    local plan=util.JSONToTable(raw)
    if type(plan)~="table" or plan.schema~=2 or plan.id~=id or type(plan.blocks)~="table" or type(plan.assets)~="table"
        or type(plan.floors)~="table" or #plan.floors>8 or not M.ID(plan.revision) then return end
    for aid,a in pairs(plan.assets) do if not M.Asset(a) or aid~=a.id then return end end
    D.Plans[id]=plan;D.Synced=nil
end)
net.Receive("LOD_MusicState",function(bits)
    if bits>32768 or not D:Enabled() then return end
    local s=util.JSONToTable(net.ReadString())
    if type(s)~="table" or type(s.sequence)~="number" or type(s.targets or {})~="table" or #(s.targets or {})>2 then return end
    if D.Current and s.sequence<=D.Current.sequence then return end
    if D.Current and s.epoch~=D.Current.epoch then D:Stop();D.LastBlock=nil;D.SeenVictory={};D.SeenVictoryOrder={};D.Victory=nil end
    D.Current=s;D.Synced=nil
    if s.stop then D:Stop();return end
    if s.role=="POST" and s.canVictory and not D.SeenVictory[s.victory] and s.startedAt>=(D.VictoryAfter or 0) then
        if not D.Victory or D.Victory.id~=s.victory then D.Victory={id=s.victory,plan=s.plan,block=s.targets[1].block,endsAt=s.endsAt} end
    elseif s.victory and not s.canVictory then D:RememberVictory(s.victory) end
    local keep={[s.plan]=true};if s.next then keep[s.next]=true end
    if D.Victory and not D.Victory.finished then keep[D.Victory.plan]=true end
    for id in pairs(D.Plans) do if not keep[id] then D.Plans[id]=nil end end
    if D.Victory and D.Victory.finished and s.role~="POST" then D.Victory=nil end
end)
net.Receive("LOD_MusicBudget",function() D.ServerBudget=net.ReadBool() end)
net.Receive("LOD_MusicSwitch",function()
    local on=net.ReadBool();if on~=D.ServerOn then D.VictoryAfter=CurTime() end
    D.ServerOn=on;if not D:Enabled() then D:Stop() end
end)
local function preferenceChanged()
    D.VictoryAfter=CurTime();D.Synced=nil;if not D:Enabled() then D:Stop() end;D:Demand()
end
cvars.AddChangeCallback("lod_music",preferenceChanged,"LOD_MusicPreference")
cvars.AddChangeCallback("lod_music_volume",preferenceChanged,"LOD_MusicVolume")
cvars.AddChangeCallback("lod_music_enabled",function() if not D:Enabled() then D:Stop() end end,"LOD_MusicPermission")
hook.Add("InitPostEntity","LOD_MusicDemand",function() D:Demand(true) end)
if timer then timer.Simple(0,function() if IsValid(LocalPlayer()) then D:Demand(true) end end) end
hook.Add("Think","LOD_MusicMix",function()
    local ok,err=pcall(D.Tick,D);if not ok then D.Error=tostring(err);D.RetryAt=SysTime()+10;D:Stop() end
end)
hook.Add("ShutDown","LOD_MusicShutdown",function() D:Stop() end)
concommand.Add("lod_music_client_status",function()
    if D.Ready and IsValid(D.Panel) then D.Panel:QueueJavascript("lodScore.stats();") end
    print("[LOD:MUSIC] "..util.TableToJSON({system="MS2",enabled=D:Enabled(),backend=D.Backend,ready=D.Ready,
        plan=D.Current and D.Current.plan,catalog=D.Catalog and D.Catalog.revision,quality=D.Quality,
        notePages=table.Count(D.Pages),noteAssets=table.Count(D.Payloads),stats=D.Stats,nativeVoices=table.Count(N.Voices),
        nativePeak=N.Peak,nativeError=N.Error,error=D.Error,streamedBytes=0}))
end)
