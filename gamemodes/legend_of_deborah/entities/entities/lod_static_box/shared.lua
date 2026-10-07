ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Static Box"
ENT.Spawnable = false
ENT.AdminOnly = false

local function invalidateVisualKind(ent, _, _, value)
    -- Proxies run before the native value changes. A reentrant render must not
    -- cache the old value while the corresponding update is still pending.
    local record = ent._LODVisualKindRecord
    if record then record.kind = nil; record.pending = value end
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BoxMins")
    self:NetworkVar("Vector", 1, "BoxMaxs")
    self:NetworkVar("Int", 0, "BoxKind")
    if CLIENT and self.NetworkVarNotify then
        self:NetworkVarNotify("BoxKind", invalidateVisualKind)
        -- Only this declared native accessor pair can borrow the notification.
        -- Legacy/custom entities retain the renderer's ordinary polling path.
        self._LODVisualKindGetter = self.GetBoxKind
        self._LODVisualKindSetter = self.SetBoxKind
        local data = self.GetTable and self:GetTable()
        -- The registry must not retain a removed entity through its bound DT
        -- closures. Borrow the live Lua table weakly, never its getter objects.
        self._LODVisualKindRecord = type(data)=="table"
            and {lua=setmetatable({data},{__mode="v"})} or nil
    end
end
