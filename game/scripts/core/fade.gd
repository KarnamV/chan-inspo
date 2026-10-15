extends CanvasLayer
## Autoload "Fade": a full-screen black overlay that survives scene changes. `to_scene` fades out,
## swaps the scene, waits for the new one to draw a couple of frames, then fades back in, so the
## room build never shows as a frozen frame.

const OUT_TIME := 0.35
const IN_TIME := 0.45

var _rect: ColorRect
var _tween: Tween
var busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


func to_scene(path: String) -> void:
	if busy:
		return
	busy = true
	_fade(1.0, OUT_TIME)
	await _tween.finished
	AssetCache.wait_all()   # normally long done; never race the room build against it
	get_tree().change_scene_to_file(path)
	for i in 3:   # scene swap happens at the end of this frame; then let the new room draw
		await get_tree().process_frame
	_fade(0.0, IN_TIME)
	await _tween.finished
	busy = false


func _fade(to: float, time: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", to, time)
