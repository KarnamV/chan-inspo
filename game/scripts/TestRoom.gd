extends Node2D

const HIT_SEARCH_RADIUS: float = 120.0

@onready var player: CharacterBody2D = $Player
@onready var dummies_container: Node2D = $Dummies
@onready var stance_label: Label = $HUD/StanceLabel

# Pre-load the talisman script so we can instantiate it at runtime.
const TalismanYinYangScript = preload("res://scripts/TalismanYinYang.gd")

var _talisman: Node = null


func _ready() -> void:
	player.attack_landed.connect(_on_attack_landed)
	_setup_talisman()


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


func _on_stance_changed(_new_stance: int) -> void:
	stance_label.text = _talisman.stance_display_text()


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
