extends Node
## M1 bot playtest: drives the real arena with a scripted player and checks the core loop.
##   godot --headless --path . res://tests/bot/bot_m1.tscn
## Prints one PASS/FAIL line per check and exits with code 0 (all pass) or 1.

const LIMIT_S := 75.0

var arena: Arena
var pc: PlayerController
var t := 0.0
var counts := {"picked": 0, "broken": 0, "knockdowns": 0, "possess_start": 0, "possess_end": 0,
		"host_hits": 0, "deaths": 0, "thrown_hits": 0}
var bot: BotBrain
var done := false


class BotBrain:
	extends Brain
	var owner_bot: Node
	var phase := "get_prop"
	var tick := 0

	func think(f: Fighter, _delta: float) -> void:
		tick += 1
		var pc: PlayerController = owner_bot.pc
		if pc.host:
			phase = "host_fight"
		elif phase == "host_fight":
			phase = "get_prop"
		match phase:
			"get_prop":
				if f.held_prop:
					phase = "beat_down"
					return
				var p := _nearest_prop(f)
				if p == null:
					phase = "beat_down"
					return
				if _go(f, p.global_position, 1.2):
					f.request_grab()
			"beat_down":
				var kd := pc.sheep_target()
				if kd and pc.spirit >= pc.sheep_cost:
					pc.try_possess()
					return
				var e := _nearest_enemy(f, true)
				if e == null:
					return
				if f.held_prop == null and _nearest_prop(f) and f.global_position.distance_to(_nearest_prop(f).global_position) < 4.0:
					phase = "get_prop"
					return
				if _go(f, e.global_position, 1.6) and tick % 12 == 0:
					if f.held_prop:
						f.request_heavy()
					else:
						f.request_light() if tick % 24 else f.request_heavy()
			"host_fight":
				var e := _nearest_enemy(f, false)
				if e and _go(f, e.global_position, 1.9) and tick % 10 == 0:
					f.request_light() if tick % 30 else f.request_heavy()

	func _go(f: Fighter, at: Vector3, within: float) -> bool:
		var to := at - f.global_position
		to.y = 0.0
		if to.length() <= within:
			f.facing = to.normalized() if to.length() > 0.01 else f.facing
			return true
		f.intent_move = to.normalized()
		return false

	func _nearest_prop(f: Fighter) -> Prop:
		var best: Prop = null
		var bd := INF
		for n in f.get_tree().get_nodes_in_group(&"props"):
			var p := n as Prop
			if p and p.can_pick_up():
				var d := f.global_position.distance_to(p.global_position)
				if d < bd:
					bd = d
					best = p
		return best

	func _nearest_enemy(f: Fighter, standing_first: bool) -> Fighter:
		var best: Fighter = null
		var bd := INF
		for n in f.get_tree().get_nodes_in_group(&"fighters"):
			var o := n as Fighter
			if o == null or o == f or o.team == f.team or o.is_dead() or o.state == Fighter.State.BODY:
				continue
			var d := f.global_position.distance_to(o.global_position)
			if standing_first and o.is_knocked_down():
				d += 5.0
			if d < bd:
				bd = d
				best = o
		return best


func _ready() -> void:
	Juice.enabled = false
	arena = (load("res://scenes/levels/test_room.tscn") as PackedScene).instantiate()
	arena.with_hud = false
	add_child(arena)
	pc = arena.controller
	arena.hero.health.max_hp = 2000.0
	arena.hero.health.hp = 2000.0
	bot = BotBrain.new()
	bot.owner_bot = self
	pc.brain = bot          # the controller hands this brain to whatever body it controls
	arena.hero.set_brain(bot)
	Events.prop_broken.connect(func(_p, _pieces): counts.broken += 1)
	Events.knocked_down.connect(func(_f): counts.knockdowns += 1)
	Events.possession_started.connect(func(_h): counts.possess_start += 1)
	Events.possession_ended.connect(func(_h): counts.possess_end += 1)
	Events.entity_died.connect(func(_f): counts.deaths += 1)
	Events.damage_dealt.connect(_on_damage)


func _on_damage(target: Node, info: DamageInfo, amount: float) -> void:
	if pc.host and info.source == pc.host and amount > 0.0:
		counts.host_hits += 1


func _physics_process(delta: float) -> void:
	if done:
		return
	t += delta
	if arena.hero.held_prop:
		counts.picked = maxi(counts.picked, 1)
	var finished := counts.possess_end >= 1 and counts.deaths >= 1
	if t >= LIMIT_S or finished:
		done = true
		_report()


func _report() -> void:
	var checks := [
		["picked up a prop", counts.picked >= 1],
		["a prop broke into pieces", counts.broken >= 1],
		["a demon was knocked down", counts.knockdowns >= 1],
		["Sheep possession started", counts.possess_start >= 1],
		["possessed host landed hits on a demon", counts.host_hits >= 1],
		["possession ended", counts.possess_end >= 1],
		["a demon died", counts.deaths >= 1],
	]
	var ok := true
	print("BOT M1 after %.1fs sim: %s" % [t, JSON.stringify(counts)])
	for c in checks:
		print(("PASS  " if c[1] else "FAIL  ") + c[0])
		ok = ok and c[1]
	print("BOT RESULT: " + ("ALL PASS" if ok else "FAILURES"))
	get_tree().quit(0 if ok else 1)
