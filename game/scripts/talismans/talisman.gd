class_name Talisman
extends RefCounted
## One zodiac talisman. Equip 3; L1/Ctrl + light/heavy/grab triggers slot 1/2/3.
## Actives override `activate()`; passives hook signals in `equip()` and undo them in `unequip()`.

var id: StringName = &""
var title := ""
var blurb := ""
var cost := 0.0          ## spirit per activation (actives)
var pc: PlayerController


func equip(p_pc: PlayerController) -> void:
	pc = p_pc
	_on_equip()


func unequip() -> void:
	_on_unequip()
	pc = null


## Returns true if it did something (spirit is spent by the caller).
func activate() -> bool:
	return false


func is_active_talisman() -> bool:
	return false


func tick(_delta: float) -> void:
	pass


## The body the player currently controls changed (possession, Monkey, Tiger swap).
func on_controlled_changed(_f: Fighter) -> void:
	pass


func on_room_cleared() -> void:
	pass


func _on_equip() -> void:
	pass


func _on_unequip() -> void:
	pass
