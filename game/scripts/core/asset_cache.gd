extends Node
## Autoload "AssetCache": loads every model, data file, icon and shader once, on worker threads,
## starting at boot (during the story intro / hub), and keeps a reference to each one forever.
## Without it, changing scene frees the old room, every resource's refcount drops to zero and the
## next room re-reads ~150 MB of .glb files from disk: a 3-5 s frozen frame per room.

const DIRS := ["res://data/fighters", "res://data/props", "res://assets/decors", "res://assets/characters",
	"res://assets/props", "res://assets/pieces", "res://assets/icons", "res://assets/portraits",
	"res://assets/shaders", "res://scenes/run"]
const EXTS := ["tres", "glb", "png", "gdshader", "tscn"]

var _held := {}
var _queue: Array[String] = []   # waiting to be requested
var _current := ""                # the one path loading on a worker thread right now
var _total := 0
var _t0 := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for dir in DIRS:
		for f in ResourceLoader.list_directory(dir):   # export-safe (sees remapped / imported names)
			if f.get_extension() in EXTS:
				_queue.append(dir.path_join(f))
	_total = _queue.size()
	_t0 = Time.get_ticks_msec()
	_next()


## One request at a time, no sub-threads: several in flight (or sub-threads) deadlocked the main
## thread when a room's own load() hit a resource a worker was half-way through.
func _next() -> void:
	_current = ""
	while not _queue.is_empty():
		var path: String = _queue.pop_front()
		if ResourceLoader.has_cached(path):
			_held[path] = load(path)
			continue
		if ResourceLoader.load_threaded_request(path, "", false) == OK:
			_current = path
			return
	set_process(false)
	print("AssetCache: %d/%d resources held, %d ms" % [_held.size(), _total, Time.get_ticks_msec() - _t0])


func _process(_delta: float) -> void:
	if _current == "":
		return
	var status := ResourceLoader.load_threaded_get_status(_current)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_held[_current] = ResourceLoader.load_threaded_get(_current)
	_next()


func is_ready() -> bool:
	return _current == "" and _queue.is_empty()


## Blocks until everything is in memory (tests; Fade calls it while the screen is black).
func wait_all() -> void:
	if _current != "":
		_held[_current] = ResourceLoader.load_threaded_get(_current)
	for path in _queue:
		_held[path] = load(path)
	_queue.clear()
	_current = ""
	set_process(false)
