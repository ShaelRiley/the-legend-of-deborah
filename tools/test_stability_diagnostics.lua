local hooks,files,now={},{},1
SERVER=true;LOD={};hook={Add=function(_,id,fn) hooks[id]=fn end}
timer={Create=function() end};concommand={Add=function() end}
RealTime=function() return now end
file={CreateDir=function() end,Write=function(path,s) files[path]=s end,Read=function() return nil end}
ents={GetCount=function() return 10 end}
IsValid=function() return false end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_runtime_audit.lua')
for i=1,1000 do hooks.LOD_RuntimeLuaErrors('failure '..i,'client',{{File='test.lua',Line=42,Function='test'}}) end
assert(LOD.RuntimeAudit.ErrorCount==1000 and #LOD.RuntimeAudit.Journal==1,'error storm must be counted and rate limited')
for i=1,100 do now=now+1;LOD.RuntimeAudit:Record('NATIVE_STAGE',string.rep('x',5000)) end
local s=files['legend_of_deborah/stability_server_latest.txt']
assert(#LOD.RuntimeAudit.Journal==64 and #s<200000,'durable evidence is unbounded')
assert(LOD.RuntimeAudit:Snapshot().lua_errors==1000)
file.Write=function() error('disk unavailable') end
LOD.RuntimeAudit:Record('TEST','disk fault');assert(not LOD.RuntimeAudit.WritingJournal,'I/O failure latched diagnostics')
print('STABILITY_DIAGNOSTICS_PASS: bounded durable evidence, flood counters, I/O failure isolation')
