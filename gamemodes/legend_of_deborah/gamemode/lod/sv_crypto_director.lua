-- Approved $DEB and Debbie Fund Token economy; persistent state is server-only.
LOD.CryptoDirector={}
local C,Store,E,Run=LOD.CryptoDirector,LOD.CryptoStore,LOD.Equipment,LOD.RunManager
C.Milestones={1,5,10,20}
function C:Ranked()
    local r=Run.State
    return Store.Ready and r and r.Ranked==true and not r.Failed and r.RunId~=nil
end
function C:Account(ply)
    local id=IsValid(ply) and ply:IsPlayer() and Run:IdentityOf(ply)
    if Store:ValidAccount(id) then
        Store.Names=Store.Names or {};Store.Names[id]=string.sub(ply:Nick(),1,96)
        return id
    end
end
function C:LevelState()
    local r=Run.State
    if not r.crypto or r.crypto.level~=r.Level then
        r.crypto={level=r.Level,heroes={},soldiers={},eliminations=0,damageToHeroes={},wounds={}}
    end
    return r.crypto
end
function C:Participate(ply)
    local id=self:Account(ply)
    if not id or not self:Ranked() then return end
    local s=self:LevelState()
    if Run:IsSoldierControl(ply) then s.soldiers[id]=s.soldiers[id] or 0
    elseif Run:IsActivePlayer(ply) then s.heroes[id]=s.heroes[id] or 0 end
end
function C:GenerateToken(id,source,reason,depth)
    local r=Run.State
    local seed=LOD.Seeds.Derive(r.CampaignSeed or 1,'dft:item:'..id..':'..source)
    local families={}
    for _,f in ipairs(E.FamilyOrder) do families[#families+1]=f end
    for _,f in ipairs(E.WeaponFamilies) do families[#families+1]=f end
    local rng=LOD.RNG.New(LOD.Seeds.Derive(seed,'family'))
    local tokenId=id..':'..source
    return {id=tokenId,item=E:Generate(seed,depth,families[rng:Int(1,#families)],'dft:'..tokenId),
        reason=reason,depth=depth,run=Run.State.RunId,source=source}
end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
function C:PromotePending(a)
    for _,level in ipairs(self.Milestones) do
        local key=tostring(level);local token=a.pending[key]
        if token and count(a.tokens)<8 then a.tokens[token.id]=token;a.pending[key]=nil end
    end
end
function C:Milestone(id,level)
    if not self:Ranked() or not Run.State.LevelCleared or not Store:ValidAccount(id) then return false end
    local key=tostring(level)
    local event='milestone:'..id..':'..key
    return Store:Transaction(event,'milestone',{id},function(accounts)
        local a=accounts[id]
        if a.milestones[key] then return false,'already' end
        local t=self:GenerateToken(id,'milestone:'..key,'Combat Level '..key,Run.State.Level)
        a.milestones[key]=true;a.pending[key]=t
        self:PromotePending(a)
        local receipt={token=t.id,level=level,pending=a.pending[key]~=nil}
        Store:History(id,event,'milestone',receipt)
        return true,receipt
    end)
end
function C:CheckMilestones(plyOrId)
    if not self:Ranked() or not Run.State.LevelCleared then return end
    local id=type(plyOrId)=='string' and plyOrId or self:Account(plyOrId)
    if not Store:ValidAccount(id) then return end
    local ps=Run:GetPlayerState(id)
    local p=ps and ps.progressionState
    if not p or p.actorType~='hero' then return end
    if IsValid(plyOrId) and Run:IsSoldierControl(plyOrId) then return end
    local a=Store:Read(id);if not a then return end
    local changed=false
    for _,level in ipairs(self.Milestones) do
        if p.level>=level and not a.milestones[tostring(level)] then
            local ok=self:Milestone(id,level);changed=ok or changed
        end
    end
    if changed and IsValid(plyOrId) then self:Sync(plyOrId) end
end
function C:Allocations(s,depth)
    local pool=100*depth
    local soldierTotal=0
    for _,n in pairs(s.soldiers) do soldierTotal=soldierTotal+n end
    local soldierPool=soldierTotal>0 and math.floor(pool*math.min(33,11*s.eliminations)/100) or 0
    local weights,contribution,total,n={},{},0,0
    for id,score in pairs(s.heroes) do
        if s.soldiers[id]==nil then contribution[id]=score;total=total+score;n=n+1 end
    end
    for id,score in pairs(contribution) do weights[id]=.5/n+(total>0 and .5*score/total or .5/n) end
    local allocations={}
    local function distribute(units,w,role)
        for _,share in ipairs(LOD.CombatAttributionSystem:LargestRemainderShares(units,w)) do
            allocations[share.identity]={amount=share.amount,role=role}
        end
    end
    distribute(pool-soldierPool,weights,'hero');distribute(soldierPool,s.soldiers,'soldier')
    return allocations,pool,soldierPool
end
function C:Settle()
    if not self:Ranked() or not Run.State.LevelCleared then return false end
    local r=Run.State;local s=self:LevelState()
    if s.settled then return false,'already' end
    local allocations,pool,soldierPool=self:Allocations(s,r.Level)
    local ids={};for id in pairs(allocations) do ids[#ids+1]=id end;table.sort(ids)
    local event='rescue:'..r.RunId..':'..r.Level
    local ok,receipt=Store:Transaction(event,'rescue',ids,function(accounts)
        for id,share in pairs(allocations) do
            local a=accounts[id];a.balance=a.balance+share.amount;a.score=a.score+share.amount
            if share.role=='hero' then
                local ps=Run:GetPlayerState(id);local progression=ps and ps.progressionState
                for _,level in ipairs(self.Milestones) do
                    local key=tostring(level)
                    if progression and progression.level>=level and not a.milestones[key] then
                        a.milestones[key]=true
                        a.pending[key]=self:GenerateToken(id,'milestone:'..key,'Combat Level '..key,r.Level)
                    end
                end
                self:PromotePending(a)
                local seed=LOD.Seeds.Derive(r.LevelSeed,'dft:rescue:'..id..':'..event)
                if count(a.tokens)<8 and LOD.RNG.New(seed):Int(1,1000)==1 then
                    local token=self:GenerateToken(id,event,'Rare rescue reward',r.Level)
                    a.tokens[token.id]=token
                end
            end
            Store:History(id,event,'rescue',share)
        end
        return true,{run=r.RunId,level=r.Level,pool=pool,soldierPool=soldierPool,allocations=allocations}
    end)
    if ok or receipt=='already' then s.settled=true end
    if ok then
        for _,ply in ipairs(player.GetAll()) do
            local share=allocations[self:Account(ply)]
            if share then self:Report(ply,'Rescue reward: +'..share.amount..' $DEB','deb_rescue');self:Sync(ply) end
        end
    end
    return ok,receipt
end
-- Ordinary kills grant run-owned items. DFT minting belongs to rescue settlement.
function C:RareOpportunity() return nil end
function C:CollectToken(ply,token)
    local id=self:Account(ply)
    if not self:Ranked() or not Run.State.LevelCleared or not id or not token or token.id~=id..':'..token.source then return false end
    local event='mint:'..token.id
    local ok,receipt=Store:Transaction(event,'rare_dft',{id},function(accounts)
        local a=accounts[id]
        if count(a.tokens)>=8 then return false,'full' end
        if a.tokens[token.id] then return false,'already' end
        a.tokens[token.id]=table.Copy(token)
        Store:History(id,event,'rare_dft',{token=token.id,name=token.item.name})
        return true,{token=token.id}
    end)
    if ok then self:Sync(ply) end
    if not ok then return false,receipt=='full' and 'Your DFT collection is full.' or receipt=='storage' and 'Wallet storage unavailable; no token was awarded.' or 'Token award unavailable.' end
    return true,'Debbie Fund Token collected — '..E:ItemName(token.item)
end
function C:Sell(ply,tokenId)
    if not self:CanUseStatue(ply) then return false,'Use the Debbie statue in staging.' end
    local id=self:Account(ply);local event='sell:'..tokenId
    local ok,receipt=Store:Transaction(event,'sale',{id},function(accounts)
        local a=accounts[id];local token=a.tokens[tokenId]
        if not token then return false,'Token unavailable.' end
        local value=E:Value(token.item)
        a.tokens[tokenId]=nil;a.balance=a.balance+value
        self:PromotePending(a)
        Store:History(id,event,'sale',{token=tokenId,amount=value})
        return true,{amount=value}
    end)
    if ok then self:Report(ply,'DFT sold for '..receipt.amount..' $DEB.','dft_sale') end
    self:Sync(ply)
    return ok,receipt
end
function C:Recreate(ply,tokenId)
    if not self:CanUseStatue(ply) then return false,'Use the Debbie statue in staging.' end
    local id=self:Account(ply);local runId=Run.State.RunId
    local event='recreate:'..runId..':'..tokenId
    local ps=Run:GetPlayerState(ply)
    local before=table.Copy(E:Ensure(ps));local createdClass
    local ammo=ply.GetAmmo and table.Copy(ply:GetAmmo()) or nil
    local active=ply:GetActiveWeapon()
    local activeClass=IsValid(active) and active:GetClass()
    local hp=ply:Health()
    local clips={}
    for _,weapon in ipairs(ply.GetWeapons and ply:GetWeapons() or {}) do
        clips[#clips+1]={weapon=weapon,one=weapon:Clip1(),two=weapon:Clip2()}
    end
    local ok,receipt=Store:Transaction(event,'recreation',{id},function(accounts)
        local token=accounts[id].tokens[tokenId]
        if not token then return false,'Token unavailable.' end
        if token.lastRun==runId then return false,'Already recreated this run.' end
        local item=table.Copy(token.item);item.id='recreated:'..runId..':'..tokenId;item.recreatedFrom=tokenId
        -- The admission path validates the statue again, then applies normal
        -- capacity, replacement, weapon and derived-state behavior.
        local def=E:Definition(item)
        if def.weapon and not IsValid(ply:GetWeapon(def.weaponClass)) then createdClass=def.weaponClass end
        if not E:AcquireWorldItem(ply,item,true,'dft') then return false,'Inventory full or item grant failed.' end
        token.lastRun=runId
        Store:History(id,event,'recreation',{token=tokenId,item=item.id,name=item.name})
        return true,{item=item.id}
    end)
    if not ok then
        -- Engine admission and SQLite commit execute synchronously. Compensate
        -- a failed grant/commit; retries never destroy the frozen entitlement.
        ps.equipment=before;ps.progressionState.equipmentKey=nil
        if createdClass and IsValid(ply:GetWeapon(createdClass)) then ply:StripWeapon(createdClass) end
        if ammo then ply:RemoveAllAmmo();for kind,n in pairs(ammo) do ply:SetAmmo(n,kind) end end
        for _,saved in ipairs(clips) do
            if IsValid(saved.weapon) then saved.weapon:SetClip1(saved.one);saved.weapon:SetClip2(saved.two) end
        end
        if activeClass and ply.SelectWeapon then ply:SelectWeapon(activeClass) end
        E:Sync(ply)
        ply:SetHealth(hp)
    else self:Report(ply,'DFT item recreated. Available again next run.','dft_recreate') end
    self:Sync(ply)
    return ok,receipt
end
function C:Report(ply,text,event)
    if LOD.RPGPresentation then LOD.RPGPresentation:Event(ply,'resource',text,{event=event}) end
    if IsValid(ply) then ply:ChatPrint(text) end
end
