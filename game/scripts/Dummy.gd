extends CharacterBody2D

const MAX_HP: int = 30

var current_hp: int = MAX_HP

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label = $HPLabel
@onready var hit_area: Area2D = $HitArea


func _ready() -> void:
	_refresh_label()


func take_damage(dmg: int) -> void:
	if current_hp <= 0:
		return
	current_hp -= dmg
	_refresh_label()
	_flash_red()
	if current_hp <= 0:
		_die()


func _refresh_label() -> void:
	hp_label.text = "HP: %d/%d" % [max(current_hp, 0), MAX_HP]


func _flash_red() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.04)
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)


func _die() -> void:
	print("[Dummy] %s destroyed." % name)
	set_process(false)
	set_physics_process(false)
	hit_area.monitoring = false
	hit_area.monitorable = false

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 0.0), 0.3)
	tween.tween_property(hp_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2)
	tween.chain().tween_callback(queue_free)
