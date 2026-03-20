## 强化/技能数据：DEFS（id -> 标题与说明）、POOL（随机池）、pick_three()。
## 新增一条强化：1) 在此加入 id 与文案 2) POOL 中加入 id 3) 在 player.gd 的 apply_upgrade() 里 match 分支实现效果。
extends Object

const DEFS: Dictionary = {
	"orbit_orb": {"title": "环绕攻击球", "desc": "新增一颗围绕你旋转的近战球"},
	"extra_projectile": {"title": "额外子弹", "desc": "每次齐射多发射一发子弹"},
	"damage_up": {"title": "更重火力", "desc": "子弹与环绕球伤害 +12%"},
	"fire_rate": {"title": "疾射", "desc": "射击间隔缩短"},
	"move_speed": {"title": "疾步", "desc": "移动速度 +8%"},
	"heal": {"title": "回复", "desc": "恢复 28% 最大生命"},
}

const POOL: Array[String] = [
	"orbit_orb", "extra_projectile", "damage_up", "fire_rate", "move_speed", "heal",
]


static func pick_three() -> Array[String]:
	var p: Array[String] = POOL.duplicate()
	p.shuffle()
	return [p[0], p[1], p[2]]
