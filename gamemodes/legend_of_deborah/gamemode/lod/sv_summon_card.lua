local E,T,Run=assert(LOD.Equipment),assert(LOD.SafeTeleport),assert(LOD.RunManager)
E.SummonSessions=setmetatable({},{__mode="k"})
E.SummonPromptTimes=setmetatable({},{__mode="k"})
local serial=0
util.AddNetworkString("LOD_SummonCardMenu")
util.AddNetworkString("LOD_SummonCardChoose")
local function name(ply) return ply:GetNW2String("LOD_HeroName",ply:Nick()) end

function E:BeginSummonCard(ply,mode)
    local binding=T:Bind(ply)
    if not binding or CurTime()<(self.SummonPromptTimes[ply] or 0) then return false end
    self.SummonPromptTimes[ply]=CurTime()+self.UseCooldown
    self.SummonSessions[ply]=nil
    local targets,list={},{}
    for _,other in ipairs(player.GetAll()) do
        if other~=ply then
            local b=T:Bind(other)
            if b then targets[other]=b;list[#list+1]=other end
        end
    end
    table.sort(list,function(a,b) return Run:IdentityOf(a)<Run:IdentityOf(b) end)
    if #list==0 then self:Report(ply,"SUMMON CARD — no other active Hero", "summon_card_failed");return false end
    local item,id=self:Equipped(self:Ensure(binding.ps),"throwable")
    if not item or item.definitionId~="summon_card" then return false end
    serial=serial%4294967295+1
    self.SummonSessions[ply]={nonce=serial,owner=binding,targets=targets,item=item,id=id,mode=mode,expires=CurTime()+15}
    net.Start("LOD_SummonCardMenu")
    net.WriteUInt(serial,32);net.WriteBool(mode=="drink");net.WriteUInt(#list,8)
    for _,other in ipairs(list) do net.WriteEntity(other);net.WriteString(name(other)) end
    net.Send(ply)
    return true
end

function E:ChooseSummonCard(ply,nonce,target)
    local session=self.SummonSessions[ply]
    if not session or session.nonce~=nonce then return false end
    self.SummonSessions[ply]=nil -- one-shot, including failed/cancelled selections
    if CurTime()>=session.expires or not T:Matches(session.owner) or not self:IsActive(ply)
        or CurTime()<(self.NextUse[ply] or 0) then return false end
    local state=self:Ensure(session.owner.ps)
    local item,id=self:Equipped(state,"throwable")
    if item~=session.item or id~=session.id or not session.targets[target] then return false end
    local ok,why=T:Relocate(session.targets[target],session.owner,session.mode,function()
        return self:Consume(state,id)
    end)
    if not ok then self:Report(ply,"SUMMON CARD — "..why,"summon_card_failed");return false end
    self.NextUse[ply]=CurTime()+self.UseCooldown
    self:Sync(ply)
    LOD.Audio:Emit(target,"confirm")
    self:Report(ply,"SUMMON CARD — brought "..name(target).." to you","summon_card")
    self:Report(target,"SUMMON CARD — summoned by "..name(ply),"summon_card_arrival")
    return true
end
net.Receive("LOD_SummonCardChoose",function(bits,ply)
    if bits>64 or not IsValid(ply) then return end
    E:ChooseSummonCard(ply,net.ReadUInt(32),net.ReadEntity())
end)
local clear=E.ClearTransient
function E:ClearTransient(ply)
    if clear then clear(self,ply) end
    self.SummonSessions[ply],self.SummonPromptTimes[ply]=nil,nil
end

concommand.Add("lod_summon_card_testkit",function(ply)
    local dev=GetConVar("lod_developer_mode")
    if not dev or not dev:GetBool() or not IsValid(ply) or not ply:IsAdmin() or not T:Hero(ply) then return end
    Run:MarkUnranked("summon_card_testkit")
    local state=E:Ensure(Run:GetPlayerState(ply))
    local count=state.items.summon_card and state.items.summon_card.count or 0
    if count<3 then E:Grant(ply,"summon_card",3-count) end
    E:Equip(state,"summon_card","throwable");E:Activate(ply)
    E:Report(ply,"SUMMON CARD TEST — LMB nearby / RMB here; choose another deployed Hero.","summon_card_testkit")
end)
