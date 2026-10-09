class_name StatusFx
extends Node
## Element statuses on a fighter. Fire = burn damage over time; water puts fire out.

signal changed

@export var burn_dps := 4.0
@export var burn_seconds := 3.0

var burning := 0.0
var fighter: Node   ## Fighter


func apply_element(element: StringName, source: Node) -> void:
	match element:
		&"fire":
			burning = burn_seconds
			changed.emit()
		&"water":
			if burning > 0.0:
				burning = 0.0
				changed.emit()


func _physics_process(delta: float) -> void:
	if burning <= 0.0 or fighter == null:
		return
	burning = maxf(burning - delta, 0.0)
	var info := DamageInfo.make(burn_dps * delta, null, DamageInfo.Type.MAGIC)
	info.stun = 0.0
	fighter.health.take(info)
	if burning == 0.0:
		changed.emit()
