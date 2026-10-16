class_name Prop
extends RigidBody3D
## A breakable prop. FREE on the floor -> HELD in a fighter's hand -> swung (wears it down) or
## THROWN (damages whatever it hits). At 0 durability it degrades into `data.pieces`.

enum Mode { FREE, HELD, THROWN, BROKEN }

const LIGHT_MASS := 3.0
const HEAVY_MASS := 14.0

@export var data: PropData

var mode: Mode = Mode.FREE
var durability := 0
var thrower: Node = null
var fire_burst := false   ## dropped lantern: bursts into fire where it lands
var ignited := 0.0        ## Dragon: seconds left burning (fire element + magic damage)
var _fire_light: OmniLight3D
var animator: Fighter     ## Rat: the fighter this prop now fights for
var anim_life := 0.0
var bonus_applied := false
var _hop_t := 0.0
var _rat_light: OmniLight3D
var hurtbox: Hurtbox
var _visual: Node3D
var _shape := CollisionShape3D.new()
var _size := Vector3.ONE * 0.5
var _aabb := AABB()


func _ready() -> void:
	add_to_group(&"props")
	durability = data.durability
	mass = HEAVY_MASS if data.weight == PropData.Weight.HEAVY else LIGHT_MASS
	collision_layer = 1 << 3
	collision_mask = 1 | (1 << 3)          # world + other props
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	body_entered.connect(_on_body_entered)
	if data.model:
		_visual = data.model.instantiate()
		add_child(_visual)
		_size = _measure(_visual)
	var box := BoxShape3D.new()
	box.size = _size
	_shape.shape = box
	_shape.position = Vector3(0, _size.y * 0.5, 0)
	add_child(_shape)
	# loose props can be hit: smack a barrel and it flies into whoever is in the way
	hurtbox = Hurtbox.new()
	var hb_shape := BoxShape3D.new()
	hb_shape.size = _size * 1.1
	hurtbox.setup(self, FixedProp.NEUTRAL_TEAM, hb_shape, _shape.position)
	add_child(hurtbox)
	# long thin props (poles, spears, planks) spawn lying down instead of balancing upright
	if _size.y > 1.8 * maxf(_size.x, _size.z):
		rotate_object_local(Vector3.RIGHT, PI / 2.0)
		position.y += maxf(_size.x, _size.z) * 0.5 + 0.05


## The model's bounds in the prop's own space (cached).
func local_aabb() -> AABB:
	if _aabb.size == Vector3.ZERO:
		_aabb = AABB(Vector3(-_size.x * 0.5, 0, -_size.z * 0.5), _size)
		if _visual:
			var first := true
			for n in _visual.find_children("*", "MeshInstance3D", true, false):
				var mi := n as MeshInstance3D
				var b := (_visual.transform * mi.transform) * mi.get_aabb()
				_aabb = b if first else _aabb.merge(b)
				first = false
	return _aabb


## Unit local axis along the prop's longest side, pointing from its origin end to its far end.
func long_axis() -> Vector3:
	var b := local_aabb()
	var ax := Vector3.ZERO
	ax[b.size.max_axis_index()] = 1.0
	return ax if ax.dot(b.get_center()) >= 0.0 else -ax


static func _measure(root: Node3D) -> Vector3:
	var aabb := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b := mi.transform * mi.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	return aabb.size.max(Vector3.ONE * 0.08) if not first else Vector3.ONE * 0.5


## Where loose props and pieces live: the node in group "level_root", else the current scene.
func _level() -> Node:
	var r := get_tree().get_first_node_in_group(&"level_root")
	if r:
		return r
	return get_tree().current_scene if get_tree().current_scene else get_tree().root


## Rat: bring this prop to life; it hops at demons for `life` seconds.
func animate(owner_f: Fighter, life: float) -> void:
	animator = owner_f
	anim_life = life
	_hop_t = 0.3
	if _rat_light == null:
		_rat_light = OmniLight3D.new()
		_rat_light.light_color = Color(0.4, 1.0, 0.5)
		_rat_light.light_energy = 1.2
		_rat_light.omni_range = 2.0
		_rat_light.position = Vector3(0, _size.y, 0)
		add_child(_rat_light)
	Events.prop_animated.emit(self)


func _physics_process(delta: float) -> void:
	if animator == null:
		return
	anim_life -= delta
	if anim_life <= 0.0 or not is_instance_valid(animator) or mode == Mode.HELD:
		animator = null
		if _rat_light:
			_rat_light.queue_free()
			_rat_light = null
		return
	_hop_t -= delta
	if _hop_t > 0.0 or linear_velocity.length() > 1.5:
		return
	_hop_t = 1.6 if data.weight == PropData.Weight.HEAVY else 1.0
	var best: Fighter = null
	var bd := 10.0
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var f := n as Fighter
		if f and f.team != animator.team and not f.is_dead() and global_position.distance_to(f.global_position) < bd:
			bd = global_position.distance_to(f.global_position)
			best = f
	if best == null:
		return
	var to := (best.global_position + Vector3.UP * 0.8) - global_position
	var speed := 7.0 if data.weight == PropData.Weight.HEAVY else 10.0
	mode = Mode.THROWN
	thrower = animator
	collision_mask = 1 | (1 << 3) | (1 << 2) | (1 << 1)
	linear_velocity = to.normalized() * speed + Vector3.UP * 3.0
	angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))


func current_element() -> StringName:
	return &"fire" if ignited > 0.0 else data.element


func ignite(seconds: float) -> void:
	ignited = seconds
	if _fire_light == null:
		_fire_light = OmniLight3D.new()
		_fire_light.light_color = Color(1.0, 0.45, 0.1)
		_fire_light.light_energy = 2.5
		_fire_light.omni_range = 3.0
		_fire_light.position = Vector3(0, _size.y * 0.8, 0)
		add_child(_fire_light)


func _process(delta: float) -> void:
	if ignited > 0.0:
		ignited -= delta
		if ignited <= 0.0 and _fire_light:
			_fire_light.queue_free()
			_fire_light = null


func can_pick_up() -> bool:
	return mode == Mode.FREE


func durability_left() -> int:
	return durability


## Hit by an attack while lying around: get knocked flying (and hurt whoever it hits).
func receive_hit(info: DamageInfo) -> float:
	if mode == Mode.HELD or mode == Mode.BROKEN:
		return 0.0
	var push := info.knockback * (3.0 if data.weight == PropData.Weight.LIGHT else 1.6)
	push.y = maxf(push.y, 2.0)
	linear_velocity = push
	if push.length() > 6.0 and info.source:
		mode = Mode.THROWN
		thrower = info.source
		collision_mask = 1 | (1 << 3) | (1 << 2) | (1 << 1)
	return 0.0


func attach_to(f: Node3D) -> void:
	mode = Mode.HELD
	if hurtbox:
		hurtbox.monitorable = false
	freeze = true
	collision_layer = 0
	collision_mask = 0
	var parent: Node3D = f.hand_attach if f.get("hand_attach") else f
	top_level = false
	reparent(parent, false)
	if parent == f:
		position = Vector3(0.35, 1.0, 0.45)
		rotation = Vector3(deg_to_rad(80), 0, 0)
	else:
		position = data.grip_offset
		rotation = Vector3.ZERO


## Leaves the hand. With a thrower it becomes a damaging projectile; without one it just drops.
func release(impulse: Vector3, by: Node) -> void:
	var xf := global_transform
	top_level = false
	reparent(_level(), false)
	global_transform = xf
	freeze = false
	if hurtbox:
		hurtbox.monitorable = true
	collision_layer = 1 << 3
	collision_mask = 1 | (1 << 3) | (1 << 2) | (1 << 1)   # thrown props also hit fighters
	thrower = by
	mode = Mode.THROWN if by else Mode.FREE
	if by is PhysicsBody3D:   # thrown from the hand, which can start inside the thrower's own body
		var body := by as PhysicsBody3D
		add_collision_exception_with(body)
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if is_instance_valid(self) and is_instance_valid(body):
				remove_collision_exception_with(body))
	linear_velocity = impulse
	angular_velocity = Vector3(randf_range(-6, 6), randf_range(-3, 3), randf_range(-6, 6)) if by else Vector3.ZERO


## Uses up durability; returns true if this broke the prop.
func wear(amount: int, _by: Node = null) -> bool:
	if mode == Mode.BROKEN:
		return true
	durability -= amount
	if durability <= 0:
		shatter()
		return true
	return false


func _burst_fire() -> void:
	fire_burst = false
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var f := n as Fighter
		if f and not f.is_dead() and f.global_position.distance_to(global_position) < 1.8:
			var info := DamageInfo.make(8.0, null, DamageInfo.Type.MAGIC)
			info.element = &"fire"
			info.knockback = (f.global_position - global_position).normalized() * 3.0
			f.receive_hit(info)
	Juice.shake(0.15)
	shatter()


func shatter() -> void:
	if mode == Mode.BROKEN:
		return
	mode = Mode.BROKEN
	var at := global_transform
	var pieces: Array = []
	var level := _level()
	var i := 0
	for pd in data.pieces:
		var p := Prop.new()
		p.data = pd
		p.position = at.origin + Vector3(randf_range(-0.3, 0.3), 0.4 + 0.15 * i, randf_range(-0.3, 0.3))
		level.add_child(p)   # level root sits at the origin, so local == global here
		p.linear_velocity = Vector3(randf_range(-2.5, 2.5), 3.0, randf_range(-2.5, 2.5))
		p.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		pieces.append(p)
		i += 1
	Events.prop_broken.emit(self, pieces)
	queue_free()


func _on_body_entered(body: Node) -> void:
	if fire_burst:
		_burst_fire()
		return
	if mode != Mode.THROWN:
		return
	if body == thrower:
		return
	var f := body as Fighter
	if f and not f.is_dead() and (thrower == null or f.team != thrower.team):
		var tm := 1.0
		if thrower is Fighter:
			tm = float((thrower as Fighter).data_mods.get("throw_mult", 1.0))
		var info := DamageInfo.make(data.damage * data.throw_mult * tm, thrower)
		info.knockback = linear_velocity.normalized() * data.knockback * 1.4 + Vector3.UP * 2.0
		info.knockdown = true
		info.stun = 0.5
		info.shatter = durability <= 2
		info.element = current_element()
		var amount := f.receive_hit(info)
		if thrower and thrower.has_signal("attack_landed"):
			thrower.attack_landed.emit(info, amount, f)
		Juice.hitstop(0.07)
		if not info.whiff:
			wear(2)
	# hitting the floor, a wall or another prop costs nothing (only real hits wear a prop)
	if mode != Mode.BROKEN:
		mode = Mode.FREE
		thrower = null
		collision_mask = 1 | (1 << 3)
