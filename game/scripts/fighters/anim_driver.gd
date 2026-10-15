class_name AnimDriver
extends RefCounted
## Thin wrapper over the model's AnimationPlayer: crossfades, time-stretches attacks to their
## duration, and falls back gracefully when a clip is missing (generated rigs share one clip set).

const FALLBACK := {
	&"knockdown": &"death", &"getup": &"death", &"throw": &"punch_cross", &"heavy": &"swing",
	&"sprint": &"run", &"stagger": &"hit", &"guard": &"idle", &"lying": &"death",
	&"chop": &"heavy", &"thrust": &"punch_cross", &"spin": &"swing", &"ram": &"heavy",
}

var player: AnimationPlayer
var current: StringName = &""


func _init(model: Node) -> void:
	if model:
		var found := model.find_children("*", "AnimationPlayer", true, false)
		if not found.is_empty():
			player = found[0]


func resolve(clip: StringName) -> StringName:
	if player == null:
		return &""
	if player.has_animation(clip):
		return clip
	var fb: StringName = FALLBACK.get(clip, &"idle")
	return fb if player.has_animation(fb) else &""


## Plays `clip` (looping clips keep looping). `fit_seconds` > 0 stretches the clip to that length.
func play(clip: StringName, blend := 0.12, fit_seconds := 0.0, backwards := false) -> void:
	var name := resolve(clip)
	if name == &"":
		return
	var speed := 1.0
	if fit_seconds > 0.0:
		speed = player.get_animation(name).length / fit_seconds
	if backwards:
		player.play_backwards(name, blend)
		player.speed_scale = speed
	else:
		var again := player.current_animation == name and player.is_playing()
		player.play(name, blend, 1.0)
		if again:   # same clip back to back (chop -> chop): play() alone would just carry on
			player.seek(0.0, true)
		player.speed_scale = speed
	current = clip


## Holds the final frame of a non-looping clip (e.g. lying on the floor after the fall).
func hold_end(clip: StringName) -> void:
	var name := resolve(clip)
	if name == &"":
		return
	player.play(name, 0.05)
	player.seek(player.get_animation(name).length, true)
	player.pause()
	current = clip


func ensure(clip: StringName, blend := 0.15) -> void:
	if current != clip or not player or not player.is_playing():
		play(clip, blend)
