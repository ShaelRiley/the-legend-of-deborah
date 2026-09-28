-- Scavenged services: informed review, canonical resources, durable receipts.
local T,E,Run,Store=assert(LOD.EventTransactions),assert(LOD.Equipment),assert(LOD.RunManager),assert(LOD.CryptoStore)
local Services={Definitions={}}
LOD.EventServices=Services
local function maximum(ply) return math.max(1,ply:GetNW2Int('LOD_MagicMax',100)) end
local function magic(ps) return math.max(0,tonumber(ps and ps.magic) or 100) end
local function equipped(state,id)
    for _,value in pairs(state.slots or {}) do if value==id then return true end end
    return false
end
local function junk(state)
    local out={}
    for id,item in pairs(state.items or {}) do
        local def=E:Definition(item)
        if def and def.wearable and not equipped(state,id) and E:JunkEligible(state,id) then out[#out+1]=item end
    end
    table.sort(out,function(a,b) local av,bv=E:Value(a),E:Value(b);return av==bv and a.id<b.id or av<bv end)
    return out
end
local function generated(i,id,label)
    local state=Run.State
    local records=state.EventServiceRewards
    if not records or records.runId~=i.runId or records.level~=i.level then
        records={runId=i.runId,level=i.level,items={}};state.EventServiceRewards=records
    end
    local key=i.archetype..':'..id..':'..label
    if not records.items[key] then
        local seed=T.Seed(i,id,label)
        local context=T.Key(i,id,label)
        records.items[key]=E.GenerateContextItem and E:GenerateContextItem(seed,i.level,E:RewardWearableFamily(seed),context)
            or E:Generate(seed,i.level,E:RewardWearableFamily(seed),context)
    end
    return records.items[key]
end
local function quote(signature,offer,cost,extra)
    local q=extra or {};q.signature=signature;q.offer=offer;q.cost=cost;return q
end
local function result(q,message) return {message=message or q.offer} end
local function nativeHealth(b,after)
    local before,cap=b.ply:Health(),b.ply:GetMaxHealth()
    return {
        perform=function()
            if after>before then return LOD.LootDirector:_GrantHealth(b.ply,after-before) end
            b.ply:SetHealth(after);return true
        end,
        validate=function() return b.ply:Health()==after and b.ply:GetMaxHealth()==cap end,
        rollback=function() if b.ownsHero() and b.ply:Health()==after then b.ply:SetHealth(before) end end
    }
end
local function reviewCurrent(i,p,identity,q)
    local r=i.serviceOffers and i.serviceOffers[identity]
    local ps=Run:GetPlayerState(p)
    return r and ps and r.expires>=CurTime() and r.ps==ps and r.life==ps.equipmentLifeSerial
        and r.spawn==p.LODRunSpawnSerial and r.signature==q.signature
        and ps.equipment==r.inventory and T.Equal(ps.equipment,r.before)
end
local function register(def)
    def.contract,def.production,def.nonblocking='UTILITY',true,true
    def.scope=def.scope or 'personal';def.persistence='account_campaign_dungeon'
    def.interactionMode='review_then_use';def.repeatability='once_per_account_per_dungeon'
    def.risk=def.risk or 'none';def.topology=def.topology or 'respite'
    def.role=def.role or 'utility';def.weight=def.weight or 1
    def.claimSemantics=def.sharedResolution and 'first_party_claimant' or 'account_once'
    def.previewNotice=def.name..' preview uses actual Hero resources and persistent wallet receipts; campaign unranked.'
    def.Claim=function(i,id) return T.Claim(i,id,nil,def.sharedResolution) end
    def.Create=function(d,i)
        local ent=ents.Create('lod_dungeon_event')
        if not IsValid(ent) then return nil,'entity_creation' end
        if not d:Track(i,ent) then ent:Remove();return nil,'stale' end
        ent:SetNW2String('LOD_EventArchetype',def.id)
        ent:SetPos(LOD.MazeBuilder:CellCenter(i.cell)+Vector(0,0,8));ent:SetEventID(i.id)
        ent:Spawn();ent:Activate();return ent
    end
    def.Snapshot=function(i,p,id)
        local q,why=def.Quote(i,p,id)
        return {kind='service',name=def.name,offer=q and q.offer or why,
            cost=q and q.cost or def.cost,scope=def.scope,
            action=q and reviewCurrent(i,p,id,q) and 'CONFIRM THIS OFFER' or 'REVIEW OFFER',
            status=def.sharedResolution and 'One shared lot; first buyer owns it.' or 'Once per account this dungeon.'}
    end
    def.Interact=function(d,i,p,id)
        local b,why=T.Begin(d,i,p,id);if not b then return false,why end
        local q; q,why=def.Quote(i,p,id);if not q then return false,why end
        if not reviewCurrent(i,p,id,q) then
            i.serviceOffers=i.serviceOffers or {}
            i.serviceOffers[id]={signature=q.signature,ps=b.ps,life=b.life,spawn=b.spawn,expires=CurTime()+12,
                inventory=b.original,before=table.Copy(b.original)}
            return false,q.offer..' Use again within 12 seconds to confirm.'
        end
        local ok,receipt=def.Settle(b,q)
        if ok then
            i.serviceOffers[id]=nil
            pcall(E.Report,E,p,string.upper(def.name)..' — '..(receipt.message or q.offer),'dungeon_event_'..def.id)
            if LOD.Audio then pcall(LOD.Audio.Emit,LOD.Audio,p,'confirm') end
        end
        return ok,receipt
    end
    def.Cleanup=function(_,i) i.serviceOffers=nil;i.serviceFusion=nil end
    Services.Definitions[def.id]=def
    LOD.EventRegistry:Register(def)
end

register({id='triage_station',name='Prison Triage',family='services',role='recovery',cost='12 $DEB',reward='missing HP',
    themeAffinities={quarantine=2,occupation=1.5},presentation={model='models/props_combine/health_charger001.mdl',color={165,235,190}},
    Quote=function(i,p)
        if p:Health()>=p:GetMaxHealth() then return nil,'Health is already full; no charge.' end
        return quote('triage:12','Pay 12 $DEB to restore missing HP. Ailments remain.','12 $DEB')
    end,
    Settle=function(b,q)
        local after=b.ply:GetMaxHealth()
        return T.Provisional(b,{debit=12,result=result(q,'Health restored for 12 $DEB.')},nativeHealth(b,after))
    end})

register({id='blood_dynamo',name='Blood Dynamo',family='anomalies',role='recovery',risk='nonlethal_hp',
    cost='10 HP',reward='25 Magic',themeAffinities={corruption=2,quarantine=1.5},
    presentation={model='models/props_lab/tpplug.mdl',color={225,75,95},scale=1.8},
    Quote=function(i,p)
        local ps=Run:GetPlayerState(p)
        if p:Health()<=10 then return nil,'More than 10 HP required; the dynamo cannot kill you.' end
        if magic(ps)>=maximum(p) then return nil,'Magic is already full.' end
        return quote('blood:10','Give 10 HP for up to 25 Magic; never below 1 HP.','10 HP')
    end,
    Settle=function(b,q)
        local nextMagic=math.min(maximum(b.ply),magic(b.ps)+25)
        return T.Provisional(b,{psFields={magic=nextMagic},result=result(q)},nativeHealth(b,b.ply:Health()-10))
    end})

register({id='salvage_press',name='Salvage Press',family='equipment',role='source',cost='unequipped wearable',reward='$DEB',
    themeAffinities={occupation=2,retinue=1.5},presentation={model='models/props_c17/trappropeller_engine.mdl',color={195,160,85}},
    Quote=function(i,p)
        local ps=Run:GetPlayerState(p);local items=ps and junk(E:Ensure(ps)) or {}
        local item=items[1];if not item then return nil,'Bring an unprotected, unequipped wearable. Starting and DFT gear are excluded.' end
        local value=E:Value(item)
        return quote(item.id..':'..value,'Destroy '..E:ItemName(item)..' for '..value..' $DEB.',E:ItemName(item),{itemId=item.id,value=value})
    end,
    Settle=function(b,q)
        if not E:Discard(b.staged,q.itemId) then return false,'Equipment changed; nothing consumed.' end
        return T.Commit(b,{credit=q.value,result={itemId=q.itemId,message='Equipment salvaged for '..q.value..' $DEB.'}})
    end})

register({id='reforging_bench',name='Scavenger Reforge',family='equipment',role='sink',topology='dead_end',cost='two unequipped wearables',reward='fused wearable',
    themeAffinities={occupation=1.5,retinue=2},presentation={model='models/props_c17/FurnitureTable002a.mdl',color={190,140,90}},
    Quote=function(i,p,id)
        local ps=Run:GetPlayerState(p);local items=ps and junk(E:Ensure(ps)) or {}
        if #items<2 then return nil,'Bring two unprotected, unequipped wearables; starting and DFT gear are excluded.' end
        local a,b=items[1],items[2];local signature=a.id..':'..b.id..':'..E:Value(a)..':'..E:Value(b)
        i.serviceFusion=i.serviceFusion or {};local cached=i.serviceFusion[id]
        if not cached or cached.signature~=signature then
            local out=E:FusionResult(T.Seed(i,id,'reforge:'..signature),E:Value(a)+E:Value(b),T.Key(i,id,'reforge'))
            cached={signature=signature,item=out};i.serviceFusion[id]=cached
        end
        if not cached.item or E:Value(cached.item)<=math.max(E:Value(a),E:Value(b)) then
            return nil,'No stronger canonical item fits these two inputs. Keep them or bring another pair.'
        end
        return quote(signature,'Fuse '..E:ItemName(a)..' + '..E:ItemName(b)..' into '..E:ItemName(cached.item)..'.',
            'Both listed wearables',{ids={a.id,b.id},item=cached.item})
    end,
    Settle=function(b,q)
        for _,id in ipairs(q.ids) do if not E:Discard(b.staged,id) then return false,'Equipment changed; nothing consumed.' end end
        if not E:StoreWearable(b.staged,q.item) then return false,'Equipment cannot accept this result; nothing consumed.' end
        return T.Commit(b,{result={itemId=q.item.id,inputs=q.ids,message=E:ItemName(q.item)..' added to Equipment.'}})
    end})

register({id='key_cutter',name='Improvised Key Cutter',family='services',role='sink',cost='1 Healing Potion + 20 Magic',reward='1 Chest Key',
    themeAffinities={occupation=1.5,hunting=2},presentation={model='models/props_c17/TrapPropeller_Lever.mdl',color={230,190,70},scale=1.5},
    Quote=function(i,p)
        local ps=Run:GetPlayerState(p);local inventory=ps and E:Ensure(ps);local potion=inventory and inventory.items.healing_potion
        if not potion or potion.count<1 then return nil,'A Healing Potion is required for the cutting bath.' end
        if magic(ps)<20 then return nil,'20 Magic is required to cut a Chest Key.' end
        return quote('key:20','Consume 1 Healing Potion and 20 Magic to cut 1 Chest Key.','1 Healing Potion + 20 Magic')
    end,
    Settle=function(b,q)
        if not E:Consume(b.staged,'healing_potion') or not E:AddConsumable(b.staged,'chest_key',1) then
            return false,'Potion unavailable or Chest Key stack full; nothing consumed.'
        end
        return T.Commit(b,{psFields={magic=magic(b.ps)-20},result=result(q,'One Chest Key cut; potion and 20 Magic consumed.')})
    end})

local firearm={weapon_pistol=true,weapon_smg1=true,weapon_shotgun=true,weapon_ar2=true,weapon_357=true}
register({id='ammo_transmuter',name='Ammo Transmuter',family='services',role='recovery',cost='15 Magic',reward='held firearm ammo',
    themeAffinities={crossfire=2,occupation=2},presentation={model='models/items/ammocrate_smg1.mdl',color={115,185,230}},
    Quote=function(i,p)
        local ps=Run:GetPlayerState(p);local gun=p:GetActiveWeapon()
        if not IsValid(gun) or not firearm[gun:GetClass()] then return nil,'Hold a Pistol, SMG, Shotgun, Revolver or Pulse Rifle.' end
        if magic(ps)<15 then return nil,'15 Magic required; hold the firearm you want to supply.' end
        return quote(gun:GetClass()..':15','Spend 15 Magic on one large ammunition ration for the held '..E.Definitions[gun:GetClass()].name..'.',
            '15 Magic',{gun=gun,class=gun:GetClass(),ammo=gun:GetPrimaryAmmoType()})
    end,
    Settle=function(b,q)
        local chosen=LOD.LootDirector:_ChooseAmmoFamily(b.ply,LOD.RNG.New(T.Seed(b.instance,b.identity,'ammo-admission')),q.class)
        if chosen~=q.class then return false,'That firearm is full; no Magic spent.' end
        local reserve,clip=b.ply:GetAmmoCount(q.ammo),q.gun:Clip1()
        local after
        local native={perform=function()
            local ok,_,amount,class=LOD.LootDirector:_GrantAmmo(b.ply,LOD.RNG.New(T.Seed(b.instance,b.identity,'ammo')),'large',q.class,true)
            after=b.ply:GetAmmoCount(q.ammo)
            if not ok or class~=q.class or after<=reserve then return false,'That firearm is full; no Magic spent.' end
            return true
        end,validate=function()
            return IsValid(q.gun) and b.ply:GetActiveWeapon()==q.gun and b.ply:GetWeapon(q.class)==q.gun
                and q.gun:Clip1()==clip and b.ply:GetAmmoCount(q.ammo)==after
        end,rollback=function()
            if b.ownsHero() and IsValid(q.gun) and b.ply:GetWeapon(q.class)==q.gun then
                local current=b.ply:GetAmmoCount(q.ammo)
                if (after and current==after) or (not after and current>reserve) then b.ply:SetAmmo(reserve,q.ammo) end
            end
        end}
        return T.Provisional(b,{psFields={magic=magic(b.ps)-15},result=result(q)},native)
    end})

register({id='prisoner_barter',name='Wounded Scavenger',family='prisoners',role='sink',topology='dead_end',cost='1 Healing Potion',reward='displayed wearable',
    themeAffinities={quarantine=2,hunting=1.5},presentation={model='models/Humans/Group03/male_07.mdl',color={180,155,145}},
    Quote=function(i,p,id)
        local item=generated(i,id,'barter');if not item then return nil,'The scavenger has nothing to exchange.' end
        return quote(item.id,'Give 1 Healing Potion to the scavenger for '..E:ItemName(item)..'.','1 Healing Potion',{item=item})
    end,
    Settle=function(b,q)
        if not E:Consume(b.staged,'healing_potion') then return false,'Bring a Healing Potion; no claim consumed.' end
        if not E:StoreWearable(b.staged,q.item) then return false,'Make room in Equipment; your potion is retained.' end
        return T.Commit(b,{result={itemId=q.item.id,message='The scavenger thanks you; '..E:ItemName(q.item)..' added to Equipment.'}})
    end})

register({id='overclock_console',name='Redline Capacitor',family='anomalies',role='risk',topology='optional',risk='voluntary_reckless',
    cost='30 seconds Reckless',reward='full Magic',themeAffinities={corruption=2,crossfire=2},
    presentation={model='models/props_lab/reciever01b.mdl',color={235,55,125},scale=1.3},
    Quote=function(i,p)
        local ps=Run:GetPlayerState(p)
        if magic(ps)>=maximum(p) then return nil,'Magic is already full.' end
        if LOD.RPGStatusElements:Has(p,'reckless') then return nil,'Wait until Reckless ends before overclocking.' end
        return quote('redline:30','Fill Magic; become Reckless for 30 seconds. You can harm your own faction.','30 seconds Reckless')
    end,
    Settle=function(b,q)
        local status,support=LOD.RPGStatusElements,{}
        local native={perform=function()
            return status:Apply(b.ply,'reckless',b.entity,{direct=true,duration=30,support=support,
                rng=LOD.RNG.New(T.Seed(b.instance,b.identity,'overclock'))})
        end,validate=function()
            local row=status.Active[b.ply] and status.Active[b.ply].reckless
            return row and row.support==support
        end,rollback=function()
            if not b.ownsHero() then return end
            local row=status.Active[b.ply] and status.Active[b.ply].reckless
            if row and row.support==support then status:ClearExpected(b.ply,'reckless',row,'event settlement failed') end
        end}
        return T.Provisional(b,{psFields={magic=maximum(b.ply)},result=result(q)},native)
    end})

register({id='contraband_lot',name='Contraband Countdown',family='merchant',role='sink',topology='dead_end',scope='party',
    sharedResolution=true,risk='another_buyer',rare=true,cost='declining $DEB price',reward='one exact shared wearable',
    themeAffinities={retinue=3,occupation=2},presentation={model='models/props_junk/wood_crate001a.mdl',color={215,100,220}},
    Quote=function(i,p)
        local item=generated(i,'party','contraband');if not item then return nil,'The lot is unavailable.' end
        -- One monotonic per-dungeon market clock survives layout replacement
        -- and is independent of Hourglass / Time Management clock extensions.
        local market=Run.State.EventServiceMarket
        if not market or market.runId~=i.runId or market.level~=i.level then
            market={runId=i.runId,level=i.level,openedAt=SysTime()};Run.State.EventServiceMarket=market
        end
        local elapsed=math.max(0,SysTime()-market.openedAt)
        local value=E:Value(item);local price=math.max(10,math.ceil(value*(1-math.min(.75,math.floor(elapsed/30)*.05))))
        return quote(item.id..':'..price,'One shared '..E:ItemName(item)..' for '..price..' $DEB. Price falls; the first buyer owns it.',
            price..' $DEB',{item=item,price=price})
    end,
    Settle=function(b,q)
        if not E:StoreWearable(b.staged,q.item) then return false,'Make room in Equipment; nothing spent.' end
        return T.Commit(b,{debit=q.price,shared=true,result={itemId=q.item.id,price=q.price,message='Shared lot purchased: '..E:ItemName(q.item)..'.'}})
    end})

register({id='life_underwriter',name='Life Underwriter',family='bureaucracy',role='risk',topology='optional',risk='reserve_life',rare=true,
    cost='1 reserve life',reward='40 $DEB',themeAffinities={hunting=3,corruption=1.5},
    presentation={model='models/props_c17/cashregister01a.mdl',color={105,185,135}},
    Quote=function(i,p)
        local ps=Run:GetPlayerState(p)
        if not ps or (ps.lives or 0)<=1 then return nil,'At least two lives required. Your final life cannot be sold.' end
        return quote('underwriter:40','Surrender 1 reserve life for 40 $DEB. This permanently reduces your current Hero’s chances.','1 reserve life')
    end,
    Settle=function(b,q)
        return T.Commit(b,{credit=40,psFields={lives=b.ps.lives-1},result=result(q,'One reserve life surrendered for 40 $DEB.')})
    end})
