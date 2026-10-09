extends Node
## Global signal bus. Systems emit here; UI, audio and tests listen, so gameplay code never
## needs to know who is watching.

signal damage_dealt(target: Node, info: DamageInfo, amount: float)
signal entity_died(entity: Node)
signal prop_broken(prop: Node, pieces: Array)
signal knocked_down(entity: Node)
signal spirit_changed(value: float, max_value: float)
signal possession_started(host: Node)
signal possession_ended(host: Node)
signal room_cleared(room: Node)
