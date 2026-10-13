include("shared.lua")

function ENT:Draw()
    render.SuppressEngineLighting(true)
    local ok,err=pcall(self.DrawModel,self)
    render.SuppressEngineLighting(false)
    if not ok then ErrorNoHalt(tostring(err).."\n") end
end
