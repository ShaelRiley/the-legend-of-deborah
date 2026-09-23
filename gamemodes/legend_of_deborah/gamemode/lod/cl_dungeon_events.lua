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
    if not IsValid(ply) or not ply:Alive() or LOD.UI.ActivePage or (LOD.UI.IsMinigameLocked and LOD.UI:IsMinigameLocked()) then return end
    local tr=ply:GetEyeTrace()
    local ent=tr and tr.Entity
    if not IsValid(ent) or (ent:GetClass()~='lod_dungeon_event'
        and ent:GetNW2String('LOD_EventArchetype','')~='false_floor'
        and ent:GetNW2String('LOD_EventArchetype','')~='skeleton_blockade')
        or ply:GetPos():DistToSqr(ent:GetPos())>160*160 then return end
    local eventID=ent.GetEventID and ent:GetEventID() or ent:GetNW2String('LOD_EventID','')
    local row,endpoint
    for _,event in ipairs(LOD.DungeonEvents.events) do
        if event.id==eventID then
            if event.archetype=='warp_hole' or event.archetype=='bribe_blockade' then
                for index,point in ipairs(event.details and event.details.endpoints or {}) do
                    if point.entityIndex==ent:EntIndex() then row,endpoint=event,index;break end
                end
            elseif event.entityIndex==ent:EntIndex()
                or event.archetype=='skeleton_blockade' and event.details and event.details.barrierIndex==ent:EntIndex() then row=event end
            if row then break end
        end
    end
    local key=string.upper(input.LookupBinding('+use') or 'E')
    local archetype=row and row.archetype or ent:GetNW2String('LOD_EventArchetype','slot_machine')
    local treasure=archetype=='treasure_chest'
    local chest=treasure or archetype=='locked_chest'
    local lines
    if archetype=='equipment_quiz' then
        local details=row and row.details or {}
        if details.spent then return end
        lines={'GAME MASTER — EQUIPMENT QUIZ',
            'Identify your worn equipment. Correct: one DFT. Wrong: that item is stolen.',
            '['..key..'] REVIEW CHALLENGE — accepting spends your one attempt this dungeon.'}
    elseif archetype=='skeleton_blockade' then
        local details=row and row.details or {}
        lines={details.name or 'SKELETON OF A HERO',
            details.class and string.upper(details.class)..' — LEVEL '..tostring(details.level or '?') or 'Hero-derived hostile miniboss',
            details.opened and 'DEFEATED — passage open for everyone.' or 'Defeat the Skeleton on this side to open the passage.'}
        if not row then lines[#lines+1]='Synchronizing encounter…' end
    elseif archetype=='bribe_blockade' then
        local details=row and row.details or {}
        local cache=ent:GetNW2String('LOD_BribeRole','')=='cache'
        lines={cache and 'LOST-PROPERTY CACHE' or 'BRIBE BLOCKADE — 50 $DEB OF EQUIPMENT',
            'One Hero pays; the passage opens for everyone. No cash charge or change.'}
        if not row then lines[#lines+1]='Synchronizing blockade…'
        elseif details.opened then lines[#lines+1]='OPEN — payment complete for this dungeon.'
        elseif cache then
            lines[#lines+1]=details.recovered and 'Ring earmarked for the party. Return to the toll terminal.'
                or '['..key..'] RECOVER SHARED COLLATERAL — ring stays safe here until payment.'
        else
            lines[#lines+1]=details.recovered and 'Lost-property collateral available; your carried gear can stay intact.'
                or 'Recover the lost-property cache on this side, or offer unequipped wearables.'
            lines[#lines+1]='['..key..'] REVIEW PAYMENT — choose items, then explicitly confirm.'
        end
    elseif archetype=='warp_hole' then
        local details=row and row.details
        local point=details and details.endpoints[endpoint]
        local number=endpoint or ent:GetNW2Int('LOD_WarpEndpoint',0)
        local floor=point and point.destinationFloor or ent:GetNW2Int('LOD_WarpDestinationFloor',0)
        lines={'WARP HOLE — ENDPOINT '..number..' → FLOOR '..floor,
            'Free paired shortcut. Ordinary stairs and progression remain available.'}
        if not row then lines[#lines+1]='Synchronizing warp…'
        else
            lines[#lines+1]=details.linked and 'LINKED — available to every deployed Hero this dungeon.'
                or 'DORMANT — first safe trip permanently links both ends this dungeon.'
            lines[#lines+1]='['..key..'] '..(details.linked and 'TRAVERSE' or 'LINK AND TRAVERSE')..' — 1 second between trips; arrival must be clear.'
        end
    elseif archetype=='false_floor' then
        lines={'FALSE FLOOR','The central panel drops you one floor. Walk around its rim to avoid it.',
            'Return by the existing stairs. Ordinary fall damage applies.',
            row and row.details and row.details.open and 'OPEN — resets after 3 seconds when clear.' or 'ARMED — stepping onto the panel opens it.'}
    elseif archetype=='vending_machine' then
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
