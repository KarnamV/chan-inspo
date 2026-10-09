class_name Health
extends Node
## Hit points with physical/magic resistances. Shatter strips physical armor for a few seconds.

signal damaged(info: DamageInfo, amount: float)
signal healed(amount: float)
signal died

@export var max_hp := 100.0
@export_range(0.0, 1.0) var resist_physical := 0.0
@export_range(0.0, 1.0) var resist_magic := 0.0
@export var shatter_seconds := 3.0

var hp := 0.0
var invulnerable := false
var shattered_left := 0.0


func _ready() -> void:
	hp = max_hp


func is_dead() -> bool:
	return hp <= 0.0


func resist_for(type: DamageInfo.Type) -> float:
	if type == DamageInfo.Type.MAGIC:
		return resist_magic
	return 0.0 if shattered_left > 0.0 else resist_physical


## Returns the damage actually taken (0 when invulnerable or already dead).
func take(info: DamageInfo) -> float:
	if invulnerable or is_dead():
		return 0.0
	if info.shatter:
		shattered_left = shatter_seconds
	var amount := info.amount * (1.0 - resist_for(info.type))
	hp = maxf(hp - amount, 0.0)
	damaged.emit(info, amount)
	if is_dead():
		died.emit()
	return amount


func heal(amount: float) -> void:
	if is_dead():
		return
	var before := hp
	hp = minf(hp + amount, max_hp)
	if hp > before:
		healed.emit(hp - before)


func _process(delta: float) -> void:
	if shattered_left > 0.0:
		shattered_left = maxf(shattered_left - delta, 0.0)
