extends Node2D

const HIT_SEARCH_RADIUS: float = 120.0

@onready var player: CharacterBody2D = $Player
@onready var dummies_container: Node2D = $Dummies
@onready var stance_label: Label = $HUD/StanceLabel
@onready var room_renderer: Node2D = $RoomRenderer
@onready var room_manager: Node  = $RoomManager

# Pre-load the talisman script so we can instantiate it at runtime.
const TalismanYinYangScript = preload("res://scripts/TalismanYinYang.gd")
const HUDScene = preload("res://scenes/HUD.tscn")

var _talisman: Node = null
var _hud: CanvasLayer = null


func _ready() -> void:
	player.attack_landed.connect(_on_attack_landed)
	_setup_talisman()
	_setup_hud()
	_setup_room_manager()


func _setup_talisman() -> void:
	# Instantiate the Yin-Yang talisman as a child of the player node so it
	# shares the player's lifetime and can access player methods directly.
	_talisman = TalismanYinYangScript.new()
	_talisman.name = "TalismanYinYang"
	player.add_child(_talisman)

	# Give the player a reference so _unhandled_input can call activate().
	player.active_talisman = _talisman

	# Wire stance label updates BEFORE applying the initial stance so the
	# label update fires correctly if _apply_stance emits stance_changed.
	_talisman.stance_changed.connect(_on_stance_changed)

	# Push LIGHT-stance multipliers directly — talisman defaults to LIGHT
	# so no toggle needed; just apply values and tint without a flash.
	player.stance_speed_mult  = _talisman.LIGHT_SPEED_MULT
	player.stance_damage_mult = _talisman.LIGHT_DAMAGE_MULT
	var sprite: Node = player.get_node("Sprite2D")
	if sprite:
		sprite.modulate = _talisman.LIGHT_TINT

	# Initialise label text to match talisman's default stance.
	stance_label.text = _talisman.stance_display_text()


func _setup_hud() -> void:
	# Instantiate the HUD scene and add it as a sibling CanvasLayer.
	# HUD.connect_player wires health_updated, spirit_updated, combo_updated.
	_hud = HUDScene.instantiate()
	add_child(_hud)
	_hud.connect_player(player)


func _setup_room_manager() -> void:
	# Give RoomManager its required references.
	room_manager.room_renderer = room_renderer
	room_manager.player        = player

	# Connect door_entered on the renderer to room_manager.travel_to_exit.
	room_renderer.door_entered.connect(room_manager.travel_to_exit)

	# Connect room_entered signal to update the stance label area with room info.
	room_manager.room_entered.connect(_on_room_entered)

	# Generate a fixed-seed run (seed 42) so testing is deterministic.
	# Change the seed to explore different graph layouts.
	room_manager.generate_run(42)


func _on_stance_changed(_new_stance: int) -> void:
	stance_label.text = _talisman.stance_display_text()


func _on_room_entered(room_data: RoomData) -> void:
	# Update the stance label to show both stance and room type.
	# Format: "☯ LIGHT  |  [COMBAT]"
	var stance_text: String = _talisman.stance_display_text() if _talisman != null else ""
	stance_label.text = "%s  |  [%s]" % [stance_text, room_data.type_name()]


func _on_attack_landed(attack_name: String, damage: int, hit_position: Vector2) -> void:
	var nearest: CharacterBody2D = null
	var best_dist: float = HIT_SEARCH_RADIUS

	for dummy in dummies_container.get_children():
		if not dummy is CharacterBody2D:
			continue
		var d: float = dummy.global_position.distance_to(hit_position)
		if d < best_dist:
			best_dist = d
			nearest = dummy

	if nearest != null:
		nearest.take_damage(damage)
