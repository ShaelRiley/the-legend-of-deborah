-- Music reads gameplay state; it never starts clocks, opens gates or delays play.
LOD.MusicDirector = LOD.MusicDirector or {}
local D,M,R=LOD.MusicDirector,LOD.Music,LOD.RunManager
D.Listeners=setmetatable({}, {__mode="k"})
D.Settings={set="all",profile="",post_victory="auto",universal_boss=false,universal_victory=false,universal_interlude=false}
local ROOT="legend_of_deborah/music/"
local enabled=CreateConVar("lod_music_enabled","0",bit.bor(FCVAR_ARCHIVE,FCVAR_REPLICATED,FCVAR_NOTIFY),
    "Permit optional streamed music. Disabled by default; player Off always wins.",0,1)
for _,name in ipairs({"LOD_MusicPlan","LOD_MusicState","LOD_MusicPlaying","LOD_MusicSwitch"}) do util.AddNetworkString(name) end
local function report(p,text)
    text="[LOD:MUSIC] "..text;print(text);if IsValid(p) then p:ChatPrint(text) end
end
local function operator(p) return not IsValid(p) or p:IsSuperAdmin() end
function D:Enabled(p)
    return enabled:GetBool() and (not p or p:GetInfoNum("lod_music",1)~=0)
end
function D:LoadCatalog(path)
    local raw=file.Read(path or ROOT.."catalog.json","DATA")
    if not raw or #raw>M.Limits.catalogBytes then return false,"catalog absent or too large" end
    local ok,c,err=pcall(function() return M.ValidateCatalog(util.JSONToTable(raw)) end)
    if not ok or not c then return false,tostring(err or c) end
    -- Do not discard a valid restricted catalog if an attempted replacement loses it.
    if self.Settings.set~="all" then local pool,why=M.Pool(c,self.Settings.set);if not pool then return false,why end end
    if self.Settings.profile~="" and not c.profiles[self.Settings.profile] then return false,"configured profile missing" end
    local missing={};local profile=c.profiles[c.projectDefault or ""]
    for _,role in ipairs(M.Roles) do
        if not profile or not c.assets[profile.roles[role]] then missing[#missing+1]=role end
    end
    self.Warning=#missing>0 and ("project defaults missing: "..table.concat(missing,",")) or nil
    self.Catalog=c;self.Error=nil;return true,"catalog "..c.revision.." loaded for future plans"
end
function D:Configure(key,value)
    local next=table.Copy(self.Settings)
    if key=="set" then
        if not M.ID(value) then return false,"invalid set ID" end
        if value~="all" then local pool,err=self.Catalog and M.Pool(self.Catalog,value);if not pool then return false,err or "catalog unavailable" end end
    elseif key=="profile" then
        if value~="" and (not self.Catalog or not self.Catalog.profiles[value]) then return false,"unknown default profile" end
    elseif key=="post_victory" then
        if value~="auto" and value~="interlude" and value~="off" then return false,"expected auto, interlude or off" end
    elseif key:match("^universal_") then
        if value~="0" and value~="1" then return false,"expected 0 or 1" end
        value=value=="1"
    else return false,"unknown option" end
    next[key]=value;self.Settings=next
    file.CreateDir(ROOT);file.Write(ROOT.."settings.json",util.TableToJSON(next,true))
    return true,"saved for newly planned dungeons"
end
function D:Prepare(s,level)
    s.MusicPlans=s.MusicPlans or {}
    if s.MusicPlans[level] then return s.MusicPlans[level] end
    -- The ingestion service queues an explicit reload. Consume it only at a new
    -- plan boundary, with no directory scan or recurring media-network work.
    local request=file.Read(ROOT.."reload.json","DATA")
    if request and #request<512 then
        local r=util.JSONToTable(request)
        if r and r.revision~=self.ReloadReceipt then
            local ok,why=self:LoadCatalog()
            if ok then self.ReloadReceipt=r.revision else self.Error=why end
        end
    end
    local id=tostring(s.RunId or s.CampaignEpoch)..":"..level
    local plan,err
    if self.Catalog then plan,err=M.Plan(self.Catalog,self.Settings,
        LOD.Seeds.DeriveLevel(s.CampaignSeed,level),id,#LOD.Config.Maze.LayerOccupancy,s.CampaignEpoch) end
    -- Even an empty offered plan is frozen. Loading assets never reshuffles it.
    plan=plan or {id=id,epoch=s.CampaignEpoch,created=CurTime(),floors={},blocks={},assets={},settings=table.Copy(self.Settings),error=err or "no catalog"}
    s.MusicPlans[level]=plan
    for old in pairs(s.MusicPlans) do if old<level-1 or old>level+1 then s.MusicPlans[old]=nil end end
    return plan
end
function D:Listener(p)
    local l=self.Listeners[p]
    if not l then l={sent={},damage={},sequence=0,confirmed=0};self.Listeners[p]=l end
    return l
end
function D:ClearAccepted(s)
    if s.MusicVictory and s.MusicVictory.level==s.Level then return end
    local plan=self:Prepare(s,s.Level)
    local a=s.Graph and s.Graph.Progression and s.Graph.Progression.Warden
    local floor=a and a.entry.z+1 or 1
    local v={id=plan.id..":clear",level=s.Level,plan=plan,block=plan.floors[floor],
        startedAt=CurTime(),endsAt=CurTime()+6.5,participants=setmetatable({}, {__mode="k"})}
    for _,p in ipairs(player.GetAll()) do
        if self:Enabled(p) then v.participants[p]=true end
    end
    s.MusicVictory=v
    v.next=self:Prepare(s,s.Level+1)
end
function D:Pressure(p,l,s,staging)
    local now=CurTime();local hits=0
    for i=#l.damage,1,-1 do if now-l.damage[i]>M.Tuning.damageWindow then table.remove(l.damage,i) else hits=hits+1 end end
    local remaining=math.huge
    if s.CampaignClock and LOD.CampaignTimeout then remaining=LOD.CampaignTimeout:Remaining(s.CampaignClock,SysTime()) or math.huge end
    l.pressure=M.Pressure(l.pressure,{staging=staging,recent=hits>0 or now<(l.combatUntil or 0),hits=hits,
        hp=p:Health()/math.max(1,p:GetMaxHealth()),remaining=remaining},now)
    return "T"..l.pressure.value
end
function D:Target(p,l,s)
    local plan=self:Prepare(s,s.Level);local ps=R:GetPlayerState(p)
    local staged=p:GetNW2Bool("LOD_Staged",false) or not ps or ps.deploymentComplete~=true
    local t={plan=plan.id,epoch=s.CampaignEpoch,targets={},role="T0"}
    local v=s.MusicVictory
    if v and s.Level>=v.level and s.Level<=v.level+1 then
        -- Receipt is independent of old maze entities and survives successful cleanup.
        if s.LevelCleared or not s.BuildReady or s.Level==v.level then
            t.plan=v.plan.id;t.role="POST";t.victory=v.id;t.endsAt=v.endsAt;t.startedAt=v.startedAt
            t.canVictory=v.participants[p]==true and CurTime()<v.endsAt
            t.targets={{block=v.block,weight=1}};t.next=v.next.id;t.nextBlock=v.next.floors[1]
            t.policy=v.plan.settings.post_victory;t.staged=false
            return t,{v.plan,v.next}
        end
    end
    if not s.BuildReady then return t,{plan} end
    if staged then t.targets={{block=plan.floors[1],weight=1}};t.staged=true;return t,{plan} end
    if not p:Alive() then return t,{plan} end
    local a,b,f=M.Floors(s.Graph,p:GetPos(),p:OnGround(),l.floor)
    if a==b then l.floor=a elseif f<.01 then l.floor=a elseif f>.99 then l.floor=b end
    local w=s.Warden;local arena=s.Graph.Progression and s.Graph.Progression.Warden
    local cell=LOD.MazeNavigator:WorldToCell(s.Graph,p:GetPos())
    local key=cell and LOD.MazeGenerator.CellKey(cell.x,cell.y,cell.z)
    local inside=arena and key and (arena.court[key] or key==LOD.MazeGenerator.CellKey(arena.entry.x,arena.entry.y,arena.entry.z))
    if inside and w and w.started then
        local continuing=not w.dead or s.Level==20 and not (LOD.Hector and LOD.Hector:RescueAllowed(s))
        t.role=continuing and "BOSS" or "T0"
        t.targets={{block=plan.floors[arena.entry.z+1],weight=1}}
        t.preload=continuing and "VICTORY" or nil
    else
        t.role=self:Pressure(p,l,s,false)
        local ba,bb=plan.floors[a],plan.floors[b]
        if ba==bb then t.targets={{block=ba,weight=1}}
        else t.targets={{block=ba,weight=1-f},{block=bb,weight=f}} end
        t.floor=a;t.destination=b;t.fraction=math.floor(f*100+.5)/100
        if arena and key==LOD.MazeGenerator.CellKey(arena.entry.x,arena.entry.y,arena.entry.z) then t.preload="BOSS" end
    end
    return t,{plan}
end
function D:SendPlan(p,l,plan)
    if l.sent[plan.id] then return true end
    local raw=util.TableToJSON(plan);local data=raw and util.Compress(raw)
    if not data or #data>M.Limits.packetBytes then self.Error="music plan exceeds transport limit";return false end
    net.Start("LOD_MusicPlan");net.WriteUInt(#data,16);net.WriteData(data,#data);net.Send(p)
    l.sent[plan.id]=true
    return true
end
function D:Update(p,s)
    local l=self:Listener(p);local on=self:Enabled(p)
    if l.on~=on then
        l.on=on;l.lastPacket=nil
        net.Start("LOD_MusicSwitch");net.WriteBool(on);net.Send(p)
        if not on and s.MusicVictory then s.MusicVictory.participants[p]=nil end
    end
    if not on then return end
    if l.epoch~=s.CampaignEpoch then
        l.epoch=s.CampaignEpoch;l.sent={};l.allowed={};l.damage={};l.pressure=nil;l.floor=nil;l.lastBlock=nil
    end
    local target,plans
    if s.Failed then target={epoch=s.CampaignEpoch,stop=true};plans={}
    else target,plans=self:Target(p,l,s) end
    local allowed={}
    for _,plan in ipairs(plans) do if not self:SendPlan(p,l,plan) then return end end
    for _,entry in ipairs(target.targets or {}) do
        if entry.block and entry.weight>0 then allowed[entry.block]=true end
    end
    if target.nextBlock then allowed[target.nextBlock]=true end
    l.allowed=allowed;l.plans=plans;l.snapshot=target
    local keep={};for _,plan in ipairs(plans) do keep[plan.id]=true end
    for id in pairs(l.sent) do if not keep[id] then l.sent[id]=nil end end
    local raw=util.TableToJSON(target)
    if raw~=l.lastPacket then
        l.sequence=l.sequence+1;target.sequence=l.sequence
        net.Start("LOD_MusicState");net.WriteString(util.TableToJSON(target));net.Send(p)
        l.lastPacket=raw
    end
end
hook.Add("Think","LOD_MusicDirector",function()
    if CurTime()<(D.nextTick or 0) then return end;D.nextTick=CurTime()+M.Tuning.tick
    local s=R.State;if not s then return end
    for _,p in ipairs(player.GetAll()) do
        local ok,err=pcall(D.Update,D,p,s)
        if not ok then D.Error=tostring(err) end -- presentation failure cannot end a run
    end
end)
hook.Add("PostEntityTakeDamage","LOD_MusicDamage",function(p,dmg,took)
    if took and IsValid(p) and p:IsPlayer() and D:Enabled(p) then
        local l=D:Listener(p);l.damage[#l.damage+1]=CurTime()
        if #l.damage>12 then table.remove(l.damage,1) end
    end
    local attacker=took and dmg and dmg.GetAttacker and dmg:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and D:Enabled(attacker) then
        D:Listener(attacker).combatUntil=CurTime()+M.Tuning.damageWindow
    end
end)
net.Receive("LOD_MusicPlaying",function(bits,p)
    if bits>2048 or not D:Enabled(p) then return end
    local seq=net.ReadUInt(32);local serial=net.ReadUInt(32);local bid=net.ReadString()
    local l=D.Listeners[p];local s=R.State
    if not l or not s or s.Failed or l.epoch~=s.CampaignEpoch or seq>l.sequence
        or seq<l.sequence-40 or serial<=l.confirmed or not l.allowed or not l.allowed[bid] then return end
    local window=math.floor(CurTime())
    if l.confirmWindow~=window then l.confirmWindow=window;l.confirmCount=0 end
    if l.confirmCount>=8 then return end
    l.confirmed=serial;l.confirmCount=l.confirmCount+1
    if l.lastBlock==bid then return end
    for _,plan in ipairs(l.plans or {}) do
        local block=plan.blocks[bid]
        if block then
            l.lastBlock=bid
            -- A private semantic family uses exactly the same record path as L.
            LOD.CombatRolls:_Send(p,3,"Now playing: "..block.title,"music",
                {event="MUSIC_BLOCK_START",blockId=bid,plan=plan.id})
            return
        end
    end
end)
hook.Add("PlayerDisconnected","LOD_MusicLeave",function(p)
    D.Listeners[p]=nil;local s=R.State
    if s and s.MusicVictory then s.MusicVictory.participants[p]=nil end
end)
cvars.AddChangeCallback("lod_music_enabled",function()
    local s=R.State
    if not enabled:GetBool() and s and s.MusicVictory then s.MusicVictory.participants=setmetatable({}, {__mode="k"}) end
    for _,p in ipairs(player.GetAll()) do
        local l=D:Listener(p);l.on=nil;l.lastPacket=nil
        net.Start("LOD_MusicSwitch");net.WriteBool(D:Enabled(p));net.Send(p)
    end
end,"LOD_MusicMaster")
for _,key in ipairs({"set","profile","post_victory","universal_boss","universal_victory","universal_interlude"}) do
    local option=key
    concommand.Add("lod_music_"..key,function(p,_,args)
        if not operator(p) then return end
        if #args==0 then report(p,option.."="..tostring(D.Settings[option]));return end
        local ok,why=D:Configure(option,args[1]);report(p,(ok and "" or "rejected: ")..why)
    end)
end
concommand.Add("lod_music_reload",function(p)
    if not operator(p) then return end
    local ok,why=D:LoadCatalog();if not ok then D.Error=why end;report(p,why)
end)
concommand.Add("lod_music_import",function(p,_,args)
    if not operator(p) then return end
    local id=args[1];if not M.ID(id) then report(p,"expected validated staged upload ID");return end
    -- Only the authenticated companion service writes these validated snapshots.
    local path=ROOT.."imports/"..id..".json"
    local ok,why=D:LoadCatalog(path)
    if ok then file.Write(ROOT.."catalog.json",util.TableToJSON(D.Catalog,true)) end
    report(p,why)
end)
concommand.Add("lod_music_status",function(p)
    if not operator(p) then return end
    local s=R.State;local plan=s and s.MusicPlans and s.MusicPlans[s.Level]
    local listeners={}
    for who,l in pairs(D.Listeners) do listeners[#listeners+1]={player=who:EntIndex(),enabled=l.on,state=l.snapshot} end
    report(p,util.TableToJSON({enabled=enabled:GetBool(),configured=D.Settings,
        catalog=D.Catalog and D.Catalog.revision,currentPlan=plan and plan.id,
        active=plan and plan.settings,eligible=plan and plan.eligible,listeners=listeners,warning=D.Warning,error=D.Error or plan and plan.error}))
end)
do
    file.CreateDir(ROOT)
    local raw=file.Read(ROOT.."settings.json","DATA")
    local saved=raw and #raw<4096 and util.JSONToTable(raw)
    -- Load catalog before validating persisted set/profile selection.
    local ok,why=D:LoadCatalog();if not ok then D.Error=why end
    if type(saved)=="table" then
        for key in pairs(D.Settings) do
            if saved[key]~=nil then
                local value=saved[key];if type(value)=="boolean" then value=value and "1" or "0" end
                local accepted=D:Configure(key,tostring(value))
                if not accepted and (key=="set" or key=="profile") then
                    -- Preserve a saved restriction during a temporarily missing catalog.
                    if M.ID(tostring(value)) then D.Settings[key]=value;D.Error="saved selection unavailable" end
                end
            end
        end
    end
end
