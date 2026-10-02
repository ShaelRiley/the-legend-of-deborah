dofile('tools/test_checkpoint_d_closure.lua')
local ok, errors = LOD.RPG:ValidateCheckpointDAuraBurstFeats()
assert(ok, table.concat(errors or {}, "; "))
assert(LOD.RPG:CheckpointDAuraBurstProfile({featIds = {"CHA_AURA_BURST_1", "CHA_RADIANCE_2"}}) == 2)
-- Current live HUMAN rows retain Radiance/Majesty radii 2/3. Guard all
-- three full same-floor square neighborhoods, including their outer corners.
local owned={}
for rank,id in ipairs({'CHA_AURA_BURST_1','CHA_RADIANCE_2','CHA_MAJESTY_3'}) do
    owned[#owned+1]=id
    local radius=LOD.RPG:CheckpointDAuraBurstProfile({featIds=owned})
    assert(radius==rank,'highest owned Aura rank must replace lower ranks')
    local cells=0
    for x=-4,4 do for y=-4,4 do
        if LOD.RPG:CheckpointDCellRadiusIncludes({x=0,y=0,z=0},{x=x,y=y,z=0},radius) then cells=cells+1 end
        assert(not LOD.RPG:CheckpointDCellRadiusIncludes({x=0,y=0,z=0},{x=x,y=y,z=1},radius))
    end end
    assert(cells==(2*rank+1)^2,'Aura Burst/Radiance/Majesty cover 3x3/5x5/7x7')
end
print("Checkpoint D Aura Burst headless PASS")
