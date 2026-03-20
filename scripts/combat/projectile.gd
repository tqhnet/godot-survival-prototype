## 玩家子弹：直线飞行，只碰撞 enemies 组；由 player 实例化到 Main 下。
## 碰撞 layer8，mask 敌人 layer2。扩展：穿透、爆炸可改此脚本或换新场景。
extends Area2D

var _dir := Vector2.RIGHT
var _damage := 14.0
var _speed := 520.0
var _life := 2.4


func setup(direction: Vector2, damage: float) -> void:
	_dir = direction.normalized()
	_damage = damage
	rotation = _dir.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(_damage)
		queue_free()
