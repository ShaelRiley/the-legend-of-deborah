include("shared.lua")

local GC = LOD and LOD.Config and LOD.Config.Geometry or {}
local floorColor = GC.FloorColor or Color(46, 49, 51, 255)
local stairColor = GC.StairColor or Color(68, 72, 74, 255)
local stairEdgeColor = GC.DebugColor or Color(225, 145, 48, 255)
local textureTile = GC.FloorTextureTile or 384

local function floorMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.GetIndustrialMaterial then
        return LOD.TexturedBox:GetIndustrialMaterial(GC.FloorMaterialFallback)
    end
    local mat = Material(GC.FloorMaterial or "models/props_wasteland/metal_tram001a")
    if mat:IsError() then
        mat = Material(GC.FloorMaterialFallback or "models/props_c17/FurnitureMetal001a")
    end
    return mat
end

LOD = LOD or {}
LOD.TexturedBox = LOD.TexturedBox or {}
-- Scheduled Think must not delay existing floor registration after Lua refresh.
-- Keep the same weak registry with the existing textured-geometry authority.
LOD.TexturedBox.StaticVisualBoxes = LOD.TexturedBox.StaticVisualBoxes or setmetatable({}, {__mode = "k"})
local visualBoxes = LOD.TexturedBox.StaticVisualBoxes
local nativeDrawOwner = {}
local nativeDefinition = ENT
local nativePass
local nativeDraw

-- Source already culls these entities using their live pose and render bounds.
-- Borrow that selection only for the exact opaque view that submitted it.
-- Unknown/nested/replaced views retain the existing conservative Lua path.
local function nativeView()
    local view = render.GetViewSetup and render.GetViewSetup(true)
    local p, a = view and view.origin, view and view.angles
    if not p or not a or view.ortho or view.offcenter
        or not view.fov or view.fov <= 0 or view.fov >= 180
        or not view.aspect or view.aspect <= 0 or not view.znear or view.znear < 0 then return end
    local values = {p.x,p.y,p.z,a.p,a.y,a.r,view.fov,view.aspect,view.znear,
        view.zfar,view.x,view.y,view.w,view.h}
    for i=1,9 do
        local value=values[i]
        if type(value)~="number" or value~=value or math.abs(value)==math.huge then return end
    end
    return values
end
hook.Add("PreRender", "LOD_StaticBoxNativeVisibility", function() nativePass=nil end)
hook.Add("PreDrawOpaqueRenderables", "LOD_StaticBoxNativeVisibility", function(depth, sky, sky3d)
    nativePass=nil
    if depth or sky or sky3d then return end
    local view=nativeView()
    if view then nativePass={view=view,entities={}} end
end)

local function currentNativePass()
    local pass=nativePass
    nativePass=nil
    if not pass then return end
    local view=nativeView()
    if not view then return end
    for i=1,14 do if pass.view[i]~=view[i] then return end end
    return pass
end

-- Transmission can resume before SetupDataTables installs the accessors.
-- Keep registry membership while waiting so the next ready frame recovers.
local function networkReady(ent, data)
    local fields = data or ent
    return fields.GetBoxMins and fields.GetBoxMaxs and fields.GetBoxKind
end

local function visibleKind(kind)
    return kind==1 or kind==2 or kind==5
end

local function registerVisualBox(ent)
    local record = ent._LODVisualKindRecord
    visualBoxes[ent] = record or true
    return record
end
local function resetKind(record)
    if type(record)=="table" then record.kind = nil; record.pending = nil; record.boundsReady = nil end
end
local function currentKind(ent, record)
    local data = type(record)=="table" and record.lua and record.lua[1]
    -- Native entity indexing itself crosses the engine boundary. Resolve the
    -- declared pair in its actual Lua table so invisible boxes stay in Lua.
    local observed = data and data._LODVisualKindRecord==record
        and data._LODVisualKindGetter and data._LODVisualKindSetter
        and data.GetBoxKind==data._LODVisualKindGetter and data.SetBoxKind==data._LODVisualKindSetter
    local cached = observed and record.kind
    if type(record)=="table" and not observed then record.kind = nil end
    if cached and not visibleKind(cached) then return cached, data end
    -- Only the verified live table may replace native entity indexing. Keep
    -- validity and current accessors live; copied/expired tables fail over.
    data = observed and data or nil
    if not IsValid(ent) then return nil end
    -- A missing instance accessor may now be inherited from a replaced class.
    -- Use the ordinary entity lookup for that legacy/custom readiness path.
    if data and not networkReady(ent, data) then data = nil end
    if not data and not networkReady(ent) then return nil end
    if cached then return cached, data end
    local kind = ent:GetBoxKind()
    -- Zero is the unreceived datatable default. Native spawn-time proxies can
    -- be absent, so keep polling it until the initial nonzero kind arrives.
    if observed and kind~=0 and (record.pending==nil or record.pending==kind) then
        record.kind = kind
        record.pending = nil
    end
    return kind, data
end

-- Invisible collision surrogates need neither a native model draw nor its
-- render-queue work. Keep them transmitted and solid; only the client flag is
-- owned here. Unknown/custom kind accessors retain the previous native path.
local function syncNativeDrawQueue(ent)
    if not ent.SetNoDraw or not ent.GetNoDraw then return end
    local record=ent._LODVisualKindRecord
    if type(record)~="table" then return end
    local kind,data=currentKind(ent,record)
    local hide=data and record.pending==nil and (kind==3 or kind==4 or kind==7)
    if hide then
        if not ent:GetNoDraw() then
            ent:SetNoDraw(true)
            record.clientNoDrawOwned=true
        end
    elseif record.clientNoDrawOwned then
        ent:SetNoDraw(false)
        record.clientNoDrawOwned=nil
    end
end

local function refreshRenderBounds(ent)
    if not networkReady(ent) then return false end
    local mins = ent:GetBoxMins()
    local maxs = ent:GetBoxMaxs()
    local record=ent._LODVisualKindRecord
    if record then
        local lo,hi=record.pendingMins,record.pendingMaxs
        -- Notifications precede the native write. A reentrant Think must not
        -- certify the old bounds while their new value is still pending.
        if lo and (lo[1]~=mins.x or lo[2]~=mins.y or lo[3]~=mins.z)
            or hi and (hi[1]~=maxs.x or hi[2]~=maxs.y or hi[3]~=maxs.z) then
            record.boundsReady=nil
            return false
        end
        record.pendingMins,record.pendingMaxs=nil,nil
    end
    local b = ent._LODBoundsSnapshot
    if not b or b[1]~=mins.x or b[2]~=mins.y or b[3]~=mins.z
        or b[4]~=maxs.x or b[5]~=maxs.y or b[6]~=maxs.z then
        ent._LODBoundsSnapshot = {mins.x,mins.y,mins.z,maxs.x,maxs.y,maxs.z}
        local margin = Vector(32, 32, 32)
        ent:SetRenderBounds(mins - margin, maxs + margin)
    end
    if record then
        local accessors=record.boundsAccessors
        record.boundsReady=accessors and ent.GetBoxMins==accessors[1] and ent.GetBoxMaxs==accessors[2]
    end
    return true
end

function ENT:Initialize()
    local record=registerVisualBox(self)
    resetKind(record)
    -- Fresh native instances bind this definition before Initialize. Retained
    -- instances from a Lua refresh stay on the fallback until Draw proves that
    -- their callback has reached this file's current implementation.
    if type(record)=="table" and nativeDefinition.Draw==nativeDraw then
        local data=record.lua and record.lua[1]
        local draw=data and rawget(data,"Draw")
        if not draw or draw==nativeDraw then record.drawOwner=nativeDrawOwner end
    end
    refreshRenderBounds(self)
    syncNativeDrawQueue(self)
    self._LODNextBoundsRefresh = 0
end

function ENT:Think()
    registerVisualBox(self)
    local now = CurTime()
    if now >= (self._LODNextBoundsRefresh or 0) and refreshRenderBounds(self) then
        syncNativeDrawQueue(self)
        self._LODNextBoundsRefresh = now + 1
    end
    -- Bounds already refresh once per second. Let Source sleep until that
    -- deadline instead of invoking an otherwise empty callback every frame.
    -- Incomplete datatables retain immediate native retries.
    if self.SetNextClientThink and (self._LODNextBoundsRefresh or 0) > now then
        self:SetNextClientThink(self._LODNextBoundsRefresh)
        return true
    end
end

function ENT:OnRemove(fullUpdate)
    -- Source may retain this entity across cl_fullupdate without Initialize.
    resetKind(visualBoxes[self])
    if not fullUpdate then visualBoxes[self] = nil end
    self._LODBoundsSnapshot = nil
    self._LODVisualBox = nil
end

hook.Add("NotifyShouldTransmit", "LOD_Recover_lod_static_box", function(ent, transmitting)
    if transmitting and IsValid(ent) and ent:GetClass() == "lod_static_box" then
        resetKind(registerVisualBox(ent))
        -- Defer bounds until Think; accessors may not exist in this hook.
        ent._LODNextBoundsRefresh = 0
        ent._LODBoundsSnapshot = nil
        ent._LODVisualBox = nil
        if ent.SetNextClientThink then ent:SetNextClientThink(CurTime()) end
    end
end)

function ENT:Draw()
    local pass=nativePass
    if not pass then return end
    pass.entities[self]=true
    local record=visualBoxes[self]
    if type(record)=="table" then record.drawOwner=nativeDrawOwner end
end
nativeDraw=ENT.Draw

local function nativeRejected(ent, record, data, pass)
    if not pass or pass.entities[ent] or not data or not record.boundsReady
        or nativeDefinition.Draw~=nativeDraw
        or record.drawOwner~=nativeDrawOwner
        or not record.boundsAccessors or data.GetBoxMins~=record.boundsAccessors[1]
        or data.GetBoxMaxs~=record.boundsAccessors[2] then return false end
    local draw=rawget(data,"Draw")
    if draw and draw~=nativeDraw then
        local profile=LOD.RuntimeAudit and LOD.RuntimeAudit.CPUProfile
        local bindings=profile and profile.bindings[data]
        local binding=bindings and bindings.Draw
        if not binding or binding.wrapper~=draw or binding.callback~=nativeDraw then return false end
    end
    -- A client NoDraw flag can suppress native Draw independently of bounds.
    -- The original manual renderer still owns such a floor's visibility.
    if ent.GetNoDraw and ent:GetNoDraw() then return false end
    return true
end

local function drawFloorSlab(ent, box, color, getMaterial)
    if ent:GetNW2Bool("LOD_CrateGrate",false) and LOD.TexturedBox and LOD.TexturedBox.DrawGrate then
        LOD.TexturedBox:DrawGrate(box.position,box.angles,box.mins,box.maxs,ent,box)
        return
    end
    local material = getMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.DrawSlab then
        LOD.TexturedBox:DrawSlab(
            box.position,
            box.angles,
            box.mins,
            box.maxs,
            material,
            color,
            textureTile,
            ent,
            box
        )
        return
    end

    if LOD.TexturedBox and LOD.TexturedBox.NeutralDrawState then LOD.TexturedBox:NeutralDrawState() end
    render.SetMaterial(material)
    render.DrawBox(box.position, box.angles, box.mins, box.maxs, color)
end

local function drawFullMetalBox(ent, box, color, getMaterial)
    local material = getMaterial()
    if LOD.TexturedBox and LOD.TexturedBox.Draw then
        LOD.TexturedBox:Draw(
            box.position,
            box.angles,
            box.mins,
            box.maxs,
            material,
            color,
            textureTile,
            ent,
            box
        )
        return
    end

    if LOD.TexturedBox and LOD.TexturedBox.NeutralDrawState then LOD.TexturedBox:NeutralDrawState() end
    render.SetMaterial(material)
    render.DrawBox(box.position, box.angles, box.mins, box.maxs, color)
end

local function drawWireframe(...)
    if LOD.TexturedBox and LOD.TexturedBox.NeutralDrawState then LOD.TexturedBox:NeutralDrawState() end
    render.DrawWireframeBox(...)
end

-- These boxes are submitted manually, bypassing the native entity draw culler.
-- Reject only oriented boxes wholly outside one current-view frustum plane.
-- Origin-centred spheres substantially over-admit long, thin floor runs and
-- stairs. Exact support bounds also preserve offset underdecks at any rotation.
-- There is no distance/floor/occlusion guess and no draw cap.
local function currentPerspective()
    if not render.GetViewSetup or not EyePos or not EyeVector then return nil end
    local view = render.GetViewSetup(true)
    if not view or view.ortho or view.offcenter
        or not view.fov or not (view.fov > 0 and view.fov < 180)
        or not view.znear or not (view.znear >= 0) then return nil end
    -- GetViewSetup(true) describes this render pass, including nested cameras.
    -- Its fov is ALREADY aspect-adjusted; applying Source's 4:3 correction again
    -- would hide visible geometry on some displays. Incomplete setups retain the
    -- previous conservative rear-plane check instead of guessing screen size.
    local angles = view.angles
    if not angles or not angles.Forward or not angles.Right or not angles.Up
        or not view.origin or not view.aspect or not (view.aspect > 0 and view.aspect < math.huge)
        or not angles.p or not angles.y or not angles.r
        or angles.p ~= angles.p or angles.y ~= angles.y or angles.r ~= angles.r then
        return EyePos(), EyeVector()
    end
    local tanX = math.tan(math.rad(view.fov) * 0.5)
    local tanY = tanX / view.aspect
    return view.origin, angles:Forward(), angles:Right(), angles:Up(),
        tanX, tanY, math.sqrt(1 + tanX*tanX), math.sqrt(1 + tanY*tanY)
end

local function plane(x,y,z,identityKey,valueKey)
    return {x,y,z,math.abs(x),math.abs(y),math.abs(z),identityKey,valueKey}
end
local lastPlanes
local function cameraSnapshot()
    local eye, f, r, u, tanX, tanY, normX, normY = currentPerspective()
    if not eye or not f then return nil end
    -- Native vector indexing and side-plane construction belong to this view,
    -- not to every generated box. Keep ownership local to the render pass so
    -- nested RenderView and immediate camera changes use their own planes.
    local fx,fy,fz=f.x,f.y,f.z
    local camera={ex=eye.x,ey=eye.y,ez=eye.z,fx=fx,fy=fy,fz=fz}
    local rx,ry,rz,ux,uy,uz
    if r and u then
        rx,ry,rz,ux,uy,uz=r.x,r.y,r.z,u.x,u.y,u.z
        camera.rx,camera.ry,camera.rz=rx,ry,rz
        camera.ux,camera.uy,camera.uz=ux,uy,uz
        camera.tanX,camera.tanY,camera.normX,camera.normY=tanX,tanY,normX,normY
    end
    -- Only direction-dependent coefficients are shared. Eye position and box
    -- geometry stay live on every pass; moving the camera never borrows a
    -- visibility decision. Immutable plane sets also survive nested views.
    local planes=lastPlanes
    if not planes or planes.fx~=fx or planes.fy~=fy or planes.fz~=fz
        or planes.rx~=rx or planes.ry~=ry or planes.rz~=rz
        or planes.ux~=ux or planes.uy~=uy or planes.uz~=uz
        or planes.tanX~=tanX or planes.tanY~=tanY
        or planes.normX~=normX or planes.normY~=normY then
        planes={fx=fx,fy=fy,fz=fz,rx=rx,ry=ry,rz=rz,ux=ux,uy=uy,uz=uz,
            tanX=tanX,tanY=tanY,normX=normX,normY=normY,
            front=plane(fx,fy,fz,"frontPlane","frontSupport")}
        if r and u then
            planes.left=plane(fx*tanX-rx,fy*tanX-ry,fz*tanX-rz,"leftPlane","leftSupport")
            planes.right=plane(fx*tanX+rx,fy*tanX+ry,fz*tanX+rz,"rightPlane","rightSupport")
            planes.bottom=plane(fx*tanY-ux,fy*tanY-uy,fz*tanY-uz,"bottomPlane","bottomSupport")
            planes.top=plane(fx*tanY+ux,fy*tanY+uy,fz*tanY+uz,"topPlane","topSupport")
        end
        lastPlanes=planes
    end
    camera.front,camera.left,camera.right=planes.front,planes.left,planes.right
    camera.bottom,camera.top=planes.bottom,planes.top
    return camera
end

-- A refresh can retain entities and snapshots from the previous implementation.
-- Resolve their basis again before borrowing fields owned by this file instance.
local snapshotOwner = {}
local function nativeMethod(metaName, name)
    local meta = FindMetaTable and FindMetaTable(metaName)
    local fn = meta and meta[name]
    if fn and debug and debug.getinfo and debug.getinfo(fn,"S").what=="C" then return fn end
end
local unpackVector, unpackAngle = nativeMethod("Vector","Unpack"), nativeMethod("Angle","Unpack")
local nativeGetPos, nativeGetAngles = nativeMethod("Entity","GetPos"), nativeMethod("Entity","GetAngles")
local function visualSnapshot(ent, data)
    local fields = data or ent
    local mins, maxs = fields.GetBoxMins(ent), fields.GetBoxMaxs(ent)
    local getPos, getAngles = ent.GetPos, ent.GetAngles
    local pos, angles = getPos(ent), getAngles(ent)
    local record = data and data._LODVisualKindRecord
    local x0,y0,z0,x1,y1,z1
    if unpackVector and record and record.boundsNative and record.boundsAccessors
        and data.GetBoxMins==record.boundsAccessors[1] and data.GetBoxMaxs==record.boundsAccessors[2] then
        x0,y0,z0=unpackVector(mins);x1,y1,z1=unpackVector(maxs)
    else
        x0,y0,z0,x1,y1,z1=mins.x,mins.y,mins.z,maxs.x,maxs.y,maxs.z
    end
    local px,py,pz
    if unpackVector and getPos==nativeGetPos then px,py,pz=unpackVector(pos)
    else px,py,pz=pos.x,pos.y,pos.z end
    local pitch,yaw,roll
    if unpackAngle and angles and getAngles==nativeGetAngles then pitch,yaw,roll=unpackAngle(angles)
    else pitch,yaw,roll=angles and angles.p,angles and angles.y,angles and angles.r end
    local cached = fields._LODVisualBox
    -- Snapshot once per pass; reuse identical geometry/pose across passes.
    -- Scalars observe in-place native vector/angle mutations immediately.
    if not cached or cached.owner ~= snapshotOwner
        or cached.x0 ~= x0 or cached.y0 ~= y0 or cached.z0 ~= z0
        or cached.x1 ~= x1 or cached.y1 ~= y1 or cached.z1 ~= z1
        or cached.px ~= px or cached.py ~= py or cached.pz ~= pz
        or cached.pitch ~= pitch or cached.yaw ~= yaw or cached.roll ~= roll then
        cached = {owner=snapshotOwner,x0=x0,y0=y0,z0=z0,x1=x1,y1=y1,z1=z1,
            px=px,py=py,pz=pz,pitch=pitch,yaw=yaw,roll=roll,
            position=pos,angles=angles,mins=mins,maxs=maxs}
        if angles and angles.Forward and angles.Right and angles.Up then
            local f, r, u = angles:Forward(), angles:Right(), angles:Up()
            local x, y, z = (x0+x1)*0.5,(y0+y1)*0.5,(z0+z1)*0.5
            cached.f, cached.r, cached.u = f, r, u
            cached.fx,cached.fy,cached.fz=f.x,f.y,f.z
            cached.rx,cached.ry,cached.rz=r.x,r.y,r.z
            cached.ux,cached.uy,cached.uz=u.x,u.y,u.z
            cached.axisAligned=cached.fx==1 and cached.fy==0 and cached.fz==0
                and cached.rx==0 and cached.ry==-1 and cached.rz==0
                and cached.ux==0 and cached.uy==0 and cached.uz==1
            cached.cx=px+cached.fx*x-cached.rx*y+cached.ux*z
            cached.cy=py+cached.fy*x-cached.ry*y+cached.uy*z
            cached.cz=pz+cached.fz*x-cached.rz*y+cached.uz*z
            cached.hx, cached.hy, cached.hz = (x1-x0)*0.5,(y1-y0)*0.5,(z1-z0)*0.5
        else
            -- An incomplete angle accessor cannot supply oriented support.
            -- Retain the previous rotation-independent origin sphere for the
            -- conservative rear-plane fallback until native axes are ready.
            local x = math.max(math.abs(x0), math.abs(x1))
            local y = math.max(math.abs(y0), math.abs(y1))
            local z = math.max(math.abs(z0), math.abs(z1))
            cached.radius = math.sqrt(x*x+y*y+z*z) + 1
        end
        fields._LODVisualBox = cached
    end
    return cached
end

local function support(box, p)
    -- The generated unrotated floors/stairs have exact identity axes. Their
    -- support uses the absolute plane coefficients already resolved once for
    -- this view. Arbitrarily rotated boxes retain the same oriented formula.
    -- At most five plane/value pairs in the existing geometry snapshot. A
    -- bounds/pose/refresh change replaces that snapshot; changed view axes or
    -- projection replace these immutable plane identities. No rounded key/TTL.
    if box[p[7]]==p then return box[p[8]] end
    local value
    if box.axisAligned then value=box.hx*p[4]+box.hy*p[5]+box.hz*p[6]
    else
        local x,y,z=p[1],p[2],p[3]
        value=box.hx*math.abs(box.fx*x+box.fy*y+box.fz*z)
            + box.hy*math.abs(box.rx*x+box.ry*y+box.rz*z)
            + box.hz*math.abs(box.ux*x+box.uy*y+box.uz*z)
    end
    box[p[7]],box[p[8]]=p,value
    return value
end
local function evaluateCamera(box, camera)
    if not camera then return true end
    if not box.f then
        local dx, dy, dz = box.px-camera.ex, box.py-camera.ey, box.pz-camera.ez
        return dx*camera.fx+dy*camera.fy+dz*camera.fz >= -box.radius
    end
    local dx, dy, dz = box.cx-camera.ex, box.cy-camera.ey, box.cz-camera.ez
    local depth = dx*camera.fx + dy*camera.fy + dz*camera.fz
    -- A malformed/unavailable view fails open rather than hiding the floor.
    if depth + support(box,camera.front) < -1 then return false end
    if camera.left then
        local side = dx*camera.rx + dy*camera.ry + dz*camera.rz
        local height = dx*camera.ux + dy*camera.uy + dz*camera.uz
        -- Unnormalized inward planes with one world-unit tolerance. A box is
        -- rejected only when its greatest support lies strictly outside a plane.
        if depth*camera.tanX-side+support(box,camera.left) < -camera.normX
            or depth*camera.tanX+side+support(box,camera.right) < -camera.normX
            or depth*camera.tanY-height+support(box,camera.bottom) < -camera.normY
            or depth*camera.tanY+height+support(box,camera.top) < -camera.normY then return false end
    end
    return true
end

local function inCamera(box, camera)
    if not camera then return true end
    -- The same native view can submit this geometry more than once. A box
    -- snapshot is replaced on any live bounds/pose change; the immutable front
    -- plane identity changes with any view axis or projection coefficient.
    -- Only an exact match, including all three current eye scalars, may borrow
    -- the pure frustum result. There is no frame lease, rounded key or draw skip.
    if box.viewPlane == camera.front and box.viewX == camera.ex
        and box.viewY == camera.ey and box.viewZ == camera.ez then
        return box.viewVisible
    end
    local visible = evaluateCamera(box, camera)
    box.viewPlane, box.viewX, box.viewY, box.viewZ, box.viewVisible =
        camera.front, camera.ex, camera.ey, camera.ez, visible
    return visible
end

local function drawGeneratedGeometry(pass)
    local camera = cameraSnapshot()
    -- Resolve the mounted concrete/fallback once per pass, only if needed.
    -- Pass-local ownership is safe for nested RenderView and retries next frame.
    local material
    local function getMaterial()
        if not material then material = floorMaterial() end
        return material
    end
    for ent, record in pairs(visualBoxes) do
        local kind, data = currentKind(ent, record)
        -- Most generated boxes are invisible collision walls. Resolve their
        -- cheap kind before native visibility/bounds/transform work. Native
        -- changes invalidate known kinds; unready/custom accessors still poll.
        if visibleKind(kind) and not nativeRejected(ent, record, data, pass)
            and not ent:GetNW2Bool("LOD_GeometryHidden", false) then
            local box = visualSnapshot(ent, data)
            if inCamera(box, camera) then

                -- Ordinary floor runs render only their top and underside. Their
                -- collision remains a substantial 32-unit slab, but internal
                -- row-run side faces are not visible, eliminating false step/riser
                -- seams across a mathematically flat deck. Stair boxes retain all six
                -- faces because their vertical risers are real geometry.
                if kind == 1 then
                    drawFloorSlab(ent, box, floorColor, getMaterial)
                    if ent:GetNW2String("LOD_EventArchetype", "") == "false_floor" then
                        drawWireframe(box.position, box.angles, box.mins, box.maxs, stairEdgeColor, false)
                    end
                elseif kind == 2 then
                    drawFullMetalBox(ent, box, stairColor, getMaterial)
                    drawWireframe(
                        box.position,
                        box.angles,
                        box.mins,
                        box.maxs,
                        stairEdgeColor,
                        true
                    )
                elseif kind == 5 then
                    -- The continuous level-0 underdeck is deliberately recessed only
                    -- half a unit beneath the ordinary deck. Use the identical material
                    -- and color and draw only broad faces, so any container-base or
                    -- exterior-corner sightline resolves to continuous concrete.
                    drawFloorSlab(ent, box, floorColor, getMaterial)
                end
                -- Kind 7 is the native-hut staging containment boundary. It owns only
                -- server collision and is intentionally invisible on the client.
            end
        end
    end
end

hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function(drawingDepth, drawingSkybox, drawing3DSkybox)
    local pass=currentNativePass()
    if drawingDepth or drawingSkybox or drawing3DSkybox then return end
    if LOD.TexturedBox and LOD.TexturedBox.WithDrawState then
        LOD.TexturedBox:WithDrawState(drawGeneratedGeometry, pass)
    else
        drawGeneratedGeometry(pass)
    end
end)
