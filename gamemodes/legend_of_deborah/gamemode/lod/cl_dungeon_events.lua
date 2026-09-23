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
    local lines={'DEBBIE SLOTS','Pay 5 $DEB. 1d4: roll 4 returns 15; otherwise 0.',
        '25%: +10 net  |  75%: -5 net  |  One play per account.'}
    if not row then lines[#lines+1]='Synchronizing machine…'
    elseif row.claimUnavailable then lines[#lines+1]='Wallet unavailable — try again shortly.'
    elseif row.claimed then
        local result=row.result
        lines[#lines+1]=result and string.format('PLAYED — rolled %d; returned %d $DEB.',result.face or 0,result.payout or 0) or 'PLAYED — return next dungeon.'
    else lines[#lines+1]='['..key..'] WAGER 5 $DEB' end
    for i,line in ipairs(lines) do
        draw.SimpleTextOutlined(line,'LOD_HUD_Small',ScrW()/2,ScrH()/2+24+i*20,
            Color(245,225,155),TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,230))
    end
end)
