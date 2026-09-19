local A,Run=LOD.Audio,LOD.RunManager
SetGlobalBool('LOD_GenerationSilent',true)
A.Building=true
local serial=0
local function mute()
    serial=serial+1;A.Building=true;SetGlobalBool('LOD_GenerationSilent',true)
    return serial
end
local build=Run.BuildCurrentLevel
function Run:BuildCurrentLevel(...)
    local token=mute()
    local ok,result=build(self,...)
    if ok then
        -- Spawn/weapon settlement may run on the next engine tick. Keep that
        -- implementation work silent, then release the finished staging room.
        timer.Simple(.25,function()
            if token~=serial or not Run.State.BuildReady then return end
            A.Building=false;SetGlobalBool('LOD_GenerationSilent',false)
        end)
    end
    return ok,result
end
local campaign=Run.NewCampaign
function Run:NewCampaign(...)
    mute() -- includes hut teardown before the underlying level build begins
    return campaign(self,...)
end
hook.Add('PreCleanupMap','LOD_AudioCleanupBarrier',mute)

-- Admin map cleanup can occur without a campaign rebuild. Restore the same
-- finished-state policy once removal callbacks have settled.
hook.Add('PostCleanupMap','LOD_AudioCleanupRelease',function()
    local token=serial
    timer.Simple(.25,function()
        if token~=serial or not Run.State.BuildReady then return end
        A.Building=false;SetGlobalBool('LOD_GenerationSilent',false)
    end)
end)
