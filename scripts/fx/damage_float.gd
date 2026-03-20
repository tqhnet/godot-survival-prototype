## 伤害飘字：世界坐标 Node2D，上移淡出；由 Main.spawn_damage_float 生成。
extends Node2D

var _amount: float = 0.0
var _color: Color = Color.WHITE
var _age: float = 0.0
const LIFE := 0.75


func setup(amount: float, color: Color) -> void:
	_amount = amount
	_color = color
	z_index = 8


func _process(delta: float) -> void:
	_age += delta
	global_position.y -= 38.0 * delta
	var a := 1.0 - _age / LIFE
	modulate = Color(_color.r, _color.g, _color.b, a)
	if _age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var text := str(int(round(_amount)))
	var font := ThemeDB.fallback_font
	var fs := 17 if _amount < 100.0 else 15
	var pos := Vector2(-14.0, 0.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(_color.r, _color.g, _color.b, modulate.a))
