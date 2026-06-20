extends Node2D

const HIT_SEARCH_RADIUS: float = 120.0

@onready var player: CharacterBody2D = $Player
@onready var enemies_container: Node2D = $Enemies
@onready var stance_label: Label = $HUD/StanceLabel
@onready var room_renderer: Node2D = $RoomRenderer
@onready var room_manager: Node  = $RoomManager

# Talisman scripts (preloaded for runtime instantiation).
const TalismanYinYangScript = preload("res://scripts/TalismanYinYang.gd")
const DragonClawScript      = preload("res://scripts/DragonClaw.gd")
const PhoenixFeatherScript  = preload("res://scripts/PhoenixFeather.gd")
const TalismanManagerScript = preload("res://scripts/TalismanManager.gd")
const HUDScene              = preload("res://scenes/HUD.tscn")

# YinYang ref kept for stance-label callbacks (it has stance_display_text()).
var _yin_yang: Node = null
var _talisman_manager: Node = null
var _hud: CanvasLayer = null

# Room-clear tracking.
var _total_enemies: int = 0
var _enemies_dead:  int = 0

# Death-transition state — guards against double-firing if signals stack.
var _death_triggered: bool = false

# Fade overlay for death sequence (separate from RoomManager's per-room fader).
var _death_canvas: CanvasLayer = null
var _death_overlay: ColorRect = null


func _ready() -> void:
	player.attack_landed.connect(_on_attack_landed)
	player.player_died.connect(_on_player_died)
	_setup_talismans()
	_setup_hud()
	_setup_room_manager()
	_connect_enemy_signals()
	_build_death_overlay()


func _setup_talismans() -> void:
	# --- Instantiate all three starting talismans as children of the player. ---
	_yin_yang = TalismanYinYangScript.new()
	_yin_yang.name = "TalismanYinYang"
	player.add_child(_yin_yang)

	var dragon_claw: Node = DragonClawScript.new()
	dragon_claw.name = "DragonClaw"
	player.add_child(dragon_claw)

	var phoenix_feather: Node = PhoenixFeatherScript.new()
	phoenix_feather.name = "PhoenixFeather"
	player.add_child(phoenix_feather)

	# --- Create TalismanManager and attach it. ---
	_talisman_manager = TalismanManagerScript.new()
	_talisman_manager.name = "TalismanManager"
	player.add_child(_talisman_manager)
	_talisman_manager.setup(player, [_yin_yang, dragon_claw, phoenix_feather])
	player.talisman_manager = _talisman_manager

	# --- Apply initial YinYang LIGHT-stance stats without a toggle flash. ---
	player.stance_speed_mult  = _yin_yang.LIGHT_SPEED_MULT
	player.stance_damage_mult = _yin_yang.LIGHT_DAMAGE_MULT
	var sprite: Node = player.get_node("Sprite2D")
	if sprite:
		sprite.modulate = _yin_yang.LIGHT_TINT

	# --- Wire signals. ---
	_yin_yang.stance_changed.connect(_on_stance_changed)
	stance_label.text = _yin_yang.stance_display_text()

	# Manager -> HUD talisman label (HUD is added in _setup_hud below, so
	# we connect the signal here but the HUD prime happens there after add_child).
	_talisman_manager.active_talisman_changed.connect(_on_active_talisman_changed)


func _setup_hud() -> void:
	# Instantiate the HUD scene and add it as a sibling CanvasLayer.
	# HUD.connect_player wires health_updated, spirit_updated, combo_updated.
	_hud = HUDScene.instantiate()
	add_child(_hud)
	_hud.connect_player(player)
	# Prime the talisman label with the first slot name.
	if _talisman_manager != null:
		_hud.set_active_talisman_name(_talisman_manager.active_display_name())


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


# ---------------------------------------------------------------------------
# Enemy signal wiring + room-clear tracking
# ---------------------------------------------------------------------------

func _connect_enemy_signals() -> void:
	# Count and connect all EnemyBase children in the Enemies container.
	# This must be called after _ready() so the enemy nodes are fully initialised.
	for enemy in enemies_container.get_children():
		if enemy.has_signal("enemy_died"):
			_total_enemies += 1
			enemy.enemy_died.connect(_on_enemy_died)

	print("[TestRoom] %d enemies registered for room-clear tracking." % _total_enemies)


func _on_enemy_died(_enemy: Node) -> void:
	_enemies_dead += 1
	RunStats.enemies_killed += 1
	print("[TestRoom] Enemy down (%d / %d)." % [_enemies_dead, _total_enemies])

	if _enemies_dead >= _total_enemies:
		_on_room_cleared()


func _on_room_cleared() -> void:
	print("[TestRoom] Room cleared! All %d enemies defeated." % _total_enemies)
	# Unlock exits via RoomManager — mark the current room as cleared so the
	# boss-lock check (which gates on is_visited) can be satisfied.
	# RoomManager already sets is_visited when a room is entered; for a
	# combat-gated room we additionally want to flag it explicitly so future
	# logic can distinguish visited vs. cleared.
	var cur_room: RoomData = room_manager.current_room()
	if cur_room != null:
		cur_room.is_visited = true
		print("[TestRoom] Exit doors unlocked.")


# ---------------------------------------------------------------------------
# Attack-landed: find nearest enemy and deal damage
# ---------------------------------------------------------------------------

func _on_attack_landed(_attack_name: String, damage: int, hit_position: Vector2) -> void:
	var nearest: CharacterBody2D = null
	var best_dist: float = HIT_SEARCH_RADIUS

	for enemy in enemies_container.get_children():
		if not enemy is CharacterBody2D:
			continue
		var d: float = enemy.global_position.distance_to(hit_position)
		if d < best_dist:
			best_dist = d
			nearest = enemy

	if nearest != null:
		nearest.take_damage(damage)


# ---------------------------------------------------------------------------
# Label callbacks
# ---------------------------------------------------------------------------

func _on_stance_changed(_new_stance: int) -> void:
	stance_label.text = _yin_yang.stance_display_text()


func _on_room_entered(room_data: RoomData) -> void:
	# Update the stance label to show both stance and room type.
	# Format: "☯ LIGHT  |  [COMBAT]"
	var stance_text: String = _yin_yang.stance_display_text() if _yin_yang != null else ""
	stance_label.text = "%s  |  [%s]" % [stance_text, room_data.type_name()]


func _on_active_talisman_changed(talisman: Node) -> void:
	if _hud == null:
		return
	var display_name: String = ""
	if talisman != null and talisman.has_method("talisman_display_name"):
		display_name = talisman.talisman_display_name()
	elif talisman != null:
		display_name = talisman.name
	_hud.set_active_talisman_name(display_name)


# ---------------------------------------------------------------------------
# Death sequence
# ---------------------------------------------------------------------------

func _build_death_overlay() -> void:
	# A dedicated CanvasLayer above everything (layer 200) for the death fade.
	# Kept separate from RoomManager's fade overlay (layer 100) so neither
	# interferes with the other.
	_death_canvas = CanvasLayer.new()
	_death_canvas.layer = 200
	_death_canvas.name = "DeathFadeCanvas"
	add_child(_death_canvas)

	_death_overlay = ColorRect.new()
	_death_overlay.name = "DeathFadeOverlay"
	_death_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_death_overlay.size = Vector2(1280, 720)
	_death_overlay.position = Vector2.ZERO
	_death_overlay.modulate.a = 0.0   # start transparent
	_death_canvas.add_child(_death_overlay)


func _on_player_died() -> void:
	if _death_triggered:
		return
	_death_triggered = true

	print("[TestRoom] Player died — starting death sequence.")

	# Freeze player physics and input for the cinematic pause.
	player.set_process_unhandled_input(false)
	player.set_physics_process(false)

	# 0.5 s dramatic pause — let the death flash finish playing.
	await get_tree().create_timer(0.5).timeout

	# Fade to black over 0.5 s using our dedicated death overlay.
	var tween: Tween = create_tween()
	tween.tween_property(_death_overlay, "modulate:a", 1.0, 0.5)
	await tween.finished

	# Hand off to the Hub scene — RunStats already has the run numbers.
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")
