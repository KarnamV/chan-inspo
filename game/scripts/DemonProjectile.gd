## DemonProjectile.gd — small purple projectile fired by the Demon enemy.
##
## Moves in a straight line at constant speed.
## Despawns when:
##   - It hits the player (calls player.take_hit with knockback + damage)
##   - It hits a wall / physics body (body_entered on the Area2D)
##   - It travels further than MAX_RANGE pixels from its spawn point
##
## Designed as a separate scene so future pooling / VFX can be added here.

extends Area2D

const SPEED:     float = 280.0
const MAX_RANGE: float = 600.0

var _direction: Vector2 = Vector2.RIGHT
var _damage:    int     = 12
var _spawn_pos: Vector2 = Vector2.ZERO


## Called immediately after instantiation by Demon._shoot().
func init(direction: Vector2, damage: int) -> void:
	_direction = direction
	_damage    = damage
	_spawn_pos = global_position


func _ready() -> void:
	# Connect the area's body_entered signal to handle player/wall hits.
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += _direction * SPEED * delta

	# Despawn if out of range.
	if global_position.distance_to(_spawn_pos) > MAX_RANGE:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == null:
		return

	# Hit the player?
	if body.is_in_group("player"):
		var knockback: Vector2 = _direction * 220.0
		body.take_hit(knockback, _damage)
		queue_free()
		return

	# Hit any other physics body (wall, etc.) — just despawn.
	queue_free()
