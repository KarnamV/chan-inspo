extends Node
## M2 gate bot: combat arena, waves up to all 6 demon types. Fights with props, chi and parries.
##   godot --headless --path . --fixed-fps 60 res://tests/bot/bot_m2.tscn

const LIMIT_S := 300.0
const TYPES := [&"brute", &"shield_demon", &"thief_imp", &"archer_demon", &"wraith", &"armored_ghoul"]

var arena: Arena
var pc: PlayerController
var t := 0.0
var killed := {}
var counts := {"chi": 0, "parried": 0, "broken": 0, "blocked": 0, "thrown_at_us": 0, "burns": 0}
var done := false


class Bot:
	extends Brain
	var tick := 0
	var pc: PlayerController

	func think(f: Fighter, _d: float) -> void:
		tick += 1
		var e := _nearest(f)
		if e == null:
			return
		var to := e.global_position - f.global_position
		to.y = 0.0
		var d := to.length()
		# parry incoming melee
		if d < 2.4 and e.state == Fighter.State.ATTACK and e.attack and e.state_t < e.attack.active_start and tick % 3 == 0:
			f.request_parry()
			return
		if tick % 90 == 0 and pc.spirit >= 25.0:
			pc.use_chi(1 if d < 2.5 else 0)
			return
		if f.held_prop == null and tick % 25 == 0:
			var p := f.nearest_prop()
			if p:
				f.request_grab()
				return
		if e.data.front_block and e.state != Fighter.State.STAGGER and e.facing.dot(-to.normalized()) > 0.3 and d < 4.0:
			if f.held_prop and d < 2.2:
				f.facing = to.normalized()
				f.request_heavy()
			else:
				f.intent_move = e.facing.cross(Vector3.UP).normalized()
				if tick % 40 == 0:
					f.request_dodge()
			return
		if d > 1.7:
			f.intent_move = to / d
			return
		f.facing = to / d
		if tick % 12 == 0:
			f.request_heavy() if (f.held_prop and tick % 36 == 0) else f.request_light()

	func _nearest(f: Fighter) -> Fighter:
		var best: Fighter = null
		var bd := INF
		for n in f.get_tree().get_nodes_in_group(&"fighters"):
			var o := n as Fighter
			if o and o.team != f.team and not o.is_dead():
				var dd := f.global_position.distance_to(o.global_position)
				if dd < bd:
					bd = dd
					best = o
		return best


func _ready() -> void:
	Juice.enabled = false
	arena = (load("res://scenes/levels/combat_arena.tscn") as PackedScene).instantiate()
	arena.with_hud = false
	add_child(arena)
	pc = arena.controller
	pc.unlock_all_chi()
	arena.hero.health.max_hp = 3000.0
	arena.hero.health.hp = 3000.0
	arena.hero.dmg_mult_physical = 2.0
	var bot := Bot.new()
	bot.pc = pc
	pc.brain = bot
	arena.hero.set_brain(bot)
	arena.hero.parried.connect(func(_a: Node) -> void: counts.parried += 1)
	Events.chi_used.connect(func(_f: Node, _id: StringName) -> void: counts.chi += 1)
	Events.prop_broken.connect(func(_p: Node, _x: Array) -> void: counts.broken += 1)
	Events.entity_died.connect(func(f: Node) -> void:
		var id: StringName = (f as Fighter).data.id
		killed[id] = int(killed.get(id, 0)) + 1)
	for n in get_tree().get_nodes_in_group(&"fighters"):
		pass


func _physics_process(delta: float) -> void:
	if done:
		return
	t += delta
	pc.add_spirit(delta * 4.0)   # keep chi flowing for the test
	var all_types := TYPES.all(func(x: StringName) -> bool: return killed.has(x))
	if t >= LIMIT_S or (all_types and counts.parried >= 1):
		done = true
		var checks := [
			["all 6 demon types defeated", all_types],
			["parried at least once", counts.parried >= 1],
			["used chi moves", counts.chi >= 3],
			["props broke", counts.broken >= 1],
		]
		print("BOT M2 after %.0fs: killed=%s counts=%s" % [t, killed, counts])
		var ok := true
		for c in checks:
			print(("PASS  " if c[1] else "FAIL  ") + c[0])
			ok = ok and c[1]
		print("BOT RESULT: " + ("ALL PASS" if ok else "FAILURES"))
		get_tree().quit(0 if ok else 1)
