class_name Hub
extends Control
## The tea house (meta hub): last run summary, Spirit Shards, boss ledger (Monkey), helpers + bonds,
## talisman unlocks, pick 3 talismans, start a run.

const BACKDROP := "res://assets/story/story_05_teahouse.png"
const MEI := "res://assets/portraits/portrait_auntie_mei.png"

var picked: Array = []
var _shards_lbl := Label.new()
var _pick_box := GridContainer.new()
var _start := Button.new()
var _status := Label.new()
var _blurb := Label.new()   ## focused talisman description (tooltips never show on gamepad)


func _ready() -> void:
	get_tree().paused = false
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.06, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if ResourceLoader.exists(BACKDROP):
		var art := TextureRect.new()
		art.texture = load(BACKDROP)
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.modulate = Color(0.45, 0.4, 0.4)   # dimmed so the menu reads on top
		add_child(art)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40
	scroll.offset_top = 24
	scroll.offset_right = -40
	scroll.offset_bottom = -24
	scroll.follow_focus = true
	add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	var title := Label.new()
	title.text = "The Tea House"
	title.theme_type_variation = &"Title"
	v.add_child(title)
	if not Run.last_summary.is_empty():
		var s := Run.last_summary
		var last := Label.new()
		last.text = ("Last run: VICTORY" if s.won else "Last run: fell") + " · rooms %d · +%d shards" % [s.rooms, s.shards]
		v.add_child(last)
	_shards_lbl.add_theme_font_size_override("font_size", 22)
	v.add_child(_shards_lbl)

	var ledger := Label.new()
	ledger.text = "Boss ledger (Monkey forms): " + (", ".join(Meta.boss_ledger.keys().map(func(k: StringName) -> String: return "%s ×%d" % [k, Meta.boss_ledger[k]])) if not Meta.boss_ledger.is_empty() else "none yet")
	v.add_child(ledger)

	v.add_child(_header("Helpers"))
	if Meta.helpers_met.is_empty():
		v.add_child(_note("Nobody yet. You'll meet them in the Night Market."))
	for h in Meta.helpers_met:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s · bond %d/3" % [Boons.HELPERS[h].name, int(Meta.bonds.get(h, 0))]
		l.custom_minimum_size = Vector2(320, 0)
		row.add_child(l)
		var b := Button.new()
		b.text = "Share a meal (%d shards)" % Meta.BOND_PRICE
		b.pressed.connect(func() -> void:
			if Meta.raise_bond(h):
				get_tree().reload_current_scene())
		row.add_child(b)
		v.add_child(row)

	v.add_child(_header("Talismans — pick 3 for the run"))
	_pick_box.columns = 6
	_pick_box.add_theme_constant_override("h_separation", 10)
	_pick_box.add_theme_constant_override("v_separation", 10)
	v.add_child(_pick_box)
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size = Vector2(0, 48)
	v.add_child(_blurb)
	picked = Run.talismans.filter(func(t: StringName) -> bool: return t in Meta.unlocked).slice(0, 3)
	if picked.is_empty():
		picked = [&"sheep", &"tiger", &"rat"]
	_build_picks()

	v.add_child(_status)
	_start.text = "Enter the Ember Night Market"
	_start.custom_minimum_size = Vector2(360, 56)
	_start.pressed.connect(start_run)
	v.add_child(_start)
	_start.grab_focus.call_deferred()
	var replay := Button.new()
	replay.text = "Replay the story"
	replay.custom_minimum_size = Vector2(220, 40)
	replay.pressed.connect(func() -> void:
		StoryIntro.replay = true
		get_tree().change_scene_to_file("res://scenes/run/intro.tscn"))
	v.add_child(replay)
	_refresh()
	if not Meta.has_seen(&"hub_intro"):
		_hub_intro.call_deferred()


func _hub_intro() -> void:
	DialoguePanel.sequence(self, [
		["Auntie Mei", "Drink. You'll need it. This tea house sits between the worlds, so the demons can't reach you here. Out there is another matter.", MEI],
		["Auntie Mei", "Those paper talismans in your pocket are real. Pick three to carry. Each one wakes up a different trick, and they recover on their own after you use them.", MEI],
		["Auntie Mei", "When you fall out there, you'll wake up here. Bring back Spirit Shards and I'll teach the other talismans to listen to you. Now go. The Night Market is waiting.", MEI],
	], func() -> void: Meta.mark_seen(&"hub_intro"))


func _header(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.theme_type_variation = &"Header"
	return l


func _note(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.modulate = Color(1, 1, 1, 0.6)
	return l


func _build_picks() -> void:
	for c in _pick_box.get_children():
		c.queue_free()
	for id in Zodiac.ALL:
		var t := Zodiac.make(id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(170, 76)
		b.toggle_mode = true
		var unlocked: bool = id in Meta.unlocked
		b.button_pressed = id in picked
		var path := "res://assets/icons/icon_talisman_%s.png" % id
		if ResourceLoader.exists(path):
			b.icon = load(path)
			b.expand_icon = true
		b.text = t.title if unlocked else "%s (%d shards)" % [t.title, Meta.TALISMAN_PRICE]
		b.tooltip_text = t.blurb
		b.focus_entered.connect(func() -> void: _blurb.text = "%s: %s" % [t.title, t.blurb])
		b.mouse_entered.connect(func() -> void: _blurb.text = "%s: %s" % [t.title, t.blurb])
		b.modulate = Color(1, 1, 1) if unlocked else Color(0.6, 0.6, 0.6)
		b.pressed.connect(_on_pick.bind(id, b))
		_pick_box.add_child(b)


func _on_pick(id: StringName, b: Button) -> void:
	if id not in Meta.unlocked:
		Meta.buy_talisman(id)
		_build_picks()
		_refresh()
		var i := Zodiac.ALL.find(id)
		await get_tree().process_frame
		if i >= 0 and i < _pick_box.get_child_count():
			(_pick_box.get_child(i) as Control).grab_focus()   # keep gamepad focus after rebuild
		return
	if id in picked:
		picked.erase(id)
	elif picked.size() < 3:
		picked.append(id)
	b.button_pressed = id in picked
	_refresh()


func _refresh() -> void:
	_shards_lbl.text = "Spirit Shards: %d   ·   runs %d   ·   best depth %d rooms" % [Meta.shards, Meta.runs, Meta.best_room]
	_status.text = "Equipped: " + ", ".join(picked.map(func(x: StringName) -> String: return String(x).capitalize()))
	_start.disabled = picked.is_empty()


func start_run() -> void:
	Run.start_run(picked)
	get_tree().change_scene_to_file(Run.ROOM_SCENE)
