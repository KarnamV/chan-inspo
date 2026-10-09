class_name IsoCamera
extends Camera3D
## Orthographic isometric follow camera. Classic iso angles: 45° yaw, ~35.26° pitch.

@export var target_path: NodePath
@export var view_size := 13.0
@export var distance := 30.0
@export var follow_speed := 6.0

var target: Node3D


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = view_size
	rotation = Vector3(deg_to_rad(-35.264), deg_to_rad(45.0), 0.0)
	if target_path:
		target = get_node_or_null(target_path)
	snap()


func snap() -> void:
	if target:
		global_position = _desired()


func _desired() -> Vector3:
	return target.global_position + global_transform.basis.z * distance


func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = global_position.lerp(_desired(), clampf(follow_speed * delta, 0.0, 1.0))


## Converts a 2D input vector (x right, y down) into a world-space move direction on the floor,
## relative to the camera, so "up" on the stick always moves away from the camera.
func input_to_world(v: Vector2) -> Vector3:
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	return (right * v.x - fwd * v.y)
