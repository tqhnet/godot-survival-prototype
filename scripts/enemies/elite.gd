## 精英：移动较慢、血量更高，周期性向玩家发射直线 enemy_bullet（见 scenes/combat/enemy_bullet）。
## 组：enemies + elites，便于后续筛选。扩展：改射击间隔或换弹体场景。
extends CharacterBody2D

@export var hit_radius: float = 16.0
const PLAYER_HIT_RADIUS := 14.0

@export var xp_orb_scene: PackedScene
@export var enemy_bullet_scene: PackedScene

var max_hp: float = 80.0
var hp: float = 80.0
var move_speed: float = 72.0
var contact_damage: float = 10.0
var contact_interval: float = 0.55
var _contact_cd: float = 0.0

var bullet_damage: float = 12.0
var shoot_interval: float = 1.15
var _shoot_cd: float = 0.8


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("elites")


func configure(difficulty: float) -> void:
	max_hp = 65.0 + difficulty * 28.0
	hp = max_hp
	move_speed = 68.0 + difficulty * 6.0
	contact_damage = 9.0 + difficulty * 1.4
	bullet_damage = 11.0 + difficulty * 1.6
	shoot_interval = maxf(0.75, 1.2 - difficulty * 0.02)
	scale = Vector2(1.15, 1.15)


func _physics_process(delta: float) -> void:
	_contact_cd -= delta
	_shoot_cd -= delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var to_player := p.global_position - global_position
	var dist := to_player.length()
	if dist > 0.001:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if _shoot_cd <= 0.0 and enemy_bullet_scene:
		_shoot_cd = shoot_interval
		_shoot_at(p)

	var my_r := hit_radius * scale.x
	var reach := PLAYER_HIT_RADIUS + my_r + 14.0
	if dist < reach and _contact_cd <= 0.0 and p.has_method("take_damage"):
		p.take_damage(contact_damage)
		_contact_cd = contact_interval


func _shoot_at(target: Node2D) -> void:
	GameAudio.play_enemy_shoot()
	var b: Node2D = enemy_bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	var dir := (target.global_position - global_position).normalized()
	if b.has_method("setup"):
		b.setup(dir, bullet_damage)


func take_damage(amount: float) -> void:
	hp -= amount
	GameAudio.play_enemy_hit()
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_damage_float"):
		main.spawn_damage_float(global_position, amount, Color(0.55, 1.0, 0.65, 1.0))
	if hp <= 0.0:
		_die()


func _die() -> void:
	if xp_orb_scene:
		for i in range(2):
			var orb := xp_orb_scene.instantiate()
			get_parent().add_child(orb)
			orb.global_position = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("register_kill"):
		main.register_kill()
	queue_free()
