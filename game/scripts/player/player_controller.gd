class_name PlayerController
extends Node
## Owns what belongs to the player, not to a body: the spirit meter, talismans (M1: Sheep only),
## and which Fighter is currently controlled (Jackie or a possessed host).

signal controlled_changed(f: Fighter)

@export var spirit_max := 100.0
@export var spirit_per_hit := 5.0
@export var sheep_cost := 40.0
@export var sheep_drain := 7.0          ## spirit per second while possessing
@export var sheep_range := 3.0
@export var body_hit_penalty := 10.0    ## extra damage when Jackie's body is hit mid-possession

var hero: Fighter
var controlled: Fighter
var host: Fighter          ## possessed demon, or null
var camera: IsoCamera
var spirit := 0.0
var brain: PlayerBrain
var _host_old_brain: Brain


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


func _on_landed(_info: DamageInfo, amount: float) -> void:
	if amount > 0.0:
		add_spirit(spirit_per_hit)


func use_talisman(slot: int) -> void:
	if slot == 0:   # M1: slot 1 is the Sheep talisman
		if host:
			end_possession(&"released")
		else:
			try_possess()


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
	if host or spirit < sheep_cost or controlled != hero:
		return false
	var t := sheep_target()
	if t == null:
		return false
	add_spirit(-sheep_cost)
	host = t
	_host_old_brain = t.brain
	t.set_team(Fighter.Team.PLAYER)
	t.collision_layer = 1 << 1
	t.set_brain(brain)
	t.set_tint(Color(0.6, 0.25, 1.0, 0.35))
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
	Events.possession_ended.emit(h)
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
	controlled_changed.emit(f)


func _physics_process(delta: float) -> void:
	if host:
		add_spirit(-sheep_drain * delta)
		if spirit <= 0.0:
			end_possession(&"spirit_out")
