class_name DamageInfo
extends RefCounted
## One hit's payload, passed from a Hitbox (or thrown Prop) to whatever it lands on.

enum Type { PHYSICAL, MAGIC }

var amount := 0.0
var type: Type = Type.PHYSICAL
var knockback := Vector3.ZERO      ## world-space push applied to the target
var knockdown := false             ## puts the target on the floor (Sheep / Ox need this)
var stun := 0.25                   ## hit-stagger seconds when not knocked down
var shatter := false               ## breaking a prop on the target strips its armor
var element: StringName = &""      ## fire / water / magic / food (M2)
var source: Node = null            ## the fighter (or prop) that dealt it
var whiff := false                 ## set by the target: passed through it (dodge, getup, i-frames)


static func make(p_amount: float, p_source: Node = null, p_type: Type = Type.PHYSICAL) -> DamageInfo:
	var d := DamageInfo.new()
	d.amount = p_amount
	d.source = p_source
	d.type = p_type
	return d
