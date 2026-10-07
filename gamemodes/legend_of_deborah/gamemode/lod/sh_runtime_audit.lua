LOD = LOD or {}
LOD.RuntimeAudit = LOD.RuntimeAudit or {}
local Audit = LOD.RuntimeAudit
Audit.Build = "generator-jit-20260917-01"
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}

local expected = SERVER and {"hostile", "pickup", "loot", "staging", "equipment", "equipment_generator", "crowbar", "statue", "manual"}
    or {"meshes", "mirror", "manual_reader", "equipment_generator"}

local function validCount(objects)
    local count = 0
    for _, object in pairs(objects or {}) do if IsValid(object) then count = count + 1 end end
    return count
end

function Audit:Snapshot(sampleVR)
    local missing = {}
    for _, name in ipairs(expected) do
        if LOD.RuntimeReceipts[name] ~= self.Build then missing[#missing + 1] = name end
    end
    local installation = file.Read("legend_of_deborah/dev_build.txt", "DATA") or "unrecorded"
    installation = string.sub(string.gsub(installation, "[\r\n]", " "), 1, 160)
    return {
        damsels = LOD.Damsels and LOD.Damsels.Version or 'missing',
        feedback_audio = LOD.Audio and LOD.Audio.Version or 'missing',
        vr = sampleVR and (LOD.VR and LOD.VR:WorkState() or {available = false, idle = false}) or nil,
        build = self.Build, realm = SERVER and "server" or "client",
        install = installation, missing = #missing > 0 and table.concat(missing, ",") or "none",
        architecture = jit and jit.arch or "unknown", branch = tostring(BRANCH or "unknown"),
        engine = tostring(VERSIONSTR or VERSION or "unknown"),
        lua_errors = self.ErrorCount or 0,
        wall_models = validCount(LOD.WallVisualsClient and LOD.WallVisualsClient.models),
        loot_entities = validCount(LOD.LootDirector and LOD.LootDirector.Entities),
        jit_version = jit and jit.version or "unknown",
        equipment_generation = LOD.Equipment and LOD.Equipment.GenerationExecutionMode or "unloaded",
        lua_kb = math.floor(collectgarbage("count")),
        entities = ents.GetCount and ents.GetCount() or #ents.GetAll(),
        meshes = LOD.TexturedBox and LOD.TexturedBox.MeshCacheCount and LOD.TexturedBox:MeshCacheCount() or 0
    }
end

function Audit:Report()
    local data = self:Snapshot()
    local parts = {}
    for _, key in ipairs({"build", "realm", "install", "missing", "architecture", "branch", "engine", "lua_errors", "lua_kb", "entities", "meshes", "wall_models", "loot_entities", "jit_version", "equipment_generation", "damsels", "feedback_audio"}) do
        parts[#parts + 1] = key .. "=" .. tostring(data[key])
    end
    print("[LOD BUILD_IDENTITY] " .. table.concat(parts, " "))
    self:Record("BUILD_IDENTITY", table.concat(parts, " "))
    if SERVER and LOD.RPGTestLog and LOD.RPGTestLog.Write then
        LOD.RPGTestLog:Write("BUILD_IDENTITY", data)
    end
end

hook.Add("InitPostEntity", "LOD_RuntimeBuildIdentity", function()
    timer.Simple(1, function() Audit:Report() end)
end)
concommand.Add(SERVER and "lod_stability_status" or "lod_stability_client_status", function(ply)
    if SERVER and IsValid(ply) and not ply:IsAdmin() then return end
    Audit:Report()
end)
-- Developer-only resource trend, bounded to one record per 30 seconds. Lua KB
-- is not process/native memory; record the engine architecture separately.
timer.Create("LOD_RuntimeStabilityHeartbeat", 30, 0, function()
    local cv = GetConVar("lod_developer_mode")
    if cv and cv:GetBool() then Audit:Report() end
end)

-- Keep the first errors and the last native boundary across a force-close.
-- A fixed ring bounds disk/memory, even if a broken Think hook repeats forever.
Audit.Journal = Audit.Journal or {}
Audit.ErrorCount = Audit.ErrorCount or 0
Audit.NextErrorRecord = Audit.NextErrorRecord or 0
function Audit:Record(kind, detail)
    if self.WritingJournal then return end
    self.WritingJournal = true
    local ok, err = pcall(function()
        local line = string.format("%.3f %s %s %s", RealTime(), self.Build,
            tostring(kind), string.sub(tostring(detail or ""), 1, 3000))
        local entries = self.Journal
        entries[#entries + 1] = line
        if #entries > 64 then table.remove(entries, 1) end
        file.CreateDir("legend_of_deborah")
        file.Write("legend_of_deborah/stability_" .. (SERVER and "server" or "client") .. "_latest.txt",
            table.concat(entries, "\n") .. "\n")
    end)
    self.WritingJournal = nil
    if not ok then print("[LOD STABILITY JOURNAL] " .. tostring(err)) end
end
hook.Add("OnLuaError", "LOD_RuntimeLuaErrors", function(message, realm, stack)
    Audit.ErrorCount = Audit.ErrorCount + 1
    if RealTime() < Audit.NextErrorRecord then return end
    Audit.NextErrorRecord = RealTime() + 1
    local lines = {"count=" .. Audit.ErrorCount .. " realm=" .. tostring(realm), tostring(message)}
    for i = 1, math.min(12, #(stack or {})) do
        local frame = stack[i]
        lines[#lines + 1] = tostring(frame.File or frame.short_src or frame.source)
            .. ":" .. tostring(frame.Line or frame.currentline) .. " " .. tostring(frame.Function or frame.name)
    end
    Audit:Record("LUA_ERROR", table.concat(lines, "\n"))
end)

-- Opt-in, partial CPU attribution for the existing frame capture. Inclusive
-- wall-clock rows overlap when callbacks call one another: never sum them into
-- a total, or mistake native render submission time for a GPU measurement.
-- No callback wrappers, entity scans or recurring hooks exist while idle.
if CLIENT and Audit.StopPerformanceCapture then Audit:StopPerformanceCapture("lua-refresh") end
if SERVER and Audit.StopServerCPUProfile then Audit:StopServerCPUProfile("lua-refresh") end
if Audit.StopCPUProfile then Audit:StopCPUProfile("lua-refresh") end
local profileChannel="LOD_PerformanceProfile"
local profileJSONLimit=262144 -- finite decompression memory; wire remains <=60000
local function profileState()
    local state=LOD.RunManager and LOD.RunManager.State
    local graph=state and state.Graph
    return {campaign=state and state.CampaignSeed,seed=graph and graph.LevelSeed,
        resources=Audit:Snapshot(true)}
end
function Audit:StartCPUProfile()
    if self.CPUProfile then self:StopCPUProfile("restarted") end
    local profile={started=SysTime(),enabled=true,rows={},
        bindings=setmetatable({},{__mode="k"}),state_start=profileState()}
    self.CPUProfile=profile
    local function getRow(name)
        local row=profile.rows[name]
        if row then return row end
        row={name=name,calls=0,completed=0,seconds=0,maximum=0};profile.rows[name]=row
        -- A vararg tail keeps every return, including intervening/trailing nils,
        -- without a per-call results table or pcall changing error/yield behavior.
        row.finish=function(start,...)
            local elapsed=math.max(0,SysTime()-start)
            row.completed=row.completed+1;row.seconds=row.seconds+elapsed
            row.maximum=math.max(row.maximum,elapsed)
            return ...
        end
        return row
    end
    profile.measure=function(name,fn,...)
        local row=getRow(name);row.calls=row.calls+1
        return row.finish(SysTime(),fn(...))
    end
    local function wrap(target,key,name,fn)
        if type(fn)~="function" then return end
        local bindings=profile.bindings[target]
        if not bindings then bindings={};profile.bindings[target]=bindings end
        if bindings[key] then return end
        local row=getRow(name)
        local original=rawget(target,key)
        local wrapper=function(...)
            if not profile.enabled then return fn(...) end
            row.calls=row.calls+1
            return row.finish(SysTime(),fn(...))
        end
        bindings[key]={original=original,wrapper=wrapper}
        target[key]=wrapper
    end
    for event,callbacks in pairs(hook.GetTable and hook.GetTable() or {}) do
        for id,fn in pairs(callbacks) do
            if type(id)=="string" and (id:find("^LOD") or id:find("^lod_"))
                and not id:find("^LOD_Performance") and not id:find("^LOD_CPUProfile") then
                wrap(callbacks,id,"hook/"..event.."/"..id,fn)
            end
        end
    end
    if SERVER then
        local services={EnemyRoster={"TickCloseDefense"},FactionManager={"BestTarget"},
            MazeNavigator={"Distance","FindHostilePath"}}
        for name,methods in pairs(services) do
            local target=LOD[name]
            if target then for _,key in ipairs(methods) do wrap(target,key,"service/"..name.."."..key,target[key]) end end
        end
    end
    local function bindEntity(ent)
        if not profile.enabled or not IsValid(ent) or not ent.GetTable or not ent.GetClass then return end
        local class=ent:GetClass()
        if not class:find("^lod_") then return end
        local target=ent:GetTable()
        if not target then return end
        local methods=SERVER and {"_BehaviourTick","BodyUpdate","Think"} or {"Think","Draw","DrawTranslucent"}
        local group=class..(SERVER and ent.LODArchetypeId and "/"..tostring(ent.LODArchetypeId) or "")
        for _,key in ipairs(methods) do
            -- Watcher's native router calls its canonical service directly.
            -- Leave the final instance binding identity intact.
            if not (key=="_BehaviourTick" and ent.LODArchetypeId=="watcher") then
                wrap(target,key,"entity/"..group.."."..key,ent[key])
            end
        end
    end
    -- Class-table edits do not reliably reach already bound Watcher methods.
    -- Borrow each native entity's actual Lua table, once, and restore its exact
    -- previous override (including absent/inherited methods) on retirement.
    if ents.GetAll then for _,ent in ipairs(ents.GetAll()) do bindEntity(ent) end end
    hook.Add("OnEntityCreated","LOD_CPUProfileNewEntity",function(ent)
        if timer.Simple then timer.Simple(0,function() bindEntity(ent) end) end
    end)
    if CLIENT then
        local starts={}
        local row={name="phase/PreRender-to-PostRender",calls=0,completed=0,seconds=0,maximum=0}
        profile.rows[row.name]=row
        hook.Add("PreRender","LOD_CPUProfileRenderStart",function()
            starts[#starts+1]=SysTime();row.calls=row.calls+1
        end)
        hook.Add("PostRender","LOD_CPUProfileRenderEnd",function()
            local start=starts[#starts];starts[#starts]=nil
            if start then
                local elapsed=math.max(0,SysTime()-start)
                row.completed=row.completed+1;row.seconds=row.seconds+elapsed;row.maximum=math.max(row.maximum,elapsed)
            end
        end)
    end
    return profile
end
function Audit:MeasureCPUCall(name,fn,...)
    local profile=self.CPUProfile
    if profile and profile.enabled then return profile.measure(name,fn,...) end
    return fn(...)
end
local function profileReport(profile,reason)
    local seconds=math.max(0,SysTime()-profile.started)
    local out={realm=SERVER and "server" or "client",reason=reason or "manual",seconds=seconds,
        timing="inclusive wall-clock; nested rows overlap; diagnostic overhead included; GPU unmeasured",
        coverage="existing LOD hooks, native LOD entity callbacks and selected AI services; excludes timers, gamemode methods and unwrapped engine work",
        state_start=profile.state_start,state_end=profileState(),rows={}}
    for _,row in pairs(profile.rows) do
        out.rows[#out.rows+1]={name=row.name,calls=row.calls,completed=row.completed,
            milliseconds=row.seconds*1000,maximum_ms=row.maximum*1000,
            mean_ms=row.completed>0 and row.seconds*1000/row.completed or 0,
            ms_per_second=seconds>0 and row.seconds*1000/seconds or 0}
    end
    table.sort(out.rows,function(a,b) return a.milliseconds==b.milliseconds and a.name<b.name or a.milliseconds>b.milliseconds end)
    return out
end
function Audit:StopCPUProfile(reason)
    local profile=self.CPUProfile
    if not profile then return end
    profile.enabled=false;self.CPUProfile=nil
    for target,bindings in pairs(profile.bindings) do
        for key,binding in pairs(bindings) do
            -- A refresh/replacement belongs to its newer authority; do not
            -- overwrite it with a callback captured before the change.
            if rawget(target,key)==binding.wrapper then target[key]=binding.original end
        end
    end
    hook.Remove("OnEntityCreated","LOD_CPUProfileNewEntity")
    hook.Remove("PreRender","LOD_CPUProfileRenderStart")
    hook.Remove("PostRender","LOD_CPUProfileRenderEnd")
    hook.Remove("Think","LOD_CPUProfileDeadline")
    return profileReport(profile,reason)
end
if SERVER and net and net.Receive and util.AddNetworkString then
    util.AddNetworkString(profileChannel)
    local lease
    local function sendReport(current,out)
        if not out or not IsValid(current.owner) then return end
        out.token=current.token
        local encoded=util.TableToJSON(out)
        -- Dense real profiles exceed the original JSON wire ceiling. Compress
        -- the complete report, retaining every row and timing. A NUL prefix is
        -- unambiguous beside the existing JSON messages; small reports keep the
        -- original wire format. Compression only runs during this finite lease.
        if encoded and #encoded>60000 then
            if #encoded<=profileJSONLimit and util.Compress then
                local ok,packed=pcall(util.Compress,encoded)
                encoded=ok and type(packed)=="string" and #packed>0 and ("\0"..packed) or nil
            else encoded=nil end
        end
        if not encoded or #encoded>60000 then
            encoded=util.TableToJSON({token=current.token,realm="server",error="profile exceeds transport limit"})
        end
        net.Start(profileChannel);net.WriteUInt(#encoded,16);net.WriteData(encoded,#encoded);net.Send(current.owner)
    end
    local function finishServer(reason)
        if not lease then return end
        local current=lease;lease=nil
        sendReport(current,Audit:StopCPUProfile(reason))
    end
    function Audit:StopServerCPUProfile(reason) finishServer(reason) end
    net.Receive(profileChannel,function(length,ply)
        if not IsValid(ply) or not ply:IsAdmin() or length<42 or length>48 then return end
        local start=net.ReadBool();local token=net.ReadUInt(32);local duration=net.ReadUInt(9)
        if not start then
            if lease and lease.owner==ply and lease.token==token then finishServer("client-stop") end
            return
        end
        if lease or duration<30 or duration>300 or token==0 then return end
        Audit:StartCPUProfile()
        lease={owner=ply,token=token,finish=SysTime()+duration+3,next_send=SysTime()+5}
        hook.Add("Think","LOD_CPUProfileDeadline",function()
            if not lease then return end
            local now=SysTime()
            if not IsValid(lease.owner) or now>=lease.finish then finishServer("deadline")
            elseif now>=lease.next_send and Audit.CPUProfile then
                -- The most recent bounded snapshot survives an immediate quit
                -- even if the final stop reply cannot reach a closing client.
                lease.next_send=now+5;sendReport(lease,profileReport(Audit.CPUProfile,"progress"))
            end
        end)
    end)
    hook.Add("ShutDown","LOD_CPUProfileServerShutdown",function() finishServer("shutdown") end)
    hook.Add("PostCleanupMap","LOD_CPUProfileServerCleanup",function() finishServer("map-cleanup") end)
end

-- Opt-in rendered-frame evidence. No frame hook, sample array, hashing or disk
-- writes exist while idle. SysTime intervals between PreRender calls include the
-- complete frame, unlike tick rate or the engine's clamped RealFrameTime value.
if CLIENT then
    if Audit.StopPerformanceCapture then Audit:StopPerformanceCapture("lua-refresh") end
    local function requestProfile(capture,start)
        if not net or not net.Start or not net.WriteBool or not net.WriteUInt or not net.SendToServer then return false end
        net.Start(profileChannel);net.WriteBool(start);net.WriteUInt(capture.token,32);net.WriteUInt(capture.duration,9);net.SendToServer()
        return true
    end
    if net and net.Receive and net.ReadUInt and net.ReadData and util.JSONToTable then
        net.Receive(profileChannel,function()
            local size=net.ReadUInt(16)
            if size<2 or size>60000 then return end
            local encoded=net.ReadData(size)
            if type(encoded)~="string" or #encoded~=size then return end
            if encoded:byte(1)==0 then
                if not util.Decompress then return end
                local ok,decoded=pcall(util.Decompress,encoded:sub(2),profileJSONLimit)
                if not ok or type(decoded)~="string" or #decoded<2 or #decoded>profileJSONLimit then return end
                encoded=decoded
            end
            local ok,out=pcall(util.JSONToTable,encoded)
            if not ok or type(out)~="table" or out.realm~="server" then return end
            local capture=Audit.PerformanceCapture
            local saved=Audit.LastPerformanceCapture
            if capture and capture.profile_requested and out.token==capture.token then capture.server_profile=out
            elseif not capture and saved and saved.cpu_profile and out.token==saved.cpu_profile.token then
                -- A stop reply arrives on the next network tick. Merge only the
                -- matching completed capture; a stale reply cannot overwrite a
                -- newer run or its file. Reuse the same atomic DATA verification.
                if saved.cpu_profile.server and saved.cpu_profile.server.reason~="progress" and out.reason=="progress" then return end
                saved.cpu_profile.server=out;saved.cpu_profile.server_status=out.error and "failed" or out.reason=="progress" and "partial" or "received"
                if Audit.SavePerformanceCapture then Audit:SavePerformanceCapture(saved) end
            end
        end)
    end
    local settingsNames={"fps_max","mat_vsync","mat_dxlevel","mat_queue_mode",
        "mat_antialias","mat_aaquality","mat_hdr_level","mat_picmip","mat_viewportscale",
        "r_shadows","r_shadowrendertotexture","r_waterforceexpensive","lod_reduced_effects","lod_wall_batches",
        "lod_third_person","lod_map_scale","lod_map_opacity"}
    local renderSources={
        "gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua",
        "gamemodes/legend_of_deborah/entities/entities/lod_static_box/shared.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_textured_box.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_batch.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_ui_theme.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_combat_roll_feed_semantics.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/sh_player_options.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_player_options.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_minimap.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_minimap_magic_quadrants.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/sh_runtime_audit.lua"}
    local populationChannel="LOD_PopulationSnapshot"
    if net and net.Receive and net.ReadUInt and net.ReadData and util.JSONToTable then
        net.Receive(populationChannel,function()
            local size=net.ReadUInt(16)
            if size<2 or size>60000 then return end
            local encoded=net.ReadData(size)
            if type(encoded)~="string" or #encoded~=size then return end
            local parsed,out=pcall(util.JSONToTable,encoded)
            if not parsed or type(out)~="table" or type(out.source)~="table"
                or type(out.observer)~="string" or type(out.seconds)~="number" then return end
            Audit.LastPopulationEvidence=out
            local text="[LOD:POPULATION] "..encoded.."\n"
            local ok,err=pcall(function()
                file.CreateDir("legend_of_deborah")
                file.Write("legend_of_deborah/population_latest.txt",text)
                assert(file.Read("legend_of_deborah/population_latest.txt","DATA")==text,"DATA write did not persist")
            end)
            Audit.PopulationEvidenceStatus={state="received",seconds=out.seconds,client_write=ok,
                server_write=out.server_write,error=not ok and tostring(err) or nil}
            if not ok then print("[LOD:POPULATION] Client save failed: "..tostring(err)) end
        end)
    end
    local function requestPopulation()
        Audit.LastPopulationEvidence=nil
        Audit.PopulationEvidenceStatus={state="unavailable"}
        if not net or not net.Start or not net.SendToServer then return end
        Audit.PopulationEvidenceStatus={state="requested"}
        local ok,err=pcall(function() net.Start(populationChannel);net.SendToServer() end)
        if not ok then Audit.PopulationEvidenceStatus={state="request-failed",error=tostring(err)} end
    end
    local function rendererState()
        local wall=LOD.WallVisualsClient
        local stats=wall and wall.batchStats or {}
        local out={status=stats.status or "unloaded",reason=stats.reason,hidden=stats.hidden or 0,
            think_calls=wall and wall.batchBuildTicks or 0,
            chunks=stats.chunks or 0,vertices=stats.vertices or 0,draws=stats.draws or 0,visits=stats.visits or 0,
            section=wall and wall.SectionMaterialStatus and wall:SectionMaterialStatus() or nil}
        local marks=wall and wall.wayfindingStats
        local brand=LOD.CrateBranding
        out.overlays={wayfinding=marks and {visits=marks.visits,draws=marks.draws,
            culled=marks.culled,milliseconds=marks.renderMilliseconds} or nil,
            branding=brand and {draws=brand.lastDrawCount,culled=brand.lastCulledCount,
                candidates=brand.lastCandidateCount,admitted=brand.lastAdmittedCount,
                milliseconds=brand.lastRenderMilliseconds} or nil}
        if hook.GetTable then
            local think=hook.GetTable().Think or {}
            out.hooks={batches=think.LOD_BuildContainerBatches~=nil,
                materials=think.LOD_ReconcileContainerSectionMaterials~=nil,
                wayfinding=think.LOD_ApplyContainerSectionColors~=nil}
        end
        return out
    end
    local function configuration()
        local out={width=ScrW(),height=ScrH(),engine=tostring(VERSIONSTR or VERSION or "unknown"),
            branch=tostring(BRANCH or "unknown"),os=jit and jit.os or "unknown",
            architecture=jit and jit.arch or "unknown",singleplayer=game.SinglePlayer(),
            map=game.GetMap(),proton_version="not-exposed-by-engine",window_mode="user-recorded"}
        for _,name in ipairs(settingsNames) do
            local cv=GetConVar(name);out[name]=cv and cv:GetString() or "unavailable"
        end
        return out
    end
    local function sourceIdentity()
        local expected={}
        for line in (file.Read("legend_of_deborah/dev_population_sources.txt","DATA") or ""):gmatch("[^\r\n]+") do
            local hash,path=line:match("^(%x+)%s+(.+)$")
            if hash and #hash==64 then expected[path]=hash end
        end
        local out={checked=0,missing=0,mismatches=0}
        for _,path in ipairs(renderSources) do
            local bytes=file.Read(path,"GAME")
            local actual=bytes and util.SHA256(bytes)
            if not actual or not expected[path] then out.missing=out.missing+1
            else out.checked=out.checked+1;if actual~=expected[path] then out.mismatches=out.mismatches+1 end end
        end
        out.verified=out.checked==#renderSources and out.missing==0 and out.mismatches==0
        return out
    end
    local function statistics(samples)
        local out={frames=#samples,seconds=0,over25=0,over50=0,over100=0}
        for _,ms in ipairs(samples) do
            out.seconds=out.seconds+ms/1000
            if ms>25 then out.over25=out.over25+1 end
            if ms>50 then out.over50=out.over50+1 end
            if ms>100 then out.over100=out.over100+1 end
        end
        if #samples==0 then return out end
        table.sort(samples)
        out.fps=#samples/out.seconds
        out.median_ms=samples[math.ceil(#samples*.5)]
        out.p95_ms=samples[math.ceil(#samples*.95)]
        out.p99_ms=samples[math.ceil(#samples*.99)]
        out.max_ms=samples[#samples]
        return out
    end
    function Audit:StopPerformanceCapture(reason)
        local capture=self.PerformanceCapture
        if not capture then return end
        self.PerformanceCapture=nil
        hook.Remove("PreRender","LOD_PerformanceFrames")
        hook.Remove("Think","LOD_PerformanceDeadline")
        local now=SysTime()
        local out={version="steam-deck-vr-idle-20261007",reason=reason or "manual",requested_seconds=capture.duration,sample_precision_ms=.001,
            elapsed_seconds=capture.ready and math.max(0,now-capture.start) or 0,
            total_seconds=math.max(0,now-capture.created),
            renderer_wait_seconds=capture.preparation_wait or math.max(0,now-capture.created),
            preparation_limit_seconds=30,preparation_timed_out=capture.preparation_timed_out or false,
            renderer_at_sample_start=capture.renderer_start,renderer_at_end=rendererState(),
            population=self.LastPopulationEvidence,population_status=self.PopulationEvidenceStatus,
            start_configuration=capture.config,
            end_configuration=configuration(),start_resources=capture.resources,end_resources=self:Snapshot(true),
            source=capture.source,all=statistics(capture.all),active=statistics(capture.active),
            other_frames=#capture.all-#capture.active,windows=capture.windows,
            wall_batches=LOD.WallVisualsClient and LOD.WallVisualsClient.batchStats}
        if capture.profile_requested then
            out.cpu_profile={token=capture.token,client=self:StopCPUProfile(reason),server=capture.server_profile,
                server_status=capture.server_profile and (capture.server_profile.error and "failed" or capture.server_profile.reason=="progress" and "partial" or "received")
                    or capture.profile_sent and "awaiting-reply" or "unavailable"}
            if capture.profile_sent then requestProfile(capture,false) end
        end
        local changed={}
        for k,v in pairs(out.start_configuration) do
            if v~=out.end_configuration[k] then changed[#changed+1]=k end
        end
        table.sort(changed);out.configuration_changes=changed
        out.sample_limit_reached=reason=="sample-limit"
        -- Active means deployed/alive with no menu/cinematic. Staging, death,
        -- menus and their pauses remain visible in ALL rather than masquerading
        -- as a representative loaded gameplay sample.
        out.active_definition="deployed, alive, no LOD menu or cinematic"
        self.LastPerformanceCapture=out
        self:SavePerformanceCapture(out)
        return out
    end
    function Audit:SavePerformanceCapture(out)
        local windowLines={}
        for i,w in ipairs(out.windows) do
            w.fps=w.active_seconds>0 and w.active_frames/w.active_seconds or 0
            windowLines[i]=string.format("window_%d active_seconds=%.3f frames=%d fps=%.2f over25=%d over50=%d over100=%d",i,
                w.active_seconds,w.active_frames,w.fps,w.over25,w.over50,w.over100)
        end
        local a=out.active
        local line=string.format("[LOD:PERF] active_frames=%d active_seconds=%.2f fps=%s median_ms=%.3f p95_ms=%.3f p99_ms=%.3f max_ms=%.3f over25=%d over50=%d over100=%d source_verified=%s reason=%s renderer=%s preparation_timed_out=%s",
            a.frames,a.seconds,a.fps and string.format("%.2f",a.fps) or "unmeasured",
            a.median_ms or 0,a.p95_ms or 0,a.p99_ms or 0,a.max_ms or 0,
            a.over25,a.over50,a.over100,tostring(out.source.verified),out.reason,
            out.renderer_at_end.status,tostring(out.preparation_timed_out))
        local text=line.."\n"..table.concat(windowLines,"\n").."\n"..util.TableToJSON(out,true).."\n"
        local ok,err=pcall(function()
            file.CreateDir("legend_of_deborah")
            file.Write("legend_of_deborah/performance_client_latest.txt",text)
            assert(file.Read("legend_of_deborah/performance_client_latest.txt","DATA")==text,"DATA write did not persist")
        end)
        out.saved=ok;out.save_error=not ok and tostring(err) or nil
        print(line)
        if out.cpu_profile then
            print(string.format("[LOD:PERF] CPU attribution: client_rows=%d server_status=%s server_rows=%d; inclusive timings overlap; GPU unmeasured",
                out.cpu_profile.client and #out.cpu_profile.client.rows or 0,out.cpu_profile.server_status,
                out.cpu_profile.server and out.cpu_profile.server.rows and #out.cpu_profile.server.rows or 0))
        end
        if ok then print("[LOD:PERF] Saved data/legend_of_deborah/performance_client_latest.txt")
        else print("[LOD:PERF] Save failed: "..tostring(err)) end
    end
    function Audit:StartPerformanceCapture(seconds,profileRequested)
        if self.PerformanceCapture then self:StopPerformanceCapture("restarted") end
        seconds=tonumber(seconds) or 180
        if seconds~=seconds or seconds==math.huge or seconds==-math.huge then seconds=180 end
        seconds=math.Clamp(seconds,30,300)
        local created=SysTime()
        local start=created+3
        local windows={}
        for i=1,math.ceil(seconds/5) do windows[i]={active_seconds=0,active_frames=0,over25=0,over50=0,over100=0} end
        self.PerformanceSerial=(self.PerformanceSerial or 0)%4294967295+1
        local capture={created=created,start=start,duration=seconds,finish=start+seconds,all={},active={},windows=windows,
            token=self.PerformanceSerial,profile_requested=profileRequested==true,
            config=configuration(),source=sourceIdentity(),resources=self:Snapshot(true)}
        self.PerformanceCapture=capture
        requestPopulation()
        hook.Add("PreRender","LOD_PerformanceFrames",function()
            local now=SysTime()
            if not capture.ready then
                local wall=LOD.WallVisualsClient
                local cv=GetConVar("lod_reduced_effects")
                local status=wall and wall.batchStats and wall.batchStats.status
                local waiting=cv and cv:GetBool() and wall and wall.world and #wall.world>0
                    and status~="ready" and status~="fallback" and status~="native"
                if waiting and now<capture.created+30 then return end
                -- A blocked renderer is evidence to measure, not a reason to
                -- discard every frame. Preserve its preflight state and proceed
                -- after this bounded wait with the same three-second warmup.
                capture.preparation_timed_out=waiting or false
                capture.preparation_wait=now-capture.created
                capture.renderer_start=rendererState()
                capture.ready=true;capture.start=now+3;capture.finish=capture.start+seconds
            end
            if now<capture.start then return end
            if now>=capture.finish then self:StopPerformanceCapture("complete");return end
            if capture.profile_requested and not capture.profile_started then
                capture.profile_started=true;self:StartCPUProfile()
                capture.profile_sent=requestProfile(capture,true)
            end
            local previous=capture.last;capture.last=now
            if not previous then return end
            local dt=now-previous
            if dt<=0 then return end
            local ms=math.floor(dt*1000000+.5)/1000
            capture.all[#capture.all+1]=ms
            -- Preserve one live renderer snapshot per five-second window. A
            -- shutdown cleanup may legitimately make renderer_at_end say off;
            -- it must not erase which renderer actually produced the sample.
            local index=math.floor((now-capture.start)/5)+1
            local w=capture.windows[index]
            if not w.renderer then
                w.renderer=rendererState()
                w.vr=LOD.VR and LOD.VR:WorkState() or {available=false,idle=false}
            end
            local ply=LocalPlayer()
            local active=IsValid(ply) and ply:Alive() and ply:GetNW2Bool("LOD_Deployed",false)
                and not (LOD.UI and LOD.UI.ActivePage)
                and not (LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic())
            if active then
                capture.active[#capture.active+1]=ms
                w.active_seconds=w.active_seconds+dt;w.active_frames=w.active_frames+1
                if ms>25 then w.over25=w.over25+1 end
                if ms>50 then w.over50=w.over50+1 end
                if ms>100 then w.over100=w.over100+1 end
            end
            if #capture.all>=65536 then self:StopPerformanceCapture("sample-limit") end
        end)
        hook.Add("Think","LOD_PerformanceDeadline",function()
            local now=SysTime()
            if capture.ready and now>=capture.finish then self:StopPerformanceCapture("complete")
            elseif not capture.ready and now>=capture.created+120 then self:StopPerformanceCapture("renderer-timeout") end
        end)
        print(string.format("[LOD:PERF] Recording %.0fs after up to 30s wall preparation and 3s warmup; play normally through combat, gates and a boss. Population evidence is requested automatically.",seconds))
        if capture.profile_requested then print("[LOD:PERF] Optional client/server CPU attribution will begin after warmup.") end
    end
    concommand.Add("lod_perf_start",function(_,_,args) Audit:StartPerformanceCapture(args[1],args[2]=="profile") end)
    concommand.Add("lod_perf_stop",function() Audit:StopPerformanceCapture("manual") end)
    hook.Add("ShutDown","LOD_PerformanceShutdown",function() Audit:StopPerformanceCapture("shutdown") end)
    hook.Add("PostCleanupMap","LOD_PerformanceCleanup",function() Audit:StopPerformanceCapture("map-cleanup") end)
end
