## 玩家：移动、自动向最近敌人射击、环绕球、升级与拾取经验、受击反馈。
## 碰撞：layer1，只与敌人 layer2 物理挤压；敌弹为 Area2D 检测，不依赖 mask。
## 扩展：在 apply_upgrade() 增加新 id；投射物/环绕场景由 player.tscn 的 export 引用。
extends CharacterBody2D

signal health_changed(current: float, max_hp: float)
signal died
signal leveled_up(new_level: int, xp_to_next: float)
signal score_changed(score: int)

@export var projectile_scene: PackedScene
@export var orbit_orb_scene: PackedScene

const ORBIT_SPIN := 2.35

@onready var orbit_rig: Node2D = $OrbitRig
@onready var visual: Polygon2D = $Visual
@onready var camera: Camera2D = $Camera2D

var _shake_t: float = 0.0
var _base_visual_color := Color(0.35, 0.75, 1.0, 1.0)

var max_hp: float = 100.0
var hp: float = 100.0
var speed: float = 240.0
var xp: float = 0.0
var level: int = 1
var xp_to_next: float = 40.0
## 拾取经验球获得的积分（与经验球数值一致）
var score: int = 0

var fire_rate: float = 0.42
var fire_cooldown: float = 0.0
var projectile_damage: float = 14.0
## 每次齐射额外发射的子弹数（总发数 = 1 + bonus_projectiles）
var bonus_projectiles: int = 0

var orbit_orb_count: int = 0
var orbit_base_radius: float = 54.0
var orbit_damage: float = 7.0


func _ready() -> void:
	add_to_group("player")
	health_changed.emit(hp, max_hp)
	score_changed.emit(score)


func _physics_process(delta: float) -> void:
	var dir := _get_movement_input()
	if dir.length_squared() > 0.0001:
		velocity = dir.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if _shake_t > 0.0:
		_shake_t -= delta
		if camera:
			camera.offset = Vector2(randf_range(-7.0, 7.0), randf_range(-5.0, 5.0))
	else:
		if camera:
			camera.offset = Vector2.ZERO

	orbit_rig.rotation += ORBIT_SPIN * delta

	fire_cooldown -= delta
	if fire_cooldown <= 0.0 and try_fire():
		fire_cooldown = fire_rate


func _get_movement_input() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1.0
	return d


func try_fire() -> bool:
	var n := 1 + bonus_projectiles
	var targets := _get_nearest_enemies(n)
	if targets.is_empty():
		return false
	for t in targets:
		var proj: Node2D = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = global_position
		var dir := (t.global_position - global_position).normalized()
		if proj.has_method("setup"):
			proj.setup(dir, projectile_damage)
	GameAudio.play_player_shoot()
	return true


func _get_nearest_enemies(n: int) -> Array[Node2D]:
	var pairs: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and is_instance_valid(e):
			pairs.append(
				{"n": e, "d": global_position.distance_squared_to(e.global_position)}
			)
	pairs.sort_custom(func(a, b): return a["d"] < b["d"])
	var out: Array[Node2D] = []
	var take: int = min(n, pairs.size())
	for i in range(take):
		out.append(pairs[i]["n"])
	return out


func _rebuild_orbit_orbs() -> void:
	for c in orbit_rig.get_children():
		c.queue_free()
	if orbit_orb_count <= 0 or orbit_orb_scene == null:
		return
	for i in range(orbit_orb_count):
		var o: Node = orbit_orb_scene.instantiate()
		orbit_rig.add_child(o)
		var angle := TAU * float(i) / float(orbit_orb_count)
		o.position = Vector2(cos(angle), sin(angle)) * orbit_base_radius
		if o.has_method("setup"):
			o.setup(orbit_damage)


func apply_upgrade(id: String) -> void:
	match id:
		"orbit_orb":
			orbit_orb_count += 1
			_rebuild_orbit_orbs()
		"extra_projectile":
			bonus_projectiles += 1
		"damage_up":
			projectile_damage *= 1.12
			orbit_damage *= 1.12
			_rebuild_orbit_orbs()
		"fire_rate":
			fire_rate *= 0.92
			fire_rate = maxf(0.12, fire_rate)
		"move_speed":
			speed *= 1.08
		"heal":
			hp = minf(hp + 0.28 * max_hp, max_hp)
			health_changed.emit(hp, max_hp)


func take_damage(amount: float) -> void:
	hp -= amount
	GameAudio.play_player_hurt()
	if visual and is_instance_valid(visual):
		var tw := create_tween()
		tw.tween_property(visual, "modulate", Color(1.0, 0.42, 0.42, 1.0), 0.06)
		tw.tween_property(visual, "modulate", _base_visual_color, 0.16)
	_shake_t = 0.14
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_damage_float"):
		main.spawn_damage_float(global_position, amount, Color(1, 0.28, 0.28, 1))
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		hp = 0.0
		if camera:
			camera.offset = Vector2.ZERO
		set_physics_process(false)
		collision_layer = 0
		collision_mask = 0
		died.emit()


func add_xp(amount: float) -> void:
	xp += amount
	score += int(round(amount))
	score_changed.emit(score)
	while xp >= xp_to_next:
		xp -= xp_to_next
		_do_level_up()


func _do_level_up() -> void:
	level += 1
	max_hp += 10.0
	hp = minf(hp + 18.0, max_hp)
	projectile_damage *= 1.09
	fire_rate *= 0.96
	fire_rate = maxf(0.14, fire_rate)
	speed += 3.0
	xp_to_next = 32.0 + float(level) * 18.0
	leveled_up.emit(level, xp_to_next)
	health_changed.emit(hp, max_hp)
