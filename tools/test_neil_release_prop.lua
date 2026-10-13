local F=dofile('tools/test_floor_map_props.lua')
local root='gamemodes/legend_of_deborah/entities/entities/lod_neil_release_button/'
local noop=function() end
SOLID_VPHYSICS,SIMPLE_USE=6,3
local failPhysics=false
function F.native:PhysicsInit(solid) self.physicsSolid=solid end
function F.native:GetPhysicsObject()
    if failPhysics then return nil end
    self.physics=self.physics or {EnableMotion=function(p,value) p.motion=value end}
    return self.physics
end
function F.native:SetUseType(value) self.useType=value end
ENT={};include=function(leaf) dofile(root..leaf) end
dofile(root..'init.lua');F.classes.lod_neil_release_button=ENT
F.initializers.lod_neil_release_button=ENT.Initialize
render={SuppressEngineLighting=noop};ErrorNoHalt=error
dofile(root..'cl_init.lua')
local used,sounds=0,0
sound={Play=function() sounds=sounds+1 end}
LOD.NeilBrute={Release=function(_,player,button) used=used+1;return player=='accepted' end}
for _,z in ipairs({-12286,0,8192}) do
    local e=F.make('lod_neil_release_button');e:SetPos(Vector(100,200,z+40));e:Spawn()
    assert(e:GetPickupPosition().x==172 and e:GetPickupPosition().y==272,'control occupies the cell-center spawn')
    assert(e:GetModel()=='models/props_lab/reciever01b.mdl')
    assert(e.physicsSolid==SOLID_VPHYSICS and e.solid==SOLID_VPHYSICS and e.physics.motion==false)
    assert(e.useType==SIMPLE_USE and e:UpdateTransmitState()==TRANSMIT_ALWAYS)
    local lo,hi=e:GetModelBounds();local mins=LOD.ProgressionProps:RotatedBounds(lo,hi,e:GetAngles())
    local block=e.LODProgressionPedestal
    assert(e:GetPos().z+mins.z==block:GetPos().z+block:OBBMaxs().z+2)
    assert(block:GetPos().z+block.lo.z==z)
    for _=1,24 do e:Draw() end
    assert(e.draws==24)
    local prior=sounds;e:Use('denied');assert(sounds==prior)
    e:Use('accepted')
    e:Remove();assert(block.removed,'button retirement orphaned the pedestal')
end
assert(used==6 and sounds==3)
failPhysics=true
local broken=F.make('lod_neil_release_button');broken:SetPos(Vector(0,0,40));broken:Spawn()
assert(broken.removed and broken.LODProgressionPedestal.removed,'unusable native button accepted')
print('NEIL_RELEASE_PROP_PASS: real Initialize/Use/Draw/cleanup; stock body and native physics/use; seating on signed floors; failure rejects body and retires pedestal')
