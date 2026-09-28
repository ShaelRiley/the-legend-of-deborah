-- Transport/cache helper for the existing director. Audio never uses game net.
-- A native HTTP request cannot be cancelled: only one fixed-size chunk can be
-- outstanding, including across Off/On, reset and Lua refresh.
LOD.MusicMedia=LOD.MusicMedia or {cache={},failures={},wanted={}}
local C,L=LOD.MusicMedia,LOD.Music.Limits
local ROOT="legend_of_deborah/music_cache/"
local function path(hash) return ROOT..hash..".dat" end
function C:Init()
    if self.initialized then return end
    self.initialized=true;file.CreateDir(ROOT)
    local files=file.Find(ROOT.."*","DATA")
    for _,name in ipairs(files or {}) do
        local hash=name:match("^([a-f0-9]+)%.dat$")
        if hash and #hash==64 then
            local bytes=file.Size(ROOT..name,"DATA")
            if bytes>0 and bytes<=L.bytes then self.cache[hash]={bytes=bytes,used=file.Time(ROOT..name,"DATA") or 0}
            else file.Delete(ROOT..name) end
        elseif name:match("%.tmp$") then file.Delete(ROOT..name) end
    end
    self:Trim(0)
end
function C:Trim(extra)
    local bytes,count=0,0
    for _,v in pairs(self.cache) do bytes=bytes+v.bytes;count=count+1 end
    while bytes+extra>L.cacheBytes or count+(extra>0 and 1 or 0)>L.cacheFiles do
        local oldest
        for hash,v in pairs(self.cache) do
            if not (self.pinned or {})[hash] and (not oldest or v.used<self.cache[oldest].used) then oldest=hash end
        end
        if not oldest then return false end
        bytes=bytes-self.cache[oldest].bytes;count=count-1
        file.Delete(path(oldest));self.cache[oldest]=nil
    end
    return true
end
function C:Stop()
    if self.job then file.Delete(self.job.temp) end
    self.job=nil;self.wanted={};self.response=nil
    -- self.flight remains occupied until the real callback, never a fake timeout.
end
function C:Begin(pinned)
    self.wanted={};self.pinned=pinned;self.order=0
end
function C:Get(asset,origin,canWork)
    local hash=asset.hash
    if self.failures[hash] then return nil,self.failures[hash] end
    if canWork then self:Init() end
    local cached=self.cache[hash]
    if cached and not cached.verified and canWork then
        local data=cached.bytes==asset.bytes and file.Read(path(hash),"DATA")
        if data and #data==asset.bytes and util.SHA256(data)==hash then cached.verified=true
        else file.Delete(path(hash));self.cache[hash]=nil;cached=nil end
    end
    if cached and cached.verified then cached.used=os.time();return "data/"..path(hash) end
    if asset.delivery~=1 then return nil,"media needs offline --prepare-delivery" end
    self.wanted[hash]=self.wanted[hash] or {asset=asset,origin=origin,order=self.order or 0}
    self.order=(self.order or 0)+1
end
function C:Pump(canWork)
    if self.job and not self.wanted[self.job.asset.hash] then self:StopJob() end
    if not canWork then return end
    self:Init()
    local j=self.job
    if not j then
        local choice
        for hash,v in pairs(self.wanted) do
            if not self.failures[hash] and (not choice or v.order<choice.order) then choice=v end
        end
        if not choice then return end
        j={asset=choice.asset,origin=choice.origin,offset=0,temp=ROOT..choice.asset.hash..".tmp"}
        file.Write(j.temp,"");self.job=j
    end
    if self.response then
        local r=self.response;self.response=nil
        if r.job==j then
            if r.error then self.failures[j.asset.hash]=r.error;self:StopJob();return end
            file.Append(j.temp,r.body);j.offset=j.offset+#r.body
            if j.offset==j.asset.bytes then
                -- One bounded hash, outside the mixer and only with headroom.
                local data=file.Read(j.temp,"DATA")
                if not data or #data~=j.asset.bytes or util.SHA256(data)~=j.asset.hash then
                    self.failures[j.asset.hash]="download hash mismatch";self:StopJob();return
                end
                if not self:Trim(j.asset.bytes) then return end
                file.Rename(j.temp,path(j.asset.hash))
                if file.Size(path(j.asset.hash),"DATA")~=j.asset.bytes then
                    self.failures[j.asset.hash]="cache write failed";self:StopJob();return
                end
                self.cache[j.asset.hash]={bytes=j.asset.bytes,used=os.time(),verified=true}
                self.job=nil;return
            end
        end
    end
    if self.flight or SysTime()<(self.nextRequest or 0) then return end
    local size=math.min(L.chunkBytes,j.asset.bytes-j.offset)
    if size<=0 then return end
    local flight={job=j,size=size};self.flight=flight
    -- No saved token credit: a pause never creates a catch-up download burst.
    self.nextRequest=SysTime()+L.chunkBytes/L.bytesPerSecond
    local function finish(body,err)
        if self.flight~=flight then return end
        self.flight=nil
        if self.job==j then self.response={job=j,body=body,error=err} end
    end
    local ok=HTTP({url=j.origin.."/music/chunks/"..j.asset.hash.."/"..math.floor(j.offset/L.chunkBytes)..".dat",
        method="GET",timeout=15,
        success=function(code,body)
            if code~=200 or type(body)~="string" or #body~=size then finish(nil,"invalid music chunk")
            else self.received=(self.received or 0)+#body;finish(body) end
        end,
        failed=function(reason) finish(nil,"media request failed: "..tostring(reason)) end})
    if ok==false then finish(nil,"media request unavailable") end
end
function C:StopJob()
    if self.job then file.Delete(self.job.temp) end
    self.job=nil;self.response=nil
end
