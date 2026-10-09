## RunStats.gd — AutoLoad singleton that tracks per-run statistics.
##
## Persists across scene changes (AutoLoad lives for the application lifetime).
## Call reset() at the start of every New Run so no stale data bleeds in.
##
## AutoLoad name: RunStats
## Register in project.godot: autoload/RunStats="*res://scripts/RunStats.gd"

extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
## Emitted whenever the run gold balance changes (collected or spent).
## HUD.gd connects to this to keep the gold label in sync.
signal gold_changed(current: int)

# ---------------------------------------------------------------------------
# Run statistics — incremented during gameplay, read by Hub.gd
# ---------------------------------------------------------------------------

## Total rooms the player has entered this run (incremented in RoomManager).
var rooms_visited: int = 0

## Total enemies defeated this run (incremented in TestRoom._on_enemy_died).
var enemies_killed: int = 0

## Total spirit points gained from confirmed hits this run (incremented in Player.gd).
## Tracked as a float internally; Hub displays floor() for clean display.
var spirit_collected: float = 0.0

## Run-only gold — spent at shops/shrines within the run. Resets every New Run
## (lost on death, per design). Enemies drop gold on death via GoldPickup.
var gold: int = 0

## Running total of gold earned this run, for the death summary. Not reduced by
## spending, so the Hub can show how much the run generated overall.
var gold_earned: int = 0

# ---------------------------------------------------------------------------
# Meta-currency formula — Spirit Shards from distance + foes + spirit.
# Banked into MetaProgress.total_shards on death (see TestRoom._on_player_died).
# ---------------------------------------------------------------------------
## 50 spirit points = 1 shard.
const SPIRIT_PER_SHARD: float = 50.0
## Each room entered awards this many shards (distance reward).
const SHARDS_PER_ROOM: int = 1
## Enemies defeated per shard (foes reward).
const KILLS_PER_SHARD: int = 2

func spirit_shards_earned() -> int:
	return int(spirit_collected / SPIRIT_PER_SHARD) \
		+ rooms_visited * SHARDS_PER_ROOM \
		+ int(enemies_killed / KILLS_PER_SHARD)


# ---------------------------------------------------------------------------
# Gold — run-only currency
# ---------------------------------------------------------------------------

## Add gold to the run balance (called when a GoldPickup is collected).
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_earned += amount
	emit_signal("gold_changed", gold)


## Attempt to spend gold. Returns true if the player could afford it (and the
## balance was deducted); false if too poor. Shops/shrines call this.
func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	emit_signal("gold_changed", gold)
	return true


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

## Reset all run stats to zero.  Call this before starting a new run so that
## leftover numbers from a previous death do not persist.
func reset() -> void:
	rooms_visited  = 0
	enemies_killed = 0
	spirit_collected = 0.0
	gold = 0
	gold_earned = 0
	emit_signal("gold_changed", gold)
