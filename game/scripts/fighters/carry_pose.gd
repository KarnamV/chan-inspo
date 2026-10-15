class_name CarryPose
extends SkeletonModifier3D
## Holds a prop up and forward while idling or running, instead of letting it hang from a limp arm
## (the locomotion clips have no carry pose). Aims the arm bones on top of whatever clip is playing;
## the Fighter fades `influence` in while it holds a prop and out while it attacks.

var fighter: Fighter
var style: StringName = &"club"
var _bones := {}


func _ready() -> void:
	var sk := get_skeleton()
	for b in ["RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm"]:
		_bones[b] = sk.find_bone(b)


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or fighter == null:
		return
	var to_sk := sk.global_basis.inverse()
	var fwd := (to_sk * fighter.global_basis.z).normalized()
	var up := (to_sk * Vector3.UP).normalized()
	var right := fwd.cross(up).normalized()
	match style:
		&"long":   # spear-ready: forearm level, pole pointing ahead
			_aim(sk, "RightUpperArm", -up * 0.9 + fwd * 0.25 + right * 0.25)
			_aim(sk, "RightLowerArm", fwd + up * 0.12)
		&"bulky":   # both arms out front, carried like a battering ram
			_aim(sk, "RightUpperArm", -up * 0.75 + fwd * 0.5 + right * 0.15)
			_aim(sk, "RightLowerArm", fwd + up * 0.2 - right * 0.25)
			_aim(sk, "LeftUpperArm", -up * 0.75 + fwd * 0.5 - right * 0.15)
			_aim(sk, "LeftLowerArm", fwd + up * 0.2 + right * 0.25)
		_:   # club / small: cocked at the hip, ready to swing
			_aim(sk, "RightUpperArm", -up * 0.85 + fwd * 0.3 + right * 0.3)
			_aim(sk, "RightLowerArm", fwd * 0.7 + up * 0.6 + right * 0.15)


## Rotates a bone (and so its children) so its +Y axis points along `dir` (skeleton space).
func _aim(sk: Skeleton3D, bone: String, dir: Vector3) -> void:
	var i: int = _bones.get(bone, -1)
	if i < 0:
		return
	var g := sk.get_bone_global_pose(i)
	var cur := g.basis.y.normalized()
	var to := dir.normalized()
	if cur.dot(to) > 0.9999:
		return
	g.basis = Basis(Quaternion(cur, to)) * g.basis
	sk.set_bone_global_pose(i, g)
