-- Reuse existing production harnesses; only Source entities, traces and transport
-- are doubled. Load loot wrappers in their real order before equipment adapters.
return function(withGraph)
    local root='gamemodes/legend_of_deborah/gamemode/lod/'
    local H,graphConfig,graphBuilder,graphVector,graphAngle,traceLine,traceHull
    if withGraph then
        H=dofile('tools/test_bestiary_b20.lua')
        dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua')
        graphConfig,graphBuilder=LOD.Config,LOD.MazeBuilder
        graphVector,graphAngle,traceLine,traceHull=Vector,Angle,util.TraceLine,util.TraceHull
        -- The equipment fixture loads shared.lua. Preserve the planner's actual
        -- completed Bestiary configuration rather than rebuilding its providers.
        LOD.Config={}
        include=nil -- let the equipment fixture install its real shared loader
        player.GetAll=function() return {} end
        IsValid=nil
    end
    local original=dofile
    dofile=function(path)
        local result=original(path)
        if path==root..'sv_loot_director.lua' then
            for _,name in ipairs({'sv_loot_context_rules.lua','sv_loot_budget_validation.lua',
                'sv_firearm_economy_equalization.lua','sv_loot_campaign_decay.lua',
                'sv_loot_smg_cap_alignment.lua'}) do original(root..name) end
        end
        return result
    end
    local env=original('tools/test_equipment_economy_runtime.lua')
    dofile=original
    if H then
        LOD.Config,LOD.MazeBuilder=graphConfig,graphBuilder
        Vector,Angle,util.TraceLine,util.TraceHull=graphVector,graphAngle,traceLine,traceHull
        H.Run.State=env.Run.State
        env.Run._ActiveCount=function() return H.Run:_ActiveCount() end
    end
    if not LOD.Equipment.Archetypes then dofile(root..'sh_big_loot_catalog.lua') end
    dofile(root..'sv_staging_deployment.lua')
    dofile(root..'sv_loot_ecology.lua')
    env.H=H
    function env:setRun(state)
        self.Run.State=state
        if self.H then self.H.Run.State=state end
    end
    function env:player(id,class)
        local p=self.actor(id)
        p.ps.progressionState.classId=class or 'fighter'
        self.Run.State.PlayerState=self.Run.State.PlayerState or {}
        self.Run.State.PlayerState[id]=p.ps
        self.Run.State.ActiveIdentity=self.Run.State.ActiveIdentity or {}
        self.Run.State.ActiveIdentity[id]=true
        p.ps.lives=3;p.ps.deploymentComplete=true
        return p
    end
    return env
end
