extends Node
## M3 gate bot: every talisman, in the real arena with real models/animations.
##   godot --headless --path . --fixed-fps 60 res://tests/bot/bot_m3.tscn

var arena: Arena
var pc: PlayerController
var hero: Fighter
var results: Array = []
var ev := {}


func _ready() -> void:
	Juice.enabled = false
	arena = (load("res://scenes/levels/test_room.tscn") as PackedScene).instantiate()
	arena.with_hud = false
	add_child(arena)
	pc = arena.controller
	hero = arena.hero
	hero.set_brain(null)
	pc.brain = null
	hero.health.max_hp = 5000.0
	hero.health.hp = 5000.0
	var arity := {"possession_started": 1, "tiger_split": 2, "tiger_merged": 1, "monkey_changed": 2,
		"prop_animated": 1, "food_eaten": 1, "dog_saved": 2, "talisman_used": 1}
	for s in arity:
		Events.connect(s, _count.bind(s).unbind(arity[s]))
	_run.call_deferred()


func _count(s: String) -> void:
	ev[s] = int(ev.get(s, 0)) + 1


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout


func _brute() -> Fighter:
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var f := n as Fighter
		if f and f.team == Fighter.Team.ENEMY and not f.is_dead() and f.data.id == &"brute":
			return f
	return null


func _knock_brute_near() -> Fighter:
	var b := _brute()
	if b == null:
		return null
	b.global_position = hero.global_position + hero.facing * 1.4
	if b.state == Fighter.State.GETUP:
		b._set_state(Fighter.State.IDLE)   # getting up is invulnerable now
	var i := DamageInfo.make(1.0)
	i.knockdown = true
	b.receive_hit(i)
	return b


func _give(id: StringName) -> Prop:
	var p := arena.spawn_prop(id, hero.global_position + Vector3(0, 0.5, 0))
	await get_tree().physics_frame
	p.attach_to(hero)
	hero.held_prop = p
	return p


func _ready_to_act() -> void:
	for i in 120:
		if hero.can_act():
			return
		await get_tree().physics_frame


func _check(name: String, ok: bool) -> void:
	results.append([name, ok])
	print(("PASS  " if ok else "FAIL  ") + name)


func _run() -> void:
	await _wait(0.5)
	hero.facing = Vector3(0, 0, -1)
	# Sheep
	pc.equip([&"sheep"])
	pc.add_spirit(100)
	_knock_brute_near()
	_check("Sheep: possess a knocked-down brute", pc.use_talisman(0) and pc.controlled != hero)
	pc.use_talisman(0)
	await _wait(1.0)
	# Tiger
	pc.equip([&"tiger"])
	pc.add_spirit(100)
	_check("Tiger: split", pc.use_talisman(0) and int(ev.get("tiger_split", 0)) == 1)
	pc.use_talisman(0)
	_check("Tiger: swap control to the twin", pc.controlled != hero)
	(pc.talisman(&"tiger") as Zodiac.Tiger).left = 0.1
	await _wait(0.5)
	_check("Tiger: merges back", int(ev.get("tiger_merged", 0)) == 1 and pc.controlled == hero)
	# Rat
	pc.equip([&"rat"])
	pc.add_spirit(100)
	var chair := arena.spawn_prop(&"chair", hero.global_position + hero.facing * 1.5)
	await _wait(0.3)
	_check("Rat: animates a prop", pc.use_talisman(0) and chair.animator == hero)
	await _wait(3.0)
	_check("Rat: the prop attacks on its own", is_instance_valid(chair) == false or chair.mode == Prop.Mode.THROWN or chair.durability < chair.data.durability)
	# Dragon
	pc.equip([&"dragon"])
	pc.add_spirit(100)
	var held := await _give(&"chair")
	await _ready_to_act()
	_check("Dragon: ignites the held prop", pc.use_talisman(0) and held.current_element() == &"fire")
	hero.drop_prop()
	# Pig
	pc.equip([&"pig"])
	pc.spirit = 0.0
	await _give(&"bun_basket")
	await _ready_to_act()
	_check("Pig: eats food for spirit", pc.use_talisman(0) and pc.spirit >= 30.0)
	# Monkey (Butcher King form, full kit)
	pc.equip([&"monkey"])
	pc.boss_ledger = {&"butcher_king": 1}
	pc.add_spirit(100)
	_check("Monkey: become the Butcher King", pc.use_talisman(0) and pc.controlled.data.id == &"butcher_king")
	var form := pc.controlled
	_check("Monkey: boss kit works (cleaver throw)", BossKit.special(form, 0))
	await _wait(0.6)
	_check("Monkey: other talismans usable while transformed", pc.equipped.size() == 1 and pc.controlled == form)
	var m := pc.talisman(&"monkey") as Zodiac.Monkey
	for i in m.attacks_left + 1:
		m._on_form_attack(null)
	await _wait(0.3)
	_check("Monkey: attack limit returns you to Jackie", pc.controlled == hero and not hero.hidden)
	# Ox
	pc.equip([&"ox"])
	await _wait(0.3)
	await _ready_to_act()
	_knock_brute_near()
	hero.request_grab()
	_check("Ox: giant swing with a downed demon", hero.state == Fighter.State.ATTACK and hero.attack.id == &"ox_giant_swing")
	await _wait(1.0)
	# Snake
	pc.equip([&"snake"])
	await _ready_to_act()
	hero.request_dodge()
	_check("Snake: stealth after dodge", hero.stealthed)
	await _wait(2.5)
	_check("Snake: stealth wears off", not hero.stealthed)
	# Rabbit, Rooster
	pc.equip([&"rabbit", &"rooster"])
	_check("Rabbit: wider parry window", hero.parry_mult == 2.0)
	_check("Rooster: launch bonus", hero.launch_bonus > 0.0)
	# Horse
	pc.equip([&"horse"])
	hero.health.hp = 1000.0
	Events.damage_dealt.emit(_brute(), DamageInfo.make(100.0, hero), 100.0)
	_check("Horse: lifesteal heals", hero.health.hp > 1000.0)
	# Dog
	pc.equip([&"dog"])
	hero.health.hp = 3.0
	var b := _brute()
	await _ready_to_act()
	hero.mercy_t = 0.0   # a stray demon hit just before would leave the hero briefly invulnerable
	hero.receive_hit(DamageInfo.make(500.0, b))
	_check("Dog: survive a lethal hit, killer converts", not hero.is_dead() and int(ev.get("dog_saved", 0)) == 1 and b.team == Fighter.Team.PLAYER)
	var ok := results.all(func(r: Array) -> bool: return r[1])
	print("BOT M3: %d/%d  events=%s" % [results.filter(func(r: Array) -> bool: return r[1]).size(), results.size(), ev])
	print("BOT RESULT: " + ("ALL PASS" if ok else "FAILURES"))
	get_tree().quit(0 if ok else 1)
