local D,Run,E,C,Store,S = LOD.Damsels,LOD.RunManager,LOD.Equipment,LOD.CryptoDirector,LOD.CryptoStore,LOD.StagingDeployment
util.AddNetworkString('LOD_DamselState')
util.AddNetworkString('LOD_DamselDialogue')
D.Entities = D.Entities or {}
D.NextTalk = setmetatable({}, {__mode='k'})
function D:Sync(ply)
    local s=Run.State
    net.Start('LOD_DamselState')
    net.WriteUInt(s.CampaignSeed or 1,31)
    net.WriteDouble(s.Level or 1)
    net.WriteDouble(s.HighestLevel or s.Level or 1)
    for i=1,20 do net.WriteBool(s.RescuedDamsels and s.RescuedDamsels[i]==true) end
    net.WriteDouble(s.CashRecovered or 0)
    net.Send(ply)
    local ps=Run:GetPlayerState(ply)
    if ps and s.Abundance and s.Level>=21 and not ps.wardenLetterSeen then
        ps.wardenLetterSeen=true
        self:Dialogue(ply,0,self.Letter,'ENDLESS CAMPAIGN — SECURE THE BAG')
    end
end
function D:Dialogue(ply,level,line,result)
    net.Start('LOD_DamselDialogue');net.WriteUInt(level,5)
    net.WriteString(line);net.WriteString(result or '');net.Send(ply)
end
function D:ClearStaging()
    for _,ent in pairs(self.Entities) do if IsValid(ent) then ent:Remove() end end
    self.Entities={}
end
function D:Placement(def,used)
    local spec=def.placement
    local center,yaw=S.HutCenter,S.HutAngles
    local hf,hr=S.HutHalfForward or 400,S.HutHalfRight or 260
    local f,r=yaw:Forward(),yaw:Right()
    local separation=math.min(hf,hr)<180 and 40 or 48
    -- Keep the first authored position whenever possible. Smaller native rooms
    -- use nearby conversational clusters, while preserving each existing actor.
    for _,extraInset in ipairs({0,24,48,72,96}) do
        for _,wallOffset in ipairs({0,1,3,2}) do
            local wall=(spec.wall-1+wallOffset)%4+1
            local inset=spec.inset+extraInset
            for _,shift in ipairs({0,.12,-.12,.24,-.24,.36,-.36,.48,-.48,.60,-.60,.72,-.72,1,-1}) do
                local a=math.Clamp(spec.along+shift,-.85,.85)
                local x=(wall==1 and hf-inset) or (wall==3 and -hf+inset) or a*(hf-44)
                local y=(wall==2 and hr-inset) or (wall==4 and -hr+inset) or a*(hr-44)
                local pos=center+f*x+r*y+Vector(0,0,2)
                local clear=true
                for _,ent in ipairs(S.HutEntities or {}) do
                    if IsValid(ent) then
                        local p=ent:GetPos()
                        if (p.x-pos.x)^2+(p.y-pos.y)^2<48^2 then clear=false;break end
                    end
                end
                for _,p in pairs(used) do if p:DistToSqr(pos)<separation^2 then clear=false;break end end
                if clear then
                    local tr=util.TraceHull({start=pos,endpos=pos,mins=Vector(-14,-14,0),maxs=Vector(14,14,72),mask=MASK_SOLID_BRUSHONLY})
                    if not tr.Hit and not tr.StartSolid then
                        return pos,Angle(0,(center-pos):Angle().y+spec.yaw,0)
                    end
                end
            end
        end
    end
end
function D:EnsureStaging()
    if not S.HutCenter then return end
    local s=Run.State;local used={}
    for i=1,20 do
        local ent=self.Entities[i]
        if IsValid(ent) and s.RescuedDamsels and s.RescuedDamsels[i] then used[i]=ent:GetPos()
        elseif IsValid(ent) then ent:Remove();self.Entities[i]=nil end
    end
    for i=1,20 do
        if s.RescuedDamsels and s.RescuedDamsels[i] and not IsValid(self.Entities[i]) then
            local pos,ang=self:Placement(self.Definitions[i],used)
            if pos then
                local ent=ents.Create('lod_rescued_damsel')
                if IsValid(ent) then
                    ent.LODDamselLevel=i;ent.LODCampaignEpoch=s.CampaignEpoch
                    ent:SetPos(pos);ent:SetAngles(ang);ent:Spawn();ent:Activate()
                    self.Entities[i]=ent;used[i]=pos
                end
            else ErrorNoHalt('[LOD:DAMSELS] No safe staging placement for '..self.Definitions[i].name..'\n') end
        end
    end
end
function D:CanUse(ply,ent)
    local s=Run.State;local ps=Run:GetPlayerState(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or not IsValid(ent) or ent~=self.Entities[ent.LODDamselLevel]
        or ent.LODCampaignEpoch~=s.CampaignEpoch or not s.RescuedDamsels or not s.RescuedDamsels[ent.LODDamselLevel]
        or not ps or ps.eliminated or ps.deploymentComplete or not Run:IsSlotActivePlayer(ply)
        or Run:IsSoldierControl(ply) or not s.BuildReady or s.Failed or s.LevelCleared or s.SimulationFrozen
        or not S:IsPlayerInHut(ply) or ply:GetPos():DistToSqr(ent:GetPos())>112^2 then return false end
    local tr=util.TraceLine({start=ply:EyePos(),endpos=ent:WorldSpaceCenter(),filter={ply,ent},mask=MASK_SOLID_BRUSHONLY})
    return not tr.Hit
end
function C:ClaimAbundance(ply)
    if not Run.State.Abundance or not D:CanUse(ply,D.Entities[20]) then return false,'Rescue Deborah and visit her in staging.' end
    local id=self:Account(ply)
    if not id or not self:Ranked() then return false,'Abundance requires a ranked campaign and a Steam account.' end
    local now=os.time();local event='abundance:'..id..':'..now
    local ok,receipt=Store:Transaction(event,'abundance',{id},function(accounts)
        local a=accounts[id]
        local remaining=math.max(0,(a.abundanceClaimAt or 0)+86400-now)
        if a.abundanceClaimAt and remaining>0 then return false,{remaining=remaining} end
        self:PromotePending(a)
        if table.Count(a.tokens)>=8 then return false,'Your eight DFT slots are full. Make room; today’s gift remains available.' end
        local token=self:GenerateToken(id,event,'Deborah’s Abundance',Run.State.Level)
        a.tokens[token.id]=token;a.abundanceClaimAt=now
        Store:History(id,event,'abundance',{token=token.id,claimedAt=now})
        return true,{token=token.id}
    end)
    self:Sync(ply)
    if ok then return true,'ABUNDANCE — +1 DFT. Your next gift is available in 24 hours.' end
    if type(receipt)=='table' and receipt.remaining then
        local minutes=math.ceil(receipt.remaining/60)
        return false,string.format('Deborah has already provided today’s DFT. Return in %dh %02dm.',math.floor(minutes/60),minutes%60)
    end
    return false,receipt=='storage' and 'Wallet unavailable. Your gift has not been claimed.' or receipt=='already' and 'Today’s DFT has already been provided.' or receipt
end
function D:Grant(ply,def,key)
    local ps=Run:GetPlayerState(ply)
    local seed=LOD.Seeds.Derive(Run.State.CampaignSeed,'damsel:'..ps.identity..':'..key)
    local rng=LOD.RNG.New(seed)
    if def.reward=='ammo' then
        -- Existing grant authority clamps clip + reserve and respects family caps.
        if not ply:HasWeapon(def.parameter) then return false,'Bring the matching weapon first.' end
        local total=0
        for _=1,32 do
            local ok,_,amount=LOD.LootDirector:_GrantAmmo(ply,rng,'large',def.parameter,true)
            if not ok then break end
            total=total+(amount or 0)
        end
        return total>0,total>0 and 'Ammunition replenished.' or 'Your ammunition is already full.'
    elseif def.reward=='heal' or def.reward=='full_heal' then
        local ok,msg=LOD.LootDirector:_GrantHealth(ply,def.reward=='heal' and def.parameter or ply:GetMaxHealth())
        return ok,msg or 'You are already in good health.'
    elseif def.reward=='cure' then
        local count=LOD.RPGStatusElements:CureNegative(ply)
        return count>0,count>0 and 'Ailments cured.' or 'No ailments to cure.'
    elseif def.reward=='magic' then
        local pool=LOD.Magic:_EnsureState(ply);local maximum=ply:GetNW2Int('LOD_MagicMax',100)
        if not pool or pool.magic>=maximum then return false,'Your Magic is already full.' end
        pool.magic=math.min(maximum,pool.magic+def.parameter);LOD.Magic:_Sync(ply,pool)
        return true,'Clarity restored: +25 Magic, up to your maximum.'
    elseif def.reward=='equipment' then
        local item=E:Generate(seed,def.level,def.parameter,'damsel:'..Run.State.RunId..':'..ps.identity..':'..def.level)
        item.economyExcluded=true
        return E:AcquireWorldItem(ply,item,true,'damsel')
    elseif def.reward=='consumable' then
        if not E:AddConsumable(E:Ensure(ps),def.parameter,1) then return false,'Make space for a Healing Potion first.' end
        E:Sync(ply);return true,'One Healing Potion, for the road.'
    elseif def.reward=='deb' then
        local id=C:Account(ply)
        if not id or not C:Ranked() then return false,'The fund requires a ranked campaign and a Steam account.' end
        local event='damsel:'..Run.State.RunId..':'..id..':'..def.level
        local amount=rng:Int(def.parameter.min,def.parameter.max)
        local ok,why=Store:Transaction(event,'damsel_gift',{id},function(accounts)
            accounts[id].balance=accounts[id].balance+amount
            Store:History(id,event,'damsel_gift',{amount=amount})
            return true,{amount=amount}
        end)
        C:Sync(ply)
        return ok,ok and ('The fund grants '..amount..' $DEB.') or (why=='already' and 'This campaign’s grant was already paid.' or 'The fund is unavailable. Try again later.')
    elseif def.reward=='life' then
        if ps.lives>=LOD.Config.Lives.StartingLives then return false,'Your reserve lives are already full.' end
        ps.lives=ps.lives+1;Run:_SyncPlayerVars(ply)
        return true,'One reserve life restored.'
    end
    return false,'Service unavailable.'
end
function D:Use(ply,ent)
    if not self:CanUse(ply,ent) or CurTime()<(self.NextTalk[ply] or 0) then return false end
    self.NextTalk[ply]=CurTime()+.7
    local def=self.Definitions[ent.LODDamselLevel]
    local ps=Run:GetPlayerState(ply);local s=Run.State
    s.DamselClaims=s.DamselClaims or {};s.DamselClaims[ps.identity]=s.DamselClaims[ps.identity] or {}
    local claims=s.DamselClaims[ps.identity]
    local key=tostring(def.level)..':'..(def.frequency=='visit' and tostring(s.Level) or 'campaign')
    local ok,result
    if def.reward=='abundance' then ok,result=C:ClaimAbundance(ply)
    elseif claims[key] then result=def.frequency=='visit' and 'Your gift for this staging visit has been claimed.' or 'My gift for this campaign is already yours.'
    else
        claims[key]=true -- reserve before invoking native/inventory callbacks
        local ran,accepted,message=pcall(self.Grant,self,ply,def,key)
        ok=ran and accepted
        if not ok then claims[key]=nil end
        result=ran and message or 'The gift could not be delivered. Please try again.'
        if not ran then ErrorNoHalt('[LOD:DAMSELS] '..tostring(accepted)..'\n') end
    end
    local line=def.dialogue[(s.Level+def.level)%#def.dialogue+1]
    self:Dialogue(ply,def.level,line,result)
    if LOD.Audio then LOD.Audio:ToPlayer(ply,ok and 'gift' or 'dialogue') end
    return ok
end
local ensure=S.EnsureHut
function S:EnsureHut(...)
    local ok=ensure(self,...)
    if ok then D:EnsureStaging() end
    return ok
end
local new=Run.NewCampaign
function Run:NewCampaign(...)
    D:ClearStaging()
    return new(self,...)
end
hook.Add('ShutDown','LOD_DamselCleanup',function() D:ClearStaging() end)
-- Non-blocking actors are still usable even when the engine's use trace ignores
-- their collision group. Server checks distance, aim and world occlusion again.
hook.Add('KeyPress','LOD_DamselUse',function(ply,key)
    if key~=IN_USE or not IsValid(ply) then return end
    -- Preserve deliberate statue, portal and menu uses when a nearby actor is
    -- also inside the wide talk cone. Actors themselves never intercept traces.
    local trace=ply.GetEyeTrace and ply:GetEyeTrace()
    if trace and IsValid(trace.Entity) and trace.HitPos and trace.HitPos:DistToSqr(ply:EyePos())<=144^2 then
        for _,prop in ipairs(S.HutEntities or {}) do if prop==trace.Entity then return end end
    end
    local best,dot=nil,.88
    for _,ent in pairs(D.Entities) do
        if D:CanUse(ply,ent) then
            local aim=(ent:WorldSpaceCenter()-ply:EyePos()):GetNormalized():Dot(ply:GetAimVector())
            if aim>dot then best,dot=ent,aim end
        end
    end
    if best then D:Use(ply,best) end
end)

-- One repeatable native playtest command, on an explicitly unranked campaign.
concommand.Add('lod_damsel_test_stage',function(ply,_,args)
    local cv=GetConVar('lod_developer_mode')
    if not cv or not cv:GetBool() or (IsValid(ply) and not ply:IsAdmin()) then return end
    local level=math.floor(tonumber(args[1]) or 21)
    if level<1 or level>10000 then return end
    Run:MarkUnranked('damsel progression playtest')
    local s=Run.State;s.Level=level;s.HighestLevel=math.max(s.HighestLevel or 1,level)
    s.RescuedDamsels={}
    for i=1,math.min(20,level-1) do s.RescuedDamsels[i]=true end
    s.RescueCount=math.min(20,level-1);s.Abundance=level>20
    s.LevelCleared=false;s.Failed=false;s.DamselClaims={}
    for _,ps in pairs(s.PlayerState or {}) do
        ps.deploymentComplete=false;ps.wardenLetterSeen=nil;ps.eliminated=false;ps.lives=math.max(1,ps.lives or 1)
    end
    local ok,err=Run:BuildCurrentLevel()
    print('[LOD:DAMSELS] playtest level='..level..' built='..tostring(ok)..(not ok and (' '..tostring(err)) or ''))
end)
concommand.Add('lod_damsel_status',function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local s=Run.State;local count=0
    for _,ent in pairs(D.Entities) do if IsValid(ent) then count=count+1 end end
    local target=s.RescueTarget or D:Target(s.Level)
    local text=string.format('level=%d target=%s:%s rescued=%d staging=%d abundance=%s highest=%d cash=%d',
        s.Level,target.type,target.name,s.RescueCount or 0,count,tostring(s.Abundance==true),s.HighestLevel or s.Level,s.CashRecovered or 0)
    print('[LOD:DAMSELS] '..text)
    if IsValid(ply) then ply:ChatPrint(text) end
end)
