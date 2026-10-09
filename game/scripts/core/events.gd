extends Node
## Global signal bus. Systems emit here; UI, audio and tests listen, so gameplay code never
## needs to know who is watching.

signal damage_dealt(target: Node, info: DamageInfo, amount: float)
signal entity_died(entity: Node)
signal prop_broken(prop: Node, pieces: Array)
signal knocked_down(entity: Node)
signal spirit_changed(value: float, max_value: float)
signal possession_started(host: Node)
signal possession_ended(host: Node, reason: StringName)
signal room_cleared(room: Node)
signal chi_used(fighter: Node, id: StringName)
signal parried(fighter: Node, attacker: Node)
signal tiger_split(yang: Node, yin: Node)
signal tiger_merged(hero: Node)
signal monkey_changed(form: Node, attacks_left: int)
signal dog_saved(hero: Node, convert: Node)
signal food_eaten(fighter: Node)
signal talismans_changed
signal prop_animated(prop: Node)
signal boss_killed(id: StringName)
signal talisman_used(id: StringName)
signal boss_phase(boss: Node, phase: int)
signal prop_picked(fighter: Node, prop: Node)
signal run_reward(kind: StringName, id: StringName)
