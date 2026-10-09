class_name AllyBrain
extends Brain
## Companion AI (Tiger twin, Dog convert): stay near the player, fight the nearest enemy,
## don't wander off. Never targets lying bodies.

var leader_fn: Callable      ## returns the Fighter to stay near
var cooldown := 0.0
var follow_dist := 3.0
var engage_range := 7.0


func _init(p_leader_fn: Callable) -> void:
	leader_fn = p_leader_fn


func think(f: Fighter, delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	var leader: Fighter = leader_fn.call() if leader_fn.is_valid() else null
	var enemy := _nearest_enemy(f)
	if enemy and f.global_position.distance_to(enemy.global_position) < engage_range:
		var to := enemy.global_position - f.global_position
		to.y = 0.0
		var d := to.length()
		if d > 1.6:
			f.intent_move = to / d
		else:
			f.facing = to / maxf(d, 0.01)
			if cooldown <= 0.0 and f.can_act():
				if f.held_prop:
					f.request_light()
				elif randf() < 0.3 and f.data.heavy:
					f.request_heavy()
				else:
					f.request_light()
				cooldown = randf_range(0.45, 0.8)
		return
	if leader and leader != f:
		var tl := leader.global_position - f.global_position
		tl.y = 0.0
		if tl.length() > follow_dist:
			f.intent_move = tl.normalized()


func _nearest_enemy(f: Fighter) -> Fighter:
	var best: Fighter = null
	var bd := INF
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o == null or o.team == f.team or o.is_dead() or o.state == Fighter.State.BODY:
			continue
		var d := f.global_position.distance_to(o.global_position)
		if d < bd:
			bd = d
			best = o
	return best
