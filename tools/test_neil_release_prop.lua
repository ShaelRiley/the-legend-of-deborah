local F=dofile('tools/test_floor_map_props.lua')
local root='gamemodes/legend_of_deborah/entities/entities/lod_neil_release_button/'
local noop=function() end
SOLID_VPHYSICS,SIMPLE_USE,COLLISION_GROUP_WEAPON=6,3,11
local failPhysics=false
function F.native:PhysicsInitBox(lo,hi) self.physicsLo,self.physicsHi=lo,hi;self.physicsSolid=SOLID_VPHYSICS end
function F.native:SetParent(owner) self.parent=owner end
F.initializers.prop_dynamic=function() end
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
    assert(e:GetModel()=='models/props_lab/generatorconsole.mdl')
    assert(e.collisionGroup==COLLISION_GROUP_WEAPON,'console blocks Hero passage')
    assert(e.physicsSolid==SOLID_VPHYSICS and e.solid==SOLID_VPHYSICS and e.physics.motion==false)
    assert(e.useType==SIMPLE_USE and e:UpdateTransmitState()==TRANSMIT_ALWAYS)
    local lo,hi=e:GetModelBounds()
    local button=e.LODReleaseButtonProp
    assert(button and button:GetModel()=='models/props_combine/combinebutton.mdl')
    assert(button.parent==e and button.solid==SOLID_NONE and button:GetAngles().p==45)
    assert(button.color.r>button.color.g and button.color.r>button.color.b)
    assert(e:GetPos().z+lo.z==z,'console floor seating')
    local blo,bhi=button:GetModelBounds()
    local mins,maxs=LOD.ProgressionProps:RotatedBounds(blo,bhi,button:GetAngles())
    assert(math.abs(button:GetPos().z+mins.z-e:GetPos().z-hi.z-1)<.001,'button clips console')
    assert(e:GetPos().z+e.physicsHi.z+.001>=button:GetPos().z+maxs.z,'button outside interaction hull')
    for _=1,24 do e:Draw() end
    assert(e.draws==24)
    local prior=sounds;e:Use('denied');assert(sounds==prior)
    e:Use('accepted')
    e:Remove();assert(button.removed,'console retirement orphaned the button')
end
assert(used==6 and sounds==3)
failPhysics=true
local broken=F.make('lod_neil_release_button');broken:SetPos(Vector(0,0,40));broken:Spawn()
assert(broken.removed and broken.LODReleaseButtonProp.removed,'unusable native button accepted')
print('NEIL_RELEASE_PROP_PASS: real Initialize/Use/Draw/cleanup; stock console/red angled button and native hull/use; seating on signed floors; failure rejects console and retires button')
