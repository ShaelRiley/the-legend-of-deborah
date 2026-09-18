-- Cosmetic projection of immutable equipment rolls. Never consumes gameplay RNG.
LOD.WeaponAppearance={Version=1,MaximumProperties=8}
local V,E=LOD.WeaponAppearance,LOD.Equipment
V.Colors={earth={194,156,88},fire={255,105,45},dark={125,72,170},ice={125,220,255},
    light={255,245,170},electric={110,180,255},neutral={180,200,210},penalty={225,100,105}}
V.Grammar={}
local ability={str={'STR','anvil'},dex={'DEX','fin'},con={'CON','plate'},int={'INT','coil'},wis={'WIS','lens'},cha={'CHA','crown'}}
local stats={physical={'DMG','anvil'},magic={'MAG','coil'},movement={'SPD','fin'},dodge={'DGE','fin'},
    defense={'ARM','plate'},regen_ceiling={'HP+','bud'},regen_rate={'REG','bud'},magic_regen={'MP+','coil'},
    push_out={'PSH','anvil'},push_resist={'ANC','plate'},map_efficiency={'MAP','lens'},summon_duration={'DUR','crown'},
    injured={'LOW','fang'},still={'STL','lens'},charged={'CHG','coil'},breadcrumb={'NAV','lens'},block={'BLK','plate'},summon_cap={'SUM','crown'}}
local riders={clumsy={'STB','fin'},immolated={'BRN','fang'},poisoned={'PSN','bud'},bleeding={'BLD','fang'},
    muted={'MUT','cage'},held={'HLD','cage'},reckless={'RCK','crown'},arcane_shattered={'SHR','shard'},
    intimidated={'FAR','crown'},push={'REP','anvil'}}
local elements={earth={'EAR','anvil'},fire={'FIR','fang'},dark={'DRK','cage'},ice={'ICE','shard'},light={'LIT','crown'},electric={'ELC','coil'}}
for index,id in ipairs(E.EconomyOrder) do
    local p=E.EconomyProperties[id];local symbol
    if p.ability then symbol=ability[p.ability]
    elseif p.save then symbol={string.upper(p.save):sub(1,2)..'S','plate'}
    elseif p.element then symbol=elements[p.element]
    elseif p.ward then symbol={elements[p.ward][1]:sub(1,2)..'R','plate'}
    elseif p.weakness then symbol={elements[p.weakness][1]:sub(1,2)..'W','shard'}
    elseif p.rider then symbol=riders[p.rider]
    elseif p.move then symbol={E.SpecialMoves[p.move].glyphs,p.move=='quickstep' and 'fin' or 'anvil'}
    else symbol=stats[id] end
    assert(symbol,'Missing weapon appearance grammar: '..id)
    V.Grammar[id]={index=index,glyph=symbol[1],shape=symbol[2],label=p.label,
        color=p.element or p.ward or p.weakness or 'neutral',maximum=p.maximum or p.fixed or 1,
        negative=p.weakness~=nil,role=p.element and 'element' or p.rider and 'rider' or p.ward and 'ward' or p.weakness and 'weakness' or 'stat'}
end
V.MaterialRegions={
    weapon_pistol={a={"pistol_body","pistol_slide"},b={"pistol_magazine","pistol_barrel"},control={"pistol_grip","pistol"}},
    weapon_357={a={"357_body","357_cylinder"},b={"357_barrel"},control={"357_grip","357"}},
    weapon_smg1={a={"smg_body","smg1_body"},b={"smg_magazine","smg1_barrel"},control={"smg_grip","smg1"}},
    weapon_ar2={a={"irifle","ar2_body"},b={"irifle_detail","ar2_barrel"},control={"irifle_grip","ar2_grip"}},
    weapon_shotgun={a={"shotgun_receiver","shotgun_body"},b={"shotgun_barrel"},control={"shotgun_stock","shotgun"}},
    weapon_lod_crowbar={a={"crowbar_shaft"},b={"crowbar_tip"},control={"crowbar_grip","crowbar"}}
}
-- Stock single-material guns need geometric regions, not fictional submaterials.
-- Distances behind the animated muzzle delimit grip/stock, receiver, barrel.
-- Crowbar has no muzzle: divide its longest native model axis into grip/shaft/tip.
V.Segments={
    weapon_pistol={stem='pistol',rear=6,front=2,control='grip',a='slide',b='muzzle'},
    weapon_357={stem='357',rear=9,front=4,control='grip',a='cylinder',b='barrel'},
    weapon_smg1={stem='smg1',rear=14,front=6,control='stock / grip',a='receiver',b='barrel'},
    weapon_ar2={stem='irifle',rear=18,front=8,control='stock / grip',a='receiver',b='emitter'},
    weapon_shotgun={stem='shotgun',rear=23,front=12,control='stock',a='receiver / pump',b='barrel'},
    weapon_lod_crowbar={stem='crowbar',low=.28,high=.78,control='grip',a='shaft',b='hook'}
}
function V:MaterialRegion(class,path)
    local mapping=self.MaterialRegions[class];if not mapping then return "control" end
    local name=path:lower():match("([^/]+)$")
    for _,region in ipairs({"control","a","b"}) do
        for _,candidate in ipairs(mapping[region]) do if name==candidate then return region end end
    end
    return "control"
end
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<math.huge end
local function hash(s)
    local n=17;for i=1,#s do n=(n*131+s:byte(i))%2147483647 end;return n
end
function V:Data(item)
    local def=E:Definition(item)
    if not def or not def.weapon or item.version~=2 or not finite(item.seed) then return nil end
    local rows={}
    for _,p in ipairs(item.properties or {}) do
        local grammar=self.Grammar[p.id]
        if not grammar or not finite(p.amount) then return nil end
        rows[#rows+1]={grammar.index,p.amount}
    end
    if #rows==0 or #rows>self.MaximumProperties then return nil end
    table.sort(rows,function(a,b) return a[1]<b[1] end)
    return {self.Version,item.seed,item.rarity or 1,item.quality or 100,rows}
end
function V:Encode(item)
    local data=self:Data(item);if not data then return '' end
    local rows={}
    for _,r in ipairs(data[5]) do rows[#rows+1]=r[1]..':'..tostring(r[2]) end
    local encoded=table.concat({data[1],data[2],data[3],data[4],table.concat(rows,',')},';')
    return #encoded<=480 and encoded or ''
end
function V:Compile(data)
    if type(data)~='table' or data[1]~=self.Version or not finite(data[2]) or not finite(data[3])
        or data[3]<1 or data[3]>4 or not finite(data[4]) or type(data[5])~='table'
        or #data[5]<1 or #data[5]>self.MaximumProperties then return nil end
    local result={traits={},rarity=math.floor(data[3]),quality=data[4],element='neutral'}
    local fingerprint={tostring(data[2]),tostring(data[3]),tostring(data[4])};local seen={};local dominant=-1
    for _,row in ipairs(data[5]) do
        if type(row)~='table' or not finite(row[1]) or not finite(row[2]) then return nil end
        local id=E.EconomyOrder[row[1]];local g=id and self.Grammar[id]
        if not g or seen[id] then return nil end;seen[id]=true
        local negative=g.negative or row[2]<0
        local strength=math.min(1,math.abs(row[2])/g.maximum)
        local trait={id=id,glyph=g.glyph,shape=g.shape,label=g.label,amount=row[2],negative=negative,
            role=g.role,color=negative and 'penalty' or g.color,strength=strength,bars=math.max(1,math.ceil(strength*4))}
        result.traits[#result.traits+1]=trait
        fingerprint[#fingerprint+1]=id..'='..tostring(row[2])
        if g.role=='element' and not negative then result.element=g.color end
        if g.role=='rider' and not negative then result.rider=trait end
        if not negative and g.role=='stat' and strength>dominant then result.structure=g.shape;dominant=strength end
        if negative then result.flawed=true end
    end
    result.hash=hash(table.concat(fingerprint,'|'))
    result.structure=result.structure or 'plate'
    result.finish='two-tone native finish'
    result.tintA=result.element
    result.tintB=({'earth','fire','dark','ice','light','electric'})[math.floor(result.hash/997)%6+1]
    local traitColors={anvil='earth',fin='ice',plate='light',bud='fire',coil='electric',crown='light',fang='fire',cage='dark',shard='ice',lens='electric'}
    result.tintB=traitColors[result.rider and result.rider.shape or result.structure] or result.tintB
    if result.tintA==result.tintB then result.tintB=({earth='ice',ice='earth',fire='electric',electric='fire',dark='light',light='dark'})[result.tintA] or 'light' end
    -- Mechanic families choose the hue pair; the full frozen roll varies shades.
    -- Store RGB triplets in the derived descriptor, never expand the network packet.
    local function shade(name,salt)
        local base=V.Colors[name] or V.Colors.neutral;local out={}
        for i=1,3 do
            local jitter=math.floor(result.hash/(salt*7^(i-1)))%37-18
            out[i]=math.max(20,math.min(255,base[i]+jitter))
        end
        return out
    end
    result.tintARGB=shade(result.tintA,31);result.tintBRGB=shade(result.tintB,173)
    result.muzzleFamily=result.structure
    result.muzzleDuration=.09+result.rarity*.015
    result.muzzleSize=12+result.rarity*2+math.max(0,dominant)*6
    result.variant=(result.hash%997)/997
    result.phase=(result.hash%628)/100
    return result
end
function V:Decode(packet)
    if type(packet)~='string' or #packet==0 or #packet>480 then return nil end
    local v,seed,rarity,quality,body=packet:match('^([^;]+);([^;]+);([^;]+);([^;]+);([^;]+)$')
    if not body then return nil end
    local rows={}
    for entry in body:gmatch('[^,]+') do
        local id,amount=entry:match('^(%d+):([%+%-%.%deE]+)$')
        if not id or #rows>=self.MaximumProperties then return nil end
        rows[#rows+1]={tonumber(id),tonumber(amount)}
    end
    return self:Compile({tonumber(v),tonumber(seed),tonumber(rarity),tonumber(quality),rows})
end
function V:Describe(style)
    if not style then return '' end
    local element=style.element=='ice' and 'Wintery (Ice)' or style.element
    local out={element..' aura and muzzle behavior; independent Tint A / Tint B with protected native surfaces.'}
    for _,t in ipairs(style.traits) do
        out[#out+1]=t.glyph..': '..t.label..' ('..t.bars..'/4 strength'..(t.negative and ', penalty' or '')..').'
    end
    return 'Visual key: '..table.concat(out,' ')..' The frozen roll determines tints and muzzle behavior; inspect properties for exact effects.'
end
function V:Stamp(ent,item)
    if not IsValid(ent) then return end
    -- Item rolls are immutable; copy selection supplies another record identity.
    if ent.LODAppearanceItem==item then return end
    ent.LODAppearanceItem=item
    ent:SetNW2String('LOD_WeaponAppearanceClass',item.definitionId or '')
    local packet=self:Encode(item)
    if ent.LODAppearancePacket~=packet then
        ent.LODAppearancePacket=packet;ent:SetNW2String('LOD_WeaponAppearance',packet)
    end
end

-- Observe the final native shot without editing bullets or re-entering combat.
-- One tiny message per gun/tick; pellets never become separate FX allocations.
if SERVER then
    util.AddNetworkString('LOD_WeaponSurfaceFlash')
    -- Retired pattern textures are no longer distributed or used.
    local last=setmetatable({}, {__mode='k'})
    hook.Add('PostEntityFireBullets','LOD_ProceduralWeaponMuzzle',function(actor)
        if not IsValid(actor) or not actor:IsPlayer() then return end
        local weapon=actor:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetNW2String('LOD_WeaponAppearance','')=='' then return end
        local tick=engine.TickCount();if last[weapon]==tick then return end;last[weapon]=tick
        net.Start('LOD_WeaponSurfaceFlash');net.WriteEntity(weapon);net.SendPVS(actor:GetShootPos())
    end)
end
