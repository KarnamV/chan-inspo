extends Node
## M4 full-run bot: hub-less run through all 10 rooms of realm 1 to the Butcher King and back.
##   godot --headless --path . --fixed-fps 60 res://tests/bot/bot_run.tscn
## Saving is disabled (doesn't touch the player's meta save). Exit 0 = all checks pass.

const LIMIT_S := 900.0

var t := 0.0
var room: RunRoom
var room_types: Array = []
var rewards: Array = []
var panels_chosen := 0
var dialogues := 0
var boss_killed := false
var ended := false
var victory := false
var back_in_hub := false
var bot: Bot
var _done := false
var _moved := false


class Bot:
	extends Brain
	var tick := 0
	var host: Node

	func think(f: Fighter, _delta: float) -> void:
		tick += 1
		var r := host.room as RunRoom
		if r == null:
			return
		var pc := r.controller
		# Sheep when possible (exercise possession in real rooms)
		if pc.host == null and pc.has_talisman(&"sheep") and pc.sheep_target() and pc.spirit >= pc.sheep_cost and tick % 30 == 0:
			pc.try_possess()
			return
		var e := _nearest(f, &"enemy")
		if e:
			if f.held_prop == null and pc.host == null:
				var p := f.nearest_prop()
				if p and tick % 20 == 0:
					f.request_grab()
			var from_e := f.global_position - e.global_position
			from_e.y = 0.0
			if e.data.front_block and e.state != Fighter.State.STAGGER and e.facing.dot(from_e.normalized()) > 0.3 and from_e.length() < 4.0:
				if f.held_prop:
					if from_e.length() < 2.2:
						f.facing = -from_e.normalized()
						f.request_heavy()   # guard break, then follow up
					else:
						f.intent_move = -from_e.normalized()   # step in for the heavy
				else:
					f.intent_move = e.facing.cross(Vector3.UP).normalized()   # get around it
					if tick % 40 == 0:
						f.request_dodge()
				return
			if _go(f, e.global_position, 2.0 if e.data.boss else 1.6) and tick % 12 == 0:
				if f.held_prop:
					f.request_heavy() if tick % 36 == 0 else f.request_light()
				else:
					f.request_light() if tick % 24 else f.request_heavy()
			return
		# no enemies: talk to NPCs, else take a door
		for n in f.get_tree().get_nodes_in_group(&"npcs"):
			var npc := n as RunNpc
			if npc and (not npc._used_once):
				if _go(f, npc.global_position, 2.0):
					npc.interact()
				return
		if not r.doors.is_empty():
			var d: RunDoor = r.doors[0]
			if is_instance_valid(d):
				f.intent_move = (d.global_position - f.global_position).normalized() * Vector3(1, 0, 1)

	func _go(f: Fighter, at: Vector3, within: float) -> bool:
		var to := at - f.global_position
		to.y = 0.0
		if to.length() <= within:
			if to.length() > 0.01:
				f.facing = to.normalized()
			return true
		f.intent_move = to.normalized()
		return false

	func _nearest(f: Fighter, _kind: StringName) -> Fighter:
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # panels pause the tree; the bot must still click them
	Juice.enabled = false
	Meta.save_enabled = false
	Meta.reset_all()
	Meta.unlocked = Zodiac.ALL.duplicate()
	Events.run_reward.connect(func(kind: StringName, id: StringName) -> void: rewards.append("%s:%s" % [kind, id]))
	Events.boss_killed.connect(func(_id: StringName) -> void: boss_killed = true)
	bot = Bot.new()
	bot.host = self
	_reparent_to_root.call_deferred()


func _reparent_to_root() -> void:
	# survive change_scene: live under the root, not the current scene
	var r := get_tree().root
	get_parent().remove_child(self)
	r.add_child(self)
	_moved = true
	Run.start_run([&"sheep", &"tiger", &"rat"], 7)
	for arg in OS.get_cmdline_user_args():   # e.g. -- --start=9 jumps to the boss room (captures)
		if arg.begins_with("--start="):
			Run.room_i = int(arg.split("=")[1])
	get_tree().change_scene_to_file(Run.ROOM_SCENE)


func _physics_process(delta: float) -> void:
	if _done or not _moved:
		return
	t += delta
	var cs := get_tree().current_scene
	if cs is Hub:
		back_in_hub = true
		_report()
		return
	var r := cs as RunRoom
	if r and r != room and r.controller:
		room = r
		room_types.append(r.spec.type)
		print("t=%.0f room %d: %s" % [t, Run.room_i + 1, r.spec.type])
		r.controller.brain = bot
		r.hero.set_brain(bot)
		r.hero.health.max_hp = 5000.0
		r.hero.health.hp = 5000.0
		r.hero.dmg_mult_physical = 3.0
		r.hero.dmg_mult_magic = 3.0
	for n in get_tree().root.find_children("*", "DialoguePanel", true, false):
		dialogues += 1
		(n as DialoguePanel).close()
	for n in get_tree().root.find_children("*", "ChoicePanel", true, false):
		var p := n as ChoicePanel
		if p.is_queued_for_deletion():
			continue
		var pick := 0
		for i in p.cards.size():
			if p.cards[i].get("enabled", true):
				pick = i
				break
		panels_chosen += 1
		p.choose(pick)
	if Run.last_summary.size() > 0 and not Run.active:
		ended = true
		victory = Run.last_summary.won
	if room and fmod(t, 30.0) < delta:
		var alive: Array = []
		for n in get_tree().get_nodes_in_group(&"fighters"):
			var o := n as Fighter
			if o and o.team == Fighter.Team.ENEMY and not o.is_dead():
				alive.append("%s@(%.0f,%.0f) st%d hp%.0f face%s" % [o.data.id, o.global_position.x, o.global_position.z, o.state, o.health.hp, o.facing.snapped(Vector3.ONE * 0.1)])
		var hh := room.hero
		print("hero@(%.0f,%.0f) st%d prop=%s" % [hh.global_position.x, hh.global_position.z, hh.state, hh.held_prop != null])
		print("t=%.0f still here: enemies=%s doors=%d npcs_unused=%d" % [t, alive, room.doors.size(),
			get_tree().get_nodes_in_group(&"npcs").filter(func(x: Node) -> bool: return not x._used_once).size()])
	if t >= LIMIT_S:
		_report()


func _report() -> void:
	if _done:
		return
	_done = true
	var met := Meta.helpers_met
	var checks := [
		["visited all 10 rooms", room_types.size() >= 10],
		["met the Stunt Coordinator", &"stunt_coordinator" in met],
		["met the Street Chef", &"street_chef" in met],
		["visited the shop", "shop" in room_types],
		["visited a shrine or vault", "shrine" in room_types or "vault" in room_types],
		["took 5+ rewards", rewards.size() >= 5],
		["beat the Butcher King", boss_killed],
		["boss recorded in the ledger (Monkey form)", Meta.boss_ledger.has(&"butcher_king")],
		["run ended in victory", victory],
		["returned to the tea house", back_in_hub],
	]
	print("BOT RUN after %.0fs sim: rooms=%s" % [t, room_types])
	print("rewards: %s" % [rewards])
	print("shards: %d  ledger: %s" % [Meta.shards, Meta.boss_ledger])
	var ok := true
	for c in checks:
		print(("PASS  " if c[1] else "FAIL  ") + c[0])
		ok = ok and c[1]
	print("BOT RESULT: " + ("ALL PASS" if ok else "FAILURES"))
	get_tree().quit(0 if ok else 1)
