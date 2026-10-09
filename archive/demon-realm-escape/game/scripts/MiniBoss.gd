## MiniBoss.gd — realm-boundary mini-boss.
##
## Reuses PossessedWarrior's melee windup→strike FSM but is much tougher, larger,
## and hits harder. Guarantees a reward on death: TestRoom checks `is_miniboss`
## in _on_enemy_died and grants a talisman or a permanent upgrade plus bonus gold.

extends "res://scripts/PossessedWarrior.gd"

## Marker read by TestRoom to award the guaranteed reward.
var is_miniboss: bool = true


func _ready() -> void:
	# PossessedWarrior._ready sets the base warrior stats + wires the melee hitbox
	# and calls EnemyBase._ready (which sets current_hp = max_hp). We call it first,
	# then override with beefed-up mini-boss numbers.
	super._ready()

	max_hp       = 240
	current_hp   = max_hp
	move_speed   = 130.0
	attack_dmg   = 28
	detect_range = 560.0
	attack_range = 62.0
	gold_reward  = 45
	_refresh_label()

	# Larger, menacing violet-red presence.
	scale = Vector2(1.6, 1.6)
	sprite.modulate = Color(0.85, 0.15, 0.55, 1.0)
