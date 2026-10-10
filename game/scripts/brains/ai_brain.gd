class_name AIBrain
extends Brain
## Basic melee demon: find the nearest hostile fighter, close in, attack on a cooldown.
## Demons start unaware: they wander near their spot until they see you (view cone), hear you up
## close, or get hit. Noticing alerts nearby demons; a "!" pops and they take a beat before engaging.
## Possessed hosts and Jackie's lying body are both valid targets (they're player-team).

var cooldown := 0.0
var think_t := 0.0
var target: Fighter
var carry_t := 0.0   ## thief: seconds spent running with loot
var strafe := 1.0 if randf() < 0.5 else -1.0
var wait_t := 0.0    ## circling while others attack
## At most this many demons swing at one target at once; the rest circle and wait their turn.
const MAX_ATTACKERS := 2
const SIGHT := 7.5
const SIGHT_DOT := 0.25     ## ~150 degree view cone
const HEAR := 2.8
const ALERT_RADIUS := 6.0

var aware := false
var react_t := 0.0          ## pause after noticing, before moving in
var home := Vector3.INF
var wander_t := 0.0
var wander_dir := Vector3.ZERO


func think(f: Fighter, delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	think_t -= delta
	if think_t <= 0.0 or target == null or not is_instance_valid(target) or target.is_dead() or target.stealthed:
		think_t = 0.4
		target = _pick_target(f)
	if target == null:
		return
	var to := target.global_position - f.global_position
	to.y = 0.0
	var dist := to.length()
	if not aware:
		if _notices(f, to, dist):
			notice(f, 0.45)
			_alert_others(f)
		else:
			_wander(f, delta)
			return
	if react_t > 0.0:
		react_t -= delta
		_turn(f, to / maxf(dist, 0.01), delta)
		return
	if dist > f.data.aggro_range:
		return
	match f.data.ai_kind:
		FighterData.AiKind.THIEF:
			_thief(f, to, dist)
			return
		FighterData.AiKind.RANGED:
			_ranged(f, to, dist, delta)
			return
	if dist > f.data.attack_range and wait_t <= 0.0:
		f.intent_move = to / dist
		return
	if wait_t > 0.0:
		wait_t -= delta
		_wait_turn(f, to, dist)
		return
	_turn(f, to / maxf(dist, 0.01), delta)
	if cooldown <= 0.0 and f.can_act() and not f.data.ai_attacks.is_empty() and f.facing.dot(to / maxf(dist, 0.01)) > 0.7:
		if not _may_attack(f):
			wait_t = randf_range(0.4, 0.8)
			return
		f.request_attack(f.data.ai_attacks[randi() % f.data.ai_attacks.size()])
		cooldown = f.data.attack_cooldown * randf_range(0.8, 1.2)


## Turn toward `dir` at the fighter's turn speed (snapping made flanking impossible).
func _turn(f: Fighter, dir: Vector3, delta: float) -> void:
	f.facing = f.facing.slerp(dir, clampf(f.data.turn_speed * delta, 0.0, 1.0)).normalized()


func _pick_target(f: Fighter) -> Fighter:
	var best: Fighter = null
	var best_d := INF
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o == null or o == f or o.team == f.team or o.is_dead() or o.stealthed:
			continue
		var d := f.global_position.distance_to(o.global_position)
		if o.state == Fighter.State.BODY:
			d += 3.0   # prefer the active fighter, but a lying body nearby is fair game
		if d < best_d:
			best_d = d
			best = o
	return best


## Thief imp: grab a prop off the floor and run from the player; throws it when cornered.
func _thief(f: Fighter, to: Vector3, dist: float) -> void:
	if f.held_prop == null:
		carry_t = 0.0
		var p := _nearest_free_prop(f, 12.0)
		if p == null:
			_melee(f, to, dist)   # nothing to steal: fight (fleeing forever made it unkillable)
			return
		var tp := p.global_position - f.global_position
		tp.y = 0.0
		if tp.length() < 1.3:
			f.request_grab()
		else:
			f.intent_move = tp.normalized()
		return
	carry_t += 0.016
	var cornered := absf(f.global_position.x) > 7.0 or absf(f.global_position.z) > 7.0
	if (dist < 2.5 or carry_t > 5.0 or cornered) and cooldown <= 0.0:
		f.facing = to / maxf(dist, 0.01)
		f.request_grab()   # throw the loot at the player
		cooldown = f.data.attack_cooldown
		carry_t = 0.0
	else:
		f.intent_move = -to / maxf(dist, 0.01) * 0.7   # loot slows it down


## Archer: keep `keep_distance`; throw a nearby prop, else a knife, on cooldown.
func _ranged(f: Fighter, to: Vector3, dist: float, _delta: float) -> void:
	var want := f.data.keep_distance
	f.facing = to / maxf(dist, 0.01)
	if f.held_prop == null:
		var p := _nearest_free_prop(f, 3.0)
		if p and dist > 3.0:
			var tp := p.global_position - f.global_position
			tp.y = 0.0
			if tp.length() < 1.3:
				f.request_grab()
			else:
				f.intent_move = tp.normalized()
			return
	if dist < want - 1.5:
		f.intent_move = -f.facing
	elif dist > want + 2.0:
		f.intent_move = f.facing
	if cooldown > 0.0 or not f.can_act():
		return
	cooldown = f.data.attack_cooldown * randf_range(0.8, 1.2)
	if f.held_prop:
		f.request_grab()
	else:
		var info := DamageInfo.make(5.0, f)
		info.stun = 0.3
		var from := f.global_position + Vector3(0, 1.3, 0) + f.facing * 0.6
		var aim := (target.global_position + Vector3(0, 1.0, 0)) - from
		Projectile.fire(f.get_tree().get_first_node_in_group(&"level_root"), from, aim, 14.0, info, f.team)
		f.anim.play(&"throw", 0.06, 0.4)


func _melee(f: Fighter, to: Vector3, dist: float) -> void:
	if dist > f.data.attack_range:
		f.intent_move = to / maxf(dist, 0.01)
		return
	f.facing = to / maxf(dist, 0.01)
	if cooldown <= 0.0 and f.can_act() and not f.data.ai_attacks.is_empty() and _may_attack(f):
		f.request_attack(f.data.ai_attacks[randi() % f.data.ai_attacks.size()])
		cooldown = f.data.attack_cooldown * randf_range(0.8, 1.2)


func _notices(f: Fighter, to: Vector3, dist: float) -> bool:
	if f.health.hp < f.health.max_hp:
		return true   # got hit
	if dist < HEAR:
		return true
	return dist < SIGHT and f.facing.dot(to / maxf(dist, 0.01)) > SIGHT_DOT


## Become aware of the player (after `delay` seconds of reaction).
func notice(f: Fighter, delay: float) -> void:
	if aware:
		return
	aware = true
	react_t = delay
	var mark := Label3D.new()
	mark.text = "!"
	mark.font_size = 120
	mark.outline_size = 24
	mark.modulate = Color(1.0, 0.8, 0.25)
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position.y = f.data.height + 0.8
	f.add_child(mark)
	mark.scale = Vector3.ONE * 0.3
	var tw := mark.create_tween()
	tw.tween_property(mark, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.6)
	tw.tween_property(mark, "modulate:a", 0.0, 0.2)
	tw.tween_callback(mark.queue_free)


func _alert_others(f: Fighter) -> void:
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o and o != f and o.team == f.team and not o.is_dead() and o.global_position.distance_to(f.global_position) < ALERT_RADIUS:
			var b := o.brain as AIBrain
			if b:
				b.notice(o, randf_range(0.5, 0.9))


## Unaware: amble around the spawn spot, pausing now and then.
func _wander(f: Fighter, delta: float) -> void:
	if home == Vector3.INF:
		home = f.global_position
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(1.2, 3.0)
		var back := home - f.global_position
		back.y = 0.0
		if back.length() > 3.0:
			wander_dir = back.normalized()
		elif randf() < 0.45:
			wander_dir = Vector3.ZERO
		else:
			var a := randf() * TAU
			wander_dir = Vector3(cos(a), 0.0, sin(a))
	f.intent_move = wander_dir * 0.35


func _may_attack(f: Fighter) -> bool:
	if f.team != Fighter.Team.ENEMY or f.data.boss:
		return true
	var busy := 0
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o and o != f and o.team == f.team and o.state == Fighter.State.ATTACK:
			var b := o.brain as AIBrain
			if b and b.target == target:
				busy += 1
	return busy < MAX_ATTACKERS


## Not our turn: back off a little and circle the target.
func _wait_turn(f: Fighter, to: Vector3, dist: float) -> void:
	var dir := to / maxf(dist, 0.01)
	var side := Vector3(-dir.z, 0.0, dir.x) * strafe
	f.intent_move = (side * 0.5 - dir * 0.3) if dist < f.data.attack_range * 0.9 else side * 0.4


func _nearest_free_prop(f: Fighter, within: float) -> Prop:
	var best: Prop = null
	var bd := within
	for n in f.get_tree().get_nodes_in_group(&"props"):
		var p := n as Prop
		if p and p.can_pick_up():
			var d := f.global_position.distance_to(p.global_position)
			if d < bd:
				bd = d
				best = p
	return best
