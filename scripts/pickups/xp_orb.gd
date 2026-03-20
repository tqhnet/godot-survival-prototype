## 经验球：玩家靠近吸附，拾取后 player.add_xp；积分同步增加。
extends Area2D

var value: float = 12.0
var _magnet_range := 140.0
var _magnet_speed := 420.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_p := player.global_position - global_position
	if to_p.length_squared() <= _magnet_range * _magnet_range:
		global_position += to_p.normalized() * _magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("add_xp"):
		body.add_xp(value)
		queue_free()
