class_name FighterData
extends Resource
## Everything that defines a fighter type (hero, brute, ...): model, body, stats, moves, AI.

@export var id: StringName = &""
@export var model: PackedScene
@export var height := 1.8
@export var radius := 0.35
@export var max_hp := 100.0
@export_range(0.0, 1.0) var resist_physical := 0.0
@export_range(0.0, 1.0) var resist_magic := 0.0
@export var move_speed := 5.5
@export var accel := 40.0
@export var turn_speed := 14.0
@export var knockdown_time := 1.8     ## seconds on the floor (Sheep window)
@export var stagger_scale := 1.0      ## multiplies incoming stun (brutes shrug off small hits)
@export var light_combo: Array[AttackData] = []
@export var heavy: AttackData
@export var dodge_time := 0.35
@export var dodge_speed := 11.0
@export var dodge_iframes := 0.3
@export var dodge_cooldown := 0.35
# AI
@export var aggro_range := 14.0
@export var attack_range := 1.8
@export var attack_cooldown := 1.6
@export var ai_attacks: Array[AttackData] = []
