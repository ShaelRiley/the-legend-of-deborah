-- Data and presentation policy shared by the one server/client MusicDirector.
LOD = LOD or {}
LOD.Music = {}
local M = LOD.Music
M.Roles = {"T0", "T1", "T2", "T3", "BOSS", "VICTORY", "INTERLUDE"}
M.Limits = {blocks=256, assets=1792, bytes=4194304, duration=180, channels=4,
    transfers=1, loads=2, decodedBytes=67108864, cacheBytes=33554432, cacheFiles=64,
    chunkBytes=16384, bytesPerSecond=32768, planChunk=1024, metadataBytes=4096,
    catalogBytes=2097152, packetBytes=60000}
M.Tuning = {tick=.2, fade=1.2, relax=6, dwell=4, escalate=.8, buffer=.3,
    damageWindow=5, urgentHP=.2, dangerHP=.4, urgentTime=60, dangerTime=180,
    cueLead=8, cueMinimum=4, cueCount=8, mixTick=1/30, frameLimit=.035,
    severeFrame=.08, severeHold=2, recovery=5, pingLimit=180, pingRise=80,
    lossLimit=2, serverBudget=.0005}
local function count(t) local n=0; for _ in pairs(t or {}) do n=n+1 end; return n end
local function finite(n, lo, hi)
    return type(n)=="number" and n==n and n>=lo and n<=hi
end
function M.ID(s) return type(s)=="string" and #s>0 and #s<=64 and s:match("^[a-z0-9][a-z0-9_-]*$")~=nil end
function M.Text(s, size) return type(s)=="string" and #s>0 and #s<=(size or 128) and not s:find("[%z\1-\31\127]") end
function M.Origin(s)
    return type(s)=="string" and #s<=200 and s:match("^https://[%w][%w%.%-]*:?%d*$")~=nil
end
function M.PulseMode(role)
    if role=="VICTORY" then return nil end
    return (role=="T0" or role=="INTERLUDE") and "quiet" or "pulse"
end
function M.RoleLevel(role)
    return ({T0=0,T1=1,T2=2,T3=3,BOSS=4,INTERLUDE=0})[role] or 0
end
function M.Cues(a)
    local c=a.cues
    if c==nil then return true end -- Legacy catalogs are explicit compatibility.
    if not a.loop or type(c)~="table" or c.version~=1
        or (c.source~="authored" and c.source~="analyzed-v1") then return false end
    for key in pairs(c) do if key~="version" and key~="source" and key~="pulse" and key~="quiet" then return false end end
    local bar=240/a.bpm
    for _,mode in ipairs({"pulse","quiet"}) do
        local list=c[mode]
        if type(list)~="table" or #list>M.Tuning.cueCount or count(list)~=#list then return false end
        local previous=-1
        for _,cue in ipairs(list) do
            if type(cue)~="table" or count(cue)~=3 or not finite(cue.start,0,a.duration)
                or not finite(cue.finish,0,a.duration+.001) or not finite(cue.energy,0,1)
                or cue.start<=previous or cue.finish-cue.start<M.Tuning.cueMinimum-.001 then return false end
            for _,point in ipairs({cue.start,cue.finish}) do
                local grid=(point-a.phase)/bar
                if math.abs(grid-math.floor(grid+.5))>=.001 then return false end
            end
            previous=cue.start
        end
    end
    if #c.pulse+#c.quiet==0 then return false end
    for _,p in ipairs(c.pulse) do for _,q in ipairs(c.quiet) do
        if math.min(p.finish,q.finish)>math.max(p.start,q.start)+.001 then return false end
    end end
    return true
end
-- Pulse/quiet eligibility is absolute. Energy only ranks within that class.
function M.Section(a,mode,previous,strong)
    local list=a.cues and a.cues[mode]
    if not list or #list==0 then return nil end
    local low,high=1,0
    for _,cue in ipairs(list) do low=math.min(low,cue.energy);high=math.max(high,cue.energy) end
    local middle=(low+high)*.5
    for offset=1,#list do
        local index=((previous or 0)+offset-1)%#list+1
        local cue=list[index]
        if (strong and cue.energy>=middle) or (not strong and cue.energy<=middle) then return cue,index end
    end
end
function M.Asset(a)
    return type(a)=="table" and type(a.hash)=="string" and #a.hash==64 and a.hash:match("^[a-f0-9]+$")
        and type(a.path)=="string" and #a.path<240 and a.path:match("^music/blocks/[a-z0-9_-]+/[a-z0-9_-]+/[a-z0-9_-]+%.ogg$")
        and finite(a.bytes,1,M.Limits.bytes) and a.bytes%1==0 and finite(a.duration,1,M.Limits.duration)
        and a.codec=="vorbis" and a.rate==44100 and a.channels==2 and type(a.loop)=="boolean"
        and finite(a.bpm,40,240) and finite(a.beats,1,720) and a.beats%1==0
        and finite(a.phase,0,a.duration) and finite(a.gain,0,1) and finite(a.headroom,0,24)
        and M.ID(a.grid) and a.handoff=="envelope" and a.loopStart==0 and a.loopEnd==a.duration
        and M.Text(a.credits,512) and M.Text(a.source,512) and M.Cues(a)
        and (a.delivery==nil or a.delivery==1)
end
function M.Compatible(a,b)
    return a and b and a.grid==b.grid and a.bpm==b.bpm and a.beats==b.beats
        and math.abs(a.duration-b.duration)<.025 and a.phase==b.phase
end
function M.ValidateCatalog(c)
    if type(c)~="table" or c.schema~=1 or not M.ID(c.revision) or not M.Origin(c.origin)
        or type(c.blocks)~="table" or type(c.assets)~="table" or type(c.profiles)~="table"
        or type(c.sets)~="table" or count(c.blocks)>M.Limits.blocks or count(c.assets)>M.Limits.assets
        or count(c.profiles)>64 or count(c.sets)>128 then return nil,"invalid catalog envelope" end
    for id,a in pairs(c.assets) do if not M.Asset(a) or id~=a.hash then return nil,"invalid asset "..tostring(id) end end
    local function roles(r, partial)
        if type(r)~="table" then return false end
        for k in pairs(r) do local found=false; for _,role in ipairs(M.Roles) do if k==role then found=true end end; if not found then return false end end
        local sibling
        for _,role in ipairs(M.Roles) do
            local id=r[role]
            if id~=nil and id~="inherit" then
                local a=c.assets[id]
                if not a or a.loop~=(role~="VICTORY") or role=="VICTORY" and a.duration>12 then return false end
                if a.cues and #a.cues[M.PulseMode(role)]==0 then return false end
                if role:sub(1,1)=="T" then
                    if sibling and not M.Compatible(sibling,a) then return false end
                    sibling=a
                end
            elseif not partial then return false end
        end
        return true
    end
    for id,b in pairs(c.blocks) do
        if not M.ID(id) or not M.ID(b.version) or not M.Text(b.title) or not M.Text(b.credits,512)
            or not roles(b.roles,true) then return nil,"invalid block "..tostring(id) end
    end
    for id,p in pairs(c.profiles) do
        if not M.ID(id) or not M.ID(p.version) or not roles(p.roles,true) then return nil,"invalid default profile" end
    end
    for id,s in pairs(c.sets) do
        if not M.ID(id) or id=="all" or not M.ID(s.revision) or not M.Text(s.title)
            or type(s.members)~="table" or #s.members>M.Limits.blocks then return nil,"invalid set" end
        for _,bid in ipairs(s.members) do if not M.ID(bid) or not c.blocks[bid] then return nil,"unknown set member" end end
    end
    if c.projectDefault and not c.profiles[c.projectDefault] then return nil,"unknown project defaults" end
    return c
end
function M.Pool(c, selection)
    local out,seen={},{}
    if selection=="all" then for id in pairs(c.blocks) do out[#out+1]=id end
    else
        local set=c.sets[selection]; if not set then return nil,"unknown Music Block Set" end
        for _,id in ipairs(set.members) do if c.blocks[id] and not seen[id] then out[#out+1]=id;seen[id]=true end end
    end
    table.sort(out)
    if #out==0 then return nil,"empty music selection" end
    return out
end
function M.Candidates(c, b, role, settings)
    local out, seen = {}, {}
    local function add(id,source)
        local a=id and c.assets[id]
        if a and not seen[id] then out[#out+1]={asset=id,source=source};seen[id]=true end
    end
    if not settings["universal_"..role:lower()] then add(b.roles[role],"custom") end
    local server=c.profiles[settings.profile or ""]
    local project=c.profiles[c.projectDefault or ""]
    if server then add(server.roles[role],"server-default") end
    if project then add(project.roles[role],"project-default") end
    return out
end
function M.Plan(c, settings, seed, id, floors, epoch)
    local pool,err=M.Pool(c,settings.set or "all");if not pool then return nil,err end
    local plan={id=id,epoch=epoch,revision=c.revision,origin=c.origin,settings=table.Copy(settings),
        setRevision=c.sets[settings.set or ""] and c.sets[settings.set].revision,
        eligible={},floors={},blocks={},assets={},created=CurTime()}
    for _,bid in ipairs(pool) do plan.eligible[bid]=c.blocks[bid].version end
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,"music:physical-floors:v1"))
    local bag={}
    for z=1,floors do
        if #bag==0 then for _,bid in ipairs(pool) do bag[#bag+1]=bid end end
        local bid=table.remove(bag,rng:Int(1,#bag));plan.floors[z]=bid
        local b=c.blocks[bid]
        if not plan.blocks[bid] then
            local p={title=b.title,version=b.version,roles={}};plan.blocks[bid]=p
            for _,role in ipairs(M.Roles) do
                p.roles[role]=M.Candidates(c,b,role,settings)
                for _,candidate in ipairs(p.roles[role]) do plan.assets[candidate.asset]=table.Copy(c.assets[candidate.asset]) end
            end
        end
    end
    -- Snapshot data, including defaults and overrides; no later catalog reference.
    return plan
end
function M.Pressure(previous, sample, now)
    local p=previous or {value=0,changed=now}; local target=0
    if not sample.staging then
        if sample.recent then target=1 end
        if sample.hits>=3 or sample.hp<=M.Tuning.dangerHP or sample.remaining<=M.Tuning.dangerTime then target=2 end
        if sample.hp<=M.Tuning.urgentHP or sample.remaining<=M.Tuning.urgentTime then target=3 end
    end
    if target~=p.target then p.target=target;p.since=now end
    local wait=target>p.value and M.Tuning.escalate or M.Tuning.relax
    if sample.staging or target==3 or now-p.since>=wait and now-p.changed>=M.Tuning.dwell then
        if p.value~=target then p.value=target;p.changed=now end
    end
    return p
end
-- Uses feet and the built stair flight, never camera height or nearest-floor Z.
function M.Floors(graph, pos, grounded, previous)
    local mc,gc=LOD.Config.Maze,LOD.Config.Geometry
    for _,e in ipairs(graph.VerticalEdges or {}) do
        local low=e.a.z<e.b.z and e.a or e.b
        local center=LOD.MazeNavigator:CellCenter(low)
        local dir=({E={1,0},N={0,1},W={-1,0},S={0,-1}})[e.LODStairDirection or "E"]
        local x,y=pos.x-center.x,pos.y-center.y
        local along=x*dir[1]+y*dir[2];local across=-x*dir[2]+y*dir[1]
        local f=math.Clamp((along+gc.StairRun)/gc.StairRun,0,1)
        local treadRise=mc.LevelHeight/(gc.StairSteps or 24)
        if along>=-gc.StairRun-8 and along<=8 and math.abs(across)<=gc.StairWidth*.5
            and math.abs(pos.z-center.z-f*mc.LevelHeight)<=treadRise+24 and grounded then
            return low.z+1,low.z+2,f
        end
    end
    if not grounded and previous then return previous,previous,0 end
    local cell=LOD.MazeNavigator:WorldToCell(graph,pos)
    if not cell then return previous or 1,previous or 1,0 end
    local floor=cell.z+1
    return floor,floor,0
end
