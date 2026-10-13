include("shared.lua")
local PC,MC=LOD.Config.Progression,LOD.Config.Maze
LOD.ClientKeycards=LOD.ClientKeycards or setmetatable({}, {__mode="k"})
LOD.ProgressionRenderStats=LOD.ProgressionRenderStats or {}
-- Remove the old hook-based body renderer on Lua refresh.
hook.Remove("PostDrawOpaqueRenderables","LOD_DrawKeycards")
hook.Remove("PostDrawTranslucentRenderables","LOD_DrawKeycardLabels")
function ENT:Initialize()
    LOD.ClientKeycards[self]=true
    LOD.ProgressionProps:RefreshBounds(self)
end
function ENT:OnRemove(fullUpdate)
    if not fullUpdate then LOD.ClientKeycards[self]=nil end
end
hook.Add("NotifyShouldTransmit","LOD_Recover_lod_keycard",function(ent,transmitting)
    if transmitting and IsValid(ent) and ent:GetClass()=="lod_keycard" then
        LOD.ClientKeycards[ent]=true;LOD.ProgressionProps:RefreshBounds(ent)
    end
end)
function ENT:Draw() LOD.ProgressionProps:Draw(self) end
function ENT:DrawTranslucent()
    if not self.GetCardIndex then return end
    local anchor=self:GetPickupPosition()
    if anchor:DistToSqr(EyePos())>(MC.CellSize*4)^2 then return end
    local card=PC.Cards[math.Clamp(self:GetCardIndex(),1,4)]
    local pos=anchor+Vector(0,0,44)
    cam.Start3D2D(pos,LOD.ProgressionProps:LabelFacing(pos),.12)
        draw.RoundedBox(4,-130,-30,260,60,Color(16,18,20,230))
        draw.SimpleText(card.name.." KEYCARD","DermaLarge",0,-8,card.color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        draw.SimpleText(card.letter.." / "..card.symbol,"DermaDefaultBold",0,18,Color(245,245,245),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
