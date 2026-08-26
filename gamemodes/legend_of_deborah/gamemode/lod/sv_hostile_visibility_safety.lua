LOD = LOD or {}
LOD.HostileVisibilitySafety = LOD.HostileVisibilitySafety or {
    DeathSerial = 0,
    Repairs = 0,
    StaleDeathRecords = 0
}

local Safety = LOD.HostileVisibilitySafety
local Motion = LOD.HostileMotionV2

local function ensureLivingVisible(hostile)
    if not IsValid(hostile) or not hostile.LODHostile or hostile.LODDead then return false end

    local repaired = false
    if hostile:GetNoDraw() then
        hostile:SetNoDraw(false)
        repaired = true
    end

    local color = hostile:GetColor()
    if color and color.a < 255 then
        hostile:SetColor(Color(color.r, color.g, color.b, 255))
        repaired = true
    end

    if repaired then
        hostile:DrawShadow(true)
        Safety.Repairs = (Safety.Repairs or 0) + 1
    end
    return repaired
end

local function installDeathGuard()
    local death = LOD.HostileDeathPresentation
    if not death or death.LODVisibilityGuardInstalled then return false end
    death.LODVisibilityGuardInstalled = true

    local baseAdd = death.Add
    if baseAdd then
        function death:Add(hostile)
            if not IsValid(hostile) then return false end
            Safety.DeathSerial = (Safety.DeathSerial or 0) + 1
            local token = Safety.DeathSerial
            hostile.LODDeathPresentationToken = token

            local before = #self.Active
            local ok = baseAdd(self, hostile)
            if ok then
                -- Add currently appends exactly one record, but find by identity so
                -- this remains safe if that implementation changes later.
                for i = #self.Active, before + 1, -1 do
                    local record = self.Active[i]
                    if record and record.hostile == hostile then
                        record.LODVisibilityToken = token
                        break
                    end
                end
            end
            return ok
        end
    end

    local baseRunDue = death._RunDue
    if baseRunDue then
        function death:_RunDue()
            -- A death blink may never alter a living actor. This also protects
            -- against stale entity handles/records surviving longer than the
            -- death state that created them.
            for i = #self.Active, 1, -1 do
                local record = self.Active[i]
                local hostile = record and record.hostile
                if IsValid(hostile) then
                    local tokenMatches = record.LODVisibilityToken ~= nil
                        and hostile.LODDeathPresentationToken == record.LODVisibilityToken
                    if not hostile.LODDead or not tokenMatches then
                        table.remove(self.Active, i)
                        ensureLivingVisible(hostile)
                        Safety.StaleDeathRecords = (Safety.StaleDeathRecords or 0) + 1
                    end
                end
            end
            return baseRunDue(self)
        end
    end

    return true
end

local function installHostileGuard()
    local stored = scripted_ents.GetStored("lod_hostile")
    local class = stored and stored.t
    if not class or class.LODLivingVisibilityGuardInstalled then return false end
    class.LODLivingVisibilityGuardInstalled = true

    local baseInitialize = class.Initialize
    function class:Initialize()
        baseInitialize(self)
        if IsValid(self) and self.LODHostile and not self.LODDead then
            self:SetNoDraw(false)
            local color = self:GetColor()
            if color and color.a < 255 then
                self:SetColor(Color(color.r, color.g, color.b, 255))
            end
            self:DrawShadow(true)
        end
    end

    local baseBehaviourTick = class._BehaviourTick
    if baseBehaviourTick then
        function class:_BehaviourTick()
            ensureLivingVisible(self)
            return baseBehaviourTick(self)
        end
    end

    local baseTryAttack = class._TryAttack
    if baseTryAttack then
        function class:_TryAttack(target)
            ensureLivingVisible(self)
            return baseTryAttack(self, target)
        end
    end

    return true
end

local function installMotionGuard()
    if not Motion or Motion.LODLivingVisibilityGuardInstalled then return false end
    Motion.LODLivingVisibilityGuardInstalled = true

    local baseMoveToward = Motion.MoveToward
    if baseMoveToward then
        function Motion:MoveToward(hostile, waypoint)
            ensureLivingVisible(hostile)
            return baseMoveToward(self, hostile, waypoint)
        end
    end

    local baseStop = Motion.Stop
    if baseStop then
        function Motion:Stop(hostile)
            ensureLivingVisible(hostile)
            return baseStop(self, hostile)
        end
    end
    return true
end

installDeathGuard()
installHostileGuard()
installMotionGuard()

hook.Add("OnEntityCreated", "LOD_LivingHostileVisibilityInstall", function(ent)
    if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
    installDeathGuard()
    installHostileGuard()
    -- Explicitly normalize a fresh living hostile on the next engine tick after
    -- its Initialize chain has finished; no recurring timer is retained.
    timer.Simple(0, function()
        if IsValid(ent) then ensureLivingVisible(ent) end
    end)
end)

function Safety:EnsureLivingVisible(hostile)
    return ensureLivingVisible(hostile)
end

concommand.Add("lod_hostile_visibility_safety_status", function(ply)
    local cv = GetConVar("lod_developer_mode")
    if cv and not cv:GetBool() then return end
    if IsValid(ply) and not ply:IsAdmin() then return end

    local line = string.format(
        "repairs=%d staleDeathRecords=%d deathGuard=%s hostileGuard=%s motionGuard=%s recurringService=false",
        Safety.Repairs or 0,
        Safety.StaleDeathRecords or 0,
        tostring(LOD.HostileDeathPresentation and LOD.HostileDeathPresentation.LODVisibilityGuardInstalled == true),
        tostring((scripted_ents.GetStored("lod_hostile") or {}).t and (scripted_ents.GetStored("lod_hostile") or {}).t.LODLivingVisibilityGuardInstalled == true),
        tostring(Motion and Motion.LODLivingVisibilityGuardInstalled == true))
    print("[LOD:HOSTILE-VIS-SAFETY] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)