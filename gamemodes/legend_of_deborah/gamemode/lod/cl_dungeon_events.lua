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
    local chest=(row and row.archetype=='locked_chest')
        or ent:GetNW2String('LOD_EventArchetype','slot_machine')=='locked_chest'
    local lines
    if chest then
        lines={'LOCKED CHEST','One procedural wearable for each Hero account.'}
        local details=row and row.details or {}
        local keys=details.keys or 0
        local equipment=LOD.Equipment
        if equipment and equipment.HasSnapshot then
            local stack=equipment.Snapshot.items.chest_key
            keys=stack and stack.count or 0
        end
        if not row or details.unavailable then lines[#lines+1]='Synchronizing chest…'
        elseif row.claimed then lines[#lines+1]='OPENED — reward added to Equipment.'
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
