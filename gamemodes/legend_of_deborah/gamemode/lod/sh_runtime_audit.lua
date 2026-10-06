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

function Audit:Snapshot()
    local missing = {}
    for _, name in ipairs(expected) do
        if LOD.RuntimeReceipts[name] ~= self.Build then missing[#missing + 1] = name end
    end
    local installation = file.Read("legend_of_deborah/dev_build.txt", "DATA") or "unrecorded"
    installation = string.sub(string.gsub(installation, "[\r\n]", " "), 1, 160)
    return {
        damsels = LOD.Damsels and LOD.Damsels.Version or 'missing',
        feedback_audio = LOD.Audio and LOD.Audio.Version or 'missing',
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

-- Opt-in rendered-frame evidence. No frame hook, sample array, hashing or disk
-- writes exist while idle. SysTime intervals between PreRender calls include the
-- complete frame, unlike tick rate or the engine's clamped RealFrameTime value.
if CLIENT then
    if Audit.StopPerformanceCapture then Audit:StopPerformanceCapture("lua-refresh") end
    local settingsNames={"fps_max","mat_vsync","mat_dxlevel","mat_queue_mode",
        "mat_antialias","mat_aaquality","mat_hdr_level","mat_picmip","mat_viewportscale",
        "r_shadows","r_shadowrendertotexture","r_waterforceexpensive","lod_reduced_effects","lod_wall_batches"}
    local renderSources={
        "gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_textured_box.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_visuals.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_wall_batch.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_container_section_recolor.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_container_wayfinding_projection.lua",
        "gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua",
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
        local out={version="steam-deck-container-overlays-20261005",reason=reason or "manual",requested_seconds=capture.duration,sample_precision_ms=.001,
            elapsed_seconds=capture.ready and math.max(0,now-capture.start) or 0,
            total_seconds=math.max(0,now-capture.created),
            renderer_wait_seconds=capture.preparation_wait or math.max(0,now-capture.created),
            preparation_limit_seconds=30,preparation_timed_out=capture.preparation_timed_out or false,
            renderer_at_sample_start=capture.renderer_start,renderer_at_end=rendererState(),
            population=self.LastPopulationEvidence,population_status=self.PopulationEvidenceStatus,
            start_configuration=capture.config,
            end_configuration=configuration(),start_resources=capture.resources,end_resources=self:Snapshot(),
            source=capture.source,all=statistics(capture.all),active=statistics(capture.active),
            other_frames=#capture.all-#capture.active,windows=capture.windows,
            wall_batches=LOD.WallVisualsClient and LOD.WallVisualsClient.batchStats}
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
        self.LastPerformanceCapture=out
        print(line)
        if ok then print("[LOD:PERF] Saved data/legend_of_deborah/performance_client_latest.txt")
        else print("[LOD:PERF] Save failed: "..tostring(err)) end
        return out
    end
    function Audit:StartPerformanceCapture(seconds)
        if self.PerformanceCapture then self:StopPerformanceCapture("restarted") end
        seconds=tonumber(seconds) or 180
        if seconds~=seconds or seconds==math.huge or seconds==-math.huge then seconds=180 end
        seconds=math.Clamp(seconds,30,300)
        local created=SysTime()
        local start=created+3
        local windows={}
        for i=1,math.ceil(seconds/5) do windows[i]={active_seconds=0,active_frames=0,over25=0,over50=0,over100=0} end
        local capture={created=created,start=start,duration=seconds,finish=start+seconds,all={},active={},windows=windows,
            config=configuration(),source=sourceIdentity(),resources=self:Snapshot()}
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
            if not w.renderer then w.renderer=rendererState() end
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
    end
    concommand.Add("lod_perf_start",function(_,_,args) Audit:StartPerformanceCapture(args[1]) end)
    concommand.Add("lod_perf_stop",function() Audit:StopPerformanceCapture("manual") end)
    hook.Add("ShutDown","LOD_PerformanceShutdown",function() Audit:StopPerformanceCapture("shutdown") end)
end
