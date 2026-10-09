extends GutTest

var h: Health


func before_each() -> void:
	h = Health.new()
	h.max_hp = 100.0
	add_child_autofree(h)


func test_physical_damage_respects_resist() -> void:
	h.resist_physical = 0.5
	var taken := h.take(DamageInfo.make(20.0))
	assert_eq(taken, 10.0)
	assert_eq(h.hp, 90.0)


func test_magic_uses_magic_resist_only() -> void:
	h.resist_physical = 0.9
	h.resist_magic = 0.25
	assert_eq(h.take(DamageInfo.make(20.0, null, DamageInfo.Type.MAGIC)), 15.0)


func test_shatter_strips_physical_armor_temporarily() -> void:
	h.resist_physical = 0.8
	var s := DamageInfo.make(10.0)
	s.shatter = true
	h.take(s)
	assert_eq(h.take(DamageInfo.make(10.0)), 10.0, "armor stripped right after a shatter")
	h._process(h.shatter_seconds + 0.1)
	assert_almost_eq(h.take(DamageInfo.make(10.0)), 2.0, 0.001, "armor back after shatter_seconds")


func test_invulnerable_takes_nothing() -> void:
	h.invulnerable = true
	assert_eq(h.take(DamageInfo.make(50.0)), 0.0)
	assert_eq(h.hp, 100.0)


func test_died_emits_once_and_dead_takes_nothing() -> void:
	watch_signals(h)
	h.take(DamageInfo.make(150.0))
	assert_true(h.is_dead())
	assert_signal_emit_count(h, "died", 1)
	assert_eq(h.take(DamageInfo.make(10.0)), 0.0)
	assert_signal_emit_count(h, "died", 1)
