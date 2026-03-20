## 环绕球：挂在玩家 OrbitRig 上旋转，重叠时对敌人造成伤害（短 CD）。
## 扩展：改 orbit_orb.tscn 形状或本脚本伤害逻辑。
extends Area2D

var _damage: float = 7.0
var _hit_cd: float = 0.0


func setup(damage: float) -> void:
	_damage = damage


func _physics_process(delta: float) -> void:
	_hit_cd -= delta
	if _hit_cd > 0.0:
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(_damage)
			_hit_cd = 0.38
			return
