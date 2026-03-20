## Boss：高血量、追击、接触伤害；周期性技能：扇形三连弹、八向环弹、短暂冲锋。
## 半血以下狂暴：技能间隔缩短、子弹伤害提高。需场景绑定 enemy_bullet_scene。
extends CharacterBody2D

## 与场景中 CollisionShape2D 圆形半径一致（Boss 体型更大）
@export var hit_radius: float = 22.0
const PLAYER_HIT_RADIUS := 14.0

@export var xp_orb_scene: PackedScene
@export var enemy_bullet_scene: PackedScene

var max_hp: float = 200.0
var hp: float = 200.0
var move_speed: float = 58.0
var contact_damage: float = 24.0
var contact_interval: float = 0.45
var _contact_cd: float = 0.0

## 技能参数（configure 内初始化）
var bullet_damage: float = 16.0
var _interval_barrage: float = 2.6
var _interval_ring: float = 5.0
var _interval_charge: float = 7.5
var _t_barrage: float = 1.2
var _t_ring: float = 2.0
var _t_charge: float = 4.0

var _charging: bool = false
var _charge_time: float = 0.0
var _charge_dir := Vector2.RIGHT
const CHARGE_MULT := 2.15
const CHARGE_DURATION := 0.85

var _enraged: bool = false
@onready var _poly: Polygon2D = $Polygon2D
var _base_poly_color := Color(0.55, 0.22, 0.85, 1.0)
var _enrage_poly_color := Color(0.85, 0.15, 0.45, 1.0)


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	if _poly:
		_base_poly_color = _poly.color


func configure(difficulty: float) -> void:
	max_hp = 180.0 + difficulty * 50.0
	hp = max_hp
	move_speed = 58.0 + difficulty * 4.0
	contact_damage = 22.0 + difficulty * 2.5
	contact_interval = 0.45
	scale = Vector2(1.75, 1.75)
	bullet_damage = 13.0 + difficulty * 1.85
	_interval_barrage = maxf(1.85, 2.85 - difficulty * 0.04)
	_interval_ring = maxf(3.4, 5.2 - difficulty * 0.06)
	_interval_charge = maxf(5.5, 8.0 - difficulty * 0.08)
	_t_barrage = 1.0
	_t_ring = 1.8
	_t_charge = 3.8
	_enraged = false
	_charging = false


func _physics_process(delta: float) -> void:
	_contact_cd -= delta
	if not _charging:
		_t_barrage -= delta
		_t_ring -= delta
		_t_charge -= delta

	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return

	var to_player := p.global_position - global_position
	var dist := to_player.length()
	var dir_player := to_player.normalized() if dist > 0.001 else Vector2.RIGHT

	if _charging:
		_charge_time -= delta
		velocity = _charge_dir * move_speed * CHARGE_MULT
		move_and_slide()
		if _charge_time <= 0.0:
			_charging = false
	else:
		if dist > 0.001:
			velocity = dir_player * move_speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()

		if enemy_bullet_scene:
			if _t_barrage <= 0.0:
				_skill_barrage(dir_player)
				_t_barrage = _interval_barrage * (0.72 if _enraged else 1.0)
			if _t_ring <= 0.0:
				_skill_ring_burst()
				_t_ring = _interval_ring * (0.72 if _enraged else 1.0)
			if _t_charge <= 0.0:
				_skill_charge(dir_player)
				_t_charge = _interval_charge * (0.75 if _enraged else 1.0)

	var my_r := hit_radius * scale.x
	var reach := PLAYER_HIT_RADIUS + my_r + 14.0
	if dist < reach and _contact_cd <= 0.0 and p.has_method("take_damage"):
		p.take_damage(contact_damage)
		_contact_cd = contact_interval


func _skill_barrage(dir_to_player: Vector2) -> void:
	## 扇形三连弹，略扩散
	GameAudio.play_enemy_shoot()
	for i in range(3):
		var ang := (-1.0 + float(i)) * 0.38
		_spawn_bullet(dir_to_player.rotated(ang), bullet_damage * (1.12 if _enraged else 1.0))


func _skill_ring_burst() -> void:
	## 八向环弹；单发略弱于瞄准弹
	GameAudio.play_enemy_shoot()
	var ring_dmg := bullet_damage * 0.82 * (1.08 if _enraged else 1.0)
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		_spawn_bullet(Vector2.from_angle(ang), ring_dmg)


func _skill_charge(dir_to_player: Vector2) -> void:
	_charging = true
	_charge_time = CHARGE_DURATION
	_charge_dir = dir_to_player


func _spawn_bullet(dir: Vector2, dmg: float) -> void:
	if enemy_bullet_scene == null:
		return
	var b: Node2D = enemy_bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position + dir * 28.0
	if b.has_method("setup"):
		b.setup(dir, dmg)


func take_damage(amount: float) -> void:
	hp -= amount
	GameAudio.play_enemy_hit()
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_damage_float"):
		main.spawn_damage_float(global_position, amount, Color(1, 0.5, 0.28, 1))
	if not _enraged and hp <= max_hp * 0.5:
		_enraged = true
		if _poly:
			_poly.color = _enrage_poly_color
	if hp <= 0.0:
		_die()


func _die() -> void:
	if xp_orb_scene:
		for i in range(3):
			var orb := xp_orb_scene.instantiate()
			get_parent().add_child(orb)
			var jitter := Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
			orb.global_position = global_position + jitter
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("register_kill"):
		main.register_kill()
	queue_free()
