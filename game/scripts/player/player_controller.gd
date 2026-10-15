class_name PlayerController
extends Node
## Owns what belongs to the player, not to a body: the spirit (chi) meter, talismans,
## and which Fighter is currently controlled (Jackie or a possessed host).

signal controlled_changed(f: Fighter)

@export var spirit_max := 100.0
@export var spirit_per_hit := 5.0
@export var sheep_duration := 10.0     ## seconds a possession lasts
@export var sheep_range := 3.0
@export var body_hit_penalty := 10.0    ## extra damage when Jackie's body is hit mid-possession

var hero: Fighter
var controlled: Fighter
var host: Fighter          ## possessed demon, or null
var _host_ring: Decal
var camera: IsoCamera
var spirit := 0.0          ## chi: spent only by chi moves; talismans run on cooldowns
var possess_left := 0.0
var brain: Brain          ## PlayerBrain normally; bots swap in a scripted brain
var _host_old_brain: Brain
var equipped: Array[Talisman] = []
## Monkey: boss id -> times killed (meta; persisted by the run/meta system in M4)
var boss_ledger := {}
var monkey_pick := 0
## Chi (magic) variants of the four buttons. Locked until unlocked by the move draft (M4).
var chi_unlocked := {&"palm": false, &"wave": false, &"pull": false, &"blink": false}
var chi_level := {&"palm": 1, &"wave": 1, &"pull": 1, &"blink": 1}
const CHI_COST := {&"palm": 12.0, &"wave": 25.0, &"pull": 10.0, &"blink": 8.0}
const CHI_SLOTS := [&"palm", &"wave", &"pull", &"blink"]


func setup(p_hero: Fighter, p_camera: IsoCamera) -> void:
	hero = p_hero
	camera = p_camera
	brain = PlayerBrain.new(self, camera)
	hero.set_brain(brain)
	hero.attack_landed.connect(_on_landed)
	hero.body_hit.connect(_on_body_hit)
	_set_controlled(hero)
	add_spirit(0.0)


func add_spirit(v: float) -> void:
	spirit = clampf(spirit + v, 0.0, spirit_max)
	Events.spirit_changed.emit(spirit, spirit_max)


func _on_landed(_info: DamageInfo, amount: float, _target: Node = null) -> void:
	if amount > 0.0:
		add_spirit(spirit_per_hit)


func unlock_all_chi() -> void:
	for k in chi_unlocked:
		chi_unlocked[k] = true


## slot: 0 light -> palm, 1 heavy -> wave, 2 grab -> pull, 3 dodge -> blink
func use_chi(slot: int) -> bool:
	var id: StringName = CHI_SLOTS[slot]
	var f := controlled
	if not chi_unlocked[id] or spirit < CHI_COST[id] or f == null or not f.can_act():
		return false
	var lvl: int = chi_level[id]
	match id:
		&"palm":
			var a := AttackData.new()
			a.clip = &"chi_cast"
			a.duration = 0.5
			a.active_start = 0.2
			a.active_end = 0.32
			a.damage = 14.0 * (1.0 + 0.35 * (lvl - 1))
			a.magic = true
			a.knockback = 6.0
			a.lunge = 0.5
			a.hit_size = Vector3(1.2, 1.4, 2.6)
			a.hit_offset = Vector3(0, 1.1, 1.6)
			f.request_attack(a)
		&"wave":
			var w := AttackData.new()
			w.clip = &"chi_cast"
			w.duration = 0.7
			w.active_start = 0.3
			w.active_end = 0.42
			w.damage = 12.0 * (1.0 + 0.35 * (lvl - 1))
			w.magic = true
			w.knockback = 7.0
			w.knockdown = true
			w.lunge = 0.0
			w.hit_size = Vector3(4.6, 1.6, 4.6)
			w.hit_offset = Vector3(0, 0.8, 0)
			f.request_attack(w)
		&"pull":
			if not _chi_pull(f, 7.0 + lvl):
				return false
		&"blink":
			_chi_blink(f, 3.5 + 0.5 * lvl)
	add_spirit(-CHI_COST[id])
	Events.chi_used.emit(f, id)
	return true


func _chi_pull(f: Fighter, reach: float) -> bool:
	if f.held_prop == null:
		var best: Prop = null
		var bd := reach
		for n in get_tree().get_nodes_in_group(&"props"):
			var p := n as Prop
			if p and p.can_pick_up() and f.global_position.distance_to(p.global_position) < bd:
				bd = f.global_position.distance_to(p.global_position)
				best = p
		if best:
			best.attach_to(f)
			f.held_prop = best
			return true
	var target: Fighter = null
	var td := reach
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o and o.team != f.team and not o.is_dead() and f.global_position.distance_to(o.global_position) < td:
			td = f.global_position.distance_to(o.global_position)
			target = o
	if target == null:
		return false
	var info := DamageInfo.make(2.0, f, DamageInfo.Type.MAGIC)
	info.knockback = (f.global_position - target.global_position).normalized() * 11.0
	info.stun = 0.7
	target.receive_hit(info)
	return true


func _chi_blink(f: Fighter, dist: float) -> void:
	var dir := f.intent_move.normalized() if f.intent_move.length() > 0.1 else f.facing
	f.facing = dir
	f.health.invulnerable = true
	var col := f.move_and_collide(dir * dist)
	f.health.invulnerable = false
	if col == null:
		Juice.shake(0.08)


## Talismans are collected during a run and never replaced. Passives just work; actives take the
## button slots (talisman modifier + light / heavy / grab / dodge) in the order they were found.
const ACTIVE_SLOTS := 4


func equip(ids: Array) -> void:
	for t in equipped:
		t.unequip()
	equipped.clear()
	for id in ids:
		var t := Zodiac.make(id)
		t.equip(self)
		equipped.append(t)
	Events.talismans_changed.emit()


var boons: Array[Talisman] = []


func add_boon(id: StringName) -> void:
	var b := Boons.make(id)
	b.equip(self)
	boons.append(b)


func has_talisman(id: StringName) -> bool:
	for t in equipped:
		if t.id == id:
			return true
	return false


func talisman(id: StringName) -> Talisman:
	for t in equipped:
		if t.id == id:
			return t
	return null


func actives() -> Array[Talisman]:
	var out: Array[Talisman] = []
	for t in equipped:
		if t.is_active_talisman() and out.size() < ACTIVE_SLOTS:
			out.append(t)
	return out


## Adds a found talisman (no-op if already held).
func collect(id: StringName) -> void:
	if has_talisman(id):
		return
	var ids: Array = equipped.map(func(x: Talisman) -> StringName: return x.id)
	ids.append(id)
	equip(ids)


func use_talisman(slot: int) -> bool:
	var act := actives()
	if slot >= act.size():
		return false
	var t := act[slot]
	var ok := t.activate()
	if ok:
		Events.talisman_used.emit(t.id)
	return ok


func sheep_target() -> Fighter:
	var best: Fighter = null
	var best_d := sheep_range
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var f := n as Fighter
		if f == null or f.team == Fighter.Team.PLAYER or not f.is_knocked_down():
			continue
		var d := controlled.global_position.distance_to(f.global_position)
		if d < best_d:
			best_d = d
			best = f
	return best


func try_possess() -> bool:
	if host or controlled != hero:
		return false
	var t := sheep_target()
	if t == null:
		return false
	host = t
	possess_left = sheep_duration
	_host_old_brain = t.brain
	t.set_team(Fighter.Team.PLAYER)
	t.collision_layer = 1 << 1
	t.set_brain(brain)
	t.set_tint(Color(0.6, 0.25, 1.0, 0.35))
	_host_ring = Vfx.ring(t, t.data.radius * (2.6 if t.data.boss else 2.2), Color(0.7, 0.4, 1.0, 0.85))
	t.knock_time = minf(t.knock_time, t.state_t + 0.2)   # stand the host up quickly
	t.attack_landed.connect(_on_landed)
	t.died.connect(_on_host_died)
	hero.set_brain(null)
	hero.enter_body_state()
	_set_controlled(t)
	Events.possession_started.emit(t)
	return true


func end_possession(reason: StringName) -> void:
	if host == null:
		return
	var h := host
	host = null
	if is_instance_valid(_host_ring):
		_host_ring.queue_free()
	_host_ring = null
	if is_instance_valid(h):
		h.attack_landed.disconnect(_on_landed)
		h.died.disconnect(_on_host_died)
		h.set_tint(null)
		if not h.is_dead():
			h.set_team(Fighter.Team.ENEMY)
			h.collision_layer = 1 << 2
			h.set_brain(_host_old_brain)
			h._knockdown()   # leaving dazes the host
	hero.leave_body_state()
	hero.set_brain(brain)
	_set_controlled(hero)
	var sheep := talisman(&"sheep")
	if sheep:
		sheep.start_cooldown()
	Events.possession_ended.emit(h, reason)
	if reason == &"body_hit":
		var info := DamageInfo.make(body_hit_penalty, null)
		hero.health.take(info)


func _on_host_died() -> void:
	end_possession(&"host_died")


func _on_body_hit(_info: DamageInfo) -> void:
	end_possession(&"body_hit")


func _set_controlled(f: Fighter) -> void:
	controlled = f
	if camera:
		camera.target = f
	for t in equipped:
		t.on_controlled_changed(f)
	for b in boons:
		b.on_controlled_changed(f)
	controlled_changed.emit(f)


func _ready() -> void:
	Events.room_cleared.connect(func(_r: Node) -> void:
		for t in equipped + boons:
			t.on_room_cleared())


func _physics_process(delta: float) -> void:
	for t in equipped:
		t.cd_left = maxf(t.cd_left - delta, 0.0)
		t.tick(delta)
	for b in boons:
		b.tick(delta)
	if host:
		possess_left -= delta
		if possess_left <= 0.0:
			end_possession(&"time_out")
