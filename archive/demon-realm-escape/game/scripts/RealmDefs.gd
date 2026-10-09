## RealmDefs.gd — static data for the 7 demon realms.
##
## Each realm has a name, a floor colour (theme), an accent (for banners), and
## difficulty multipliers applied to enemy HP and damage at run start.
## Realm 0 is the entry realm (always unlocked). Beating a realm's BOSS room
## unlocks the next (see MetaProgress.unlock_realm / TestRoom).

class_name RealmDefs
extends RefCounted

const REALMS: Array = [
	{ "name": "Ember Wastes",    "floor": Color(0.14, 0.09, 0.09), "accent": Color(1.00, 0.55, 0.30), "hp_mult": 1.00, "dmg_mult": 1.00 },
	{ "name": "Frostmarch",      "floor": Color(0.09, 0.11, 0.16), "accent": Color(0.55, 0.80, 1.00), "hp_mult": 1.15, "dmg_mult": 1.10 },
	{ "name": "Verdant Rot",     "floor": Color(0.09, 0.13, 0.09), "accent": Color(0.55, 1.00, 0.50), "hp_mult": 1.30, "dmg_mult": 1.20 },
	{ "name": "Ashfall Keep",    "floor": Color(0.12, 0.12, 0.13), "accent": Color(0.85, 0.85, 0.85), "hp_mult": 1.50, "dmg_mult": 1.35 },
	{ "name": "Bone Cathedral",  "floor": Color(0.15, 0.14, 0.12), "accent": Color(0.95, 0.92, 0.80), "hp_mult": 1.70, "dmg_mult": 1.50 },
	{ "name": "Void Reach",      "floor": Color(0.12, 0.08, 0.16), "accent": Color(0.75, 0.50, 1.00), "hp_mult": 2.00, "dmg_mult": 1.70 },
	{ "name": "Demon Throne",    "floor": Color(0.16, 0.06, 0.08), "accent": Color(1.00, 0.30, 0.35), "hp_mult": 2.40, "dmg_mult": 2.00 },
]


static func count() -> int:
	return REALMS.size()


## Returns the realm dictionary at `index`, clamped into range.
static func get_realm(index: int) -> Dictionary:
	return REALMS[clampi(index, 0, REALMS.size() - 1)]


static func realm_name(index: int) -> String:
	return get_realm(index)["name"]
