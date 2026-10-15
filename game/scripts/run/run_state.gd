extends Node
## The current run (autoload "Run"): room sequence for realm 1, doors + rewards, gold, carried HP /
## spirit / talismans / chi / boons, extra lives. Death or victory converts progress into Shards.

const ROOM_SCENE := "res://scenes/run/room.tscn"
const HUB_SCENE := "res://scenes/run/hub.tscn"

## Realm 1: Ember Night Market. Story rooms introduce helpers; the boss closes the realm.
const REALM1 := [
	{"type": "combat", "depth": 1},
	{"type": "combat", "depth": 2},
	{"type": "story", "depth": 2, "helper": &"stunt_coordinator"},
	{"type": "combat", "depth": 3},
	{"type": "shop", "depth": 3},
	{"type": "story", "depth": 4, "helper": &"street_chef", "fight": true},
	{"type": "combat", "depth": 5},
	{"type": "rest", "depth": 5},
	{"type": "combat", "depth": 6, "elite": true},
	{"type": "boss", "depth": 7, "boss": &"butcher_king"},
]
const REST_KINDS := ["shrine", "vault"]
const ENEMY_POOL := [&"brute", &"shield_demon", &"thief_imp", &"archer_demon", &"wraith", &"armored_ghoul"]
const REWARDS := [&"talisman", &"boon", &"draft", &"gold"]

var active := false
var room_i := 0
var gold := 0
var hp := -1.0
var max_hp_bonus := 0.0
var spirit := 0.0
var talismans: Array = []
var chi_unlocked := {}
var chi_level := {}
var boons: Array = []
var mods := {"bare_mult": 1.0, "prop_mult": 1.0, "light_mult": 1.0, "durability_bonus": 0,
	"dodge_cd_mult": 1.0, "fire_mult": 1.0}
var extra_lives := 0
var pending_reward: StringName = &""
var rest_kind := "shrine"
var rooms_cleared := 0
var rng := RandomNumberGenerator.new()
var victory := false


func start_run(p_talismans: Array, seed_value := -1) -> void:
	active = true
	victory = false
	room_i = 0
	gold = 0
	hp = -1.0
	max_hp_bonus = 0.0
	spirit = 0.0
	talismans = p_talismans.duplicate()
	chi_unlocked = {&"palm": false, &"wave": false, &"pull": false, &"blink": false}
	chi_level = {&"palm": 1, &"wave": 1, &"pull": 1, &"blink": 1}
	boons = []
	mods = {"bare_mult": 1.0, "prop_mult": 1.0, "light_mult": 1.0, "durability_bonus": 0,
		"dodge_cd_mult": 1.0, "fire_mult": 1.0}
	extra_lives = 0
	pending_reward = &"talisman"   # runs start empty-handed: the first room always gives a talisman
	rooms_cleared = 0
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	Meta.runs += 1
	Meta.save_meta()


func spec() -> Dictionary:
	var s: Dictionary = REALM1[clampi(room_i, 0, REALM1.size() - 1)].duplicate()
	if s.type == "rest":
		s.type = rest_kind
	return s


func is_last_room() -> bool:
	return room_i >= REALM1.size() - 1


## Two doors out of the current room. Reward doors for normal rooms; the next room's type when it
## is special (shop / rest / story / boss).
func door_options() -> Array:
	if is_last_room():
		return []
	var nxt: Dictionary = REALM1[room_i + 1]
	var pool: Array = REWARDS.duplicate()
	if Meta.helpers_met.is_empty() and boons.is_empty():
		pool.erase(&"boon")
	pool.shuffle()
	match nxt.type:
		"boss":
			return [{"reward": &"boss", "label": "The Butcher King"}]
		"shop":
			return [{"reward": &"shop", "label": "Shop"}, {"reward": pool[0], "label": _label(pool[0])}]
		"story":
			return [{"reward": &"story", "label": "Someone is waiting..."}]
		"rest":
			return [{"reward": &"shrine", "label": "Shrine"}, {"reward": &"vault", "label": "Prop vault"}]
	return [{"reward": pool[0], "label": _label(pool[0])}, {"reward": pool[1], "label": _label(pool[1])}]


func _label(r: StringName) -> String:
	return {&"talisman": "Talisman", &"boon": "Helper's boon", &"draft": "New technique",
		&"gold": "Gold"}.get(r, String(r))


func choose_door(opt: Dictionary) -> void:
	var r: StringName = opt.reward
	pending_reward = r if r in REWARDS else &""
	if r == &"shrine" or r == &"vault":
		rest_kind = String(r)
	room_i += 1
	Fade.to_scene(ROOM_SCENE)


func room_cleared() -> void:
	rooms_cleared += 1
	Meta.best_room = maxi(Meta.best_room, rooms_cleared)


## Called by the room when the player body changes rooms or dies.
func store(pc: PlayerController) -> void:
	hp = pc.hero.health.hp
	spirit = pc.spirit
	talismans = pc.equipped.map(func(t: Talisman) -> StringName: return t.id)
	chi_unlocked = pc.chi_unlocked.duplicate()
	chi_level = pc.chi_level.duplicate()


func apply(pc: PlayerController) -> void:
	pc.hero.health.max_hp += max_hp_bonus
	pc.hero.health.hp = pc.hero.health.max_hp if hp < 0.0 else minf(hp, pc.hero.health.max_hp)
	pc.spirit = spirit
	pc.chi_unlocked = chi_unlocked.duplicate()
	pc.chi_level = chi_level.duplicate()
	pc.boss_ledger = Meta.boss_ledger
	pc.equip(talismans)
	for b in boons:
		pc.add_boon(b)
	pc.hero.data_mods = mods


func end_run(won: bool) -> void:
	victory = won
	var earned := rooms_cleared * 4 + (40 if won else 0)
	Meta.shards += earned
	Meta.save_meta()
	active = false
	last_summary = {"won": won, "rooms": rooms_cleared, "shards": earned, "gold": gold}


var last_summary := {}


func go_hub() -> void:
	Fade.to_scene(HUB_SCENE)


## Enemy waves for a combat room at `depth` (1..7).
func waves_for(depth: int, elite: bool) -> Array:
	var pool_size := clampi(1 + depth, 2, ENEMY_POOL.size())
	var count := clampi(1 + depth / 2, 2, 5) + (1 if elite else 0)
	var waves: Array = []
	var n_waves := 1 if depth <= 2 else 2
	for w in n_waves:
		var wave: Array = []
		for i in count - (1 if w == 0 and n_waves > 1 else 0):
			wave.append(ENEMY_POOL[rng.randi_range(0, pool_size - 1)])
		waves.append(wave)
	return waves
