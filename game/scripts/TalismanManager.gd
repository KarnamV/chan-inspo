extends Node

# ---------------------------------------------------------------------------
# TalismanManager.gd — Holds up to 3 equipped talismans per run.
#
# Attach as a child of the Player node. TestRoom calls setup() to populate
# the slots and bind the manager to the player.
#
# Cycling with Tab wraps around: slot 0 → 1 → 2 → 0.
# Activation is handled by Player._unhandled_input, which reads
# player.active_talisman (kept in sync by this manager after each cycle).
# ---------------------------------------------------------------------------

const MAX_SLOTS: int = 3

# Populated by setup() before the scene starts gameplay.
var _slots: Array = []         # Array[Talisman]
var _active_index: int = 0
var _player: Node = null

# Emitted when the active slot changes so the HUD can update its label.
signal active_talisman_changed(talisman: Node)


# Call from TestRoom (or equivalent setup code) with:
#   manager.setup(player, [talisman_a, talisman_b, talisman_c])
# All talismans must already be added as children of the player before setup().
func setup(player: Node, talismans: Array) -> void:
	_player = player
	_slots.clear()
	for t in talismans:
		if _slots.size() >= MAX_SLOTS:
			break
		_slots.append(t)

	_active_index = 0
	if _slots.size() > 0:
		_player.active_talisman = _slots[0]
		emit_signal("active_talisman_changed", _slots[0])


# Returns the currently active talisman node (or null if no slots filled).
func get_active() -> Node:
	if _slots.is_empty():
		return null
	return _slots[_active_index]


# Advance to the next slot (wraps around). Called on Tab press.
func cycle_next() -> void:
	if _slots.size() <= 1:
		return
	_active_index = (_active_index + 1) % _slots.size()
	var t: Node = _slots[_active_index]
	_player.active_talisman = t
	emit_signal("active_talisman_changed", t)


# Returns the display name of the active talisman for the HUD.
func active_display_name() -> String:
	var t: Node = get_active()
	if t == null:
		return ""
	if t.has_method("talisman_display_name"):
		return t.talisman_display_name()
	return t.name


# Returns the slot index (0-based) of the active talisman.
func active_index() -> int:
	return _active_index


# Returns total number of filled slots.
func slot_count() -> int:
	return _slots.size()
