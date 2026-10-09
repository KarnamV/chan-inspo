extends GutTest

var _level: Node3D


func _root() -> Node3D:
	if _level == null or not is_instance_valid(_level):
		_level = Node3D.new()
		_level.add_to_group(&"level_root")
		add_child(_level)
	return _level


func _data(id: StringName, durability: int, pieces: Array = []) -> PropData:
	var d := PropData.new()
	d.id = id
	d.durability = durability
	var typed: Array[PropData] = []
	for p in pieces:
		typed.append(p)
	d.pieces = typed
	return d


func _spawn(d: PropData) -> Prop:
	var p := Prop.new()
	p.data = d
	_root().add_child(p)
	return p


func after_each() -> void:
	for n in get_tree().get_nodes_in_group(&"props"):
		n.queue_free()
	await wait_process_frames(2)


func test_wear_counts_down_without_breaking() -> void:
	var p := _spawn(_data(&"chair", 4))
	assert_false(p.wear(1))
	assert_eq(p.durability_left(), 3)
	assert_true(p.can_pick_up())


func test_breaking_degrades_into_pieces() -> void:
	var leg := _data(&"leg", 2)
	var p := _spawn(_data(&"chair", 2, [leg, leg]))
	watch_signals(Events)
	assert_true(p.wear(2), "wear to zero breaks it")
	assert_signal_emitted(Events, "prop_broken")
	var params: Array = get_signal_parameters(Events, "prop_broken")
	assert_eq((params[1] as Array).size(), 2, "chair -> two legs")
	for piece in params[1]:
		assert_eq((piece as Prop).data.id, &"leg")
		assert_true((piece as Prop).can_pick_up(), "pieces are usable props")


func test_piece_with_no_pieces_just_vanishes() -> void:
	var p := _spawn(_data(&"stake", 1))
	watch_signals(Events)
	p.wear(5)
	var params: Array = get_signal_parameters(Events, "prop_broken")
	assert_eq((params[1] as Array).size(), 0)
	assert_eq(p.mode, Prop.Mode.BROKEN)
