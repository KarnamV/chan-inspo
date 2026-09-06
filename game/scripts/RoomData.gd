## RoomData.gd
## A lightweight Resource representing a single room node in the procedural
## level graph.  Serialisable via Godot's Resource system (safe for save/load).
##
## Fields
##   id          : int      — unique room index within a run (0 = start)
##   type        : RoomType — enum value; determines what happens in the room
##   depth       : int      — distance from start room (start = 0, boss = max)
##   exits       : Dictionary[String, int]
##                   keys:   "N" | "S" | "E" | "W"
##                   values: id of the room that direction leads to
##                   Only directions that have a connection are present.
##   parent_id   : int      — id of the room this was spawned from (-1 for root)
##   is_visited  : bool     — set true when the player enters the room
##
## Phase 2 note: exits are one-directional in the tree (parent→child only).
##   Back-travel support (Phase 3) will add the reverse direction to the parent.

class_name RoomData
extends Resource

## ------------------------------------------------------------------
## Room type enum
## ------------------------------------------------------------------
enum RoomType {
	START      = 0,   ## Always depth 0; one per graph
	COMBAT     = 1,   ## Standard enemy encounter  (70 % of non-special rooms)
	ELITE      = 2,   ## Harder enemy, better drop  (15 %)
	SHOP       = 3,   ## Merchant; spend gold        ( 5 %)
	SHRINE     = 4,   ## HP / blessing choice        ( 5 %)
	BOSS       = 5,   ## Realm boss; always deepest room
	TEMPTATION = 6,   ## Cursed power-up; risk gold/shards for a buff + curse
}

## Human-readable name for debug output
const TYPE_NAMES: Dictionary = {
	RoomType.START:      "START",
	RoomType.COMBAT:     "COMBAT",
	RoomType.ELITE:      "ELITE",
	RoomType.SHOP:       "SHOP",
	RoomType.SHRINE:     "SHRINE",
	RoomType.BOSS:       "BOSS",
	RoomType.TEMPTATION: "TEMPTATION",
}

## ------------------------------------------------------------------
## Exported properties (serialisable via .tres / save system)
## ------------------------------------------------------------------
@export var id: int = -1
@export var type: RoomType = RoomType.COMBAT
@export var depth: int = 0
## exits: direction string → neighbour room id
@export var exits: Dictionary = {}
@export var parent_id: int = -1
@export var is_visited: bool = false

## ------------------------------------------------------------------
## Convenience helpers
## ------------------------------------------------------------------

## Returns the display name of this room's type.
func type_name() -> String:
	return TYPE_NAMES.get(type, "UNKNOWN")


## Returns true if this room has an exit in the given direction ("N","S","E","W").
func has_exit(direction: String) -> bool:
	return exits.has(direction)


## Returns the opposite cardinal direction (used when adding back-edges in Phase 3).
static func opposite_direction(dir: String) -> String:
	match dir:
		"N": return "S"
		"S": return "N"
		"E": return "W"
		"W": return "E"
	return ""
