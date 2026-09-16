-- Compatibility cleanup for clients refreshing from the former overlay.
-- cl_minimap.lua owns both the blue marker and its topology-space transform.
hook.Remove("PostDrawHUD", "LOD_MinimapComplementaryPlayerMarker")
LOD.MinimapPlayerContrast = nil
concommand.Add("lod_minimap_player_color_status", function()
    print("[LOD:MINIMAP-PLAYER] rgb=72,132,255 renderer=LOD_MinimapHUD duplicateOverlay=false")
end)
