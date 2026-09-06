## RoomRenderer.gd
## Reusable Node2D that renders any RoomData as a 1280×720 arena.
##
## Call render_room(room_data, all_rooms) to (re)build the visual from scratch.
## The node clears and rebuilds all children on every call so it is safe to
## call multiple times during a run.
##
## Visual layout (pixels)
##   Floor:   full-width ColorRect behind everything
##   Walls:   20px thick ColorRect (visual) + StaticBody2D (physical) per side
##   Doors:   60×80px gap in the wall; Area2D trigger + glowing archway ColorRect
##            + Label showing destination room type
##
## Wall colours per room type (used for CURRENT room):
##   START  → teal       Color(0.10, 0.55, 0.55)
##   COMBAT → dark amber Color(0.40, 0.22, 0.08)
##   ELITE  → deep red   Color(0.55, 0.08, 0.08)
##   SHOP   → gold       Color(0.60, 0.50, 0.05)
##   SHRINE → muted blue Color(0.12, 0.20, 0.55)
##   BOSS   → near-black Color(0.12, 0.05, 0.15)
##
## The door archway glow uses a lighter version of the DESTINATION room's colour.

class_name RoomRenderer
extends Node2D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const ROOM_W: float  = 1280.0
const ROOM_H: float  = 720.0
const WALL_T: float  = 20.0       # wall thickness
const DOOR_W: float  = 60.0       # door gap width
const DOOR_H: float  = 80.0       # door gap height (visual arch height)

# Door archway "glow" rect size (slightly larger than the gap).
const ARCH_PAD: float = 6.0       # extra padding around door gap for the glow rect

## Wall colour per RoomType.
const WALL_COLORS: Dictionary = {
	RoomData.RoomType.START:  Color(0.10, 0.55, 0.55, 1.0),  # teal
	RoomData.RoomType.COMBAT: Color(0.40, 0.22, 0.08, 1.0),  # dark amber
	RoomData.RoomType.ELITE:  Color(0.55, 0.08, 0.08, 1.0),  # deep red
	RoomData.RoomType.SHOP:   Color(0.60, 0.50, 0.05, 1.0),  # gold
	RoomData.RoomType.SHRINE: Color(0.12, 0.20, 0.55, 1.0),  # muted blue
	RoomData.RoomType.BOSS:   Color(0.12, 0.05, 0.15, 1.0),  # near-black purple
	RoomData.RoomType.TEMPTATION: Color(0.42, 0.10, 0.38, 1.0),  # cursed magenta
}

## Lighter / more saturated glow tint for door arches (destination type).
const GLOW_COLORS: Dictionary = {
	RoomData.RoomType.START:  Color(0.30, 0.90, 0.90, 1.0),
	RoomData.RoomType.COMBAT: Color(0.90, 0.50, 0.20, 1.0),
	RoomData.RoomType.ELITE:  Color(1.00, 0.25, 0.25, 1.0),
	RoomData.RoomType.SHOP:   Color(1.00, 0.90, 0.20, 1.0),
	RoomData.RoomType.SHRINE: Color(0.40, 0.60, 1.00, 1.0),
	RoomData.RoomType.BOSS:   Color(0.80, 0.20, 1.00, 1.0),
	RoomData.RoomType.TEMPTATION: Color(1.00, 0.30, 0.90, 1.0),
}

const FLOOR_COLOR: Color = Color(0.12, 0.12, 0.14, 1.0)

## Per-realm floor colour override. TestRoom sets this from RealmDefs before the
## first render_room so the whole run is themed to the selected realm.
var realm_floor_color: Color = FLOOR_COLOR

# Collision shape sizes and positions for the wall segments on each side.
# Each wall may have 1 or 2 segments depending on whether a door is present.
# We build these dynamically in _build_wall().

## Signal emitted when the player enters a door trigger.
## direction: "N" | "S" | "E" | "W"
signal door_entered(direction: String)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _current_room: RoomData = null


# ---------------------------------------------------------------------------
# Public
# ---------------------------------------------------------------------------

## Rebuild the entire room visual from the given RoomData.
## all_rooms: the full Dictionary[int, RoomData] from the run, so we can look
## up destination room types for door labels.
func render_room(room_data: RoomData, all_rooms: Dictionary) -> void:
	_current_room = room_data
	# Clear previous children entirely.
	for child in get_children():
		child.queue_free()

	var wall_color: Color = WALL_COLORS.get(room_data.type, Color(0.3, 0.3, 0.3, 1.0))

	_build_floor()
	_build_walls(room_data, all_rooms, wall_color)
	_build_room_type_label(room_data)


# ---------------------------------------------------------------------------
# Private builders
# ---------------------------------------------------------------------------

func _build_floor() -> void:
	var floor_rect := ColorRect.new()
	floor_rect.name = "Floor"
	floor_rect.color = realm_floor_color
	floor_rect.position = Vector2.ZERO
	floor_rect.size = Vector2(ROOM_W, ROOM_H)
	floor_rect.z_index = -1
	add_child(floor_rect)


## Build all four walls with gaps for exits that are present in room_data.exits.
func _build_walls(room_data: RoomData, all_rooms: Dictionary, wall_color: Color) -> void:
	for dir in ["N", "S", "E", "W"]:
		var has_door: bool = room_data.exits.has(dir)
		var dest_id: int   = room_data.exits.get(dir, -1)
		var dest_room: RoomData = all_rooms.get(dest_id, null) if dest_id >= 0 else null

		_build_wall(dir, has_door, wall_color, dest_room)


## Build one wall side.  If has_door, cut a gap and place a door trigger there.
func _build_wall(dir: String, has_door: bool, wall_color: Color, dest_room: RoomData) -> void:
	var segs: Array[Dictionary] = _wall_segments(dir, has_door)
	for seg in segs:
		_make_wall_segment(seg["rect"], wall_color, seg["shape_pos"], seg["shape_size"])

	if has_door:
		_make_door(dir, dest_room)


## Returns an Array of segment dictionaries, each with:
##   rect       : Rect2  — visual ColorRect rect in room-local pixels
##   shape_pos  : Vector2 — StaticBody2D centre position
##   shape_size : Vector2 — RectangleShape2D size
func _wall_segments(dir: String, has_door: bool) -> Array[Dictionary]:
	var segs: Array[Dictionary] = []

	match dir:
		"N":
			if not has_door:
				segs.append(_seg(Rect2(0, 0, ROOM_W, WALL_T),
								Vector2(ROOM_W * 0.5, WALL_T * 0.5),
								Vector2(ROOM_W, WALL_T)))
			else:
				var gap_left:  float = ROOM_W * 0.5 - DOOR_W * 0.5
				var gap_right: float = ROOM_W * 0.5 + DOOR_W * 0.5
				segs.append(_seg(Rect2(0, 0, gap_left, WALL_T),
								Vector2(gap_left * 0.5, WALL_T * 0.5),
								Vector2(gap_left, WALL_T)))
				segs.append(_seg(Rect2(gap_right, 0, ROOM_W - gap_right, WALL_T),
								Vector2(gap_right + (ROOM_W - gap_right) * 0.5, WALL_T * 0.5),
								Vector2(ROOM_W - gap_right, WALL_T)))
		"S":
			var y: float = ROOM_H - WALL_T
			if not has_door:
				segs.append(_seg(Rect2(0, y, ROOM_W, WALL_T),
								Vector2(ROOM_W * 0.5, y + WALL_T * 0.5),
								Vector2(ROOM_W, WALL_T)))
			else:
				var gap_left:  float = ROOM_W * 0.5 - DOOR_W * 0.5
				var gap_right: float = ROOM_W * 0.5 + DOOR_W * 0.5
				segs.append(_seg(Rect2(0, y, gap_left, WALL_T),
								Vector2(gap_left * 0.5, y + WALL_T * 0.5),
								Vector2(gap_left, WALL_T)))
				segs.append(_seg(Rect2(gap_right, y, ROOM_W - gap_right, WALL_T),
								Vector2(gap_right + (ROOM_W - gap_right) * 0.5, y + WALL_T * 0.5),
								Vector2(ROOM_W - gap_right, WALL_T)))
		"W":
			if not has_door:
				segs.append(_seg(Rect2(0, 0, WALL_T, ROOM_H),
								Vector2(WALL_T * 0.5, ROOM_H * 0.5),
								Vector2(WALL_T, ROOM_H)))
			else:
				var gap_top:    float = ROOM_H * 0.5 - DOOR_W * 0.5
				var gap_bottom: float = ROOM_H * 0.5 + DOOR_W * 0.5
				segs.append(_seg(Rect2(0, 0, WALL_T, gap_top),
								Vector2(WALL_T * 0.5, gap_top * 0.5),
								Vector2(WALL_T, gap_top)))
				segs.append(_seg(Rect2(0, gap_bottom, WALL_T, ROOM_H - gap_bottom),
								Vector2(WALL_T * 0.5, gap_bottom + (ROOM_H - gap_bottom) * 0.5),
								Vector2(WALL_T, ROOM_H - gap_bottom)))
		"E":
			var x: float = ROOM_W - WALL_T
			if not has_door:
				segs.append(_seg(Rect2(x, 0, WALL_T, ROOM_H),
								Vector2(x + WALL_T * 0.5, ROOM_H * 0.5),
								Vector2(WALL_T, ROOM_H)))
			else:
				var gap_top:    float = ROOM_H * 0.5 - DOOR_W * 0.5
				var gap_bottom: float = ROOM_H * 0.5 + DOOR_W * 0.5
				segs.append(_seg(Rect2(x, 0, WALL_T, gap_top),
								Vector2(x + WALL_T * 0.5, gap_top * 0.5),
								Vector2(WALL_T, gap_top)))
				segs.append(_seg(Rect2(x, gap_bottom, WALL_T, ROOM_H - gap_bottom),
								Vector2(x + WALL_T * 0.5, gap_bottom + (ROOM_H - gap_bottom) * 0.5),
								Vector2(WALL_T, ROOM_H - gap_bottom)))

	return segs


func _seg(rect: Rect2, sp: Vector2, ss: Vector2) -> Dictionary:
	return {"rect": rect, "shape_pos": sp, "shape_size": ss}


func _make_wall_segment(rect: Rect2, color: Color, shape_pos: Vector2, shape_size: Vector2) -> void:
	# Visual.
	var cr := ColorRect.new()
	cr.color = color
	cr.position = rect.position
	cr.size = rect.size
	add_child(cr)

	# Physics.
	var body := StaticBody2D.new()
	body.position = shape_pos
	add_child(body)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = shape_size
	cshape.shape = rect_shape
	body.add_child(cshape)


## Build the door gap visual + Area2D trigger for one direction.
func _make_door(dir: String, dest_room: RoomData) -> void:
	var dest_type: RoomData.RoomType = dest_room.type if dest_room != null else RoomData.RoomType.COMBAT
	var glow_color: Color = GLOW_COLORS.get(dest_type, Color(0.8, 0.8, 0.8, 1.0))
	var type_label_text: String = dest_room.type_name() if dest_room != null else "???"

	# Position and size of the arch glow rect.
	var arch_rect: Rect2 = _arch_rect_for_dir(dir)

	# Glow arch (visual — slightly inset from wall edge so it peeks out).
	var arch := ColorRect.new()
	arch.name = "Arch_%s" % dir
	arch.color = glow_color
	arch.position = arch_rect.position
	arch.size = arch_rect.size
	add_child(arch)

	# Destination label centred in the arch.
	var lbl := Label.new()
	lbl.name = "DoorLabel_%s" % dir
	lbl.text = type_label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = arch_rect.position
	lbl.size = arch_rect.size
	var ls := LabelSettings.new()
	ls.font_size = 13
	ls.font_color = Color(1, 1, 1, 1)
	ls.shadow_color = Color(0, 0, 0, 0.8)
	ls.shadow_offset = Vector2(1, 1)
	lbl.label_settings = ls
	add_child(lbl)

	# Area2D trigger — tall enough to reliably catch the player walking through.
	var area := Area2D.new()
	area.name = "DoorArea_%s" % dir
	area.position = _door_trigger_pos(dir)
	add_child(area)

	var cshape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = _door_trigger_size(dir)
	cshape.shape = rect_shape
	area.add_child(cshape)

	# Capture the direction in a closure so the lambda knows which door fired.
	var captured_dir: String = dir
	area.body_entered.connect(func(body: Node2D) -> void:
		_on_door_body_entered(body, captured_dir)
	)


## Glow arch Rect2 in room-local coordinates.
func _arch_rect_for_dir(dir: String) -> Rect2:
	match dir:
		"N":
			return Rect2(ROOM_W * 0.5 - DOOR_W * 0.5 - ARCH_PAD,
						 0.0,
						 DOOR_W + ARCH_PAD * 2.0,
						 DOOR_H * 0.5)
		"S":
			return Rect2(ROOM_W * 0.5 - DOOR_W * 0.5 - ARCH_PAD,
						 ROOM_H - DOOR_H * 0.5,
						 DOOR_W + ARCH_PAD * 2.0,
						 DOOR_H * 0.5)
		"W":
			return Rect2(0.0,
						 ROOM_H * 0.5 - DOOR_W * 0.5 - ARCH_PAD,
						 DOOR_H * 0.5,
						 DOOR_W + ARCH_PAD * 2.0)
		"E":
			return Rect2(ROOM_W - DOOR_H * 0.5,
						 ROOM_H * 0.5 - DOOR_W * 0.5 - ARCH_PAD,
						 DOOR_H * 0.5,
						 DOOR_W + ARCH_PAD * 2.0)
	return Rect2()


## Area2D body centre in room-local coords (just inside the wall gap).
func _door_trigger_pos(dir: String) -> Vector2:
	match dir:
		"N": return Vector2(ROOM_W * 0.5, WALL_T + 24.0)
		"S": return Vector2(ROOM_W * 0.5, ROOM_H - WALL_T - 24.0)
		"W": return Vector2(WALL_T + 24.0, ROOM_H * 0.5)
		"E": return Vector2(ROOM_W - WALL_T - 24.0, ROOM_H * 0.5)
	return Vector2(ROOM_W * 0.5, ROOM_H * 0.5)


## Area2D trigger size — wide enough to catch the player sprite (32px).
func _door_trigger_size(dir: String) -> Vector2:
	match dir:
		"N", "S": return Vector2(DOOR_W, 48.0)
		"W", "E": return Vector2(48.0, DOOR_W)
	return Vector2(48.0, 48.0)


## Room type label in the bottom-right corner of the HUD layer.
## We put it directly on the Node2D (not a CanvasLayer) so it scrolls with the
## room if a camera is ever added.  TestRoom keeps the actual CanvasLayer HUD.
func _build_room_type_label(room_data: RoomData) -> void:
	var lbl := Label.new()
	lbl.name = "RoomTypeLabel"
	lbl.text = "[%s]  Room %d" % [room_data.type_name(), room_data.id]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.position = Vector2(ROOM_W - 220.0, ROOM_H - 36.0)
	lbl.size = Vector2(210.0, 28.0)
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.font_color = Color(1, 1, 1, 0.75)
	ls.shadow_color = Color(0, 0, 0, 0.6)
	ls.shadow_offset = Vector2(1, 1)
	lbl.label_settings = ls
	add_child(lbl)


# ---------------------------------------------------------------------------
# Door trigger callback
# ---------------------------------------------------------------------------

func _on_door_body_entered(body: Node2D, dir: String) -> void:
	# Only react to the player (CharacterBody2D named "Player").
	if not body is CharacterBody2D:
		return
	emit_signal("door_entered", dir)
