-- Real audit capture, deterministic rendered-frame clock/native doubles.
-- Percentile/sample/state/lifecycle checks; never a target-hardware measurement.
CLIENT=true;SERVER=false;LOD={UI={}}
local noop=function() end
local now=0;SysTime=function() return now end;RealTime=SysTime
local hooks,commands={},{ }
hook={Add=function(event,id,fn) hooks[event]=hooks[event] or {};hooks[event][id]=fn end,
    Remove=function(event,id) if hooks[event] then hooks[event][id]=nil end end}
concommand={Add=function(id,fn) commands[id]=fn end};timer={Create=noop}
local files,writes={},0
local reads=0
file={CreateDir=noop,Read=function(path,realm) reads=reads+1;return files[realm..':'..path] end,
    Write=function(path,text) writes=writes+1;files['DATA:'..path]=text end}
util={SHA256=function(bytes) return string.rep(bytes=='exact' and 'a' or 'b',64) end,
    TableToJSON=function() return '{}' end}
function math.Clamp(n,a,b) return math.max(a,math.min(b,n)) end
ents={GetCount=function() return 3000 end}
function ScrW() return 1280 end;function ScrH() return 800 end
game={GetMap=function() return 'gm_flatgrass' end,SinglePlayer=function() return true end}
local settings={lod_reduced_effects='1',fps_max='300',mat_vsync='0'}
GetConVar=function(name)
    if not settings[name] then return end
    return {GetString=function() return settings[name] end,GetBool=function() return settings[name]=='1' end}
end
local ply={alive=true,deployed=true}
function IsValid(e) return type(e)=='table' and e.valid~=false end
function LocalPlayer() return ply end
function ply:Alive() return self.alive end
function ply:GetNW2Bool(name) assert(name=='LOD_Deployed');return self.deployed end
LOD.WallVisualsClient={world={{}},models={},batchStats={status='building'}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local paths={'gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua',
    root..'cl_textured_box.lua',root..'cl_wall_visuals.lua',root..'cl_wall_batch.lua',
    root..'cl_container_section_recolor.lua',root..'sh_runtime_audit.lua'}
local manifest={}
for _,p in ipairs(paths) do manifest[#manifest+1]=string.rep('a',64)..'  '..p;files['GAME:'..p]='exact' end
files['DATA:legend_of_deborah/dev_population_sources.txt']=table.concat(manifest,'\n')
files['DATA:legend_of_deborah/dev_build.txt']='test-checkout clean'
dofile(root..'sh_runtime_audit.lua')
local A=LOD.RuntimeAudit
local function fire(event)
    local work={};for _,fn in pairs(hooks[event] or {}) do work[#work+1]=fn end
    for _,fn in ipairs(work) do fn() end
end
assert(not hooks.PreRender,'idle frame sampler installed')
assert(commands.lod_perf_start and commands.lod_perf_stop)
commands.lod_perf_start(nil,nil,{'180'})
assert(A.PerformanceCapture.source.verified and A.PerformanceCapture.source.checked==6)
local startReads=reads
-- Preparing batches is separated from sustained gameplay; no empty warmup data.
now=20;fire('PreRender');fire('Think');assert(#A.PerformanceCapture.all==0)
LOD.WallVisualsClient.batchStats.status='ready';fire('PreRender')
assert(A.PerformanceCapture.start==23 and A.PerformanceCapture.finish==203)
now=23;fire('PreRender')
local oracle,active={},0
for i=1,6000 do
    local dt=i%50==0 and .12 or .025
    now=now+dt
    if now>=203 then break end
    ply.deployed=now>=43
    ply.alive=not (now>=53 and now<58)
    LOD.UI.ActivePage=now>=73 and now<78 and 'options' or nil
    oracle[#oracle+1]=dt*1000
    if ply.deployed and ply.alive and not LOD.UI.ActivePage then active=active+1 end
    fire('PreRender');fire('Think')
end
now=203;fire('Think')
local out=assert(A.LastPerformanceCapture)
assert(out.reason=='complete' and out.source.verified and out.renderer_wait_seconds==20)
assert(out.all.frames==#oracle and out.active.frames==active and out.other_frames==#oracle-active)
assert(math.abs(out.active.median_ms-25)<1e-7 and math.abs(out.active.p99_ms-120)<1e-7)
assert(out.active.over100>80 and out.active.fps<40 and out.active.seconds>120)
assert(out.active.over25==out.active.over100,'floating-point noise misclassified 25ms frames')
assert(#out.windows==36 and out.windows[1].active_frames==0 and out.windows[10].active_frames>0,'sparse window loss')
local windowFrames=0;for _,w in ipairs(out.windows) do windowFrames=windowFrames+w.active_frames end
assert(windowFrames==out.active.frames,'window aggregation dropped gameplay')
assert(out.start_configuration.width==1280 and out.start_configuration.height==800 and #out.configuration_changes==0)
assert(files['DATA:legend_of_deborah/performance_client_latest.txt']:find('p99_ms=120.000',1,true))
assert(not next(hooks.PreRender) and not next(hooks.Think),'sampler left recurring hooks')
local afterReads=reads;assert(afterReads-startReads==1,'per-frame hashing/I/O occurred')
local written=writes;fire('PreRender');fire('Think');commands.lod_perf_stop();assert(writes==written)
-- Build identity remains independently verified. Missing/tampered mounts are
-- explicit; the installed SHA label does not certify the loaded client bytes.
files['GAME:'..paths[1]]='tampered';A:StartPerformanceCapture(30)
assert(not A.PerformanceCapture.source.verified and A.PerformanceCapture.source.mismatches==1)
settings.mat_vsync='1';out=A:StopPerformanceCapture('manual')
assert(out.all.frames==0 and out.active.frames==0 and out.configuration_changes[1]=='mat_vsync')
files['GAME:'..paths[1]]='exact';files['DATA:legend_of_deborah/dev_population_sources.txt']=''
A:StartPerformanceCapture('invalid');assert(A.PerformanceCapture.duration==180 and A.PerformanceCapture.source.missing==6)
A:StopPerformanceCapture('manual')
-- Lifecycle cleanup and bounded collection, even at absurd synthetic FPS.
ply.deployed=true;ply.alive=true;LOD.UI.ActivePage=nil
A:StartPerformanceCapture(math.huge);assert(A.PerformanceCapture.duration==180)
fire('PreRender');now=A.PerformanceCapture.start;fire('PreRender')
for _=1,65536 do now=now+.0001;fire('PreRender') end
out=A.LastPerformanceCapture;assert(out.sample_limit_reached and out.all.frames==65536 and not A.PerformanceCapture)
A:StartPerformanceCapture(10000);assert(A.PerformanceCapture.duration==300)
fire('ShutDown');assert(not A.PerformanceCapture and A.LastPerformanceCapture.reason=='shutdown')
A:StartPerformanceCapture(-1);assert(A.PerformanceCapture.duration==30)
dofile(root..'sh_runtime_audit.lua');assert(not A.PerformanceCapture and A.LastPerformanceCapture.reason=='lua-refresh')
LOD.WallVisualsClient.batchStats.status='building';A:StartPerformanceCapture(30)
now=now+121;fire('Think');assert(not A.PerformanceCapture and A.LastPerformanceCapture.reason=='renderer-timeout')
LOD.WallVisualsClient.batchStats.status='ready';A:StartPerformanceCapture(30)
local oldWrite=file.Write;file.Write=function() error('injected disk failure') end
out=A:StopPerformanceCapture('manual');assert(out and not A.PerformanceCapture and not next(hooks.PreRender))
file.Write=oldWrite
print('PERFORMANCE_CAPTURE_PASS: opt-in/idle; frame clock and percentiles; active/staged/dead/menu separation; all 36 pacing windows; build/settings/resource evidence; preparation excluded; 65536 limit; reset/refresh/shutdown/I/O cleanup')
