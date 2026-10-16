class_name Fighter
extends CharacterBody3D
## Shared body for Jackie and every demon. A swappable Brain decides what to do each frame; the
## Fighter does it (move, attack, swing/throw props, dodge, react to hits). Possession = brain swap.

signal attack_landed(info: DamageInfo, amount: float, target: Node)
signal attack_started(a: AttackData)
signal perfect_dodge
signal dodged
signal knocked_down
signal died
signal body_hit(info: DamageInfo)   ## hit while lying as a possession body (Sheep)
signal parried(attacker: Node)
signal caught(prop: Node)
signal blocked(info: DamageInfo)

enum State { IDLE, ATTACK, DODGE, STAGGER, KNOCKDOWN, GETUP, DEAD, BODY, PICKUP, THROW, PARRY }
enum Team { PLAYER, ENEMY }

const GRAVITY := 20.0
const PICKUP_RANGE := 1.7
const AIM_RANGE := 3.2          ## player attacks snap toward an enemy this close...
const AIM_CONE := 0.5           ## ...within ~60 degrees of where you're pushing
const BODY_MASK := 1 | (1 << 1) | (1 << 2)   ## world + other fighters
const DODGE_FOLLOW_FROM := 0.12  ## attack this far into a dodge (or...)
const DODGE_FOLLOW_AFTER := 0.22 ## ...this soon after it) = a dodge move
const COUNTER_WINDOW := 1.2      ## after a perfect dodge, the next light is the counter spin
const MAX_LUNGE := 11.0         ## fastest step-in toward an aimed enemy (m/s, during the windup)
const STAGGER_ESCAPE := 0.15    ## player can dodge out of a stagger after this long
const CHAIN_AT := 0.35          ## a queued light fires this far into an attack's recovery (0 = right after the hit)

@export var data: FighterData
@export var team: Team = Team.ENEMY

var brain: Brain
var health: Health
var status: StatusFx
var parry_mult := 1.0    ## Rabbit widens the parry/perfect-dodge window
var dmg_mult_physical := 1.0   ## Tiger Yang
var dmg_mult_magic := 1.0      ## Tiger Yin
var crit_next := false         ## Snake: next hit from stealth crits and spares the prop
var stealthed := false         ## Snake: AI ignores you
var heavy_one_hand := false    ## Ox: heavy props swing at light speed
var launch_bonus := 0.0        ## Rooster: extra upward knock on knockdowns
var grab_override: Callable    ## Ox: grab a knocked-down demon instead of a prop
var hidden := false            ## Monkey: Jackie is 'inside' the boss form
var shield_guard: Callable     ## Wok Shield boon: returns true to block a hit
var data_mods := {}            ## run modifiers (Run.mods): bare/prop/light/fire/throw multipliers
var hurtbox: Hurtbox
var hitbox: Hitbox
var model: Node3D
var anim: AnimDriver
var held_prop: Prop
var hand_attach: Node3D
var carry: CarryPose
var _skel: Skeleton3D
var _bone_l := -1               ## LeftHand / RightHand / Chest, for the two-hand grip
var _bone_r := -1
var _bone_chest := -1

var state: State = State.IDLE
var state_t := 0.0
var intent_move := Vector3.ZERO
var facing := Vector3.FORWARD * -1.0   # +Z
var combo_index := 0
var prop_combo := 0             ## alternates prop light swings (swing / backhand chop...)
var combo_reset_t := 0.0
var queued_light := false
var attack: AttackData
var attack_with_prop: Prop
var attack_hit_any := false
var dodge_cd := 0.0
var knock_time := 0.0
var lunge_speed := 0.0          ## this attack's windup step speed (attack.lunge, or more to close in)
var since_dodge := 99.0         ## seconds since the last dodge ended
var counter_t := 0.0            ## > 0: perfect dodge counter ready
var mercy_t := 0.0              ## post-hit invulnerability (data.hit_iframes)
var _flash_t := 0.0
var _flash_mat: StandardMaterial3D
var _tint_mat: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []
var hp_bar: MeshInstance3D      ## tiny bar over demons (bosses use the BossBar)
var _chip := 1.0
static var _hp_mat: ShaderMaterial
var _overlay: Material


func _ready() -> void:
	add_to_group(&"fighters")
	collision_layer = 1 << (1 if team == Team.PLAYER else 2)
	collision_mask = BODY_MASK
	var body := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = data.radius
	cap.height = data.height
	body.shape = cap
	body.position.y = data.height * 0.5
	add_child(body)

	health = Health.new()
	health.max_hp = data.max_hp
	health.resist_physical = data.resist_physical
	health.resist_magic = data.resist_magic
	add_child(health)
	health.died.connect(_on_died)
	status = StatusFx.new()
	status.fighter = self
	add_child(status)

	hurtbox = Hurtbox.new()
	var hcap := CapsuleShape3D.new()
	hcap.radius = data.radius * 1.25
	hcap.height = data.height
	hurtbox.setup(self, team, hcap, Vector3(0, data.height * 0.5, 0))
	add_child(hurtbox)

	hitbox = Hitbox.new()
	hitbox.team = team
	add_child(hitbox)
	hitbox.landed.connect(_on_hit_landed)

	if data.model:
		model = data.model.instantiate()
		add_child(model)
		anim = AnimDriver.new(model)
		hand_attach = _make_hand_attach()
		if hand_attach:
			carry = CarryPose.new()
			carry.fighter = self
			carry.influence = 0.0
			hand_attach.get_parent().add_child(carry)
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			_meshes.append(mi as MeshInstance3D)
			(mi as MeshInstance3D).layers = 2   # keeps blob-shadow decals off the body
		CharacterLook.apply(_meshes, CharacterLook.HERO_RIM if team == Team.PLAYER else CharacterLook.ENEMY_RIM)
		var r := data.radius * (2.6 if data.boss else 2.2)
		Vfx.blob_shadow(self, r, Color(0.35, 0.95, 0.7, 0.7) if team == Team.PLAYER else Color(0, 0, 0, 0))
	else:
		anim = AnimDriver.new(null)
	_flash_mat = flash_material()
	if team == Team.ENEMY and not data.boss:
		_make_hp_bar()
	_set_state(State.IDLE)


## White hit-flash overlay. Warm and see-through: a solid white silhouette read as a blob.
static func flash_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 0.92, 0.8, 0.38)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func hp_material() -> ShaderMaterial:
	if _hp_mat == null:
		_hp_mat = ShaderMaterial.new()
		_hp_mat.shader = load("res://assets/shaders/enemy_hp.gdshader")
	return _hp_mat


func _make_hp_bar() -> void:
	hp_material()
	hp_bar = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(clampf(data.radius * 2.6, 0.8, 1.4), 0.13)
	hp_bar.mesh = q
	hp_bar.material_override = _hp_mat
	hp_bar.position.y = data.height + 0.35
	hp_bar.layers = 2
	hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar.visible = false
	add_child(hp_bar)


func _update_hp_bar(delta: float) -> void:
	var r := health.hp / maxf(health.max_hp, 1.0)
	_chip = maxf(move_toward(_chip, r, delta * 0.8), r)
	hp_bar.visible = team == Team.ENEMY and not is_dead() and r < 0.999 and not hidden
	hp_bar.set_instance_shader_parameter(&"ratio", r)
	hp_bar.set_instance_shader_parameter(&"chip", _chip)


func _make_hand_attach() -> Node3D:
	var skels := model.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return null
	var sk: Skeleton3D = skels[0]
	if sk.find_bone("RightHand") < 0:
		return null
	_skel = sk
	_bone_l = sk.find_bone("LeftHand")
	_bone_r = sk.find_bone("RightHand")
	_bone_chest = sk.find_bone("Chest")
	var ba := BoneAttachment3D.new()
	ba.bone_name = "RightHand"
	sk.add_child(ba)
	return ba


# ---------------- control API (called by brains) ----------------
func set_brain(b: Brain) -> void:
	brain = b


func set_team(t: Team) -> void:
	team = t
	hurtbox.team = t
	hitbox.team = t


func can_act() -> bool:
	return state == State.IDLE


func request_light() -> void:
	if _dodge_follow():   # out of a dodge: counter spin after a perfect dodge, else a dash strike
		_start_attack(_counter_attack() if counter_t > 0.0 else _dash_attack(), held_prop)
		return
	if state == State.ATTACK and attack and state_t >= attack.combo_window and attack.id != &"" and _is_light(attack):
		queued_light = true
	elif can_act():
		if held_prop:
			_start_attack(_prop_attack(false), held_prop)
		else:
			_start_attack(_combo_attack(), null)


func request_heavy() -> void:
	if _dodge_follow():
		_start_attack(_slam_attack(), held_prop)
		return
	if state == State.ATTACK and _in_recovery() and _is_light(attack):
		_set_state(State.IDLE)   # light -> heavy finisher cancel (bare or with a prop)
	if not can_act():
		return
	if held_prop:
		_start_attack(_prop_attack(true), held_prop)
	elif data.kit != &"":
		BossKit.special(self, 1)   # boss forms: heavy = signature heavy (ground pound)
	elif data.heavy:
		_start_attack(data.heavy, null)


func request_grab() -> void:
	if not can_act():
		return
	if held_prop:
		_set_state(State.THROW)
		anim.play(&"throw", 0.08, 0.38)
	elif grab_override.is_valid() and grab_override.call(self):
		return
	elif data.kit != &"" and BossKit.grab(self):
		return
	else:
		var p := nearest_prop()
		if p:
			attack_with_prop = p   # remembered until the pickup frame
			_set_state(State.PICKUP)
			anim.play(&"pickup", 0.08, 0.3)
		else:
			for n in get_tree().get_nodes_in_group(&"fixed_props"):
				var fp := n as FixedProp
				if fp and fp.kind == FixedProp.Kind.WEAPON_RACK and global_position.distance_to(fp.global_position) < 2.2:
					if fp.give_to(self):
						anim.play(&"pickup", 0.08, 0.3)
					return


func request_dodge() -> void:
	if dodge_cd > 0.0 or not (can_act() or can_dodge_cancel()):
		return
	if intent_move.length() > 0.1:
		facing = intent_move.normalized()
	_set_state(State.DODGE)
	health.invulnerable = true
	collision_mask = 1   # world only: dodge through demons instead of stopping dead on them
	dodged.emit()
	anim.play(&"dodge", 0.05, data.dodge_time)


## Player bodies can dodge out of attack recovery and out of a stagger, so a crowd can't lock them.
func can_dodge_cancel() -> bool:
	if team != Team.PLAYER:
		return false
	match state:
		State.ATTACK:
			return _in_recovery()
		State.STAGGER:
			return state_t >= STAGGER_ESCAPE
	return false


func _in_recovery() -> bool:
	return attack != null and state_t >= attack.active_end


## Player only: pressing attack late in a dodge, or just after it, turns into a dodge move.
func _dodge_follow() -> bool:
	if team != Team.PLAYER or data.kit != &"":
		return false
	if state == State.DODGE and state_t >= DODGE_FOLLOW_FROM:
		_set_state(State.IDLE)
		return true
	return state == State.IDLE and since_dodge < DODGE_FOLLOW_AFTER


func _move(id: StringName, clip: StringName, dur: float, strike: Vector2, dmg: float) -> AttackData:
	var a := AttackData.new()
	a.id = id
	a.clip = clip
	a.duration = dur
	a.active_start = dur * strike.x
	a.active_end = dur * strike.y
	a.combo_window = dur   # these don't chain; they end the string
	a.damage = dmg + (held_prop.data.damage * 0.6 if held_prop else 0.0)
	a.knockdown = true
	return a


## Dodge -> light: flying shoulder charge through the first demon in the way.
func _dash_attack() -> AttackData:
	var a := _move(&"dash_strike", &"ram", 0.42, Vector2(0.28, 0.62), 11.0)
	a.lunge = 9.0
	a.knockback = 7.0
	a.hit_size = Vector3(1.5, 1.4, 1.5)
	a.hit_offset = Vector3(0, 1.0, 0.8)
	return a


## Perfect dodge -> light: spinning backfist that clears everyone around you (the crit doubles it).
func _counter_attack() -> AttackData:
	counter_t = 0.0
	var a := _move(&"counter_spin", &"spin", 0.55, Vector2(0.24, 0.72), 14.0)
	a.lunge = 1.5
	a.knockback = 6.5
	a.hit_size = Vector3(3.8, 1.6, 3.8)
	a.hit_offset = Vector3(0, 1.0, 0)
	return a


## Dodge -> heavy: leap and slam, a shockwave that floors everything close.
func _slam_attack() -> AttackData:
	var a := _move(&"leap_slam", &"heavy", 0.62, Vector2(0.62, 0.78), 13.0)
	a.lunge = 4.5
	a.knockback = 5.0
	a.hit_size = Vector3(3.4, 1.4, 3.4)
	a.hit_offset = Vector3(0, 0.8, 0.9)
	a.prop_wear = 2
	return a


func _is_light(a: AttackData) -> bool:
	return a != null and (a in data.light_combo or String(a.id).ends_with("_light"))


## Point in the attack where recovery can be cut short: a queued light chains, moving walks out.
func _chain_point() -> float:
	return attack.active_end + (attack.duration - attack.active_end) * CHAIN_AT


## Parry is folded into the dodge: a dodge started just before a hit lands is a perfect dodge
## (staggers the attacker, slow-mo, next hit crits). Kept so old callers and the button still work.
func request_parry() -> void:
	request_dodge()


func request_attack(a: AttackData) -> void:
	if can_act():
		_start_attack(a, null)


func set_hidden(h: bool) -> void:
	hidden = h
	visible = not h
	hitbox.deactivate()
	hurtbox.monitorable = not h
	collision_layer = 0 if h else (1 << (1 if team == Team.PLAYER else 2))
	set_physics_process(not h)
	if h:
		drop_prop()
		velocity = Vector3.ZERO
		_set_state(State.IDLE)


func is_knocked_down() -> bool:
	return state == State.KNOCKDOWN


func is_dead() -> bool:
	return state == State.DEAD


func nearest_prop() -> Prop:
	var best: Prop = null
	var best_d := PICKUP_RANGE
	for n in get_tree().get_nodes_in_group(&"props"):
		var p := n as Prop
		if p == null or not p.can_pick_up():
			continue
		var d := global_position.distance_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


# ---------------- attacks ----------------
func _combo_attack() -> AttackData:
	if data.light_combo.is_empty():
		return null
	if combo_reset_t <= 0.0:
		combo_index = 0
	var a: AttackData = data.light_combo[combo_index % data.light_combo.size()]
	combo_index += 1
	return a


## Prop attacks by style. Light / heavy:
##   club  (chair, planks, wok...)  swing / overhead chop
##   long  (pole, spear)            thrust, long and narrow / spin, hits all around
##   bulky (bench, barrel, carts)   ram shove, big push / two-hand slam
##   small (buns, shard, duck)      quick jab / chop
## `strike` = fraction of the clip where the blow lands (matches the clip's keyframes).
func _prop_attack(heavy: bool) -> AttackData:
	var pd := held_prop.data
	var style := pd.attack_style()
	var a := AttackData.new()
	a.id = StringName("prop_%s_%s" % [style, "heavy" if heavy else "light"])
	var slow := 1.2 if pd.weight == PropData.Weight.HEAVY and not heavy_one_hand else 1.0
	var r := pd.reach
	var dur := 0.38
	var strike := Vector2(0.42, 0.68)
	if combo_reset_t <= 0.0:
		prop_combo = 0
	var second := not heavy and prop_combo % 2 == 1   # every other light swing is a backhand
	if not heavy:
		prop_combo += 1
	a.damage = pd.damage * (pd.heavy_mult if heavy else 1.0)
	a.knockback = pd.knockback * (1.6 if heavy else 0.6)   # lights keep them in reach for the next swing
	a.knockdown = heavy or pd.weight == PropData.Weight.HEAVY
	a.stun = 0.4
	a.lunge = 2.5 if heavy else 1.5
	a.hit_size = Vector3(1.6 if heavy else 1.2, 1.4, r)
	a.hit_offset = Vector3(0, 1.0, 0.35 + r * 0.5)
	if second and style in [&"club", &"small"]:
		style = &"backhand"
	match [style, heavy]:
		[&"club", false]:
			a.clip = &"swing"
		[&"backhand", false]:   # quick downward chop to follow a swing
			a.clip = &"chop"
			dur = 0.36
			strike = Vector2(0.45, 0.66)
			a.lunge = 2.0
			a.hit_size = Vector3(1.0, 1.6, r + 0.3)
			a.hit_offset = Vector3(0, 0.9, 0.3 + (r + 0.3) * 0.5)
		[&"club", true], [&"small", true]:
			a.clip = &"chop"
			dur = 0.5
			strike = Vector2(0.45, 0.66)
			a.hit_size = Vector3(1.0, 1.6, r + 0.3)   # narrow but deep: a downward blow
			a.hit_offset = Vector3(0, 0.9, 0.3 + (r + 0.3) * 0.5)
		[&"small", false]:
			a.clip = &"punch_jab"
			dur = 0.26
			strike = Vector2(0.3, 0.6)
			a.lunge = 2.0
		[&"long", false]:
			a.clip = &"thrust"
			dur = 0.38
			strike = Vector2(0.4, 0.66)
			a.lunge = 3.2
			a.hit_size = Vector3(0.7, 1.2, r + 0.4)   # long, narrow poke
			a.hit_offset = Vector3(0, 1.1, 0.3 + (r + 0.4) * 0.5)
			a.knockback = pd.knockback * 1.2
		[&"long", true]:
			a.clip = &"spin"
			dur = 0.7
			strike = Vector2(0.24, 0.74)
			a.lunge = 0.5
			a.damage = pd.damage * 1.2   # hits everyone around you, so less than a full heavy
			a.hit_size = Vector3(r * 2.0 + 0.6, 1.4, r * 2.0 + 0.6)
			a.hit_offset = Vector3(0, 1.0, 0)
		[&"bulky", false]:
			a.clip = &"ram"
			dur = 0.44
			strike = Vector2(0.45, 0.66)
			a.lunge = 3.5
			a.knockdown = false
			a.knockback = pd.knockback * 1.15   # shove, but stay in reach of the next ram
			a.stun = 0.6
			a.hit_size = Vector3(1.8, 1.4, 1.3)
			a.hit_offset = Vector3(0, 1.0, 1.0)
		[&"bulky", true]:
			a.clip = &"heavy"
			dur = 0.58
			strike = Vector2(0.55, 0.74)
			a.hit_size = Vector3(2.0, 1.6, r + 0.4)   # wide slam
	a.duration = dur * slow
	a.active_start = a.duration * strike.x
	a.active_end = a.duration * strike.y
	a.combo_window = a.active_start   # presses from the windup on queue the next swing
	a.prop_wear = 2 if heavy else 1
	return a


func _start_attack(a: AttackData, prop: Prop) -> void:
	if a == null:
		return
	attack = a
	attack_with_prop = prop
	attack_hit_any = false
	queued_light = false
	lunge_speed = a.lunge
	if team == Team.PLAYER:
		var d := _aim()
		if d > 0.0 and a.lunge > 0.0:   # step in to striking distance (knockback pushed them away)
			var ideal := maxf(a.hit_offset.z, 0.9)
			var close := (d - ideal) / maxf(a.active_start, 0.08)
			lunge_speed = clampf(close, a.lunge, MAX_LUNGE)
	_set_state(State.ATTACK)
	anim.play(a.clip, 0.06, a.duration)
	if prop and team == Team.PLAYER:
		SwingTrail.follow(self, prop, a)
	attack_started.emit(a)


## Soft aim: face the pushed direction, snapping to the nearest enemy roughly that way.
## Returns the distance to the enemy it snapped to, or -1.
func _aim() -> float:
	var dir := intent_move.normalized() if intent_move.length() > 0.1 else facing
	var best: Fighter = null
	var best_d := AIM_RANGE
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o == null or o == self or o.team == team or o.is_dead() or o.hidden:
			continue
		var to := o.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d < best_d and (d < 0.9 or dir.dot(to / d) > AIM_CONE):
			best_d = d
			best = o
	if best:
		var to := best.global_position - global_position
		to.y = 0.0
		if to.length() > 0.01:
			dir = to.normalized()
	facing = dir
	return best_d if best else -1.0


func _attack_info(a: AttackData) -> DamageInfo:
	var info := DamageInfo.make(a.damage, self, DamageInfo.Type.MAGIC if a.magic else DamageInfo.Type.PHYSICAL)
	info.knockback = facing * a.knockback + Vector3.UP * ((2.0 + launch_bonus) if a.knockdown else 0.0)
	info.knockdown = a.knockdown
	info.stun = a.stun
	if attack_with_prop:
		info.shatter = attack_with_prop.durability_left() <= a.prop_wear
		info.element = attack_with_prop.data.element
		info.element = attack_with_prop.current_element()
		if info.element == &"magic" or info.element == &"fire" and attack_with_prop.ignited > 0.0:
			info.type = DamageInfo.Type.MAGIC
	info.amount *= dmg_mult_magic if info.type == DamageInfo.Type.MAGIC else dmg_mult_physical
	if not data_mods.is_empty():
		info.amount *= float(data_mods.get("prop_mult", 1.0)) if attack_with_prop else float(data_mods.get("bare_mult", 1.0))
		if a in data.light_combo:
			info.amount *= float(data_mods.get("light_mult", 1.0))
		if info.element == &"fire":
			info.amount *= float(data_mods.get("fire_mult", 1.0))
	if crit_next:
		info.amount *= 2.0
	return info


func _on_hit_landed(hb: Hurtbox, info: DamageInfo, amount: float) -> void:
	if not (hb.owner_fighter is Fighter) or info.whiff:
		return   # loose props, or a target that wasn't hittable: no wear, no hitstop
	if not attack_hit_any and attack_with_prop and is_instance_valid(attack_with_prop) and state == State.ATTACK:
		attack_hit_any = true
		var p := attack_with_prop
		if not crit_next and p.wear(attack.prop_wear, self):
			held_prop = null
	crit_next = false
	attack_landed.emit(info, amount, hb.owner_fighter)
	if team == Team.PLAYER:   # only your own hits freeze the frame; a crowd hitting you shouldn't stutter
		Juice.hitstop((0.07 if info.knockdown else 0.045) + (0.015 if attack_with_prop else 0.0))
		Juice.shake(0.16 if info.knockdown else 0.06)
		Inputs.rumble(0.3, 0.4 if info.knockdown else 0.0, 0.08)


# ---------------- hits taken ----------------
## Perfect dodge: the attacker overcommits (staggered, unless a boss), time slows for a beat and
## your next hit is a critical.
func _perfect_counter(info: DamageInfo) -> void:
	perfect_dodge.emit()
	var atk := info.source as Fighter
	if atk and not atk.is_dead() and not atk.data.boss and atk.global_position.distance_to(global_position) < 3.5:
		atk.hitbox.deactivate()
		atk._set_state(State.STAGGER)
		atk.knock_time = 0.9
		atk.anim.play(&"hit", 0.05, 0.6)
	parried.emit(info.source)
	Events.parried.emit(self, info.source)
	if team == Team.PLAYER:
		crit_next = true
		counter_t = COUNTER_WINDOW
		Juice.slowmo(0.3, 0.35)
		Vfx.ring_flash(self)


func receive_hit(info: DamageInfo) -> float:
	if state == State.DEAD or state == State.GETUP or mercy_t > 0.0:
		info.whiff = true
		return 0.0
	if state == State.PARRY and state_t <= data.parry_window * parry_mult:
		var atk := info.source as Fighter
		if atk and not atk.is_dead():
			atk.hitbox.deactivate()
			atk._set_state(State.STAGGER)
			atk.knock_time = 0.9
			atk.anim.play(&"hit", 0.05, 0.6)
		parried.emit(info.source)
		Juice.hitstop(0.1)
		return 0.0
	if shield_guard.is_valid() and shield_guard.call(info):
		_flash_t = 0.12
		blocked.emit(info)
		return 0.0
	if data.front_block and not info.shatter and info.type == DamageInfo.Type.PHYSICAL 			and info.source is Node3D and state not in [State.KNOCKDOWN, State.STAGGER]:
		var to_src: Vector3 = (info.source as Node3D).global_position - global_position
		to_src.y = 0.0
		if to_src.length() > 0.01 and facing.dot(to_src.normalized()) > 0.35:
			velocity += -to_src.normalized() * 2.0
			blocked.emit(info)
			if info.knockdown:   # heavy hit on the shield: guard break, shield down for a moment
				hitbox.deactivate()
				_set_state(State.STAGGER)
				knock_time = 0.9
				anim.play(&"hit", 0.05, 0.6)
			return 0.0
	if health.invulnerable and state == State.DODGE and state_t <= data.dodge_iframes:
		info.whiff = true
		if state_t <= data.parry_window * parry_mult:   # timed it: the hit was already coming
			_perfect_counter(info)
		return 0.0
	var amount := health.take(info)
	if health.invulnerable:
		info.whiff = true
		return 0.0
	if info.element != &"" and amount > 0.0:
		status.apply_element(info.element, info.source)
	Events.damage_dealt.emit(self, info, amount)
	_flash_t = 0.09
	if amount > 0.0:
		mercy_t = data.hit_iframes
	if state == State.BODY:
		body_hit.emit(info)
		return amount
	if health.is_dead():
		return amount
	if data.ai_kind == FighterData.AiKind.THIEF and team == Team.ENEMY and amount > 0.0:
		drop_prop()
	velocity += info.knockback
	if info.knockdown and state != State.KNOCKDOWN and not data.knockdown_immune:
		_knockdown()
	elif state != State.KNOCKDOWN and info.stun * data.stagger_scale > 0.05:
		hitbox.deactivate()
		_set_state(State.STAGGER)
		knock_time = info.stun * data.stagger_scale
		anim.play(&"hit", 0.05, maxf(knock_time, 0.2))
	if team == Team.PLAYER:
		Juice.shake(0.25 if info.knockdown else 0.12)
		Inputs.rumble(0.5, 0.6 if info.knockdown else 0.25, 0.25 if info.knockdown else 0.12)
	return amount


func _knockdown() -> void:
	hitbox.deactivate()
	drop_prop()
	_set_state(State.KNOCKDOWN)
	knock_time = data.knockdown_time
	anim.play(&"knockdown", 0.06, 0.55)
	knocked_down.emit()
	Events.knocked_down.emit(self)


func _on_died() -> void:
	hitbox.deactivate()
	drop_prop()
	_set_state(State.DEAD)
	anim.play(&"death", 0.08)
	hurtbox.monitorable = false
	collision_layer = 0
	died.emit()
	Events.entity_died.emit(self)


## Extra life: stand back up from death with `hp`.
func revive(hp: float) -> void:
	health.hp = hp
	hurtbox.monitorable = true
	collision_layer = 1 << (1 if team == Team.PLAYER else 2)
	_set_state(State.GETUP)
	anim.play(&"getup", 0.05, 0.8, true)
	health.invulnerable = true
	get_tree().create_timer(1.5, false).timeout.connect(func() -> void: health.invulnerable = false)


func drop_prop() -> void:
	if held_prop and is_instance_valid(held_prop):
		held_prop.release(Vector3.UP * 1.5 + facing * 0.5, null)
	held_prop = null


## Possession body: lie down and wait (brain is usually null meanwhile).
func enter_body_state() -> void:
	hitbox.deactivate()
	drop_prop()
	_set_state(State.BODY)
	anim.hold_end(&"lying")


func leave_body_state() -> void:
	if state == State.BODY:
		_set_state(State.GETUP)
		anim.play(&"getup", 0.05, 0.6, true)


# ---------------- frame update ----------------
func _set_state(s: State) -> void:
	if state == State.DODGE and s != State.DODGE:
		health.invulnerable = false
		collision_mask = BODY_MASK
		since_dodge = 0.0
		dodge_cd = data.dodge_cooldown * float(data_mods.get("dodge_cd_mult", 1.0))
	if state == State.ATTACK and s != State.ATTACK:
		hitbox.deactivate()
		if model:
			model.rotation.y = 0.0   # undo the spin turn
			model.position.y = 0.0   # land the leap
	state = s
	state_t = 0.0


func _physics_process(delta: float) -> void:
	state_t += delta
	dodge_cd = maxf(dodge_cd - delta, 0.0)
	mercy_t = maxf(mercy_t - delta, 0.0)
	combo_reset_t = maxf(combo_reset_t - delta, 0.0)
	since_dodge += delta
	counter_t = maxf(counter_t - delta, 0.0)
	intent_move = Vector3.ZERO
	if brain and state != State.DEAD:
		brain.think(self, delta)

	var target_vel := Vector3.ZERO
	match state:
		State.IDLE:
			target_vel = intent_move * data.move_speed
			if intent_move.length() > 0.1:
				facing = facing.slerp(intent_move.normalized(), clampf(data.turn_speed * delta, 0, 1)).normalized()
				anim.ensure(&"run" if intent_move.length() > 0.6 else &"walk")
			else:
				anim.ensure(&"idle")
		State.ATTACK:
			if state_t < attack.active_start:
				target_vel = facing * lunge_speed
			if state_t >= attack.active_start and not hitbox.active and state_t < attack.active_end:
				hitbox.activate(_attack_info(attack), attack.hit_size, attack.hit_offset)
				if attack.id == &"leap_slam":
					Vfx.dust(global_position + facing * 0.9, true)
					Vfx.shockwave(global_position + facing * 0.9)
					Juice.shake(0.25)
			if attack.id == &"leap_slam" and model:   # hop up during the windup, drop on the strike
				var k := clampf(state_t / attack.active_start, 0.0, 1.0)
				model.position.y = sin(k * PI) * 0.9
			if state_t >= attack.active_end and hitbox.active:
				hitbox.deactivate()
			if attack.clip == &"spin" and model:
				# the full turn is done on the model (the import drops hip rotation from the clip)
				var k := clampf((state_t - attack.active_start) / maxf(attack.active_end - attack.active_start, 0.01), 0.0, 1.0)
				model.rotation.y = -TAU * (k * k * (3.0 - 2.0 * k))
			var chain := queued_light and state_t >= _chain_point()
			var walk_out := team == Team.PLAYER and not queued_light and state_t >= _chain_point() 					and intent_move.length() > 0.5
			if chain or walk_out or state_t >= attack.duration:
				_set_state(State.IDLE)
				combo_reset_t = 0.45
				if chain:
					request_light()
		State.DODGE:
			target_vel = facing * data.dodge_speed
			if held_prop == null and state_t <= 0.2 * parry_mult:
				_try_catch()
			if state_t >= data.dodge_iframes:
				health.invulnerable = false
			if state_t >= data.dodge_time:
				_set_state(State.IDLE)
		State.STAGGER:
			if state_t >= knock_time:
				_set_state(State.IDLE)
		State.KNOCKDOWN:
			if state_t > 0.55 and anim.current != &"lying":
				anim.hold_end(&"lying")
			if state_t >= knock_time:
				_set_state(State.GETUP)
				anim.play(&"getup", 0.05, 0.6, true)
		State.GETUP:
			if state_t >= 0.6:
				_set_state(State.IDLE)
		State.PICKUP:
			if state_t >= 0.15 and attack_with_prop and held_prop == null:
				var p := attack_with_prop
				attack_with_prop = null
				if is_instance_valid(p) and p.can_pick_up():
					p.attach_to(self)
					held_prop = p
					if not data_mods.is_empty() and not p.bonus_applied:
						p.durability += int(data_mods.get("durability_bonus", 0))
						p.bonus_applied = true
					Events.prop_picked.emit(self, p)
			if state_t >= 0.3:
				_set_state(State.IDLE)
		State.PARRY:
			if state_t >= data.parry_window * parry_mult + data.parry_recovery:
				_set_state(State.IDLE)
		State.THROW:
			if state_t >= 0.16 and held_prop:
				var p := held_prop
				held_prop = null
				p.release(facing * 13.0 + Vector3.UP * 2.0, self)
			if state_t >= 0.38:
				_set_state(State.IDLE)

	var horiz := Vector3(velocity.x, 0, velocity.z)
	var accel := data.accel if state in [State.IDLE, State.ATTACK, State.DODGE] else 8.0
	horiz = horiz.move_toward(target_vel, accel * delta)
	velocity.x = horiz.x
	velocity.z = horiz.z
	if data.hover > 0.0:
		velocity.y = (data.hover - global_position.y) * 6.0
	else:
		velocity.y = 0.0 if is_on_floor() and velocity.y < 0.0 else velocity.y - GRAVITY * delta
	move_and_slide()
	if facing.length() > 0.01:
		rotation.y = atan2(facing.x, facing.z)
	_update_flash(delta)
	if carry:
		var want := 1.0 if held_prop and state in [State.IDLE, State.PICKUP, State.STAGGER] else 0.0
		carry.influence = move_toward(carry.influence, want, delta * (6.0 if want > 0.0 else 14.0))
		carry.active = carry.influence > 0.0
		if held_prop:
			carry.style = held_prop.data.attack_style()
	if hp_bar:
		_update_hp_bar(delta)


## Long and bulky props don't hang off the right hand like a club: a pole points where it's thrust
## (or out along the arm in a spin) and a bulky prop lies across the chest between both hands.
func _process(_delta: float) -> void:
	var p := held_prop
	if p == null or not is_instance_valid(p) or p.mode != Prop.Mode.HELD or _skel == null or _bone_l < 0:
		return
	var style := p.data.attack_style()
	if style != &"long" and style != &"bulky":
		return
	var sx := _skel.get_global_transform_interpolated()
	var rh := sx * _skel.get_bone_global_pose(_bone_r).origin
	var lh := sx * _skel.get_bone_global_pose(_bone_l).origin
	var fwd := get_global_transform_interpolated().basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var b := p.local_aabb()
	var ax := p.long_axis()
	var xf := Transform3D()
	if style == &"long":
		var dir := fwd
		if state == State.ATTACK and attack and attack.clip == &"spin" and _bone_chest >= 0:
			dir = rh - sx * _skel.get_bone_global_pose(_bone_chest).origin   # out along the arm
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.05 else fwd
		dir = (dir + Vector3.DOWN * 0.08).normalized()
		var side := Vector3.UP.cross(dir).normalized()
		xf.basis = _basis_mapping(ax, dir, _other_axis(ax), side)
		var half := b.size.dot(ax.abs()) * 0.5
		xf.origin = rh - xf.basis * (b.get_center() - ax * half * 0.55)   # grip a quarter from the end
	else:
		var side := lh - rh
		side.y = 0.0
		side = side.normalized() if side.length() > 0.05 else fwd.cross(Vector3.UP)
		if absf(ax.y) > 0.9:   # tall (barrel, urn): carried upright against the chest
			xf.basis = _basis_mapping(Vector3.UP, Vector3.UP, Vector3.RIGHT, side)
		else:
			xf.basis = _basis_mapping(ax, side, Vector3.UP, Vector3.UP)
		var depth := b.size.dot((xf.basis.inverse() * fwd).abs())   # its size front-to-back once rotated
		var mid := (lh + rh) * 0.5 + fwd * (depth * 0.5 + 0.05)
		xf.origin = mid - xf.basis * b.get_center()
	p.top_level = true
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.global_transform = xf


## A local axis perpendicular to unit axis `a`.
static func _other_axis(a: Vector3) -> Vector3:
	return Vector3.UP if absf(a.y) < 0.9 else Vector3.BACK


## Rotation taking local unit axes a, b (perpendicular) onto world unit axes wa, wb.
static func _basis_mapping(a: Vector3, wa: Vector3, b: Vector3, wb: Vector3) -> Basis:
	wb = (wb - wa * wa.dot(wb)).normalized()
	var local := Basis(a, b, a.cross(b))
	var world := Basis(wa, wb, wa.cross(wb))
	return world * local.inverse()


## Perfect dodge into a thrown prop (yours or an enemy's) snatches it out of the air.
func _try_catch() -> void:
	for n in get_tree().get_nodes_in_group(&"props"):
		var p := n as Prop
		if p == null or p.mode != Prop.Mode.THROWN or p.thrower == self:
			continue
		if global_position.distance_to(p.global_position) < 1.4:
			p.attach_to(self)
			held_prop = p
			caught.emit(p)
			return


func _update_flash(delta: float) -> void:
	if not model:
		return
	var overlay: Material = _tint_mat
	if _flash_t > 0.0:
		_flash_t -= delta
		overlay = _flash_mat
	if overlay == _overlay:
		return
	_overlay = overlay
	for mi in _meshes:
		if is_instance_valid(mi):
			mi.material_overlay = overlay


## Persistent colour tint over the model (e.g. violet while possessed). null clears it.
func set_tint(c: Variant) -> void:
	if c == null:
		_tint_mat = null
		return
	_tint_mat = StandardMaterial3D.new()
	_tint_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tint_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tint_mat.albedo_color = c
