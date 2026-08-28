include("shared.lua")
include("lod/sh_tetris.lua")
include("lod/cl_textured_box.lua")
include("lod/cl_wall_visuals.lua")
include("lod/cl_container_wayfinding_projection.lua")
include("lod/cl_container_section_recolor.lua")
include("lod/cl_container_marking_panel.lua")
include("lod/cl_debug.lua")
include("lod/cl_hud.lua")
include("lod/cl_tetris.lua")
include("lod/cl_intermission_tetris.lua")
include("lod/cl_victory_celebration.lua")
include("lod/cl_magic_hud.lua")
include("lod/cl_dev_testing.lua")
include("lod/cl_hit_confirm.lua")
include("lod/cl_combat_roll_feed.lua")
include("lod/cl_melee_contact_audit.lua")
include("lod/cl_hostile_damage_audit.lua")
include("lod/cl_minimap.lua")
include("lod/cl_minimap_magic_quadrants.lua")
include("lod/cl_minimap_reliability.lua")
include("lod/cl_minimap_logical_cell.lua")
include("lod/cl_minimap_player_contrast.lua")
include("lod/cl_topology_sync_safety.lua")
include("lod/cl_soldier_shot_contract.lua")
include("lod/cl_player_weapon_specials.lua")
include("lod/cl_magnum_aim_state.lua")
include("lod/cl_watcher.lua")
include("lod/cl_watcher_polish.lua")
include("lod/cl_hostile_presentation_safety.lua")
include("lod/cl_seeker.lua")
include("lod/cl_magic.lua")
include("lod/cl_pushback_fx.lua")

-- Staging-room interaction prompts and instruction-manual navigation are installed
-- here as a late client authority. The scripted manual entity owns its content and
-- presentation; this pass only supplies robust input behavior that GMod's older
-- embedded Chromium does not provide consistently on its own.
surface.CreateFont("LOD_StagingBoundPrompt", {
    font = "DejaVu Sans",
    size = 38,
    weight = 1000,
    antialias = true
})

local function useBindingLabel()
    local binding = input.LookupBinding("+use")
    if not isstring(binding) or binding == "" then binding = "E" end
    binding = string.upper(binding)
    binding = string.gsub(binding, "MOUSE(%d+)", "MOUSE %1")
    binding = string.gsub(binding, "MWHEELUP", "MOUSE WHEEL UP")
    binding = string.gsub(binding, "MWHEELDOWN", "MOUSE WHEEL DOWN")
    return binding
end

local function aimedAtStaging(ply, className, kind, maxDist, minDot)
    if not IsValid(ply) then return nil end
    local eye = ply:EyePos()
    local forward = ply:EyeAngles():Forward()
    local best, bestDot

    for _, ent in ipairs(ents.FindByClass(className)) do
        if IsValid(ent) and (not kind or (ent.GetStageKind and ent:GetStageKind() == kind)) then
            local delta = ent:WorldSpaceCenter() - eye
            local dist2 = delta:LengthSqr()
            if dist2 <= (maxDist * maxDist) and dist2 > 1 then
                delta:Normalize()
                local dot = forward:Dot(delta)
                if dot >= (minDot or 0.94) and (not bestDot or dot > bestDot) then
                    best, bestDot = ent, dot
                end
            end
        end
    end

    return best
end

local function installBoundStagingPrompts()
    hook.Add("HUDPaint", "LOD_FieldManualAndPortalPrompts", function()
        local manual = LOD and LOD.FieldManual
        if manual and IsValid(manual.Frame) then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or ply:GetNW2Bool("LOD_Deployed", false) then return end

        local key = useBindingLabel()
        local text
        if IsValid(aimedAtStaging(ply, "lod_field_manual", nil, 260, 0.94)) then
            text = string.format("Press \"%s\" to Read", key)
        elseif IsValid(aimedAtStaging(ply, "lod_staging_prop", 2, 320, 0.92)) then
            text = string.format("Press \"%s\" to Enter the Labyrinth", key)
        end

        if text then
            draw.SimpleTextOutlined(text, "LOD_StagingBoundPrompt",
                ScrW() * 0.5, ScrH() * 0.64,
                Color(250, 250, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                4, Color(0, 0, 0, 245))
        end
    end)
end

-- Entity scripts may register their original HUD hook after gamemode cl_init. Reuse
-- the same hook identifier so this binding-aware callback becomes the final one.
installBoundStagingPrompts()
timer.Create("LOD_StagingPromptBindingRefresh", 1, 0, installBoundStagingPrompts)

local MANUAL_SCROLL_PATCH = [=[
(function(){
  if(window.LODManualScrollControlsInstalled) return;
  window.LODManualScrollControlsInstalled=true;

  var left=document.getElementById('leftPage');
  var right=document.getElementById('rightPage');
  var reading=document.getElementById('readingView');
  if(!left || !right) return;

  var style=document.createElement('style');
  style.type='text/css';
  style.innerHTML=
    '.page-slot{overflow-y:scroll!important;overflow-x:hidden!important;scrollbar-color:#ffd84a #282a2f!important;}'+
    '.page-slot::-webkit-scrollbar{width:26px!important;background:#282a2f!important;}'+
    '.page-slot::-webkit-scrollbar-track{background:#282a2f!important;border-left:3px solid #ffd84a!important;}'+
    '.page-slot::-webkit-scrollbar-thumb{background:#ffd84a!important;border:4px solid #282a2f!important;border-radius:8px!important;min-height:48px!important;}'+
    '.page-slot::-webkit-scrollbar-thumb:hover{background:#fff1a1!important;}'+
    '.page-slot::-webkit-scrollbar-button{display:block!important;height:22px!important;background:#ffd84a!important;}'+
    '.reading{overflow-y:scroll!important;overflow-x:hidden!important;scrollbar-color:#ffd84a #282a2f!important;}'+
    '.reading::-webkit-scrollbar{width:26px!important;background:#282a2f!important;}'+
    '.reading::-webkit-scrollbar-track{background:#282a2f!important;border-left:3px solid #ffd84a!important;}'+
    '.reading::-webkit-scrollbar-thumb{background:#ffd84a!important;border:4px solid #282a2f!important;border-radius:8px!important;min-height:48px!important;}';
  (document.head || document.documentElement).appendChild(style);

  var activePane=right;
  function readingActive(){
    if(!reading) return false;
    if(reading.classList && reading.classList.contains('active')) return true;
    return (' '+reading.className+' ').indexOf(' active ')>=0;
  }
  function paneVisible(el){
    if(!el) return false;
    var s=window.getComputedStyle?window.getComputedStyle(el):null;
    return !s || (s.display!=='none' && s.visibility!=='hidden');
  }
  function choosePane(){
    if(readingActive()) return reading;
    if(activePane && paneVisible(activePane)) return activePane;
    if(right && paneVisible(right) && right.scrollHeight>right.clientHeight) return right;
    return left || right;
  }
  function clampScroll(el,value){
    if(!el) return;
    var maximum=Math.max(0,el.scrollHeight-el.clientHeight);
    el.scrollTop=Math.max(0,Math.min(maximum,value));
  }
  function scrollByAmount(amount){
    var el=choosePane();
    if(!el) return;
    clampScroll(el,el.scrollTop+amount);
  }
  function pageAmount(direction){
    var el=choosePane();
    if(!el) return;
    var amount=Math.max(160,Math.floor(el.clientHeight*0.84));
    clampScroll(el,el.scrollTop+amount*direction);
  }
  function toEdge(end){
    var el=choosePane();
    if(!el) return;
    clampScroll(el,end?el.scrollHeight:0);
  }
  function setActive(el){ if(el) activePane=el; }

  function bindPane(el){
    if(!el) return;
    el.onmouseenter=function(){setActive(el);};
    el.onmousemove=function(){setActive(el);};
    el.onmousedown=function(){setActive(el);};
    el.addEventListener('wheel',function(e){
      setActive(el);
      var delta=0;
      if(typeof e.deltaY==='number') delta=e.deltaY;
      else if(typeof e.wheelDelta==='number') delta=-e.wheelDelta;
      else if(typeof e.detail==='number') delta=e.detail*40;
      if(delta===0) delta=80;
      clampScroll(el,el.scrollTop+delta);
      if(e.preventDefault) e.preventDefault();
      if(e.stopPropagation) e.stopPropagation();
      return false;
    },false);
    el.onmousewheel=function(e){
      e=e||window.event;
      setActive(el);
      var delta=e.wheelDelta ? -e.wheelDelta : 80;
      clampScroll(el,el.scrollTop+delta);
      if(e.preventDefault) e.preventDefault();
      e.returnValue=false;
      return false;
    };
  }

  bindPane(left);
  bindPane(right);
  bindPane(reading);

  document.addEventListener('keydown',function(e){
    e=e||window.event;
    var key=e.key||'';
    var code=e.keyCode||0;
    var lower=String(key).toLowerCase();
    var handled=true;

    if(key==='ArrowDown' || code===40 || lower==='s') scrollByAmount(72);
    else if(key==='ArrowUp' || code===38 || lower==='w') scrollByAmount(-72);
    else if(key==='PageDown' || code===34) pageAmount(1);
    else if(key==='PageUp' || code===33) pageAmount(-1);
    else if(key==='Home' || code===36) toEdge(false);
    else if(key==='End' || code===35) toEdge(true);
    else handled=false;

    if(handled){
      if(e.preventDefault) e.preventDefault();
      if(e.stopPropagation) e.stopPropagation();
      if(e.stopImmediatePropagation) e.stopImmediatePropagation();
      return false;
    }
    return true;
  },true);

  window.lodManualScroll=function(amount){scrollByAmount(Number(amount)||0);};
  window.lodManualPageScroll=function(direction){pageAmount(Number(direction)||1);};
  window.lodManualScrollHome=function(){toEdge(false);};
  window.lodManualScrollEnd=function(){toEdge(true);};
})();
]=]

local lastPatchedBrowser
local function injectManualScrollControls(browser)
    if not IsValid(browser) then return end
    browser:QueueJavascript(MANUAL_SCROLL_PATCH)
end

hook.Add("Think", "LOD_FieldManualRobustScrollInstaller", function()
    local manual = LOD and LOD.FieldManual
    local browser = manual and manual.Browser
    if not IsValid(browser) then
        lastPatchedBrowser = nil
        return
    end
    if browser == lastPatchedBrowser then return end
    lastPatchedBrowser = browser

    -- SetHTML is asynchronous in DHTML. Queue the idempotent patch several times
    -- across the first half-second so it lands after the booklet DOM exists on both
    -- fast desktops and slower Steam Deck starts.
    timer.Simple(0.08, function() if IsValid(browser) then injectManualScrollControls(browser) end end)
    timer.Simple(0.25, function() if IsValid(browser) then injectManualScrollControls(browser) end end)
    timer.Simple(0.55, function() if IsValid(browser) then injectManualScrollControls(browser) end end)
end)
