-- Native fallback for older HTML engines. The same JS composer supplies notes.
-- A finite generated tone/voice bank is reused, never one sound ID per phrase.
if LOD.MusicNative and LOD.MusicNative.Stop then LOD.MusicNative:Stop() end
LOD.MusicNative={Voices={},Queue={},Mix={},Volume=.55,Quality=1,Peak=0}
local N=LOD.MusicNative
local names={[0]="acid","industrial","strings","brass","bass","tom","snare","kick","closed"}
local roots={[0]=64,60,69,64,40,45,38,36,42}
local pools={[0]=2,6,6,4,2,2,2,2,2}
local gains={[0]=.10,.10,.09,.115,.16,.22,.21,.28,.12}
local generated=LOD.MS2NativeGenerated or {};LOD.MS2NativeGenerated=generated
local function finite(x,lo,hi) return type(x)=="number" and x==x and x>=lo and x<=hi end
local function mixNow(mix,now)
    if not mix then return 0 end
    return mix.from+(mix.value-mix.from)*math.Clamp((now-mix.at)/.7,0,1)
end
local function waveData(name)
    local raw=file.Read("sound/lod/ms2/"..name..".wav","GAME")
    if not raw or #raw<44 or raw:sub(1,4)~="RIFF" or raw:sub(37,40)~="data" then return nil end
    return raw:sub(45)
end
function N:Ensure()
    if self.Ready then return true end
    if not sound.Generate then self.Error="Native PCM synthesis requires current Garry's Mod";return false end
    for inst=0,8 do
        local bytes=waveData(names[inst]);if not bytes then self.Error="Missing native instrument "..names[inst];return false end
        for slot=1,pools[inst] do
            local id="lod_ms2_instrument_"..inst.."_"..slot
            if not generated[id] then
                sound.Generate(id,22050,#bytes/44100,bytes,inst<5 and 0 or nil);generated[id]=true
            end
        end
    end
    local bytes=waveData("open");if not bytes then self.Error="Missing open hat";return false end
    for slot=1,pools[8] do
        local id="lod_ms2_open_"..slot
        if not generated[id] then sound.Generate(id,22050,#bytes/44100,bytes);generated[id]=true end
    end
    self.Ready=true;return true
end
function N:Stop()
    for _,v in pairs(self.Voices) do v.patch:Stop() end
    self.Voices={};self.Queue={};self.Mix={}
end
function N:Drop(lane)
    self.Mix[lane]=nil
    for _,v in pairs(self.Voices) do if v.lane==lane then
        v.patch:ChangeVolume(0,.03);v.ends=math.min(v.ends,SysTime()+.04);v.releasing=true
    end end
end
function N:SetVolume(volume,quality)
    self.Quality=quality
    if math.abs(self.Volume-volume)<.0001 then return end
    self.Volume=volume
    local now=SysTime()
    for _,v in pairs(self.Voices) do
        v.patch:ChangeVolume(v.level*mixNow(self.Mix[v.lane],now)*volume,.08)
    end
end
function N:SetMix(lane,value,pitch)
    if not LOD.MusicDirector or not LOD.MusicDirector:Enabled() then return end
    if not LOD.Music.ID(lane) or not finite(value,0,1) or not LOD.MusicDirector.Catalog
        or not LOD.MusicDirector.Catalog.blocks[lane] then return end
    local now=SysTime()
    self.Mix[lane]={value=value,from=mixNow(self.Mix[lane],now),at=now,pitch=pitch or 0}
    -- One sustained tonal bridge also covers native frame-sized note jitter.
    local key="bed:"..lane
    if value>0 and self.Voices[key] then self.Voices[key].ends=math.huge;self.Voices[key].releasing=false end
    if value>0 and not self.Voices[key] and self:Ensure() then
        -- The bridge gets a dedicated immutable sample ID, not a melodic slot.
        local id="lod_ms2_bed_"..lane
        if not generated[id] then
            local bytes=waveData("industrial");sound.Generate(id,22050,#bytes/44100,bytes,0);generated[id]=true
        end
        local patch=CreateSound(game.GetWorld(),id)
        if patch then patch:SetSoundLevel(0);patch:PlayEx(0,100*2^((50-60)/12));self.Voices[key]={patch=patch,lane=lane,inst=-1,level=.014,ends=math.huge} end
    end
    for _,v in pairs(self.Voices) do if v.lane==lane then v.patch:ChangeVolume(v.level*value*self.Volume,.7) end end
end
function N:Enqueue(raw)
    if not LOD.MusicDirector or not LOD.MusicDirector:Enabled() or type(raw)~="string" or #raw>120000 then return end
    local events=util.JSONToTable(raw);if type(events)~="table" or #events>512 then return end
    local now=SysTime()
    for _,e in ipairs(events) do
        if #self.Queue>=1024 then break end
        if type(e)=="table" and LOD.Music.ID(e.lane) and finite(e.delay,0,.7) and finite(e.inst,0,8) and e.inst%1==0
            and finite(e.pitch,20,100) and finite(e.velocity,1,127) and finite(e.duration,0,5) then
            e.at=now+e.delay;self.Queue[#self.Queue+1]=e
        end
    end
    table.sort(self.Queue,function(a,b) return a.at<b.at end)
end
function N:Note(e)
    local mix=self.Mix[e.lane];if not mix or mix.value<=0 or not self:Ensure() then return end
    local inst=e.inst;local now=SysTime();local weight=mixNow(mix,now);local chosen,oldest
    for slot=1,pools[inst] do
        local key=inst..":"..slot;local v=self.Voices[key]
        if not v then chosen=slot;break end
        if not oldest or v.ends<oldest.ends then oldest={slot=slot,ends=v.ends} end
    end
    chosen=chosen or oldest.slot
    local key=inst..":"..chosen;local old=self.Voices[key]
    if old then old.patch:Stop();self.Voices[key]=nil end
    -- Per-lane mono acid/bass and two tom voices; global pools stay finite.
    local same={}
    for k,v in pairs(self.Voices) do if v.lane==e.lane and v.inst==inst then same[#same+1]={key=k,voice=v} end end
    local limit=(inst==0 or inst==4 or inst>=6) and 1 or (inst==3 or inst==5) and 2 or 3
    if #same>=limit then
        table.sort(same,function(a,b) return a.voice.ends<b.voice.ends end)
        same[1].voice.patch:Stop();self.Voices[same[1].key]=nil
    end
    local count,quiet=0
    for k,v in pairs(self.Voices) do
        if v.inst>=0 then
            count=count+1
            if not quiet or v.level<quiet.voice.level then quiet={key=k,voice=v} end
        end
    end
    if count>=(self.Quality==0 and 16 or 24) and quiet then
        quiet.voice.patch:Stop();self.Voices[quiet.key]=nil
    end
    local id=inst==8 and e.pitch==46 and "lod_ms2_open_"..chosen or "lod_ms2_instrument_"..inst.."_"..chosen
    local patch=CreateSound(game.GetWorld(),id);if not patch then self.Error="Native voice creation failed";return end
    local pitch=inst<5 and 100*2^((e.pitch-roots[inst]+(e.expression==1 and .22 or 0))/12)
        or inst==5 and 100*2^((e.pitch-45)/12) or 100
    local level=gains[inst]*(e.velocity/127)^1.25*(e.expression==1 and 1.08 or 1)
    patch:SetSoundLevel(0);patch:PlayEx(inst<5 and 0 or level*weight*self.Volume,math.Clamp(pitch,1,255))
    if inst<5 then patch:ChangeVolume(level*weight*self.Volume,(inst==0 or inst==4) and .008 or .035) end
    local duration=inst<5 and math.min(4,e.duration) or inst==8 and e.pitch==46 and .48 or .42
    self.Voices[key]={patch=patch,lane=e.lane,inst=inst,level=level,ends=now+duration,releasing=false}
    self.Peak=math.max(self.Peak,table.Count(self.Voices))
end
function N:Tick()
    if not LOD.MusicDirector or not LOD.MusicDirector:Enabled() then return end
    local now=SysTime();local future={};local work=0
    for _,e in ipairs(self.Queue) do
        if e.at<=now and work<64 then if now-e.at<.15 then self:Note(e) end;work=work+1
        else future[#future+1]=e end
    end
    self.Queue=future
    for key,v in pairs(self.Voices) do
        if now>=v.ends then v.patch:Stop();self.Voices[key]=nil
        elseif v.inst>=0 and v.inst<5 and not v.releasing and now>=v.ends-.035 then v.patch:ChangeVolume(0,.035);v.releasing=true end
    end
end
