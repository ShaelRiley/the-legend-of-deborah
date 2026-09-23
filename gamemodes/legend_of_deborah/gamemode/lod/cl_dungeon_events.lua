-- Whole snapshots replace prior generation state; no optimistic client claims.
LOD.DungeonEvents={events={}}
net.Receive('LOD_DungeonEvents',function()
    local snapshot=net.ReadTable()
    if type(snapshot)=='table' and type(snapshot.events)=='table'
        and (tonumber(snapshot.token) or 0)>=(tonumber(LOD.DungeonEvents.token) or 0) then
        LOD.DungeonEvents=snapshot
    end
end)
hook.Add('HUDPaint','LOD_DungeonEventPrompt',function()
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or LOD.UI.ActivePage then return end
    local tr=ply:GetEyeTrace()
    local ent=tr and tr.Entity
    if not IsValid(ent) or ent:GetClass()~='lod_dungeon_event' or ply:GetPos():DistToSqr(ent:GetPos())>160*160 then return end
    local row
    for _,event in ipairs(LOD.DungeonEvents.events) do
        if event.id==ent:GetEventID() and event.entityIndex==ent:EntIndex() then row=event;break end
    end
    local key=string.upper(input.LookupBinding('+use') or 'E')
    local archetype=row and row.archetype or ent:GetNW2String('LOD_EventArchetype','slot_machine')
    local treasure=archetype=='treasure_chest'
    local chest=treasure or archetype=='locked_chest'
    local lines
    if archetype=='vending_machine' then
        local details=row and row.details or {}
        local held=details.held or 0
        if LOD.Equipment and LOD.Equipment.HasSnapshot then
            local item=LOD.Equipment.Snapshot.items.healing_potion
            held=item and item.count or 0
        end
        local balance=details.balance
        if LOD.Wallet and LOD.Wallet.Snapshot and type(LOD.Wallet.Snapshot.balance)=='number' then
            balance=LOD.Wallet.Snapshot.balance
        end
        lines={'DEBBIE VENDING','1 Healing Potion — 10 $DEB. One purchase per account per dungeon.',
            'Potion stack: '..held..'/3. Added to Equipment; does not heal immediately.'}
        if not row then lines[#lines+1]='Synchronizing machine…'
        elseif row.claimUnavailable then lines[#lines+1]='Wallet unavailable — nothing spent; retry shortly.'
        elseif row.claimed then lines[#lines+1]='PURCHASED — return next dungeon.'
        elseif details.unavailable then lines[#lines+1]='Wallet unavailable — nothing spent; retry shortly.'
        elseif held>=3 then lines[#lines+1]='Potion stack full — make room; nothing spent.'
        elseif (balance or 0)<10 then lines[#lines+1]='You need 10 $DEB. Nothing spent.'
        else lines[#lines+1]='['..key..'] BUY 1 HEALING POTION — 10 $DEB' end
    elseif chest then
        lines=treasure and {'TREASURE CHEST','One persistent DFT per account. Collection capacity: 8.'}
            or {'LOCKED CHEST','One procedural wearable for each Hero account.'}
        if treasure and row then lines[#lines+1]='Chest '..tostring(row.memberIndex or 1)..' of '..tostring(row.memberCount or 1) end
        local details=row and row.details or {}
        local keys=details.keys or 0
        local equipment=LOD.Equipment
        if equipment and equipment.HasSnapshot then
            local stack=equipment.Snapshot.items.chest_key
            keys=stack and stack.count or 0
        end
        if not row then lines[#lines+1]='Synchronizing chest…'
        elseif row.claimUnavailable then lines[#lines+1]='Wallet unavailable — nothing spent; retry shortly.'
        elseif row.claimed then lines[#lines+1]=treasure and 'OPENED — DFT recorded in Wallet.' or 'OPENED — reward added to Equipment.'
        elseif details.unavailable then lines[#lines+1]='Reward unavailable — nothing spent; retry shortly.'
        elseif details.collectionFull then lines[#lines+1]='DFT collection full — sell a token in staging; nothing spent.'
        elseif details.unlocked then lines[#lines+1]='['..key..'] COLLECT — lock already picked'
        else
            if keys>0 then lines[#lines+1]='['..key..'] USE 1 CHEST KEY  ('..keys..' held)'
            elseif details.threshold and not details.attempted then lines[#lines+1]='['..key..'] PICK LOCK'
            else lines[#lines+1]='Find a Chest Key to open your reward.' end
            if details.attempted then lines[#lines+1]='Lockpick attempt spent; a Chest Key still works.'
            elseif details.threshold then
                local sprint=string.upper(input.LookupBinding('+speed') or 'SHIFT')
                lines[#lines+1]='['..sprint..' + '..key..'] PICK LOCK — '..details.threshold..'% chance; one attempt.'
            end
        end
    else
        lines={'DEBBIE SLOTS','Pay 5 $DEB. 1d4: roll 4 returns 15; otherwise 0.',
        '25%: +10 net  |  75%: -5 net  |  One play per account.'}
        if not row then lines[#lines+1]='Synchronizing machine…'
        elseif row.claimUnavailable then lines[#lines+1]='Wallet unavailable — try again shortly.'
        elseif row.claimed then
            local result=row.result
            lines[#lines+1]=result and string.format('PLAYED — rolled %d; returned %d $DEB.',result.face or 0,result.payout or 0) or 'PLAYED — return next dungeon.'
        else lines[#lines+1]='['..key..'] WAGER 5 $DEB' end
    end
    for i,line in ipairs(lines) do
        draw.SimpleTextOutlined(line,'LOD_HUD_Small',ScrW()/2,ScrH()/2+24+i*20,
            Color(245,225,155),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,230))
    end
end)
