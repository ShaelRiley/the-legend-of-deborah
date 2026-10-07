local O,UI=LOD.PlayerOptions,LOD.UI
function O:Close()
    if IsValid(self.Frame) then self.Frame:Remove() end
    self.Frame=nil
    if UI.ActivePage=="options" then UI.ActivePage=nil end
end
function O:Open()
    if UI:IsMinigameLocked() then return end
    UI:SelectPage("options");self:Close();UI.ActivePage="options"
    local f=vgui.Create("DFrame");self.Frame=f
    f:SetSize(math.min(980,ScrW()-32),math.min(620,ScrH()-32));f:Center();f:SetTitle("");f:MakePopup()
    f.Paint=function(_,w,h) UI:Paper(0,0,w,h) end
    f.OnRemove=function() if O.Frame==f then O.Frame=nil;if UI.ActivePage=="options" then UI.ActivePage=nil end end end
    UI:CloseButton(f,function() self:Close() end);UI:PageLinks(f,"options",70)
    local title=vgui.Create("DLabel",f);title:SetPos(28,24);title:SetSize(f:GetWide()-56,26)
    title:SetFont("LOD_SheetTitle");title:SetTextColor(UI.Colors.ink);title:SetText("OPTIONS")
    local scroll=vgui.Create("DScrollPanel",f);scroll:SetPos(24,112);scroll:SetSize(f:GetWide()-48,f:GetTall()-136)
    local content=vgui.Create("DPanel",scroll);content:SetSize(scroll:GetWide()-20,480);content.Paint=function() end
    local function label(text,y,font)
        local l=vgui.Create("DLabel",content);l:SetPos(4,y);l:SetSize(content:GetWide()-8,26)
        l:SetFont(font or "LOD_SheetBody");l:SetTextColor(UI.Colors.ink);l:SetText(text);return l
    end
    local function slider(text,y,convar,low,high)
        local s=vgui.Create("DNumSlider",content);s:SetPos(4,y);s:SetSize(math.min(550,content:GetWide()-8),32)
        s:SetText(text);s:SetMinMax(low,high);s:SetDecimals(2);s:SetConVar(convar)
        s.Label:SetTextColor(UI.Colors.ink);s.TextArea:SetTextColor(UI.Colors.ink);return s
    end
    label("Audio",0,"LOD_SheetHeading")
    slider("Event cue volume",32,"lod_adventure_volume",0,1)
    local audioNote=label("Ambience and gameplay sounds use Garry's Mod sound settings.",72)
    audioNote:SetWrap(true);audioNote:SetTall(44)
    label("Controls and performance",120,"LOD_SheetHeading")
    local run=vgui.Create("DCheckBoxLabel",content);run:SetPos(6,158)
    local binding=input.LookupBinding("+speed") or "Shift"
    run:SetText("Always Run (hold "..string.upper(binding).." to walk)");run:SetTextColor(UI.Colors.ink);run:SetConVar("lod_always_run");run:SizeToContents()
    local reduced=vgui.Create("DCheckBoxLabel",content);reduced:SetPos(6,190)
    reduced:SetText("Reduced effects (Steam Deck / slower PCs)");reduced:SetTextColor(UI.Colors.ink)
    reduced:SetConVar("lod_reduced_effects");reduced:SizeToContents()
    label("Camera",238,"LOD_SheetHeading")
    local third=vgui.Create("DCheckBoxLabel",content);third:SetPos(6,274)
    third:SetText("Third-person camera");third:SetTextColor(UI.Colors.ink);third:SetConVar("lod_third_person");third:SizeToContents()
    label("Map",322,"LOD_SheetHeading")
    slider("Map size (0.5x - 1.5x)",354,"lod_map_scale",0.5,1.5)
    slider("Map opacity",394,"lod_map_opacity",0,1)
    local saved=label("Changes apply immediately. Your options are saved automatically.",436)
    saved:SetWrap(true);saved:SetTall(44)
end

-- Extend the native base view AFTER its vehicle/drive/player/weapon pipeline.
-- CalcView hooks for VR and authored cinematics retain their ordinary precedence.
function O:ThirdPersonView(ply,view)
    if not self.ThirdPerson:GetBool() or not view or view.drawviewer
        or not IsValid(ply) or not ply:Alive() or ply:InVehicle()
        or ply:GetObserverMode()~=OBS_MODE_NONE or ply:GetViewEntity()~=ply
        or LOD.VR and LOD.VR:IsActive(ply)
        or LOD.CampaignTimeout and LOD.CampaignTimeout:IsCinematic() then return view end
    local celebration=LOD.VictoryCelebrationClient
    if celebration and (celebration.finale or celebration.endsAt and CurTime()<celebration.endsAt) then return view end
    -- Retain the existing celebration camera's placement and hull dimensions.
    -- Allocate the fixed native vectors only on first use, never while disabled.
    if not self.CameraHull then
        self.CameraHull={mins=Vector(-6,-6,-6),maxs=Vector(6,6,6),lift=Vector(0,0,34)}
    end
    local origin,angles=view.origin,view.angles
    local hull=self.CameraHull
    local tr=util.TraceHull({start=origin,endpos=origin-angles:Forward()*118+hull.lift,
        mins=hull.mins,maxs=hull.maxs,mask=MASK_SOLID,filter=ply})
    if tr.StartSolid or tr.AllSolid then return view end
    view.origin=tr.HitPos
    view.drawviewer=true
    return view
end

function GM:CalcView(ply,origin,angles,fov,znear,zfar)
    return O:ThirdPersonView(ply,self.BaseClass.CalcView(self,ply,origin,angles,fov,znear,zfar))
end
