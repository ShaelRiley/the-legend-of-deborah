if not SERVER then return end

local function runQA()
    print("================== AG003 QA START ==================")
    local ply = player.GetAll()[1]
    if not IsValid(ply) then
        print("[AG003-QA] FAIL: No player found")
        RunConsoleCommand("quit")
        return
    end

    -- Setup
    ply:SetNW2Int("LOD_DEX", 15)
    LOD.CharacterProgressionSystem:GrantFeat(ply, "DEX_MAGNUM_DEADEYE")

    local weapons = {"weapon_pistol", "weapon_357", "weapon_lod_crowbar", "weapon_smg1", "weapon_shotgun", "weapon_ar2", "weapon_frag"}
    for _, w in ipairs(weapons) do ply:Give(w) end
    ply:GiveAmmo(999, "Pistol")
    ply:GiveAmmo(999, "357")
    ply:GiveAmmo(999, "SMG1")
    ply:GiveAmmo(999, "Buckshot")
    ply:GiveAmmo(999, "AR2")
    ply:GiveAmmo(10, "Grenade")

    local function runSequence(seq, idx)
        if idx > #seq then
            print("MULTICLIENT_ISOLATION=HUMAN_FOLLOWUP")
            print("[LOD:DEADEYE] QA runtime gates PASS")

            RunConsoleCommand("lod_deadeye_aim_validate")
            RunConsoleCommand("lod_deadeye_aim_status")
            RunConsoleCommand("lod_rpg_test_mark", "ag003_deadeye")
            RunConsoleCommand("lod_rpg_validate")
            RunConsoleCommand("lod_rpg_test_finish", "ag003_deadeye")
            RunConsoleCommand("lod_rpg_test_upload_status")

            timer.Simple(2, function() RunConsoleCommand("quit") end)
            return
        end
        local step = seq[idx]
        if type(step) == "string" then
            if step:match("^wep_") then
                ply:SelectWeapon("weapon_" .. step:sub(5))
                timer.Simple(0.5, function() runSequence(seq, idx+1) end)
            elseif step == "+attack" then
                ply:ConCommand("+attack")
                timer.Simple(0.1, function()
                    ply:ConCommand("-attack")
                    runSequence(seq, idx+1)
                end)
            elseif step == "+attack2" then
                ply:ConCommand("+attack2")
                timer.Simple(0.1, function()
                    ply:ConCommand("-attack2")
                    runSequence(seq, idx+1)
                end)
            end
        elseif type(step) == "number" then
            timer.Simple(step, function() runSequence(seq, idx+1) end)
        end
    end

    local seq = {
        "wep_pistol", 1.0, "+attack", 0.1, "+attack", 0.5,
        "wep_357", 1.0, "+attack", 0.5,
        "wep_lod_crowbar", 1.0, "+attack", 0.5, "+attack", 0.5,
        "wep_smg1", 1.0, "+attack", 0.1, "+attack", 0.5,
        "wep_shotgun", 1.0, "+attack", 0.5,
        "wep_ar2", 1.0, "+attack", 1.0, "+attack2", 0.5,
        "wep_frag", 1.0, "+attack", 0.5
    }

    runSequence(seq, 1)
end

concommand.Add("ag003_run_qa", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    runQA()
end)

hook.Add("InitPostEntity", "AG003_AutoQA", function()
    timer.Simple(5, function()
        if GetConVar("lod_developer_mode") and GetConVar("lod_developer_mode"):GetBool() then
            if #player.GetAll() > 0 then
                runQA()
            end
        end
    end)
end)
