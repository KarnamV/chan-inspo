class_name BossBrain
extends Brain
## Boss AI built on the boss's own kit (BossKit). Picks moves by distance; phase 2 below half HP
## is faster and chains a second ground pound.

var cooldown := 1.5
var target: Fighter
var think_t := 0.0
var phase := 1
var _chain_pound := false


func think(f: Fighter, delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	think_t -= delta
	if think_t <= 0.0 or target == null or not is_instance_valid(target) or target.is_dead() or target.stealthed:
		think_t = 0.5
		target = _pick(f)
	if target == null:
		return
	if phase == 1 and f.health.hp < f.health.max_hp * 0.5:
		phase = 2
		Events.boss_phase.emit(f, 2)
	var to := target.global_position - f.global_position
	to.y = 0.0
	var d := to.length()
	if d > 0.01 and f.can_act():
		f.facing = f.facing.slerp(to / d, clampf(6.0 * delta, 0, 1)).normalized()
	if _chain_pound and f.can_act():
		_chain_pound = false
		BossKit.ground_pound(f)
		return
	if cooldown > 0.0 or not f.can_act():
		if d > 2.4 and f.can_act():
			f.intent_move = to / d * 0.8
		return
	var speed := 0.65 if phase == 2 else 1.0
	if d > 6.0:
		if randf() < 0.55:
			BossKit.cleaver_throw(f)
		else:
			BossKit.meat_hook(f, 9.0)
		cooldown = 2.2 * speed
	elif d > 2.6:
		if randf() < 0.5:
			BossKit.meat_hook(f, 9.0)
			cooldown = 1.2 * speed
		else:
			f.intent_move = to / d
	else:
		if randf() < 0.45:
			BossKit.ground_pound(f)
			_chain_pound = phase == 2 and randf() < 0.5
			cooldown = 2.4 * speed
		elif not f.data.light_combo.is_empty():
			f.request_light()
			cooldown = 1.0 * speed


func _pick(f: Fighter) -> Fighter:
	var best: Fighter = null
	var bd := INF
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o == null or o.team == f.team or o.is_dead() or o.stealthed or o.state == Fighter.State.BODY:
			continue
		var dd := f.global_position.distance_to(o.global_position)
		if dd < bd:
			bd = dd
			best = o
	return best
