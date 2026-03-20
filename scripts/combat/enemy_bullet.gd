## 敌弹：直线伤害玩家；collision_layer=32，mask=玩家 layer1。不要放入 enemies 组以免被玩家子弹打。
extends Area2D

var _dir := Vector2.RIGHT
var _damage := 14.0
var _speed := 400.0
var _life := 3.2


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
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(_damage)
		queue_free()
