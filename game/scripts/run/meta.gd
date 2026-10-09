extends Node
## Persistent meta progression (survives death): Spirit Shards, boss ledger (feeds Monkey),
## helpers met + bonds, unlocked talismans, prop codex. Saved to user://meta.json.

const PATH := "user://meta.json"
const STARTING_TALISMANS := [&"sheep", &"tiger", &"rat", &"dragon", &"ox", &"horse"]
const TALISMAN_PRICE := 30
const BOND_PRICE := 20

var shards := 0
var boss_ledger := {}            # boss id -> kills
var helpers_met: Array = []      # helper ids
var bonds := {}                  # helper id -> bond level
var unlocked: Array = []         # talisman ids
var codex: Array = []            # prop ids seen
var runs := 0
var best_room := 0
var save_enabled := true


func _ready() -> void:
	load_meta()


func load_meta() -> void:
	unlocked = STARTING_TALISMANS.duplicate()
	if not save_enabled or not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	shards = int(d.get("shards", 0))
	runs = int(d.get("runs", 0))
	best_room = int(d.get("best_room", 0))
	for k in d.get("boss_ledger", {}):
		boss_ledger[StringName(k)] = int(d["boss_ledger"][k])
	helpers_met = (d.get("helpers_met", []) as Array).map(func(x: Variant) -> StringName: return StringName(x))
	for k in d.get("bonds", {}):
		bonds[StringName(k)] = int(d["bonds"][k])
	var u: Array = (d.get("unlocked", []) as Array).map(func(x: Variant) -> StringName: return StringName(x))
	for t in u:
		if t not in unlocked:
			unlocked.append(t)
	codex = (d.get("codex", []) as Array).map(func(x: Variant) -> StringName: return StringName(x))


func save_meta() -> void:
	if not save_enabled:
		return
	var d := {"shards": shards, "runs": runs, "best_room": best_room, "boss_ledger": boss_ledger,
		"helpers_met": helpers_met, "bonds": bonds, "unlocked": unlocked, "codex": codex}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))


func record_boss(id: StringName) -> void:
	boss_ledger[id] = int(boss_ledger.get(id, 0)) + 1
	save_meta()


func meet_helper(id: StringName) -> void:
	if id not in helpers_met:
		helpers_met.append(id)
		bonds[id] = 0
		save_meta()


func see_prop(id: StringName) -> void:
	if id not in codex:
		codex.append(id)


func buy_talisman(id: StringName) -> bool:
	if id in unlocked or shards < TALISMAN_PRICE:
		return false
	shards -= TALISMAN_PRICE
	unlocked.append(id)
	save_meta()
	return true


func raise_bond(id: StringName) -> bool:
	if id not in helpers_met or shards < BOND_PRICE or int(bonds.get(id, 0)) >= 3:
		return false
	shards -= BOND_PRICE
	bonds[id] = int(bonds.get(id, 0)) + 1
	save_meta()
	return true


func reset_all() -> void:
	shards = 0
	boss_ledger = {}
	helpers_met = []
	bonds = {}
	unlocked = STARTING_TALISMANS.duplicate()
	codex = []
	runs = 0
	best_room = 0
	save_meta()
