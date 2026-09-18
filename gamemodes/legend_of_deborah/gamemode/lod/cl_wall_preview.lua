LOD.WallPreview=LOD.WallPreview or {}
local P=LOD.WallPreview
local material=Material('models/debug/debugwhite')
local angle=Angle(0,0,0)
local labels={ready='WALL — RMB TO CAST',ground='WALL — AIM AT NEARBY GROUND',
    space='WALL — NOT ENOUGH SPACE',narrow='WALL — GAP TOO NARROW',ceiling='WALL — CEILING TOO LOW',
    blocked='WALL — SOLID COVER',magic='WALL — NEED MAGIC',cap='WALL — ONE ALREADY ACTIVE',
    cooldown='WALL — COOLDOWN',status='WALL — STATUS PREVENTS CASTING',throwable='WALL — STOW THROWABLE',
    staging='WALL — ENTER THE MAZE TO CAST'}
net.Receive('LOD_WallPreview',function()
    if not net.ReadBool() then P.Record=nil;return end
    local record={ready=net.ReadBool(),reason=net.ReadString(),expires=RealTime()+.8}
    if net.ReadBool() then record.origin=net.ReadVector();record.mins=net.ReadVector();record.maxs=net.ReadVector() end
    P.Record=record
end)
function P:Current()
    local r=self.Record
    if not r or RealTime()>r.expires then self.Record=nil;return end
    local ply=LocalPlayer()
    local book=LOD.Spellbook and LOD.Spellbook.Snapshot
    if not IsValid(ply) or not ply:Alive() or ply:GetNW2Bool('LOD_IsSoldier',false)
        or book and book.selectedFormId~='wall' or LOD.UI.ActivePage then return end
    return r
end
local function color(r,alpha)
    return r.ready and Color(120,210,255,alpha) or Color(255,125,95,alpha)
end
hook.Add('PostDrawTranslucentRenderables','LOD_WallPlacementGhost',function(depth,sky)
    if depth or sky then return end
    local r=P:Current();if not r or not r.origin then return end
    render.SetMaterial(material)
    render.DrawBox(r.origin,angle,r.mins,r.maxs,color(r,36),false)
    render.DrawWireframeBox(r.origin,angle,r.mins,r.maxs,color(r,230),false)
end)
hook.Add('HUDPaint','LOD_WallPlacementHint',function()
    local r=P:Current();if not r then return end
    LOD.UI:HUDText(labels[r.reason] or labels.space,'LOD_SheetKey',ScrW()*.5,ScrH()*.58,color(r,255),TEXT_ALIGN_CENTER)
end)
hook.Add('PreCleanupMap','LOD_WallPreviewCleanup',function() P.Record=nil end)
hook.Add('ShutDown','LOD_WallPreviewShutdown',function() P.Record=nil end)
