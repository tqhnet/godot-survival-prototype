## 普通敌人：追击玩家、接触伤害；死亡掉 1 经验球。take_damage 会调 Main.spawn_damage_float。
## 扩展：改 configure(difficulty) 曲线；或复制场景做新变种。
extends CharacterBody2D

## 与场景中 CollisionShape2D 圆形半径一致（用于近战判定）
@export var hit_radius: float = 16.0
## 玩家碰撞圆半径（与 player.tscn 中一致）
const PLAYER_HIT_RADIUS := 14.0

@export var xp_orb_scene: PackedScene

var max_hp: float = 28.0
var hp: float = 28.0
var move_speed: float = 95.0
var contact_damage: float = 12.0
var contact_interval: float = 0.55
var _contact_cd: float = 0.0


func _ready() -> void:
	add_to_group("enemies")


func configure(difficulty: float) -> void:
	max_hp = 22.0 + difficulty * 14.0
	hp = max_hp
	move_speed = 78.0 + difficulty * 10.0
	contact_damage = 8.0 + difficulty * 1.8


func _physics_process(delta: float) -> void:
	_contact_cd -= delta
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

	var my_r := hit_radius * scale.x
	var reach := PLAYER_HIT_RADIUS + my_r + 14.0
	if dist < reach and _contact_cd <= 0.0 and p.has_method("take_damage"):
		p.take_damage(contact_damage)
		_contact_cd = contact_interval


func take_damage(amount: float) -> void:
	hp -= amount
	GameAudio.play_enemy_hit()
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_damage_float"):
		main.spawn_damage_float(global_position, amount, Color(1, 0.92, 0.55, 1))
	if hp <= 0.0:
		_die()


func _die() -> void:
	if xp_orb_scene:
		var orb := xp_orb_scene.instantiate()
		get_parent().add_child(orb)
		orb.global_position = global_position
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("register_kill"):
		main.register_kill()
	queue_free()
