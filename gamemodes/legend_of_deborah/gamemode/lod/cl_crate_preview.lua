LOD = LOD or {}
local C,GC=LOD.CrateVisuals,LOD.Config.Geometry
local frame
local colors={
    {"White / untinted",Color(255,255,255)}, {"Red",Color(220,48,43)},
    {"Blue",Color(45,85,225)}, {"Yellow",Color(232,204,45)},
    {"Green",Color(62,185,75)}, {"Orange",Color(225,122,45)},
    {"Purple",Color(155,65,205)}, {"Cyan",Color(40,198,204)},
    {"Dark gray",Color(65,65,65)}, {"Earth",Color(138,123,80)}
}
local previewHull
local function hullMaterial()
    previewHull=previewHull or CreateMaterial("lod_crate_c1_preview_hull","VertexLitGeneric",{
        ["$basetexture"]="metal/metalwall001a",
        ["$bumpmap"]="models/props_wasteland/cargo_container01_normal",
        ["$model"]="1",["$blendtintbybasealpha"]="0",["$blendtintcoloroverbase"]="0.68"})
    return previewHull
end

concommand.Add("lod_crate_preview",function()
    if IsValid(frame) then frame:Remove() end
    frame=vgui.Create("DFrame")
    frame:SetSize(math.min(1060,ScrW()-40),math.min(780,ScrH()-40))
    frame:Center();frame:SetTitle("Great Crate — C2 hull candidate / native inspection");frame:MakePopup()
    local note=vgui.Create("DLabel",frame);note:Dock(TOP);note:SetTall(44);note:SetWrap(true)
    note:SetText("Drag to orbit; wheel to zoom. Gold outline is the safe area. C2 candidate is selected here only; compare with fallback. Native acceptance is pending. Grates retain solid collision and cover in the maze.")
    local controls=vgui.Create("DPanel",frame);controls:Dock(TOP);controls:SetTall(30)
    local brands=vgui.Create("DComboBox",controls);brands:Dock(LEFT);brands:SetWide(400)
    local selected=0
    brands:AddChoice("Unbranded",0)
    for id=1,256 do brands:AddChoice(string.format("%03d — %s",id,LOD.CrateBrandMetadata[id].name),id) end
    brands:SetValue("Unbranded — inspect repaired hull first")
    local brandMaterial=nil
    brands.OnSelect=function(_,_,_,id) selected=id;brandMaterial=id>0 and LOD.CrateBranding.MaterialFor(id,"preview") or nil end
    local tints=vgui.Create("DComboBox",controls);tints:Dock(LEFT);tints:SetWide(160)
    for i,row in ipairs(colors) do tints:AddChoice(row[1],i) end
    tints:SetValue(colors[1][1])
    LOD.CrateHull.PreviewInspected=true
    local candidate=true
    local hull=Material(LOD.CrateHull.PreviewMaterial)
    local tint=Vector(1,1,1)
    hull:SetVector("$color2",tint)
    tints.OnSelect=function(_,_,_,i)
        local c=colors[i][2];tint=Vector(c.r/255,c.g/255,c.b/255);hull:SetVector("$color2",tint)
    end
    local hullChoice=vgui.Create("DCheckBoxLabel",controls);hullChoice:Dock(LEFT);hullChoice:SetWide(140)
    hullChoice:SetText("C2 hull candidate");hullChoice:SetValue(1)
    hullChoice.OnChange=function(_,value)
        candidate=value
        hull=value and Material(LOD.CrateHull.PreviewMaterial) or hullMaterial()
        hull:SetVector("$color2",tint)
    end
    local outlines=vgui.Create("DCheckBoxLabel",controls);outlines:Dock(LEFT);outlines:SetWide(140)
    outlines:SetText("Safe-area outline");outlines:SetValue(1)
    local panel=vgui.Create("DModelPanel",frame);panel:Dock(FILL);panel:SetModel(GC.ContainerModel)
    panel:SetFOV(48);panel:SetAmbientLight(Color(85,85,85));panel:SetDirectionalLight(BOX_TOP,Color(230,230,230))
    local yaw,pitch,distance,lastX,lastY=25,18,640
    panel.LayoutEntity=function(self,ent)
        ent:SetAngles(angle_zero);ent:SetMaterial(candidate and LOD.CrateHull.PreviewMaterial or "!lod_crate_c1_preview_hull")
        if self:IsHovered() and input.IsMouseDown(MOUSE_LEFT) then
            local x,y=gui.MousePos()
            if lastX then yaw=yaw+(x-lastX)*0.5;pitch=math.Clamp(pitch+(y-lastY)*0.4,-25,65) end
            lastX,lastY=x,y
        else lastX,lastY=nil,nil end
        local angle=Angle(pitch,yaw,0)
        self:SetLookAt(Vector(0,0,0));self:SetCamPos(-angle:Forward()*distance)
    end
    panel.OnMouseWheeled=function(_,delta) distance=math.Clamp(distance-delta*40,280,1000) end
    panel.PostDrawModel=function(self,ent)
        local mins=ent:GetRenderBounds()
        if selected>0 then LOD.CrateBranding.Draw(ent,selected,brandMaterial,self:GetCamPos(),outlines:GetChecked()) end
        local z=mins.z
        -- Adjacent slab samples exercise the production world-planar renderer.
        local material=LOD.TexturedBox:GetIndustrialMaterial()
        LOD.TexturedBox:DrawSlab(Vector(0,-260,z-16),angle_zero,Vector(-192,-128,-16),Vector(192,128,16),material,GC.FloorColor,GC.FloorTextureTile)
        LOD.TexturedBox:DrawGrate(Vector(0,0,z-16),angle_zero,Vector(-192,128,-16),Vector(192,256,16))
    end
end)
hook.Add("ShutDown","LOD_CratePreview",function() if IsValid(frame) then frame:Remove() end end)

local lastSummaryWorld
local function summary()
    local wall=LOD.WallVisualsClient or {}
    local material,fallback=LOD.TexturedBox:GetIndustrialMaterial()
    local grates=0
    for _,e in ipairs(ents.FindByClass("lod_static_box")) do
        if e:GetNW2Bool("LOD_CrateGrate",false) then grates=grates+1 end
    end
    local info={model=GC.ContainerModel,hull=LOD.CrateHull.CandidateEnabled() and LOD.CrateHull.Texture or "metal/metalwall001a",
        hullRepair="c2-candidate-native-acceptance-pending",
        candidateEnabled=LOD.CrateHull.CandidateEnabled(),candidateSamplerValid="not-requested",
        normal="models/props_wasteland/cargo_container01_normal",floor=GC.FloorMaterial,
        floorFallback=fallback,floorStyle=C.FloorStyle,
        grates=grates,grateStyle=C.GrateStyle,brand=LOD.CrateBranding.Summary(),seed=wall.seed,
        clientFrameMilliseconds=FrameTime()*1000,meshCache=LOD.TexturedBox:MeshCacheCount()}
    if LOD.CrateHull.CandidateEnabled() or LOD.CrateHull.PreviewInspected then
        info.candidateSamplerValid=LOD.CrateHull.CandidateAvailable()
    end
    for index,m in pairs(wall.models or {}) do
        if IsValid(m) then
            info.stockSlots=m:GetMaterials();info.override=m:GetMaterial()
            info.candidateFallback=wall.world[index] and wall.world[index].hullCandidateFallback or false
            local mat=Material(info.override)
            info.shader=mat:GetShader();info.materialError=mat:IsError()
            local tex=mat:GetTexture("$basetexture")
            info.sampler=tex and tex:GetName() or "missing"
            info.tint=wall.world[index] and wall.world[index].sectionColor or m:GetColor()
            break
        end
    end
    print("[LOD:CRATE-SUMMARY] "..util.TableToJSON(info))
end
concommand.Add("lod_crate_status",summary)
hook.Add("Think","LOD_CrateSummary",function()
    local w=LOD.WallVisualsClient
    if not w or #w.world==0 or w.world==lastSummaryWorld or (w.nextModel or 1)<=#w.world then return end
    if #(w.retryQueue or {})>0 then return end
    lastSummaryWorld=w.world;summary()
end)

-- Focused read-only recovery of mounted *stock* model/material dependencies.
-- No remote access, upload or game mutation. Source restricts DATA extensions,
-- so retain bytes as .dat with exact original paths in the manifest.
concommand.Add("lod_crate_export_sources",function()
    local model=ClientsideModel(GC.ContainerModel,RENDERGROUP_OPAQUE)
    if not IsValid(model) then print("[LOD:CRATE-EXPORT] canonical model unavailable");return end
    model:SetNoDraw(true)
    local dir="legend_of_deborah/crate_sources"
    file.CreateDir(dir)
    local report={model=GC.ContainerModel,slots=model:GetMaterials(),files={},missing={},bytes=0}
    local seen={}
    local function copy(path)
        path=string.lower(path)
        if seen[path] then return end;seen[path]=true
        local data=file.Read(path,"GAME")
        if not data or #data>8*1024*1024 or report.bytes+#data>32*1024*1024 then
            report.missing[#report.missing+1]=path;return
        end
        local name=path:gsub("[^%w_.-]","_")..".dat"
        file.Write(dir.."/"..name,data)
        report.files[#report.files+1]={source=path,file=name,bytes=#data,crc=util.CRC(data)}
        report.bytes=report.bytes+#data
    end
    local stem=GC.ContainerModel:gsub("%.mdl$","")
    for _,suffix in ipairs({".mdl",".vvd",".dx90.vtx",".phy"}) do copy(stem..suffix) end
    for _,name in ipairs(report.slots or {}) do
        copy("materials/"..name..".vmt")
        local material=Material(name)
        for _,key in ipairs({"$basetexture","$bumpmap","$detail","$envmapmask","$selfillummask","$phongexponenttexture"}) do
            local path=material:GetString(key)
            if path and path~="" and not path:find("[<>]") then copy("materials/"..path..".vtf") end
        end
    end
    model:Remove()
    file.Write(dir.."/manifest.json",util.TableToJSON(report,true))
    print("[LOD:CRATE-EXPORT] files="..#report.files.." bytes="..report.bytes.." missing="..#report.missing.." directory=data/"..dir)
end)
