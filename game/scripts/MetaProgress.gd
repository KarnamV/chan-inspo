## MetaProgress.gd — AutoLoad singleton for PERSISTENT meta-progression.
##
## Unlike RunStats (which resets every run), this survives across runs AND app
## restarts by saving to user://meta.cfg. It holds:
##   - total_shards       : banked Spirit Shards (the meta-currency)
##   - upgrades           : permanent perk levels bought in the Hub
##   - max_realm_unlocked : highest realm index the player may select
##   - selected_realm     : the realm chosen for the next run
##
## AutoLoad name: MetaProgress
## Register in project.godot: autoload/MetaProgress="*res://scripts/MetaProgress.gd"

extends Node

signal shards_changed(total: int)
signal upgrades_changed()

const SAVE_PATH: String = "user://meta.cfg"

# ---------------------------------------------------------------------------
# Persistent state
# ---------------------------------------------------------------------------
var total_shards: int = 0
var upgrades: Dictionary = {"max_hp": 0, "damage": 0, "speed": 0, "slots": 0}
var max_realm_unlocked: int = 0
var selected_realm: int = 0

# ---------------------------------------------------------------------------
# Upgrade tuning — perk key → max level, and per-level effect strength.
# ---------------------------------------------------------------------------
const UPGRADE_MAX_LEVEL: Dictionary = {"max_hp": 5, "damage": 5, "speed": 4, "slots": 2}
const UPGRADE_BASE_COST: int = 3    # shards for level 0 → 1
const UPGRADE_COST_STEP: int = 2    # added per existing level

const HP_PER_LEVEL:     int   = 20
const DAMAGE_PER_LEVEL: float = 0.10
const SPEED_PER_LEVEL:  float = 0.06

# Human-readable perk labels for the Hub menu.
const UPGRADE_LABELS: Dictionary = {
	"max_hp": "Iron Constitution  (+20 Max HP)",
	"damage": "Honed Strikes  (+10% damage)",
	"speed":  "Fleet Footwork  (+6% move speed)",
	"slots":  "Talisman Attunement  (+1 start slot)",
}


func _ready() -> void:
	load_data()


# ---------------------------------------------------------------------------
# Shards
# ---------------------------------------------------------------------------

## Bank Spirit Shards earned from a completed run. Persists immediately.
func bank_shards(amount: int) -> void:
	if amount <= 0:
		return
	total_shards += amount
	emit_signal("shards_changed", total_shards)
	save_data()


# ---------------------------------------------------------------------------
# Upgrades
# ---------------------------------------------------------------------------

func upgrade_level(key: String) -> int:
	return int(upgrades.get(key, 0))

func upgrade_max(key: String) -> int:
	return int(UPGRADE_MAX_LEVEL.get(key, 0))

func is_maxed(key: String) -> bool:
	return upgrade_level(key) >= upgrade_max(key)

func upgrade_cost(key: String) -> int:
	return UPGRADE_BASE_COST + UPGRADE_COST_STEP * upgrade_level(key)

func can_buy_upgrade(key: String) -> bool:
	return not is_maxed(key) and total_shards >= upgrade_cost(key)

## Purchase one level of a perk. Returns true on success. Persists immediately.
func buy_upgrade(key: String) -> bool:
	if not can_buy_upgrade(key):
		return false
	total_shards -= upgrade_cost(key)
	upgrades[key] = upgrade_level(key) + 1
	emit_signal("shards_changed", total_shards)
	emit_signal("upgrades_changed")
	save_data()
	return true


# ---------------------------------------------------------------------------
# Run-start bonuses — read by TestRoom when applying perks to a fresh run.
# ---------------------------------------------------------------------------

func bonus_max_hp() -> int:
	return HP_PER_LEVEL * upgrade_level("max_hp")

func damage_mult() -> float:
	return 1.0 + DAMAGE_PER_LEVEL * upgrade_level("damage")

func speed_mult() -> float:
	return 1.0 + SPEED_PER_LEVEL * upgrade_level("speed")

func bonus_slots() -> int:
	return upgrade_level("slots")


# ---------------------------------------------------------------------------
# Realm unlocks
# ---------------------------------------------------------------------------

func unlock_realm(index: int) -> void:
	if index > max_realm_unlocked:
		max_realm_unlocked = index
		save_data()

func is_realm_unlocked(index: int) -> bool:
	return index <= max_realm_unlocked


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func save_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("meta", "total_shards", total_shards)
	cfg.set_value("meta", "upgrades", upgrades)
	cfg.set_value("meta", "max_realm_unlocked", max_realm_unlocked)
	cfg.set_value("meta", "selected_realm", selected_realm)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return   # no save yet — keep defaults
	total_shards = int(cfg.get_value("meta", "total_shards", 0))
	var stored: Dictionary = cfg.get_value("meta", "upgrades", {})
	for k in upgrades.keys():
		if stored.has(k):
			upgrades[k] = int(stored[k])
	max_realm_unlocked = int(cfg.get_value("meta", "max_realm_unlocked", 0))
	selected_realm = int(cfg.get_value("meta", "selected_realm", 0))

## Wipe all meta-progression (debug / new-game). Persists immediately.
func reset_all() -> void:
	total_shards = 0
	upgrades = {"max_hp": 0, "damage": 0, "speed": 0, "slots": 0}
	max_realm_unlocked = 0
	selected_realm = 0
	emit_signal("shards_changed", total_shards)
	emit_signal("upgrades_changed")
	save_data()
