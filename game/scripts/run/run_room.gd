class_name RunRoom
extends Arena
## One room of a run (realm 1: Ember Night Market). Reads Run.spec(): combat / story / shop /
## shrine / vault / boss. Clear it -> reward (from the door you came through) -> exit doors.

const MARKET_PROPS := [&"chair", &"bench", &"crate", &"barrel", &"pole", &"lantern", &"bucket", &"stool",
	&"spear", &"bun_basket", &"roast_duck", &"spirit_urn", &"market_stall_cart", &"wok", &"crate_of_fish",
	&"fruit_cart"]
const RARE_PROPS := [&"spirit_urn", &"spear", &"lantern", &"fruit_cart", &"market_stall_cart", &"roast_duck"]

var spec: Dictionary
var waves: Array = []
var wave_i := 0
var cleared := false
var doors: Array[RunDoor] = []
var boss: Fighter
var _ending := false
var _wave_delay := -1.0


func _configure() -> void:
	if not Run.active:   # opened directly in the editor: start a throwaway run
		Run.start_run([&"sheep", &"tiger", &"rat"])
	spec = Run.spec()
	spawn_enemies = false
	talismans.clear()
	match spec.type:
		"boss": room_size = 22.0
		"shop", "shrine": room_size = 14.0
		_: room_size = 18.0
	hero_spawn = Vector3(0, 0, room_size / 2 - 3.0)
	if ResourceLoader.exists("res://assets/textures/market_floor.png"):
		floor_tex = "res://assets/textures/market_floor.png"
	if ResourceLoader.exists("res://assets/textures/market_wall.png"):
		wall_tex = "res://assets/textures/market_wall.png"


func _decorate() -> void:
	var h := room_size / 2
	var rng := Run.rng
	var spots := [Vector3(-h + 1.2, 0, -h + 2.5), Vector3(h - 1.2, 0, -h + 2.5), Vector3(-h + 1.2, 0, 1.0),
		Vector3(h - 1.2, 0, 1.0), Vector3(-h + 1.2, 0, h - 3.0), Vector3(h - 1.2, 0, h - 3.0)]
	var kinds := ["stall_awning", "noodle_stand", "paper_lantern_string", "rice_sacks", "incense_stand", "paper_lantern_string"]
	for i in spots.size():
		var yaw := PI / 2 if spots[i].x < 0 else -PI / 2
		if decor("res://assets/decors/%s.glb" % kinds[(i + rng.randi_range(0, 2)) % kinds.size()], spots[i], yaw) == null:
			decor("res://assets/decors/pillar.glb", spots[i])
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 3.5, 0)
	glow.light_color = Color(1.0, 0.6, 0.3)
	glow.light_energy = 2.0
	glow.omni_range = room_size
	add_child(glow)


func _populate() -> void:
	Run.apply(controller)
	if controller.equipped.is_empty():
		controller.equip([&"sheep"])
	hero.died.connect(_on_hero_died)
	Events.prop_picked.connect(func(_f: Node, p: Node) -> void: Meta.see_prop((p as Prop).data.id))
	match spec.type:
		"combat":
			_scatter_props(10, MARKET_PROPS)
			waves = Run.waves_for(int(spec.depth), spec.get("elite", false))
			_next_wave()
		"story":
			_scatter_props(8, MARKET_PROPS)
			if spec.get("fight", false):
				waves = [Run.waves_for(int(spec.depth), false)[0]]
				_next_wave()
			else:
				_spawn_helper()
		"shop":
			_scatter_props(3, MARKET_PROPS)
			var shop := _npc("res://assets/characters/helper_street_chef.glb", "Night Market Stall", "[E] Shop")
			shop.reusable = true
			shop.used.connect(_open_shop)
			_on_clear()
		"shrine":
			var altar := _npc("res://assets/decors/incense_stand.glb", "Demon Shrine", "[E] Pray")
			altar.used.connect(_open_shrine)
			_on_clear()
		"vault":
			_scatter_props(16, RARE_PROPS)
			Run.gold += 40
			_on_clear()
		"boss":
			_scatter_props(10, MARKET_PROPS)
			var d: FighterData = load("res://data/fighters/%s.tres" % spec.boss)
			boss = spawn_fighter(d, Fighter.Team.ENEMY, Vector3(0, 0, -room_size / 2 + 4.0))
			boss.set_brain(BossBrain.new())
			boss.died.connect(_on_boss_died)
			var bar := BossBar.new()
			add_child(bar)
			bar.bind(boss, "THE BUTCHER KING")


func _scatter_props(n: int, pool: Array) -> void:
	var rng := Run.rng
	var h := room_size / 2 - 2.0
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < n and tries < 200:
		tries += 1
		var at := Vector3(rng.randf_range(-h, h), 0, rng.randf_range(-h, h - 2.0))
		if at.distance_to(hero_spawn) < 2.0 or placed.any(func(p: Vector3) -> bool: return p.distance_to(at) < 1.6):
			continue
		var id: StringName = pool[rng.randi_range(0, pool.size() - 1)]
		if not ResourceLoader.exists("res://data/props/%s.tres" % id):
			continue
		spawn_prop(id, at)
		placed.append(at)
	for i in 2:
		spawn_fixed(&"hanging_lantern", Vector3(rng.randf_range(-h, h), 2.6, rng.randf_range(-h, 0)))


func _next_wave() -> void:
	if wave_i >= waves.size():
		return
	var list: Array = waves[wave_i]
	wave_i += 1
	for i in list.size():
		var d: FighterData = load("res://data/fighters/%s.tres" % list[i])
		if d:
			spawn_fighter(d, Fighter.Team.ENEMY, ENEMY_SPAWNS[i % ENEMY_SPAWNS.size()] * (room_size / 18.0))


func _process(_delta: float) -> void:
	if cleared or _ending or spec.type in ["shop", "shrine", "vault", "boss"]:
		return
	if waves.is_empty():
		return
	if living_enemies() == 0 and controller.host == null:
		if wave_i < waves.size():
			if _wave_delay < 0.0:
				_wave_delay = 1.2
			_wave_delay -= _delta
			if _wave_delay <= 0.0:
				_wave_delay = -1.0
				_next_wave()
		else:
			if spec.type == "story":
				_spawn_helper()
				cleared = true   # the helper conversation opens the doors
			else:
				_on_clear()


func _on_clear() -> void:
	if cleared and spec.type != "story":
		return
	cleared = true
	Events.room_cleared.emit(self)
	if spec.type in ["combat", "story"]:
		Run.room_cleared()
	if Run.pending_reward != &"":
		var kind := Run.pending_reward
		Run.pending_reward = &""
		_offer(kind, _open_doors)
	else:
		_open_doors()


func _offer(kind: StringName, then: Callable) -> void:
	var offers := Rewards.offers(kind, controller, Run.rng)
	if offers.is_empty():
		then.call()
		return
	var titles := {&"talisman": "Choose a talisman", &"boon": "A helper's boon", &"draft": "New technique",
		&"gold": "Gold"}
	var panel := ChoicePanel.open(self, titles.get(kind, "Reward"), offers)
	panel.chosen.connect(func(i: int) -> void:
		offers[i].apply.call()
		if kind != &"boon":   # boons report themselves (Rewards.grant_boon)
			Events.run_reward.emit(kind, StringName(offers[i].title))
		then.call())


func _open_doors() -> void:
	var opts := Run.door_options()
	var h := room_size / 2
	for i in opts.size():
		var d := RunDoor.new()
		d.setup(opts[i])
		var x := 0.0 if opts.size() == 1 else (-3.5 if i == 0 else 3.5)
		d.position = Vector3(x, 0, -h + 1.0)
		add_child(d)
		d.taken.connect(_take_door)
		doors.append(d)


func _take_door(opt: Dictionary) -> void:
	if _ending:
		return
	_ending = true
	if controller.host:
		controller.end_possession(&"released")
	Run.store(controller)
	Run.choose_door(opt)


# ---------------------------------------------------------------- story / shop / shrine
func _npc(model: String, title: String, prompt: String) -> RunNpc:
	var n := RunNpc.new()
	n.model_path = model
	n.title = title
	n.prompt = prompt
	n.position = Vector3(0, 0, -1.0)
	add_child(n)
	return n


func _spawn_helper() -> void:
	var hid: StringName = spec.helper
	var info: Dictionary = Boons.HELPERS[hid]
	var n := _npc("res://assets/characters/helper_%s.glb" % hid, info.name, "[E] Talk")
	n.used.connect(func() -> void:
		var d := DialoguePanel.open(self, info.name, info.intro, "res://assets/portraits/%s.png" % info.portrait)
		d.finished.connect(func() -> void:
			Meta.meet_helper(hid)
			var cards: Array = []
			var pool: Array = (info.boons as Array).duplicate()
			Rewards._shuffle(pool, Run.rng)
			for b in pool.slice(0, 3):
				cards.append(Rewards.boon_card(b, controller))
			var panel := ChoicePanel.open(self, "%s's boon" % info.name, cards)
			panel.chosen.connect(func(i: int) -> void:
				cards[i].apply.call()
				cleared = false
				_on_clear())))


func _open_shop() -> void:
	var stock := Rewards.shop_stock(controller, Run.rng)
	var panel := ChoicePanel.open(self, "Night Market Stall — %d gold" % Run.gold, stock)
	panel.chosen.connect(func(i: int) -> void:
		var item: Dictionary = stock[i]
		if int(item.get("price", 0)) > 0:
			Run.gold -= int(item.price)
			item.apply.call()
			Events.run_reward.emit(&"shop", StringName(item.title)))


func _open_shrine() -> void:
	var opts := Rewards.shrine_options(controller, Run.rng)
	var panel := ChoicePanel.open(self, "Demon Shrine", opts)
	panel.chosen.connect(func(i: int) -> void:
		opts[i].apply.call()
		Events.run_reward.emit(&"shrine", StringName(opts[i].title)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not _ending and get_tree().get_nodes_in_group(&"modal").is_empty():
		var p := ChoicePanel.open(self, "Paused", [{"title": "Resume", "text": "", "icon": ""},
			{"title": "Abandon run", "text": "Back to the tea house. You keep shards for rooms cleared.", "icon": ""}])
		p.add_to_group(&"modal")
		p.chosen.connect(func(i: int) -> void:
			if i == 1:
				_ending = true
				Run.end_run(false)
				Run.go_hub())


# ---------------------------------------------------------------- life / death / victory
func _on_hero_died() -> void:
	if Run.extra_lives > 0:
		Run.extra_lives -= 1
		hero.revive(hero.health.max_hp * 0.5)
		Events.run_reward.emit(&"extra_life_used", &"")
		return
	_ending = true
	Run.end_run(false)
	_summary("You fell in the Night Market", "Rooms cleared: %d\nSpirit Shards earned: %d" % [Run.last_summary.rooms, Run.last_summary.shards])


func _on_boss_died() -> void:
	_ending = true
	Meta.record_boss(spec.boss)
	Events.boss_killed.emit(spec.boss)
	Run.room_cleared()
	Run.end_run(true)
	_summary("The Butcher King is beaten!", "Realm 1 cleared.\nSpirit Shards earned: %d\nThe Monkey talisman can now become him." % Run.last_summary.shards)


func _summary(title: String, text: String) -> void:
	get_tree().create_timer(1.5, false).timeout.connect(func() -> void:
		var panel := ChoicePanel.open(self, title, [{"title": "Back to the tea house", "text": text, "icon": ""}])
		panel.chosen.connect(func(_i: int) -> void: Run.go_hub()))
