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
    result.finish=({'brushed metal','ceramic','carbon','hammered metal'})[result.hash%4+1]
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
    local out={style.finish..'; '..style.element..' core; '..style.structure..' frame.'}
    for _,t in ipairs(style.traits) do
        out[#out+1]=t.glyph..': '..t.label..' ('..t.shape..(t.negative and ', fractured' or '')..', '..t.bars..'/4 marks).'
    end
    return 'Visual key: '..table.concat(out,' ')
end
function V:Stamp(ent,item)
    if not IsValid(ent) then return end
    -- Item rolls are immutable; copy selection supplies another record identity.
    if ent.LODAppearanceItem==item then return end
    ent.LODAppearanceItem=item
    local packet=self:Encode(item)
    if ent.LODAppearancePacket~=packet then
        ent.LODAppearancePacket=packet;ent:SetNW2String('LOD_WeaponAppearance',packet)
    end
end
