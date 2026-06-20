## RoomGraph.gd
## Procedural room-layout generator for Demon Realm Escape.
##
## Produces a TREE (no loops) of 8-12 rooms per realm run.
## Loop support is deferred to Phase 3.
##
## Usage (from any GDScript):
##
##   var graph_result := RoomGraph.new().generate(12345)
##   # graph_result = {
##   #   "rooms"    : Dictionary[int → RoomData],
##   #   "start_id" : int,
##   #   "boss_id"  : int,
##   # }
##
## Public API:
##   generate(rng_seed: int) -> Dictionary
##   get_room(id: int)       -> RoomData or null
##   get_neighbors(id: int)  -> Array[RoomData]
##   get_path_to_boss(start_id: int) -> Array[RoomData]
##
## Algorithm summary
##   1. Create root (START, depth 0).
##   2. BFS queue: each node picks 1–3 child directions not yet used.
##   3. Stop when total room count reaches target (8-12, chosen randomly).
##   4. Deepest room (greatest depth; tie-broken by highest id) = BOSS.
##   5. All non-START, non-BOSS rooms get weighted-random types.
##
## Type weights (non-special rooms):
##   COMBAT 70 %, ELITE 15 %, SHOP 5 %, SHRINE 5 %   (remaining 5 % → BOSS, handled separately)

class_name RoomGraph
extends RefCounted

## ------------------------------------------------------------------
## Constants
## ------------------------------------------------------------------

## Cardinal directions and their screen-space meaning (top-down).
const DIRECTIONS: Array[String] = ["N", "S", "E", "W"]

## Weighted pool for non-special room types.
## Repeated entries implement the % distribution without float math.
## 20 entries: COMBAT×14, ELITE×3, SHOP×1, SHRINE×1, (BOSS slot×1 unused here)
## Effective: COMBAT 70%, ELITE 15%, SHOP 5%, SHRINE 5%, leftover 5% → COMBAT
## Total = COMBAT 75%, ELITE 15%, SHOP 5%, SHRINE 5%  (boss handled outside pool)
const TYPE_WEIGHT_POOL: Array = [
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.COMBAT,
	RoomData.RoomType.ELITE,
	RoomData.RoomType.ELITE,
	RoomData.RoomType.ELITE,
	RoomData.RoomType.SHOP,
	RoomData.RoomType.SHRINE,
	RoomData.RoomType.COMBAT,  # fills the last 5% → COMBAT to honour 70%+ target
]

## ------------------------------------------------------------------
## State (reset on each generate() call)
## ------------------------------------------------------------------
var _rooms: Dictionary = {}         # int → RoomData
var _next_id: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## ------------------------------------------------------------------
## Public: generate
## ------------------------------------------------------------------

## Build a fresh room tree and return the result dictionary.
## Calling generate() multiple times with the same seed produces identical output.
func generate(rng_seed: int) -> Dictionary:
	_rooms.clear()
	_next_id = 0
	_rng.seed = rng_seed

	# Choose target room count: 8-12 inclusive
	var target_count: int = _rng.randi_range(8, 12)

	# --- Step 1: create root ---
	var root := _make_room(RoomData.RoomType.START, 0, -1)

	# --- Step 2: BFS expansion ---
	var bfs_queue: Array[RoomData] = [root]

	while _rooms.size() < target_count and bfs_queue.size() > 0:
		var current: RoomData = bfs_queue.pop_front()

		# Available directions on this node (we never overwrite an existing exit)
		var available_dirs: Array[String] = _available_directions(current)
		if available_dirs.is_empty():
			continue

		# Shuffle so direction choice is random
		_shuffle_array(available_dirs)

		# Pick how many children to spawn: 1-3, clamped to available dirs and
		# remaining room budget.
		var remaining: int = target_count - _rooms.size()
		if remaining <= 0:
			break

		var child_count: int = _rng.randi_range(1, min(3, min(available_dirs.size(), remaining)))

		for i in range(child_count):
			if _rooms.size() >= target_count:
				break
			var dir: String = available_dirs[i]
			# Placeholder type — will be reassigned after tree is complete
			var child := _make_room(RoomData.RoomType.COMBAT, current.depth + 1, current.id)
			# Connect parent → child
			current.exits[dir] = child.id
			bfs_queue.append(child)

	# --- Step 3: Assign room types ---
	_assign_types()

	# --- Step 4: Debug print ---
	_debug_print_tree(rng_seed, target_count)

	return {
		"rooms":    _rooms.duplicate(),
		"start_id": 0,
		"boss_id":  _find_boss_id(),
	}


## ------------------------------------------------------------------
## Public: helpers
## ------------------------------------------------------------------

## Return the RoomData for the given id, or null if not found.
func get_room(id: int) -> RoomData:
	return _rooms.get(id, null)


## Return all RoomData neighbours (children only in Phase 2 tree).
func get_neighbors(id: int) -> Array[RoomData]:
	var room: RoomData = get_room(id)
	if room == null:
		return []
	var neighbours: Array[RoomData] = []
	for neighbour_id in room.exits.values():
		var n: RoomData = get_room(neighbour_id)
		if n != null:
			neighbours.append(n)
	return neighbours


## Return the ordered path from start_id to the boss room using DFS.
## Returns an empty array if no path exists.
func get_path_to_boss(start_id: int) -> Array[RoomData]:
	var boss_id := _find_boss_id()
	if boss_id < 0:
		return []
	var path: Array[RoomData] = []
	if _dfs_path(start_id, boss_id, path, {}):
		return path
	return []


## ------------------------------------------------------------------
## Private: room creation
## ------------------------------------------------------------------

func _make_room(type: RoomData.RoomType, depth: int, parent_id: int) -> RoomData:
	var room := RoomData.new()
	room.id        = _next_id
	room.type      = type
	room.depth     = depth
	room.parent_id = parent_id
	room.exits     = {}
	room.is_visited = false
	_rooms[_next_id] = room
	_next_id += 1
	return room


## Directions not already occupied on this room and not used by siblings
## (to avoid two siblings claiming the same parent-direction).
func _available_directions(room: RoomData) -> Array[String]:
	var used: Array[String] = []
	# Directions already used by this room's own exits
	for d in room.exits.keys():
		used.append(d)
	# Direction we came FROM (parent → this room) — find the inbound direction
	if room.parent_id >= 0:
		var parent: RoomData = _rooms.get(room.parent_id, null)
		if parent != null:
			for dir in parent.exits.keys():
				if parent.exits[dir] == room.id:
					# The inbound direction to us is the opposite of the parent's exit dir
					used.append(RoomData.opposite_direction(dir))
					break

	var result: Array[String] = []
	for d in DIRECTIONS:
		if not used.has(d):
			result.append(d)
	return result


## ------------------------------------------------------------------
## Private: type assignment
## ------------------------------------------------------------------

func _assign_types() -> void:
	# Find deepest depth across all rooms
	var max_depth: int = 0
	for room in _rooms.values():
		if room.depth > max_depth:
			max_depth = room.depth

	# Boss = deepest room (tie-break: highest id for determinism)
	var boss_id: int = _pick_boss_room(max_depth)

	for room in _rooms.values():
		if room.id == 0:
			room.type = RoomData.RoomType.START
		elif room.id == boss_id:
			room.type = RoomData.RoomType.BOSS
		else:
			room.type = TYPE_WEIGHT_POOL[_rng.randi_range(0, TYPE_WEIGHT_POOL.size() - 1)]


func _pick_boss_room(max_depth: int) -> int:
	var candidates: Array[int] = []
	for room in _rooms.values():
		if room.depth == max_depth:
			candidates.append(room.id)
	# Deterministic tie-break: highest id
	candidates.sort()
	return candidates[-1] if candidates.size() > 0 else -1


func _find_boss_id() -> int:
	for room in _rooms.values():
		if room.type == RoomData.RoomType.BOSS:
			return room.id
	return -1


## ------------------------------------------------------------------
## Private: DFS path finding
## ------------------------------------------------------------------

func _dfs_path(current_id: int, target_id: int, path: Array[RoomData], visited: Dictionary) -> bool:
	if visited.has(current_id):
		return false
	visited[current_id] = true
	var room: RoomData = get_room(current_id)
	if room == null:
		return false
	path.append(room)
	if current_id == target_id:
		return true
	for neighbour_id in room.exits.values():
		if _dfs_path(neighbour_id, target_id, path, visited):
			return true
	path.pop_back()
	return false


## ------------------------------------------------------------------
## Private: utilities
## ------------------------------------------------------------------

func _shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## ------------------------------------------------------------------
## Private: debug output
## ------------------------------------------------------------------

func _debug_print_tree(rng_seed: int, target_count: int) -> void:
	var boss_id := _find_boss_id()
	var path_to_boss := get_path_to_boss(0)

	print("=== RoomGraph.generate() seed=%d  target=%d  actual=%d ===" % [rng_seed, target_count, _rooms.size()])

	# Tree view (depth-first, indented)
	print("--- Room Tree (depth-first) ---")
	_print_subtree(0, "", true)

	# Type distribution summary
	var counts: Dictionary = {}
	for rt in RoomData.TYPE_NAMES.keys():
		counts[rt] = 0
	for room in _rooms.values():
		counts[room.type] = counts.get(room.type, 0) + 1

	print("--- Type distribution ---")
	for rt in RoomData.TYPE_NAMES.keys():
		var n: int = counts.get(rt, 0)
		var pct: float = float(n) / float(_rooms.size()) * 100.0
		print("  %-8s : %d rooms  (%.0f%%)" % [RoomData.TYPE_NAMES[rt], n, pct])

	# Path to boss
	print("--- Path to boss (id=%d) ---" % boss_id)
	if path_to_boss.is_empty():
		print("  (no path found)")
	else:
		var parts: Array[String] = []
		for r in path_to_boss:
			parts.append("Room%d[%s,d%d]" % [r.id, r.type_name(), r.depth])
		print("  " + " → ".join(parts))

	print("=== end RoomGraph ===")


func _print_subtree(room_id: int, prefix: String, is_last: bool) -> void:
	var room: RoomData = get_room(room_id)
	if room == null:
		return

	var connector := "└─ " if is_last else "├─ "
	var exits_str := ""
	if not room.exits.is_empty():
		var exit_parts: Array[String] = []
		for dir in room.exits.keys():
			exit_parts.append("%s→%d" % [dir, room.exits[dir]])
		exits_str = "  exits:[%s]" % ", ".join(exit_parts)

	print("%s%sRoom%d  [%s, depth=%d]%s" % [prefix, connector, room.id, room.type_name(), room.depth, exits_str])

	var child_ids: Array[int] = room.exits.values()
	var new_prefix := prefix + ("   " if is_last else "│  ")
	for i in range(child_ids.size()):
		_print_subtree(child_ids[i], new_prefix, i == child_ids.size() - 1)
