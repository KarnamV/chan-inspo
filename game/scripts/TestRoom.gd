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
const GoldPickupScript      = preload("res://scripts/GoldPickup.gd")
const ShopUIScript          = preload("res://scripts/ShopUI.gd")
const ShrineUIScript        = preload("res://scripts/ShrineUI.gd")
const TemptationUIScript    = preload("res://scripts/TemptationUI.gd")
const PauseMenuScript        = preload("res://scripts/PauseMenu.gd")
const TigerFangScript       = preload("res://scripts/TigerFang.gd")
const SnakeCoilScript       = preload("res://scripts/SnakeCoil.gd")
const MonkeyStepScript      = preload("res://scripts/MonkeyStep.gd")
const CraneWingScript       = preload("res://scripts/CraneWing.gd")
const DemonSealScript       = preload("res://scripts/DemonSeal.gd")
const VoidStarScript        = preload("res://scripts/VoidStar.gd")
const HeavensTokenScript    = preload("res://scripts/HeavensToken.gd")
const MiniBossScene         = preload("res://scenes/MiniBoss.tscn")
const RealmDefs             = preload("res://scripts/RealmDefs.gd")
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

# Overlay guard — only one interactive overlay (shop/shrine) open at a time.
var _overlay_open: bool = false

# Pause-menu guard — true while the Esc pause menu is open.
var _paused_menu_open: bool = false

# Mini-boss guard — at most one realm-boundary mini-boss active at a time.
var _miniboss_alive: bool = false

# Fade overlay for death sequence (separate from RoomManager's per-room fader).
var _death_canvas: CanvasLayer = null
var _death_overlay: ColorRect = null


func _ready() -> void:
	player.attack_landed.connect(_on_attack_landed)
	player.player_died.connect(_on_player_died)
	_setup_talismans()
	_setup_hud()
	_apply_meta_upgrades()
	_apply_realm_theme()
	_setup_room_manager()
	_connect_enemy_signals()
	_build_death_overlay()


## Theme the run to the selected realm: tint the floor and scale enemy HP/damage
## by the realm difficulty. Must run before _setup_room_manager (which triggers
## the first render_room) and before enemies engage.
func _apply_realm_theme() -> void:
	var realm: Dictionary = RealmDefs.get_realm(MetaProgress.selected_realm)
	room_renderer.realm_floor_color = realm["floor"]

	var hp_mult: float = realm["hp_mult"]
	var dmg_mult: float = realm["dmg_mult"]
	for e in enemies_container.get_children():
		if not ("max_hp" in e):
			continue
		e.max_hp = int(e.max_hp * hp_mult)
		e.current_hp = e.max_hp
		e.attack_dmg = int(e.attack_dmg * dmg_mult)
		if e.has_method("_refresh_label"):
			e._refresh_label()

	_announce("Realm %d — %s" % [MetaProgress.selected_realm + 1, realm["name"]], realm["accent"])
	AudioManager.play_music("realm_%d" % MetaProgress.selected_realm)


## Apply persistent meta-upgrades (bought in the Hub) to this run's player.
## Called after the HUD is wired so the boosted Max HP shows immediately.
func _apply_meta_upgrades() -> void:
	var bonus_hp: int = MetaProgress.bonus_max_hp()
	if bonus_hp > 0:
		player.add_max_hp(bonus_hp)   # also grants the HP, so the run starts full
	player.permanent_damage_mult *= MetaProgress.damage_mult()
	var sm: float = MetaProgress.speed_mult()
	player.speed_run  *= sm
	player.speed_walk *= sm


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
	# Meta-upgrade "Talisman Attunement" grants extra starting slots.
	_talisman_manager.max_slots = 3 + MetaProgress.bonus_slots()
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


func _on_enemy_died(enemy: Node) -> void:
	_enemies_dead += 1
	RunStats.enemies_killed += 1
	print("[TestRoom] Enemy down (%d / %d)." % [_enemies_dead, _total_enemies])

	_drop_gold(enemy)

	# Mini-bosses drop a guaranteed reward on top of their gold.
	if "is_miniboss" in enemy and enemy.is_miniboss:
		_miniboss_alive = false
		_grant_miniboss_reward()
		_try_unlock_next_realm()

	if _enemies_dead >= _total_enemies:
		_on_room_cleared()


## Scatter a burst of GoldPickup coins at the enemy's position. The enemy's
## gold_reward is split across a few coins so the drop fans out for game feel.
func _drop_gold(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var reward: int = enemy.gold_reward if "gold_reward" in enemy else 0
	if reward <= 0:
		return
	var drop_pos: Vector2 = (enemy as Node2D).global_position

	# 2–4 coins; the first carries any remainder so the total always matches.
	var coin_count: int = clampi(reward / 3, 2, 4)
	var base: int = reward / coin_count
	var remainder: int = reward - base * coin_count
	for i in coin_count:
		var v: int = base + (remainder if i == 0 else 0)
		var coin: Node2D = GoldPickupScript.new()
		coin.value = v
		add_child(coin)
		coin.global_position = drop_pos


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

	# Interstitial rooms open their overlay on entry; realm-boundary rooms
	# (ELITE / BOSS) spawn a mini-boss guarding a guaranteed reward.
	match room_data.type:
		RoomData.RoomType.SHOP:
			_open_shop()
		RoomData.RoomType.SHRINE:
			_open_shrine()
		RoomData.RoomType.TEMPTATION:
			_open_temptation()
		RoomData.RoomType.ELITE, RoomData.RoomType.BOSS:
			_spawn_miniboss()


# ---------------------------------------------------------------------------
# Interstitial overlays (shop / shrine)
# ---------------------------------------------------------------------------

## Debug/testing hooks: procedural graphs may not always place a SHOP or SHRINE
## room, so B opens the shop and N opens the shrine from anywhere.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE:
			_toggle_pause()
		KEY_B:
			_open_shop()
		KEY_N:
			_open_shrine()
		KEY_T:
			_open_temptation()
		KEY_M:
			_spawn_miniboss()


# ---------------------------------------------------------------------------
# Pause menu (Esc)
# ---------------------------------------------------------------------------

## Open the pause menu on Esc. Skipped while an interstitial overlay
## (shop/shrine/temptation) is up — those handle their own Esc to close.
## The menu closes itself (and clears _paused_menu_open via its `closed` signal).
func _toggle_pause() -> void:
	if _overlay_open or _paused_menu_open:
		return
	_paused_menu_open = true
	var menu: CanvasLayer = PauseMenuScript.new()
	menu.name = "PauseMenu"
	add_child(menu)
	menu.closed.connect(_on_pause_closed)
	menu.open()
	AudioManager.play_sfx("ui_open")
	# Consume this Esc so the freshly-opened menu doesn't also see it and close.
	get_viewport().set_input_as_handled()


func _on_pause_closed() -> void:
	_paused_menu_open = false


func _open_shop() -> void:
	if _overlay_open or _talisman_manager == null:
		return
	_overlay_open = true
	var shop: CanvasLayer = ShopUIScript.new()
	shop.name = "ShopUI"
	add_child(shop)
	shop.closed.connect(_on_overlay_closed)
	shop.open(player, _talisman_manager)
	AudioManager.play_sfx("ui_open")


func _open_shrine() -> void:
	if _overlay_open:
		return
	_overlay_open = true
	var shrine: CanvasLayer = ShrineUIScript.new()
	shrine.name = "ShrineUI"
	add_child(shrine)
	shrine.closed.connect(_on_overlay_closed)
	shrine.open(player)
	AudioManager.play_sfx("ui_open")


func _open_temptation() -> void:
	if _overlay_open:
		return
	_overlay_open = true
	var temptation: CanvasLayer = TemptationUIScript.new()
	temptation.name = "TemptationUI"
	add_child(temptation)
	temptation.closed.connect(_on_overlay_closed)
	temptation.open(player)
	AudioManager.play_sfx("ui_open")


func _on_overlay_closed() -> void:
	_overlay_open = false


# ---------------------------------------------------------------------------
# Mini-boss (realm boundary)
# ---------------------------------------------------------------------------

func _spawn_miniboss() -> void:
	if _miniboss_alive:
		return
	_miniboss_alive = true

	var boss: Node = MiniBossScene.instantiate()
	boss.name = "MiniBoss"
	boss.position = Vector2(640, 150)
	enemies_container.add_child(boss)

	# Count it toward room-clear and route its death through the shared handler.
	_total_enemies += 1
	boss.enemy_died.connect(_on_enemy_died)

	AudioManager.play_sfx("miniboss")
	_announce("A mini-boss appears!", Color(1.0, 0.35, 0.55))


## Guaranteed mini-boss reward: a talisman OR a permanent upgrade (design:
## "Drop guaranteed talisman/upgrade"). Bonus gold comes from its gold_reward.
func _grant_miniboss_reward() -> void:
	if randi() % 2 == 0 and _talisman_manager != null:
		var scripts: Array = [TigerFangScript, SnakeCoilScript, MonkeyStepScript,
			CraneWingScript, DemonSealScript, VoidStarScript, HeavensTokenScript]
		var s: Script = scripts[randi() % scripts.size()]
		var t: Node = s.new()
		t.name = s.resource_path.get_file().get_basename()
		player.add_child(t)
		_talisman_manager.add_talisman(t)
		_announce("Reward: %s talisman!" % t.name, Color(0.7, 0.85, 1.0))
	elif randi() % 2 == 0:
		player.permanent_damage_mult *= 1.15
		_announce("Reward: +15% damage!", Color(1.0, 0.8, 0.3))
	else:
		player.add_max_hp(25)
		_announce("Reward: +25 Max HP!", Color(0.6, 1.0, 0.6))


## Defeating the mini-boss in a BOSS room clears the realm and unlocks the next.
func _try_unlock_next_realm() -> void:
	var cur: RoomData = room_manager.current_room()
	if cur == null or cur.type != RoomData.RoomType.BOSS:
		return
	var next: int = MetaProgress.selected_realm + 1
	if next < RealmDefs.count() and not MetaProgress.is_realm_unlocked(next):
		MetaProgress.unlock_realm(next)
		_announce("Realm cleared! %s unlocked." % RealmDefs.realm_name(next), Color(0.4, 1.0, 0.6))


## Show a large centred banner on the HUD that fades out after a couple seconds.
func _announce(text: String, color: Color = Color.WHITE) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.position = Vector2(240, 120)
	label.size = Vector2(800, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hud: CanvasLayer = $HUD
	hud.add_child(label)

	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


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

	# Bank this run's Spirit Shards into persistent meta-progression.
	MetaProgress.bank_shards(RunStats.spirit_shards_earned())

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
