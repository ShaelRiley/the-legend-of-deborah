LOD = LOD or {}
LOD.DebugGraph = LOD.DebugGraph or {edges = {}, expires = 0}

net.Receive("LOD_DebugGraphBegin", function()
    LOD.DebugGraph.edges = {}
    LOD.DebugGraph.expires = CurTime() + 30
end)

net.Receive("LOD_DebugGraphEdge", function()
    LOD.DebugGraph.edges[#LOD.DebugGraph.edges + 1] = {
        a = net.ReadVector(),
        b = net.ReadVector(),
        vertical = net.ReadBool()
    }
end)

net.Receive("LOD_DebugGraphEnd", function()
    LOD.DebugGraph.expires = CurTime() + 30
end)

hook.Add("PostDrawTranslucentRenderables", "LOD_DebugGraphRender", function()
    if CurTime() > (LOD.DebugGraph.expires or 0) then return end
    for _, edge in ipairs(LOD.DebugGraph.edges or {}) do
        render.DrawLine(
            edge.a,
            edge.b,
            edge.vertical and Color(255, 190, 55) or Color(80, 190, 255),
            false
        )
    end
end)
