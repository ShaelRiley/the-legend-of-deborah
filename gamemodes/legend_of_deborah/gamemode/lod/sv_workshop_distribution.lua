-- Canonical public distribution contract.
-- This is The Legend of Deborah's own Workshop item, not a third-party dependency.
-- Servers mark it for download so a joining player receives the published gamemode
-- package even when the host is running a local/development checkout.

local WORKSHOP_ID = "3791535712"

resource.AddWorkshop(WORKSHOP_ID)

print("[LOD:WORKSHOP] marked canonical Workshop item " .. WORKSHOP_ID .. " for client download")
