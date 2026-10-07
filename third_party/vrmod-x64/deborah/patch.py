"""Deterministic, fail-closed idle overlay for the unchanged pinned archive."""
from pathlib import Path

VERSION = "deborah-vr-idle-20261007-r2"
ROOT = Path(__file__).resolve().parent


def replace(text, before, after):
    if text.count(before) != 1:
        raise ValueError("Pinned VRMod idle patch anchor differs")
    return text.replace(before, after, 1)


def apply(upstream):
    files = dict(upstream)
    # Small checksum-error fixtures don't stand in for the real runtime.
    if "lua/vrmod/core/cl_vrmod.lua" not in files:
        return files
    # Source treats lua/weapons/gmod_tool/ as a weapon even in a base-derived
    # gamemode, then requests its absent shared.lua. Deborah has no Sandbox
    # toolgun; retain this optional editor outside the automatic weapon loader.
    optional_tool = "lua/vrmod/optional_sandbox/vrmod_pickup_list.lua"
    files[optional_tool] = files.pop("lua/weapons/gmod_tool/stools/vrmod_pickup_list.lua")
    for name, data in tuple(files.items()):
        if not name.startswith("lua/") or not name.endswith(".lua"):
            continue
        text = data.decode().replace("\r\n", "\n")
        if name == "lua/autorun/vrmod_init.lua":
            prefix = ('vrmod = vrmod or {}\n'
                      'if SERVER then\n'
                      '    AddCSLuaFile("vrmod/lod_idle.lua")\n'
                      '    AddCSLuaFile("vrmod/optional_sandbox/vrmod_pickup_list.lua")\n'
                      'end\n'
                      'include("vrmod/lod_idle.lua")\n')
            text = prefix + 'local hook, timer = vrmod.LODIdle.Hook, vrmod.LODIdle.Timer\n' + text
            text += "\nvrmod.LODIdle:FinishLoad()\n"
        else:
            prefix = ''
            if name.startswith('lua/weapons/') or name == optional_tool:
                # Direct weapon reloads can execute independently of autorun.
                # Both paths share the same singleton and hook registry.
                prefix = ('vrmod = vrmod or {}\nif not vrmod.LODIdle then\n'
                          '    if SERVER then AddCSLuaFile("vrmod/lod_idle.lua") end\n'
                          '    include("vrmod/lod_idle.lua")\nend\n')
            text = prefix + 'local hook, timer = vrmod.LODIdle.Hook, vrmod.LODIdle.Timer\n' + text
        if name == "lua/vrmod/core/cl_vrmod.lua":
            begin = text.index("\tif vrmod.LoadNativeModule then\n")
            end = text.index("\n\t-- 0) Helper functions", begin)
            block = text[begin:end]
            text = text[:begin] + "\tlocal function LoadModuleOnRequest()\n" + block + "\n\tend\n" + text[end:]
            text = replace(text, "\t\tif not PerformStartup() then return end",
                           "\t\tLoadModuleOnRequest()\n\t\tif not PerformStartup() then return end")
            text = replace(text, '\t\t\tvrmod.logger.Info("Ended VR session (full teardown; cold restart OK)")',
                           '\t\t\tvrmod.logger.Info("Ended VR session (full teardown; cold restart OK)")\n'
                           '\t\t\tvrmod.LODIdle:Reconcile()')
            text = replace(text, '\t\t\tworldPortalsPatched = true',
                           '\t\t\tvrmod.LODIdle:Binding(wp, "renderportals", orig, wp.renderportals)\n'
                           '\t\t\tworldPortalsPatched = true')
        elif name == "lua/vrmod/network/sh_network.lua":
            begin = text.index('\thook.Add("CreateMove", "vrutil_hook_joincreatemove"')
            end = text.index('\n\tnet.Receive("vrutil_net_entervehicle"', begin)
            text = text[:begin] + '\t-- Presence/autostart is owned by lod_idle.lua\n' + text[end:]
            text = replace(text, '\t\tif g_VR[steamid] == nil then return end\n\t\tg_VR[steamid] = nil',
                           '\t\tif g_VR[steamid] == nil then return end\n'
                           '\t\tvrmod.LODIdle:ReleaseHeld(steamid)\n\t\tg_VR[steamid] = nil')
            text = replace(text, '\t\tif not IsValid(ply) then\n\t\t\tply = player.GetBySteamID(steamid)\n\t\tend',
                           '\t\tif not IsValid(ply) then\n'
                           '\t\t\tlocal connected = player.GetBySteamID(steamid)\n'
                           '\t\t\tif IsValid(connected) then ply = connected end\n\t\tend')
            text = replace(text, '\thook.Add("PlayerDisconnected", "vrutil_hook_playerdisconnected", function(ply)\n\t\tif not IsValid(ply) then return end\n',
                           '\thook.Add("PlayerDisconnected", "vrutil_hook_playerdisconnected", function(ply)\n')
            text = replace(text, '\t\t\thook.Run("VRMod_Exit", ply)\n\t\tend\n\n\t\tnet.Start("vrutil_net_exit")',
                           '\t\tend\n\t\thook.Run("VRMod_Exit", ply, steamid)\n\n\t\tnet.Start("vrutil_net_exit")')
        elif name == "lua/vrmod/core/sh_startup.lua":
            text = replace(text, '\nend\n\nPatchVRVehicleAim()',
                           '\n    vrmod.LODIdle:Binding(plyMeta, "GetAimVector", _GetAimVector, plyMeta.GetAimVector)\nend\n\nPatchVRVehicleAim()')
            text = replace(text, 'timer.Create("vrmod_start", 0.1, 0, function()',
                           'timer.Create("vrmod_start", 0.1, 1, function()')
            # The explicit command gets one request even before a local session
            # exists. Cursor wait must never become an idle repeating timer.
            text = replace(text, '        timer.Create("vrmod_start", 0.1, 1, function()',
                           '        vrmod.LODIdle.starting = true\n        vrmod.LODIdle:Resume()\n'
                           '        timer.Create("vrmod_start", 0.1, 1, function()')
            text = replace(text, '                VRUtilClientStart()\n            end\n        end)',
                           '                VRUtilClientStart()\n            end\n'
                           '            vrmod.LODIdle.starting = false\n            vrmod.LODIdle:Reconcile()\n        end)')
            text = replace(text, '        if isfunction(VRUtilClientExit) then VRUtilClientExit() end',
                           '        if isfunction(VRUtilClientExit) then VRUtilClientExit() end\n'
                           '        vrmod.LODIdle.starting = false\n        vrmod.LODIdle:Reconcile()')
        elif name == "lua/vrmod/player/sh_pmchange.lua":
            text = replace(text, '\t\tend\n\tend)\nend\n\nif CLIENT then',
                           '\t\tend\n\t\tvrmod.LODIdle:Binding(meta, "SetModel", og, meta.SetModel)\n\tend)\nend\n\nif CLIENT then')
        elif name == "lua/vrmod/physics/sv_collision_proxies.lua":
            text = replace(text, 'local proxyOwners = {}',
                           'local proxyOwners = {}\n'
                           'vrmod.LODIdle.resources.proxies = function()\n'
                           '    local count = 0\n'
                           '    for ent in pairs(proxyOwners) do if IsValid(ent) then count = count + 1 end end\n'
                           '    return {physics_proxies = count}\nend')
            text = replace(text, 'local function RemoveVRProxies(ply)\n    if not IsValid(ply) then return end',
                           'local function RemoveVRProxies(ply)\n    -- Owned proxy cleanup also applies after the player entity becomes invalid.')
            text = replace(text, '        timer.Simple(0, function()\n            if proxies[part]',
                           '        timer.Simple(0, function()\n'
                           '            if not IsValid(ply) or vrProxies[ply] ~= proxies or not vrmod.IsPlayerInVR(ply) then return end\n'
                           '            if proxies[part]')
            text = replace(text, '    vrProxies[ply] = nil\nend',
                           '    vrProxies[ply] = nil\n    lastAppliedWeapon[ply] = nil\nend')
        elif name == "lua/vrmod/utils/sh_pickup.lua":
            text = replace(text, 'local pickupController\n',
                           'local pickupController\n'
                           'if SERVER then\n'
                           '    vrmod.LODIdle.resources.pickup = function()\n'
                           '        return {held_props = pickupCount, motion_controllers = IsValid(pickupController) and 1 or 0}\n'
                           '    end\nend\n')
            text = replace(text, 'timer.Simple(3.0, function() if IsValid(ent) then ent:Remove() end end)',
                           'vrmod.LODIdle:Cleanup(3.0, function() if IsValid(ent) then ent:Remove() end end)')
        elif name == "lua/vrmod/pickup/sh_manualpickup.lua":
            text = replace(text, '\tply:SetNWBool("IsVR", false)',
                           '\tif IsValid(ply) then ply:SetNWBool("IsVR", false) end')
        elif name == "lua/vrmod/ui/cl_panel2vr.lua":
            text = replace(text, '\t-- Refresh dimensions + fonts against VR ScaleSize',
                           '\tvrmod.LODIdle:Binding(StyledTheme, "ScaleSize", styledOrigScaleSize, StyledTheme.ScaleSize)\n'
                           '\tvrmod.LODIdle:Binding(StyledTheme, "BlurPanel", styledOrigBlur, StyledTheme.BlurPanel)\n\n'
                           '\t-- Refresh dimensions + fonts against VR ScaleSize')
            text = replace(text, '\t-- Submenus call child:Open',
                           '\tvrmod.LODIdle:Binding(ct, "Open", oldOpen, ct.Open)\n\t-- Submenus call child:Open')
            text = replace(text, '\n\t-- Spawn: only if nothing bound yet',
                           '\n\tvrmod.LODIdle:Binding(meta, "MakePopup", origMakePopup, meta.MakePopup)\n\n\t-- Spawn: only if nothing bound yet')
        elif name == "lua/vrmod/ui/cl_cube_derma_skin.lua":
            text = replace(text, '\tend\nend\n\n------------------------------------------------------------------------\n-- Hooks — restore on exit only.',
                           '\tend\n\tvrmod.LODIdle:Binding(ct, "Paint", oldPaint, ct.Paint)\nend\n\n------------------------------------------------------------------------\n-- Hooks — restore on exit only.')
        elif name == "lua/vrmod/ui/cl_dermapopups.lua":
            text = replace(text, '\t\tend\n\tend)\nend)',
                           '\t\tend\n\t\tvrmod.LODIdle:Binding(meta, "MakePopup", orig, meta.MakePopup)\n\tend)\nend)')
        elif name == "lua/vrmod/ui/cl_halos.lua":
            text = replace(text, '\n\thook.Remove("PostDrawEffects", "RenderHalos")\n\n\t-- After pickup',
                           '\n\tvrmod.LODIdle:Binding(halo, "Add", stockAdd, halo.Add)\n'
                           '\tvrmod.LODIdle:Binding(halo, "RenderedEntity", stockRendered, halo.RenderedEntity)\n'
                           '\n\thook.Remove("PostDrawEffects", "RenderHalos")\n\n\t-- After pickup')
        files[name] = text.encode()
    files["lua/vrmod/lod_idle.lua"] = (ROOT / "idle.lua").read_bytes()
    return files
