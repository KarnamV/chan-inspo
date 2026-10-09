class_name AttackData
extends Resource
## One attack: timing, hit volume and payload. Durations are in seconds; the clip is time-stretched
## to fit `duration`.

@export var id: StringName = &""
@export var clip: StringName = &"punch_jab"
@export var duration := 0.45
@export var active_start := 0.15      ## hitbox on from here...
@export var active_end := 0.28        ## ...to here
@export var combo_window := 0.25      ## light presses after this point queue the next combo step
@export var damage := 6.0
@export var magic := false
@export var knockback := 2.5
@export var knockdown := false
@export var stun := 0.25
@export var lunge := 2.0              ## forward speed (m/s) during the windup
@export var hit_size := Vector3(1.0, 1.2, 1.1)
@export var hit_offset := Vector3(0.0, 1.0, 0.85)   ## local: +Z is forward
@export var prop_wear := 1            ## durability cost when swung with a prop
