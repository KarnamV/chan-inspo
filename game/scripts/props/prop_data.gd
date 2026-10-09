class_name PropData
extends Resource
## A breakable prop type. Breaking degrades it into `pieces` (smaller usable props) before it's gone.

enum Weight { LIGHT, HEAVY }

@export var id: StringName = &""
@export var model: PackedScene
@export var weight: Weight = Weight.LIGHT
@export var durability := 4
@export var damage := 12.0            ## light swing damage; heavy = x heavy_mult, throw = x throw_mult
@export var heavy_mult := 1.6
@export var throw_mult := 1.3
@export var knockback := 4.0
@export var reach := 1.3              ## hit-box length when swung
@export var pieces: Array[PropData] = []
@export var element: StringName = &""
@export var grip_offset := Vector3.ZERO   ## local offset so the hand holds the right end
