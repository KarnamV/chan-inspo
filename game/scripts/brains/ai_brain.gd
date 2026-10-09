class_name AIBrain
extends Brain
## Basic melee demon: find the nearest hostile fighter, close in, attack on a cooldown.
## Possessed hosts and Jackie's lying body are both valid targets (they're player-team).

var cooldown := 0.0
var think_t := 0.0
var target: Fighter
var carry_t := 0.0   ## thief: seconds spent running with loot


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
	if dist > f.data.aggro_range:
		return
	match f.data.ai_kind:
		FighterData.AiKind.THIEF:
			_thief(f, to, dist)
			return
		FighterData.AiKind.RANGED:
			_ranged(f, to, dist, delta)
			return
	if dist > f.data.attack_range:
		f.intent_move = to / dist
		return
	_turn(f, to / maxf(dist, 0.01), delta)
	if cooldown <= 0.0 and f.can_act() and not f.data.ai_attacks.is_empty() and f.facing.dot(to / maxf(dist, 0.01)) > 0.7:
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
		var info := DamageInfo.make(8.0, f)
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
	if cooldown <= 0.0 and f.can_act() and not f.data.ai_attacks.is_empty():
		f.request_attack(f.data.ai_attacks[randi() % f.data.ai_attacks.size()])
		cooldown = f.data.attack_cooldown * randf_range(0.8, 1.2)


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
