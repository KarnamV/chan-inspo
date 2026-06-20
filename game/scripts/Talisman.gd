extends Node

# ---------------------------------------------------------------------------
# Talisman.gd — Base class for all talismans.
#
# Each talisman is a Node child of the entity that holds it (Player, Enemy).
# Being a Node (not Resource) lets talismans own Timers, Tweens, and signals.
#
# Subclasses override activate() and deactivate().
# activate() is called every time the player presses the talisman key —
# it is up to the subclass to decide whether that means "toggle", "cast", etc.
# ---------------------------------------------------------------------------

## The player (or entity) currently bound to this talisman.
## Set by the owner scene (e.g. TestRoom) before activate() is first called.
var bound_player: Node = null


## Called when the player activates this talisman (key press).
## Override in subclasses. Default: no-op.
func activate(player: Node) -> void:
	pass


## Called when this talisman is unequipped / replaced.
## Override to clean up any lingering effects.
func deactivate(player: Node) -> void:
	pass
