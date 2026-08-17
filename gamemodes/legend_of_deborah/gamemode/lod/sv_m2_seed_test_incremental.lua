LOD = LOD or {}

local RunManager = LOD.RunManager

local function allowed(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function printTo(ply, text)
    print("[LOD:M2] " .. text)
    if IsValid(ply) then ply:ChatPrint(text) end
end

-- Full progression generation is intentionally expensive. Running dozens or
-- hundreds of seeds in one concommand callback monopolizes Garry's Mod's main
-- Lua thread and makes the client appear frozen. Replace the original M2 seed
-- test with an incremental runner that yields between generated seeds.
concommand.Remove("lod_m2_seed_test")

concommand.Add("lod_m2_seed_test", function(ply, _, args)
    if not allowed(ply) then return end

    local count = math.Clamp(math.floor(tonumber(args[1]) or 100), 1, LOD.Config.Debug.SeedTestMax)
    local base = RunManager.State.LevelSeed or 1

    if LOD.M2SeedTestJob and LOD.M2SeedTestJob.active then
        LOD.M2SeedTestJob.active = false
        printTo(ply, "previous incremental seed test cancelled")
    end

    local job = {
        active = true,
        count = count,
        nextIndex = 1,
        failures = 0,
        worstLayoutAttempt = 0,
        minDetour = math.huge,
        maxDetour = 0,
        minGateSeparation = math.huge,
        elapsed = 0,
        ply = ply,
        base = base
    }
    LOD.M2SeedTestJob = job

    local progressEvery = math.max(1, math.floor(count / 10))

    local function finish()
        if not job.active then return end
        job.active = false
        if job.minDetour == math.huge then job.minDetour = 0 end
        if job.minGateSeparation == math.huge then job.minGateSeparation = 0 end
        printTo(job.ply, string.format(
            "seed test generated=%d failures=%d worstLayoutAttempt=%d cardDetourRange=%d-%d minGateSeparation=%d generationCPU=%.2fs",
            job.count,
            job.failures,
            job.worstLayoutAttempt,
            job.minDetour,
            job.maxDetour,
            job.minGateSeparation,
            job.elapsed
        ))
    end

    local function step()
        if not job.active or LOD.M2SeedTestJob ~= job then return end

        local i = job.nextIndex
        local seed = LOD.Seeds.Derive(job.base, "m2-seed-test:" .. i)
        local started = SysTime()
        local graph = RunManager:_GenerateProgressionLevel(seed)
        job.elapsed = job.elapsed + (SysTime() - started)

        if not graph or not graph.Progression or not graph.Progression.Validation or not graph.Progression.Validation.valid then
            job.failures = job.failures + 1
        else
            job.worstLayoutAttempt = math.max(job.worstLayoutAttempt, graph.ProgressionLayoutAttempt or 1)
            for _, card in ipairs(graph.Progression.Keycards or {}) do
                local d = card.graphDistanceFromSectorEntry or 0
                job.minDetour = math.min(job.minDetour, d)
                job.maxDetour = math.max(job.maxDetour, d)
                if card.gateCellSeparation then
                    job.minGateSeparation = math.min(job.minGateSeparation, card.gateCellSeparation)
                end
            end
        end

        job.nextIndex = i + 1
        if i >= job.count then
            finish()
            return
        end

        if i % progressEvery == 0 then
            printTo(job.ply, string.format(
                "seed test progress %d/%d failures=%d",
                i, job.count, job.failures
            ))
        end

        -- Timers still run on Garry's Mod's main thread, but yielding between
        -- seeds prevents one enormous uninterrupted multi-minute stall and lets
        -- the game render/respond between individual expensive generations.
        timer.Simple(0.25, step)
    end

    printTo(ply, string.format(
        "incremental seed test started: %d seeds; brief per-seed hitches may occur; use lod_m2_seed_test_cancel to stop",
        count
    ))
    timer.Simple(0, step)
end)

concommand.Add("lod_m2_seed_test_cancel", function(ply)
    if not allowed(ply) then return end
    if LOD.M2SeedTestJob and LOD.M2SeedTestJob.active then
        LOD.M2SeedTestJob.active = false
        printTo(ply, "incremental seed test cancelled")
    else
        printTo(ply, "no incremental seed test is running")
    end
end)
