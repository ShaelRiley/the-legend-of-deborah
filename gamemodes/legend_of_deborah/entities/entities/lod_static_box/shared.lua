ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Static Box"
ENT.Spawnable = false
ENT.AdminOnly = false

local nativeDTVector
if CLIENT and FindMetaTable and debug and debug.getinfo and debug.getupvalue then
    local meta = FindMetaTable("Entity")
    local getter = meta and meta.GetDTVector
    if getter and debug.getinfo(getter, "S").what == "C" then nativeDTVector = getter end
end
local function nativeVectorAccessor(getter)
    if not nativeDTVector or type(getter) ~= "function" then return false end
    -- NetworkVar captures its typed native reader in a private descriptor.
    -- Unknown implementations retain scalar reads; no returned value is cached.
    local index = 1
    while true do
        local name, value = debug.getupvalue(getter, index)
        if not name then return false end
        if type(value) == "table" and value.GetFunc == nativeDTVector then return true end
        index = index + 1
    end
end

local function invalidateVisualKind(ent, _, _, value)
    -- Proxies run before the native value changes. A reentrant render must not
    -- cache the old value while the corresponding update is still pending.
    local record = ent._LODVisualKindRecord
    if record then
        record.kind = nil; record.pending = value; record.drawOwner=nil
        -- Proxies run before the write. Releasing our invisible-only flag is
        -- safe immediately and lets a newly visible floor enter this frame's
        -- native render selection; hiding waits for the committed native kind.
        if record.clientNoDrawOwned and value~=3 and value~=4 and value~=7 then
            if ent.SetNoDraw then ent:SetNoDraw(false) end
            record.clientNoDrawOwned=nil
        end
        ent._LODNextBoundsRefresh=0
        if ent.SetNextClientThink then ent:SetNextClientThink(CurTime()) end
    end
end

local function invalidateVisualBounds(ent, name, _, value)
    local record = ent._LODVisualKindRecord
    if record then
        record.boundsReady = nil
        if value then
            record[name=="BoxMins" and "pendingMins" or "pendingMaxs"]={value.x,value.y,value.z}
        end
    end
    ent._LODNextBoundsRefresh = 0
    if ent.SetNextClientThink then ent:SetNextClientThink(CurTime()) end
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BoxMins")
    self:NetworkVar("Vector", 1, "BoxMaxs")
    self:NetworkVar("Int", 0, "BoxKind")
    if CLIENT and self.NetworkVarNotify then
        self:NetworkVarNotify("BoxKind", invalidateVisualKind)
        self:NetworkVarNotify("BoxMins", invalidateVisualBounds)
        self:NetworkVarNotify("BoxMaxs", invalidateVisualBounds)
        -- Only this declared native accessor pair can borrow the notification.
        -- Legacy/custom entities retain the renderer's ordinary polling path.
        self._LODVisualKindGetter = self.GetBoxKind
        self._LODVisualKindSetter = self.SetBoxKind
        local data = self.GetTable and self:GetTable()
        -- The registry must not retain a removed entity through its bound DT
        -- closures. Borrow the live Lua table weakly, never its getter objects.
        self._LODVisualKindRecord = type(data)=="table"
            and {lua=setmetatable({data},{__mode="v"}),
                boundsNative=nativeVectorAccessor(self.GetBoxMins) and nativeVectorAccessor(self.GetBoxMaxs),
                boundsAccessors=setmetatable({self.GetBoxMins,self.GetBoxMaxs},{__mode="v"})} or nil
    end
end
