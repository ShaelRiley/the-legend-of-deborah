-- Exercise the real server with a backpressured channel and adversarial ACKs.
local registered, receivers, messages, scheduled, hooks, recurring = {}, {}, {}, {}, {}, {}
local html = '<!doctype html>' .. string.rep('book', 20000)
local now, reads = 10, {}
LOD = {};isstring = function(v) return type(v)=='string' end
IsValid = function(v) return type(v)=='table' and v.valid~=false end
RealTime=function() return now end
include=function(path)
 if path:find('manifest',1,true) then return {version='test',chapters=124,chunks=1} end
 return html
end
util={Compress=function(v) return v end,AddNetworkString=function(id) registered[id]=true end}
hook={Add=function(_,id,fn) hooks[id]=fn end}
timer={Simple=function(_,fn) scheduled[#scheduled+1]=fn end,Create=function(id,_,_,fn) recurring[id]=fn end}
local writing
net={Receive=function(id,fn) receivers[id]=fn end,Start=function(id) writing={name=id,fields={}} end,
 WriteString=function(v) writing.fields[#writing.fields+1]=v end,
 WriteUInt=function(v) writing.fields[#writing.fields+1]=v end,
 WriteData=function(v) writing.fields[#writing.fields+1]=v end,
 ReadUInt=function() return table.remove(reads,1) end,
 Send=function(p) writing.player=p;messages[#messages+1]=writing;writing=nil end}
dofile('gamemodes/legend_of_deborah/gamemode/lod/sv_instruction_manual.lua')
local T=LOD.InstructionManualTransport
local p={};receivers.LOD_RequestInstructionManual(0,p)
assert(#messages==1 and #scheduled==0,'only one message may be in flight')
local pieces={}
for index=1,T.ChunkCount do
 local f=messages[#messages].fields
 assert(f[4]==index and f[7]<=16384 and f[7]==#f[8]);pieces[index]=f[8]
 local n=#messages
 reads={f[3]+1,index};receivers.LOD_InstructionManualAck(24,p)
 assert(#messages==n and #scheduled==0,'foreign transfer ACK advanced stream')
 reads={f[3],index};receivers.LOD_InstructionManualAck(24,p)
 reads={f[3],index};receivers.LOD_InstructionManualAck(24,p)
 if index<T.ChunkCount then
  assert(#scheduled==1,'duplicate ACK scheduled another chunk')
  local fn=table.remove(scheduled,1);fn();assert(#messages==n+1)
 end
end
assert(table.concat(pieces)==html and not T.Active[p])
now=20;receivers.LOD_RequestInstructionManual(0,p);assert(T.Active[p])
now=41;recurring.LOD_ManualTransferExpiry();assert(not T.Active[p],'lost ACK retains transfer')
receivers.LOD_RequestInstructionManual(0,p);hooks.LOD_ManualTransferCleanup(p)
assert(not T.Active[p] and not T.LastRequest[p])
local n=#messages;receivers.LOD_RequestInstructionManual(0,{valid=false});assert(#messages==n)
print('MANUAL_TRANSPORT_PASS: exact bytes, one in-flight chunk, duplicate/foreign ACK, expiry, disconnect')
