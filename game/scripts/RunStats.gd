## RunStats.gd — AutoLoad singleton that tracks per-run statistics.
##
## Persists across scene changes (AutoLoad lives for the application lifetime).
## Call reset() at the start of every New Run so no stale data bleeds in.
##
## AutoLoad name: RunStats
## Register in project.godot: autoload/RunStats="*res://scripts/RunStats.gd"

extends Node

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

# ---------------------------------------------------------------------------
# Meta-currency formula (placeholder, Phase 3 will flesh this out)
# ---------------------------------------------------------------------------
## Spirit Shards earned this run.  Phase 3 will tie these to a real shop.
## Formula: floor(spirit_collected / 50) — 50 spirit points = 1 shard.
const SPIRIT_PER_SHARD: float = 50.0

func spirit_shards_earned() -> int:
	return int(spirit_collected / SPIRIT_PER_SHARD)


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

## Reset all run stats to zero.  Call this before starting a new run so that
## leftover numbers from a previous death do not persist.
func reset() -> void:
	rooms_visited  = 0
	enemies_killed = 0
	spirit_collected = 0.0
