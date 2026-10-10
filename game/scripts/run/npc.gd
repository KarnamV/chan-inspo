class_name RunNpc
extends Node3D
## A talkable spot in a run room: helper, shopkeeper, shrine altar. Shows "[E] Talk" (or the pad button) when the player
## is near; `interact()` fires `used` (the room decides what happens).

signal used

@export var model_path := ""
@export var title := ""
@export var prompt := "Talk"   ## verb; the interact button is prefixed per device
@export var range := 2.6

var _prompt: Label3D
var _used_once := false
var reusable := false
var anim: AnimDriver


func _ready() -> void:
	add_to_group(&"npcs")
	if model_path != "" and ResourceLoader.exists(model_path):
		var m: Node3D = load(model_path).instantiate()
		add_child(m)
		anim = AnimDriver.new(m)
		anim.play(&"talk" if anim.resolve(&"talk") == &"talk" else &"idle")
	var name_lbl := Label3D.new()
	name_lbl.text = title
	name_lbl.font_size = 56
	name_lbl.outline_size = 10
	name_lbl.modulate = Color(1.0, 0.8, 0.4)
	name_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_lbl.position.y = 2.5
	add_child(name_lbl)
	_prompt = Label3D.new()
	_prompt.text = prompt
	_prompt.font_size = 44
	_prompt.outline_size = 10
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.position.y = 2.15
	_prompt.visible = false
	add_child(_prompt)


func near(f: Node3D) -> bool:
	return f != null and global_position.distance_to(f.global_position) < range


func interact() -> void:
	if _used_once and not reusable:
		return
	_used_once = true
	used.emit()


func _process(_d: float) -> void:
	var lvl := get_tree().get_first_node_in_group(&"level_root") as Arena
	if lvl == null or lvl.controller == null:
		return
	var f := lvl.controller.controlled
	_prompt.visible = near(f) and (reusable or not _used_once)
	_prompt.text = "[%s] %s" % [Inputs.label(&"interact"), prompt]
	if _prompt.visible and Inputs.just_pressed(&"interact"):
		interact()
