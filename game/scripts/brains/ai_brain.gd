class_name AIBrain
extends Brain
## Basic melee demon: find the nearest hostile fighter, close in, attack on a cooldown.
## Possessed hosts and Jackie's lying body are both valid targets (they're player-team).

var cooldown := 0.0
var think_t := 0.0
var target: Fighter


func think(f: Fighter, delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	think_t -= delta
	if think_t <= 0.0 or target == null or not is_instance_valid(target) or target.is_dead():
		think_t = 0.4
		target = _pick_target(f)
	if target == null:
		return
	var to := target.global_position - f.global_position
	to.y = 0.0
	var dist := to.length()
	if dist > f.data.aggro_range:
		return
	if dist > f.data.attack_range:
		f.intent_move = to / dist
		return
	f.facing = to / maxf(dist, 0.01)
	if cooldown <= 0.0 and f.can_act() and not f.data.ai_attacks.is_empty():
		f.request_attack(f.data.ai_attacks[randi() % f.data.ai_attacks.size()])
		cooldown = f.data.attack_cooldown * randf_range(0.8, 1.2)


func _pick_target(f: Fighter) -> Fighter:
	var best: Fighter = null
	var best_d := INF
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o == null or o == f or o.team == f.team or o.is_dead():
			continue
		var d := f.global_position.distance_to(o.global_position)
		if o.state == Fighter.State.BODY:
			d += 3.0   # prefer the active fighter, but a lying body nearby is fair game
		if d < best_d:
			best_d = d
			best = o
	return best
