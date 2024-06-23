extends MeshInstance3D

# script by thomason1005 to create tire marks on a vehiclewheel
# this is meant to be attached to a MeshInstance3D which is not a child of the VehicleBody, so in global space.
# the mesh can be left empty, as it will be overriden each frame
# one of these is needed for each wheel, apply any material you want to it

@export var target:VehicleWheel3D # the tire we are making tire marks for
@export var skidLimit:float = .7 # the limit at which we start creating tire marks

var vertices = PackedVector3Array()
#var UVs = PackedVector2Array()
var max_length = 3*100 # should be a multiple of 6, as we write 6 each frame
var i = 0 # this is used to loop through the vertices array
var min_dist = .5 # after this distance, we will create new vertices
var width = .2 # width of the tire track

var arrays = []

# remember where we did the last traingles, so we can connect to them
var lastStart = Vector3.ZERO
var oldPos = Vector3.ZERO
var oldPosA = Vector3.ZERO
var oldPosB = Vector3.ZERO

var hasGap = false # if the tire track has been interrupted

func _ready():
	# initialize things
	vertices.resize(max_length)
	arrays.resize(Mesh.ARRAY_MAX)
	
func _process(delta):
	var pos = (target.global_position - global_position) - Vector3(0,.25,0)
	#make our second corner perpendicular to the last direction
	var tangent:Vector3 = ((pos-oldPos).cross(Vector3.UP)).normalized()*width
	var posB = pos-tangent*.5
	var posA = pos+tangent*.5
	
	var skidding = target.is_in_contact() and target.get_skidinfo() < skidLimit #or use target.wheel_friction_slip
	
	# make a new tire mark if we are above the threshold distance
	if (pos-lastStart).length() > min_dist:
		#only make skidmarks if wheels are below treshold
		if skidding:
			if i >= max_length-6:
				i = 0
			vertices[i+0] = oldPosB
			vertices[i+1] = posA
			vertices[i+2] = oldPosA
			vertices[i+3] = oldPosB
			vertices[i+4] = posB
			vertices[i+5] = posA
			i+=6
			
		#always progress location, even when not skidding
		lastStart = pos
		oldPos = pos
		oldPosA = posA
		oldPosB = posB
		
		hasGap = not skidding
	# extend the old tire mark if we are below the treshold
	else:
		if skidding and not hasGap:
			
			var lastI = (i-6)
			if lastI < 0:
				lastI += max_length
			#update our last position with the new coords
			vertices[lastI+1] = posA
			vertices[lastI+4] = posB
			vertices[lastI+5] = posA
			oldPosA = posA
			oldPosB = posB
			
		
	
	arrays[Mesh.ARRAY_VERTEX] = vertices

	# Create the Mesh.
	# this is done each frame, maybe there is a better option to only update the positions?
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = arr_mesh
