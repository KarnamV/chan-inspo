## RoomManager.gd
## Node that owns the procedural room graph for a single run and drives all
## room transitions (fade-out → swap content → fade-in).
##
## Attach to TestRoom (or any future main scene) as a child node.
##
## Public API
##   generate_run(seed: int)          — build a fresh RoomGraph, go to START room
##   travel_to(room_id: int)          — begin transition to the named room
##   current_room() -> RoomData       — the room the player is currently in
##
## Signals
##   room_entered(room_data: RoomData) — emitted after fade-in completes

class_name RoomManager
extends Node

## Emitted after the fade-in of a new room completes.
signal room_entered(room_data: RoomData)

# ---------------------------------------------------------------------------
# Inspector-tunable
# ---------------------------------------------------------------------------
@export var fade_duration: float = 0.3   # seconds per half-transition

# ---------------------------------------------------------------------------
# Internal references — assigned in _ready() by the owning scene
# ---------------------------------------------------------------------------

## The RoomRenderer node that draws the current room.
var room_renderer: Node2D = null

## The Player node — repositioned to the entry door after each transition.
var player: CharacterBody2D = null

## The black overlay CanvasLayer used for fades.
## Created automatically in _ready if not already present.
var _fade_overlay: ColorRect = null
var _fade_canvas: CanvasLayer = null

# ---------------------------------------------------------------------------
# Run state
# ---------------------------------------------------------------------------
var _rooms: Dictionary = {}       # int → RoomData (from RoomGraph.generate)
var _start_id: int = -1
var _boss_id: int = -1
var _current_room_id: int = -1
var _is_transitioning: bool = false

# Direction the player entered from (so we can place them at the opposite door).
var _entry_direction: String = ""

# ---------------------------------------------------------------------------
const DOOR_SPAWN_OFFSETS: Dictionary = {
	"N": Vector2(640, 80),
	"S": Vector2(640, 640),
	"E": Vector2(1200, 360),
	"W": Vector2(80, 360),
}

# Opposite directions (same as RoomData.opposite_direction).
const OPPOSITE: Dictionary = {
	"N": "S",
	"S": "N",
	"E": "W",
	"W": "E",
}


func _ready() -> void:
	_build_fade_overlay()


## Build a fresh run from the given RNG seed.  Call this from the owning scene.
func generate_run(rng_seed: int) -> void:
	var graph := RoomGraph.new()
	var result: Dictionary = graph.generate(rng_seed)
	_rooms  = result["rooms"]
	_start_id = result["start_id"]
	_boss_id  = result["boss_id"]
	_current_room_id = _start_id

	# Mark start room visited immediately.
	var start_room: RoomData = _rooms.get(_start_id, null)
	if start_room != null:
		start_room.is_visited = true

	# Render the start room; player stays wherever they already are.
	if room_renderer != null and start_room != null:
		room_renderer.render_room(start_room, _rooms)


## Returns the RoomData the player is currently in, or null.
func current_room() -> RoomData:
	return _rooms.get(_current_room_id, null)


## Called by a door Area2D when the player steps through it.
## direction: the exit direction label ("N"/"S"/"E"/"W") on the CURRENT room.
func travel_to_exit(direction: String) -> void:
	if _is_transitioning:
		return

	var cur_room: RoomData = current_room()
	if cur_room == null:
		return

	if not cur_room.exits.has(direction):
		return

	# BOSS room lock: boss exit is locked until all sibling rooms at its depth
	# (i.e. all rooms at depth boss_depth - 1) have been visited.
	# (Actual "cleared" logic comes with enemy AI; for now we use is_visited.)
	var dest_id: int = cur_room.exits[direction]
	var dest_room: RoomData = _rooms.get(dest_id, null)
	if dest_room != null and dest_room.type == RoomData.RoomType.BOSS:
		if not _all_non_boss_siblings_visited():
			print("[RoomManager] BOSS room is locked — visit all other rooms first.")
			return

	_begin_transition(dest_id, direction)


## Immediately travel to a room by id (no direction, player placed at centre).
## Useful for warp/debug.
func travel_to(room_id: int) -> void:
	if _is_transitioning:
		return
	_begin_transition(room_id, "")


# ---------------------------------------------------------------------------
# Transition internals
# ---------------------------------------------------------------------------

func _begin_transition(dest_id: int, from_direction: String) -> void:
	_is_transitioning = true

	# Freeze the player during the transition so they cannot re-trigger a door
	# or move while the fade is in progress.  We freeze input + physics processing
	# rather than touching the State enum (which is internal to Player.gd).
	if player != null:
		player.set_process_unhandled_input(false)
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO

	_entry_direction = from_direction

	# Fade out.
	await _fade(1.0)

	# Swap room.
	_current_room_id = dest_id
	var dest_room: RoomData = _rooms.get(dest_id, null)
	if dest_room != null:
		dest_room.is_visited = true
		if room_renderer != null:
			room_renderer.render_room(dest_room, _rooms)

	# Reposition player at the entry door (opposite side from the direction we left).
	_reposition_player(from_direction)

	# Fade in.
	await _fade(0.0)

	_is_transitioning = false

	# Restore player control.
	if player != null:
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)

	if dest_room != null:
		emit_signal("room_entered", dest_room)


## Tween the fade overlay alpha to `target_alpha` over `fade_duration` seconds.
func _fade(target_alpha: float) -> void:
	if _fade_overlay == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", target_alpha, fade_duration)
	await tween.finished


func _reposition_player(from_direction: String) -> void:
	if player == null:
		return
	# The player came FROM `from_direction`, so they should appear at the
	# OPPOSITE door in the new room.
	if from_direction == "" or not OPPOSITE.has(from_direction):
		# No direction info → place at room centre.
		player.global_position = Vector2(640, 360)
		return
	var entry_side: String = OPPOSITE[from_direction]
	player.global_position = DOOR_SPAWN_OFFSETS.get(entry_side, Vector2(640, 360))


# ---------------------------------------------------------------------------
# Boss lock helper
# ---------------------------------------------------------------------------

func _all_non_boss_siblings_visited() -> bool:
	# Find the boss room's depth, then check all rooms at depth - 1.
	var boss_room: RoomData = _rooms.get(_boss_id, null)
	if boss_room == null:
		return true
	# All rooms at boss_depth - 1 must be visited.
	var check_depth: int = boss_room.depth - 1
	if check_depth < 0:
		return true
	for room in _rooms.values():
		if room.id == _boss_id:
			continue
		if room.depth == check_depth and not room.is_visited:
			return false
	return true


# ---------------------------------------------------------------------------
# Fade overlay
# ---------------------------------------------------------------------------

func _build_fade_overlay() -> void:
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 100   # above everything, including HUD (layer 10)
	_fade_canvas.name = "FadeCanvas"
	add_child(_fade_canvas)

	_fade_overlay = ColorRect.new()
	_fade_overlay.name = "FadeOverlay"
	_fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade_overlay.size = Vector2(1280, 720)
	_fade_overlay.position = Vector2.ZERO
	# Start transparent (not yet fading).
	_fade_overlay.modulate.a = 0.0
	_fade_canvas.add_child(_fade_overlay)
