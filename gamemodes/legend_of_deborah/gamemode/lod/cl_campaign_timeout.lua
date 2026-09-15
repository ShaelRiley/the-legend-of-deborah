local T=LOD.CampaignTimeout
T.Client=T.Client or {}
local C=T.Client
if C.ResetScene then C.ResetScene() end
local fire=Material("sprites/light_glow02_add")
local smoke=Material("particle/particle_smokegrenade")
surface.CreateFont("LOD_TimeOver",{font="DejaVu Sans",size=64,weight=1000})
surface.CreateFont("LOD_TimeOverPrompt",{font="DejaVu Sans",size=23,weight=800})

function T:IsCinematic() return C.scene~=nil end
function T:Elapsed()
    local s=C.scene
    if not s or s.elapsed<0 then return 0 end
    return math.min(self.Settle,s.elapsed+RealTime()-C.received)
end

-- Guard only this gamemode's presentation callbacks. Keep their registrations
-- and state intact so reset resumes them without re-including any modules.
local guarded={}
local function guardPresentation()
    for _,event in ipairs({"HUDPaint","PostDrawHUD","CalcView","PlayerButtonDown","PlayerBindPress"}) do
        for id,fn in pairs(hook.GetTable()[event] or {}) do
            if isstring(id) and id:sub(1,4)=="LOD_" and not id:find("Timeout",1,true) then
                local wrapper=function(...)
                    if T:IsCinematic() then return end
                    return fn(...)
                end
                hook.Add(event,id,wrapper)
                guarded[#guarded+1]={event=event,id=id,fn=fn,wrapper=wrapper}
            end
        end
    end
end
local function restorePresentation()
    for _,item in ipairs(guarded) do
        if (hook.GetTable()[item.event] or {})[item.id]==item.wrapper then hook.Add(item.event,item.id,item.fn) end
    end
    guarded={}
end

local function resetScene()
    restorePresentation()
    local wall=LOD.WallVisualsClient
    if wall then for i,model in pairs(wall.models or {}) do
        local instance=wall.world[i]
        if IsValid(model) and instance then model:SetPos(instance.pos);model:SetAngles(instance.ang);model.LODTimeoutSettled=nil;model.LODTimeoutEpoch=nil end
    end end
    C.scene=nil;C.startView=nil;C.lastBurst=nil;C.frozenWorld=nil
end

C.ResetScene=resetScene
hook.Add("PostCleanupMap","LOD_TimeoutClientMapCleanup",resetScene)
net.Receive(T.Message,function()
    local epoch=net.ReadUInt(32)
    local started,remaining,failed=net.ReadBool(),net.ReadFloat(),net.ReadBool()
    local hasScene=net.ReadBool()
    local scene
    if hasScene then
        scene={elapsed=net.ReadFloat(),center=net.ReadVector(),radius=net.ReadFloat(),ground=net.ReadFloat(),ready=net.ReadBool()}
    end
    if C.epoch and epoch<C.epoch then return end
    local entering=scene and (not C.scene or epoch~=C.epoch)
    if not scene or epoch~=C.epoch then resetScene() end
    C.epoch=epoch;C.started=started;C.remaining=remaining;C.failed=failed;C.received=RealTime();C.scene=scene
    if entering then
        C.startView=EyePos()
        guardPresentation()
        -- End lingering victory cues/camera and modal menus. No saved character
        -- data is discarded; the server owns the subsequent new campaign.
        if LOD.VictoryCelebrationClient then
            local v=LOD.VictoryCelebrationClient;v.endsAt=0;v.generation=(v.generation or 0)+1
        end
        if LOD.CharacterSheet and LOD.CharacterSheet.Close then LOD.CharacterSheet:Close() end
        if LOD.UI and LOD.UI.SelectPage then LOD.UI:SelectPage(nil) end
        if LOD.FieldManual and IsValid(LOD.FieldManual.Frame) then LOD.FieldManual.Frame:Remove() end
        surface.PlaySound("ambient/alarms/klaxon1.wav")
    end
end)

hook.Add("CalcView","LOD_TimeoutCamera",function(_,origin)
    local s=C.scene
    if not s then return end
    local elapsed=T:Elapsed()
    local target=s.center
    local wide=T:Camera(target,s.radius)
    local fraction=math.Clamp(elapsed/3,0,1)
    fraction=1-(1-fraction)^3
    local from=C.startView or origin
    local pos=LerpVector(fraction,from,wide)
    local angles=(target-pos):Angle()
    if elapsed>4 and elapsed<15 then
        angles.r=math.sin(elapsed*13)*0.25
    end
    return {origin=pos,angles=angles,fov=90,znear=8,zfar=60000,drawviewer=false}
end)
hook.Add("HUDShouldDraw","LOD_TimeoutStockHUD",function()
    if T:IsCinematic() then return false end
end)
hook.Add("PreDrawViewModel","LOD_TimeoutViewModel",function() if T:IsCinematic() then return true end end)
hook.Add("PrePlayerDraw","LOD_TimeoutPlayers",function() if T:IsCinematic() then return true end end)

hook.Add("Think","LOD_TimeoutPresentation",function()
    local s=C.scene
    if not s then return end
    local elapsed=T:Elapsed()
    local wall=LOD.WallVisualsClient
    -- Existing render models remain engine-culled; update transforms at 20 Hz.
    -- After settling, touch only models newly supplied by a late wall manifest.
    if wall and RealTime()>=(C.nextPose or 0) then
        C.nextPose=RealTime()+0.05
        for i,model in pairs(wall.models or {}) do
            local instance=wall.world[i]
            if IsValid(model) and instance and (not model.LODTimeoutSettled or model.LODTimeoutEpoch~=C.epoch) then
                local pos,ang=T:ContainerPose(instance.pos,instance.ang,s.center,s.radius,s.ground,elapsed,i)
                model:SetPos(pos);model:SetAngles(ang)
                model.LODTimeoutEpoch=C.epoch
                model.LODTimeoutSettled=elapsed>=T.Settle
            end
        end
    end
    if elapsed>=4 and elapsed<15 then
        local burst=math.floor((elapsed-4)*3)
        if C.lastBurst~=burst then
            C.lastBurst=burst
            -- A local non-diegetic mix is audible at the distant cinematic camera.
            -- Late clients play the current beat, never a backlog of explosions.
            surface.PlaySound("ambient/explosions/explode_"..tostring(burst%4+1)..".wav")
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables","LOD_TimeoutExplosions",function(depth,sky)
    local s=C.scene
    if not s or depth or sky then return end
    local elapsed=T:Elapsed()
    if elapsed<4 or elapsed>20 then return end
    local reduced=LOD.AdventurePresentation and LOD.AdventurePresentation:Reduced()
    local current=math.floor((elapsed-4)*3)
    -- At most 24 fire/smoke quads, no emitters, lights, or networked blasts.
    for i=math.max(0,current-(reduced and 3 or 7)),math.min(32,current) do
        local age=elapsed-(4+i/3)
        if age>=0 and age<3 then
            local x=((i*37)%101)/100-0.5
            local y=((i*61)%103)/102-0.5
            local pos=s.center+Vector(x*s.radius*1.4,y*s.radius*1.25,200+((i*19)%400))
            local size=(300+age*600)*(reduced and 0.8 or 1)
            render.SetMaterial(fire)
            render.DrawSprite(pos,size,size,Color(255,135+math.floor(age*20),40,math.max(0,255-age*160)))
            render.SetMaterial(smoke)
            local cloud=pos+Vector(0,0,age*180)
            render.DrawSprite(cloud,size*1.2,size*0.8,Color(75,65,70,math.max(0,160-age*50)))
            render.DrawSprite(cloud+Vector(140,60,60),size*0.8,size,Color(120,95,85,math.max(0,120-age*40)))
        end
    end
end)

local nextRestart=0
hook.Add("Think","LOD_TimeoutRestartKey",function()
    if not C.scene or not C.scene.ready then C.useDown=input.IsKeyDown(KEY_E);return end
    local down=input.IsKeyDown(KEY_E)
    if down and not C.useDown and not gui.IsGameUIVisible() and RealTime()>=nextRestart then
        nextRestart=RealTime()+1
        net.Start("LOD_RestartCampaign");net.SendToServer()
    end
    C.useDown=down
end)
hook.Add("HUDPaint","LOD_TimeoutHUD",function()
    local w,h=ScrW(),ScrH()
    if C.scene then
        surface.SetDrawColor(0,0,0,235)
        surface.DrawRect(0,0,w,h*0.105);surface.DrawRect(0,h*0.87,w,h*0.13)
        draw.SimpleTextOutlined("TIME OVER","LOD_TimeOver",w*0.5,h*0.045,Color(255,180,95),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,2,color_black)
        local text=C.scene.ready and "PRESS E TO BEGIN A NEW RUN" or "THE PRISON IS COMING APART"
        draw.SimpleText(text,"LOD_TimeOverPrompt",w*0.5,h*0.93,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        return
    end
    if C.failed or not C.received then return end
    local remaining=C.started and math.max(0,(C.remaining or 1800)-(RealTime()-C.received)) or 1800
    local seconds=math.ceil(remaining)
    local text=C.started and string.format("COLLAPSE  %02d:%02d",math.floor(seconds/60),seconds%60) or "30:00  •  AWAITING FIRST HERO"
    local color=remaining<=60 and Color(255,130,105) or Color(245,215,155)
    -- The objective owns the upper-right band and may wrap toward center. Keep
    -- the campaign clock in its own row beneath the upper-left run/card block.
    draw.SimpleTextOutlined(text,"LOD_TimeOverPrompt",22,72,color,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,1,color_black)
end)
hook.Add("ShutDown","LOD_TimeoutClientCleanup",resetScene)
