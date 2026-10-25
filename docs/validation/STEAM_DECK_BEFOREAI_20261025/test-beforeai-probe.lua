local source=assert(io.open((debug.getinfo(1,'S').source:sub(2):match('^(.*[/])') or './')..'bench_beforeai_start.lua')):read('*a')
local realinfo=debug.getinfo
local ticks=0;function SysTime()ticks=ticks+.00001;return ticks end
SERVER=true;local written={};local spec={variant='on'}
file={Read=function()return ''end,Write=function(p,v)written[p]=v end};util={JSONToTable=function()return spec end,TableToJSON=function(v)return v end}
timer={Create=function()end,Remove=function()end}
local function setup(fn,variant,inherited)
 written={};spec.variant=variant or'on';LOD={RuntimeAudit={},EntrySafety=inherited and setmetatable({},{__index={BeforeAI=fn}})or{BeforeAI=fn}}
 debug.getinfo=function(f,what)if f==fn then return{linedefined=496,source='sv_entry_safety.lua'}end return realinfo(f,what)end
 assert(load(source:gsub('local capacity=524288','local capacity=8')))()
 return LOD.BenchBeforeAI,LOD.EntrySafety
end
local calls=0;local original=function(self,a,b,c)calls=calls+1;assert(a==12 and b==nil and c==23);return nil,7,nil,9 end
local l,o=setup(original);local a,b,c,d=o:BeforeAI(12,nil,23);assert(a==nil and b==7 and c==nil and d==9 and calls==1)
assert(l.calls==1 and l.completed==1 and l.max_active==1 and #l.starts==8);assert(l:Stop('explicit').passed and o.BeforeAI==original)
l,o=setup(original,'off');assert(o.BeforeAI==original and l.calls==0);assert(l:Stop('explicit').passed)
l,o=setup(original,'on',true);assert(l:Stop('explicit').passed and rawget(o,'BeforeAI')==nil and o.BeforeAI==original)
l,o=setup(original);local foreign=function()end;o.BeforeAI=foreign;assert(not l:Stop('explicit').passed and o.BeforeAI==foreign)
l,o=setup(function()error('sentinel',0)end);local ok,err=pcall(o.BeforeAI,o);assert(not ok and err=='sentinel');assert(not l:Stop('explicit').passed and l.calls==1 and l.completed==0)
l,o=setup(function()coroutine.yield('yield');return 'done',nil,3 end);local co=coroutine.create(function()return o:BeforeAI()end);local ok,v=coroutine.resume(co);assert(ok and v=='yield');local ok,a,b,c=coroutine.resume(co);assert(ok and a=='done'and b==nil and c==3);assert(l:Stop('explicit').passed)
l,o=setup(original);local before=calls;for i=1,9 do o:BeforeAI(12,nil,23)end;assert(calls-before==9 and l.overflow and not l:Stop('explicit').passed)
debug.getinfo=realinfo;print('PASS: exact forwarding/nil returns/off/inherited restore/foreign owner/error/yield/overflow')
