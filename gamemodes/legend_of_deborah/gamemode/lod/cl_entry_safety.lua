-- The sanctuary is intentionally invisible. Protection remains spatial and
-- bilateral on the server; attempted combat reports through the Die Logger.
-- Remove old hooks during Lua refresh as well as on a fresh connection.
hook.Remove("PostDrawTranslucentRenderables","LOD_EntrySanctuaryBoundary")
hook.Remove("HUDPaint","LOD_EntrySanctuaryCaption")
