class_name StoryIntro
extends Control
## Opening story: five illustrated cards with slow camera drift and captions, before the tea house.
## Main scene. Shown once (Meta "intro"); the hub can replay it. Confirm = next card, hold cancel = skip.

const NEXT_SCENE := "res://scenes/run/hub.tscn"
const CARDS := [
	["res://assets/story/story_01_set.png",
		"Hong Kong. Night shoot. Take forty-seven.\nJackie has been a stunt double for nine years. Never the star. Always the guy who goes through the window."],
	["res://assets/story/story_02_trunk.png",
		"Between takes he finds the prop master's old trunk: twelve paper talismans, one for each animal of the zodiac.\n\"Don't touch those,\" the prop master told him. Jackie opens it anyway."],
	["res://assets/story/story_03_action.png",
		"\"Action!\"\nThe lanterns flare red. The extras' masks stop being masks. The trunk bursts open and the talismans scatter into the dark. The street folds in on itself, and the crew is gone."],
	["res://assets/story/story_04_realm.png",
		"The Demon Realm. A twisted copy of the night market, ruled by the Butcher King.\nBeyond it lie six more realms, and a Demon Emperor who collects fighters like trophies."],
	["res://assets/story/story_05_teahouse.png",
		"Between the worlds stands a tea house. Auntie Mei, a ghost who has poured tea here for sixty years, slides a cup across the table.\n\"No wires here, kid. No retakes. Every chair is a weapon. Break your way out.\""],
]
const CHARS_PER_SEC := 55.0
const SKIP_HOLD := 0.8

static var replay := false   ## set by the hub's "Replay intro" button

var _i := -1
var _img: TextureRect
var _caption: Label
var _hint: Label
var _skip_bar: ProgressBar
var _fade: ColorRect
var _drift: Tween
var _typing := 0.0
var _skip_t := 0.0
var _leaving := false


func _ready() -> void:
	if Meta.has_seen(&"intro") and not replay:
		get_tree().change_scene_to_file.call_deferred(NEXT_SCENE)
		return
	replay = false
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_img = TextureRect.new()
	_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_img)
	# letterbox + caption band
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.92 if top else 0.78)
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.74
		bar.anchor_bottom = 0.07 if top else 1.0
		add_child(bar)
	_caption = Label.new()
	_caption.anchor_left = 0.1
	_caption.anchor_right = 0.9
	_caption.anchor_top = 0.765
	_caption.anchor_bottom = 0.95
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 24)
	_caption.add_theme_color_override("font_color", Color(0.98, 0.93, 0.85))
	add_child(_caption)
	_hint = Label.new()
	_hint.anchor_left = 0.5
	_hint.anchor_right = 0.98
	_hint.anchor_top = 0.955
	_hint.anchor_bottom = 0.995
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.modulate = Color(1, 1, 1, 0.55)
	add_child(_hint)
	_skip_bar = ProgressBar.new()
	_skip_bar.show_percentage = false
	_skip_bar.max_value = SKIP_HOLD
	_skip_bar.anchor_left = 0.02
	_skip_bar.anchor_right = 0.2
	_skip_bar.anchor_top = 0.965
	_skip_bar.anchor_bottom = 0.98
	_skip_bar.visible = false
	add_child(_skip_bar)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_next()


func _next() -> void:
	_i += 1
	if _i >= CARDS.size():
		_finish()
		return
	var tw := create_tween()
	if _i > 0:
		tw.tween_property(_fade, "color:a", 1.0, 0.35)
	tw.tween_callback(_show_card)
	tw.tween_property(_fade, "color:a", 0.0, 0.6)


func _show_card() -> void:
	var path: String = CARDS[_i][0]
	_img.texture = load(path) if ResourceLoader.exists(path) else null
	_caption.text = CARDS[_i][1]
	_caption.visible_ratio = 0.0
	_typing = 0.0
	# slow push-in, alternating drift direction
	if _drift:
		_drift.kill()
	_img.pivot_offset = size * 0.5
	_img.scale = Vector2.ONE * 1.04
	_img.position = Vector2(-12.0 if _i % 2 == 0 else 12.0, 0)
	_drift = create_tween().set_parallel()
	_drift.tween_property(_img, "scale", Vector2.ONE * 1.12, 12.0).set_trans(Tween.TRANS_SINE)
	_drift.tween_property(_img, "position", Vector2(12.0 if _i % 2 == 0 else -12.0, -8.0), 12.0)


func _process(delta: float) -> void:
	if _leaving or _caption == null:
		return
	var n := _caption.text.length()
	if _caption.visible_ratio < 1.0:
		_typing += delta * CHARS_PER_SEC
		_caption.visible_ratio = minf(_typing / maxf(n, 1), 1.0)
	var pad := Inputs.using_pad
	_hint.text = "%s  next     hold %s  skip" % ["A" if pad else "Enter", "B" if pad else "Esc"]
	if Input.is_action_pressed(&"ui_cancel") or Input.is_action_pressed(&"pause"):
		_skip_t += delta
		_skip_bar.visible = true
		_skip_bar.value = _skip_t
		if _skip_t >= SKIP_HOLD:
			_finish()
	else:
		_skip_t = 0.0
		_skip_bar.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	var go: bool = event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"attack_light") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not go:
		return
	get_viewport().set_input_as_handled()
	if _caption.visible_ratio < 1.0:
		_caption.visible_ratio = 1.0   # first press finishes the line
		_typing = _caption.text.length()
	else:
		_next()


func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	Meta.mark_seen(&"intro")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.5)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(NEXT_SCENE))
