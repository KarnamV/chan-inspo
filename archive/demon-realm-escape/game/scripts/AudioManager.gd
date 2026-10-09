## AudioManager.gd — AutoLoad for all SFX and music playback.
##
## Designed for the AI asset pipeline: it references audio by KEY and looks up a
## file in res://assets/audio/. When a file does not exist yet it simply no-ops,
## so the game runs silently until AI-generated audio is dropped in — no code
## changes needed later. Add a file named <key>.ogg (or .wav) to the right folder
## and it plays automatically.
##
## AutoLoad name: AudioManager
## Register in project.godot: autoload/AudioManager="*res://scripts/AudioManager.gd"

extends Node

const SFX_DIR:   String = "res://assets/audio/sfx/"
const MUSIC_DIR: String = "res://assets/audio/music/"

## Canonical SFX keys the game triggers. Drop <key>.ogg/.wav into SFX_DIR.
const SFX_KEYS: Array = [
	"hit",           # player strike connects
	"big_hit",       # counter / talisman-boosted hit
	"enemy_death",   # enemy destroyed
	"player_hurt",   # player takes damage
	"coin",          # gold pickup collected
	"talisman",      # talisman activated
	"ui_open",       # shop/shrine/temptation overlay opens
	"purchase",      # bought something / took a pact
	"miniboss",      # mini-boss appears
]

const SFX_POOL_SIZE: int = 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _music_player: AudioStreamPlayer = null

# key/name → AudioStream or null (cached so a missing file is only probed once).
var _cache: Dictionary = {}


func _ready() -> void:
	# Keep audio alive while the tree is paused (shop/shrine overlays pause it).
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in SFX_POOL_SIZE:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Play a one-shot SFX by key. Silent no-op if the file isn't present yet.
func play_sfx(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _resolve(SFX_DIR, key)
	if stream == null:
		return
	var p: AudioStreamPlayer = _sfx_players[_next_player]
	_next_player = (_next_player + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


## Play a looping music track by name (file base name in MUSIC_DIR). No-op +
## stops current music if the file isn't present.
func play_music(name: String, volume_db: float = -6.0) -> void:
	var stream: AudioStream = _resolve(MUSIC_DIR, name)
	if stream == null:
		_music_player.stop()
		return
	# Enable looping where the stream type supports it.
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true
	if _music_player.stream == stream and _music_player.playing:
		return   # already playing this track
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

## Find <base>.<ext> in dir for the first supported extension; cache the result.
func _resolve(dir: String, base: String) -> AudioStream:
	var cache_key: String = dir + base
	if _cache.has(cache_key):
		return _cache[cache_key]
	var stream: AudioStream = null
	for ext in [".ogg", ".wav", ".mp3"]:
		var path: String = dir + base + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	_cache[cache_key] = stream
	return stream
