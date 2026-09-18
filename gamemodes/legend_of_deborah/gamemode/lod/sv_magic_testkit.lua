-- Explicit developer setup: progression remains canonical and the run unranked.
concommand.Add('lod_magic_test_all',function(ply)
    local cv=GetConVar('lod_developer_mode')
    if not IsValid(ply) then print('[LOD:MAGIC-TEST] Run lod_magic_test_all from your player console.');return end
    if not cv or not cv:GetBool() or not ply:IsAdmin() then
        ply:ChatPrint('Magic test setup requires an admin and server lod_developer_mode 1.');return
    end
    local run=LOD.RunManager
    if run and run.IsSoldierControl and run:IsSoldierControl(ply) then
        ply:ChatPrint('Return to your Hero before granting test Forms.');return
    end
    local ps=run and run:GetPlayerState(ply)
    local state=ps and ps.progressionState
    if not state then ply:ChatPrint('Choose a character first.');return end
    run:MarkUnranked('magic_all_forms_testkit')
    local progression=LOD.MagicProgression
    local count=0
    for _,id in ipairs(progression.FormOrder) do
        if progression:GrantForm(state,id) then count=count+1 end
    end
    for _,id in ipairs(progression.ContentOrder) do progression:GrantContent(state,id) end
    ps.magic=100;LOD.Magic.NextCast[ply]=0
    ply:SetNW2Float('LOD_MagicNextCast',0);LOD.Magic:_Sync(ply,ps)
    LOD.CharacterProgressionSystem:SyncPlayer(ply)
    ply:ChatPrint(string.format('MAGIC TEST: %d Forms + all Contents; Magic refilled. I opens Spellbook. Run unranked.%s',
        count,state.classId~='wizard' and ' Wall and Summon remain Wizard-only.' or ''))
end)
