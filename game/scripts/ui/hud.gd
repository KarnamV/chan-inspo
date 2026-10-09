class_name Hud
extends CanvasLayer
## HUD: HP, spirit, 3 talisman slots (icon, key, cost, ready), body/prop status, Monkey + Tiger
## timers, controls hint.

const SLOT_KEYS := ["Ctrl+J", "Ctrl+K", "Ctrl+L"]

var controller: PlayerController
var hp_bar := ProgressBar.new()
var spirit_bar := ProgressBar.new()
var info := Label.new()
var hint := Label.new()
var slots_box := HBoxContainer.new()
var _slot_nodes: Array = []   # [panel, icon, label]


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 18)
	box.custom_minimum_size = Vector2(340, 0)
	add_child(box)
	for pair in [[hp_bar, Color(0.85, 0.2, 0.2)], [spirit_bar, Color(0.25, 0.85, 0.55)]]:
		var bar: ProgressBar = pair[0]
		bar.custom_minimum_size = Vector2(340, 18)
		bar.show_percentage = false
		var sb := StyleBoxFlat.new()
		sb.bg_color = pair[1]
		bar.add_theme_stylebox_override("fill", sb)
		box.add_child(bar)
	info.add_theme_font_size_override("font_size", 18)
	box.add_child(info)
	slots_box.add_theme_constant_override("separation", 10)
	box.add_child(slots_box)
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(1, 1, 1, 0.7)
	hint.text = "WASD move · J light · K heavy · L grab/throw · Space dodge · I parry · Shift+button chi · Ctrl+J/K/L talismans · 1-0,-,= swap talismans · R reset"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.position = Vector2(20, -34)
	add_child(hint)
	Events.talismans_changed.connect(_rebuild_slots)


func bind(c: PlayerController) -> void:
	controller = c
	_rebuild_slots()


func _rebuild_slots() -> void:
	for n in slots_box.get_children():
		n.queue_free()
	_slot_nodes.clear()
	if controller == null:
		return
	for i in controller.equipped.size():
		var t := controller.equipped[i]
		var panel := VBoxContainer.new()
		panel.custom_minimum_size = Vector2(104, 0)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var path := "res://assets/icons/icon_talisman_%s.png" % t.id
		if ResourceLoader.exists(path):
			icon.texture = load(path)
		panel.add_child(icon)
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(lbl)
		slots_box.add_child(panel)
		_slot_nodes.append([panel, icon, lbl, t])


func _process(_d: float) -> void:
	if controller == null or controller.controlled == null:
		return
	var f := controller.controlled
	hp_bar.max_value = f.health.max_hp
	hp_bar.value = f.health.hp
	spirit_bar.max_value = controller.spirit_max
	spirit_bar.value = controller.spirit
	var held := String(f.held_prop.data.id) if f.held_prop and is_instance_valid(f.held_prop) else "bare hands"
	if f.held_prop and is_instance_valid(f.held_prop) and f.held_prop.ignited > 0.0:
		held += " (burning)"
	var who := "Jackie"
	if controller.host:
		who = "POSSESSING %s" % String(f.data.id).to_upper()
	var monkey := controller.talisman(&"monkey") as Zodiac.Monkey
	if monkey and monkey.form:
		who = "MONKEY: %s · %d attacks before you lose yourself" % [String(f.data.id).to_upper(), monkey.attacks_left]
	var tiger := controller.talisman(&"tiger") as Zodiac.Tiger
	if tiger and tiger.twin:
		who = "TIGER %s · %.0fs" % ["YANG" if f == controller.hero else "YIN", tiger.left]
	info.text = "%s  ·  %s" % [who, held]
	if Run.active:
		info.text += "\nRoom %d/%d  ·  %d gold  ·  %d extra lives" % [Run.room_i + 1, Run.REALM1.size(), Run.gold, Run.extra_lives]
	for i in _slot_nodes.size():
		var t: Talisman = _slot_nodes[i][3]
		var lbl: Label = _slot_nodes[i][2]
		var icon: TextureRect = _slot_nodes[i][1]
		var cost := "" if not t.is_active_talisman() else " · %d" % int(t.cost)
		lbl.text = "%s%s\n%s" % [t.title, cost, SLOT_KEYS[i] if t.is_active_talisman() else "passive"]
		var ready := not t.is_active_talisman() or controller.spirit >= t.cost
		icon.modulate = Color(1, 1, 1, 1) if ready else Color(0.45, 0.45, 0.45, 0.8)
