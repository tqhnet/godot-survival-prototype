## 主场景逻辑：刷怪/精英/Boss、强化三选一 UI、游戏时间、伤害飘字入口。
## 节点需在 PROCESS_MODE_ALWAYS 下运行，以便在 get_tree().paused 时仍处理菜单与计时器。
## 扩展玩法：改 export 刷怪参数；新敌人类型在 _spawn_* 中实例化；新强化 id 见 scripts/data/upgrade_definitions.gd + player.apply_upgrade。
extends Node2D

const Upgrades := preload("res://scripts/data/upgrade_definitions.gd")
const DamageFloatScene := preload("res://scenes/fx/damage_float.tscn")

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var elite_scene: PackedScene
## 每次刷小怪时，有该概率改为生成精英（远程直线弹）
@export_range(0.0, 1.0) var elite_spawn_chance: float = 0.16
## 强化弹窗间隔（秒）。用 Timer(PAUSABLE) 驱动；游戏暂停时计时也会停。
@export var upgrade_interval_sec: float = 10.0
## Boss 出现间隔（秒），由 BossTimer(PAUSABLE) 驱动，与游戏暂停同步。
@export var boss_interval_sec: float = 20.0

@onready var player: CharacterBody2D = $Player
@onready var spawn_root: Node2D = $SpawnContainer
@onready var upgrade_timer: Timer = $UpgradeTimer
@onready var boss_timer: Timer = $BossTimer
@onready var ui_hp: Label = $CanvasLayer/UI/Margin/VBox/HP
@onready var ui_level: Label = $CanvasLayer/UI/Margin/VBox/Level
@onready var ui_time: Label = $CanvasLayer/UI/Margin/VBox/Time
@onready var ui_kills: Label = $CanvasLayer/UI/Margin/VBox/Kills
@onready var ui_score: Label = $CanvasLayer/UI/Margin/VBox/Score
@onready var game_over: Control = $CanvasLayer/GameOver
@onready var go_time: Label = $CanvasLayer/GameOver/Panel/VBox/TimeValue
@onready var go_kills: Label = $CanvasLayer/GameOver/Panel/VBox/KillsValue
@onready var go_score: Label = $CanvasLayer/GameOver/Panel/VBox/ScoreValue

@onready var upgrade_picker: Control = $UpgradeLayer/UpgradePicker
@onready var upgrade_buttons: Array[Button] = [
	$UpgradeLayer/UpgradePicker/Panel/VBox/HBox/Btn1,
	$UpgradeLayer/UpgradePicker/Panel/VBox/HBox/Btn2,
	$UpgradeLayer/UpgradePicker/Panel/VBox/HBox/Btn3,
]

var _spawn_timer: float = 0.0
var _time: float = 0.0
var _kills: int = 0
var _playing: bool = true
var _choosing_upgrade: bool = false
var _current_offers: Array[String] = []

@export var spawn_start_interval: float = 1.85
@export var spawn_min_interval: float = 0.32
@export var spawn_radius: float = 640.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	set_process(true)
	add_to_group("main")
	game_over.visible = false
	GameAudio.restart_bgm()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.leveled_up.connect(_on_player_leveled_up)
	player.score_changed.connect(_on_player_score_changed)
	for i in range(upgrade_buttons.size()):
		var idx := i
		upgrade_buttons[i].pressed.connect(func(): _on_upgrade_picked(idx))

	upgrade_timer.wait_time = maxf(0.05, upgrade_interval_sec)
	upgrade_timer.one_shot = true
	upgrade_timer.timeout.connect(_on_upgrade_timer_timeout)
	upgrade_timer.start()

	boss_timer.wait_time = maxf(0.05, boss_interval_sec)
	boss_timer.one_shot = false
	boss_timer.timeout.connect(_on_boss_timer_timeout)
	boss_timer.start()

	_refresh_ui()


func _on_upgrade_timer_timeout() -> void:
	if not _playing or _choosing_upgrade:
		return
	_open_upgrade_menu()


func _on_boss_timer_timeout() -> void:
	if not _playing:
		return
	var diff := 1.0 + _time / 28.0
	_spawn_boss(diff)


func _process(delta: float) -> void:
	if not _playing:
		return
	if _choosing_upgrade:
		return
	_time += delta
	var diff := 1.0 + _time / 28.0
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_enemy(diff)
		var interval: float = spawn_start_interval / diff
		_spawn_timer = maxf(spawn_min_interval, interval)
	ui_time.text = "游戏时间: %.0f 秒" % _time


func _open_upgrade_menu() -> void:
	if _choosing_upgrade:
		return
	_choosing_upgrade = true
	get_tree().paused = true
	_current_offers = Upgrades.pick_three()
	for i in range(3):
		var id: String = _current_offers[i]
		var d: Dictionary = Upgrades.DEFS[id]
		upgrade_buttons[i].text = "%s\n%s" % [d.title, d.desc]
	upgrade_picker.visible = true
	upgrade_picker.show()
	upgrade_layer_to_front()


func upgrade_layer_to_front() -> void:
	var layer := upgrade_picker.get_parent() as CanvasLayer
	if layer:
		layer.layer = 120


func _on_upgrade_picked(idx: int) -> void:
	if not _choosing_upgrade or idx < 0 or idx >= _current_offers.size():
		return
	var id: String = _current_offers[idx]
	if player.has_method("apply_upgrade"):
		player.apply_upgrade(id)
	upgrade_picker.hide()
	upgrade_picker.visible = false
	_choosing_upgrade = false
	get_tree().paused = false
	upgrade_timer.wait_time = maxf(0.05, upgrade_interval_sec)
	upgrade_timer.start()


func spawn_damage_float(world_pos: Vector2, amount: float, color: Color = Color.WHITE) -> void:
	var n := DamageFloatScene.instantiate()
	spawn_root.add_child(n)
	n.global_position = world_pos + Vector2(randf_range(-9.0, 9.0), randf_range(-20.0, -8.0))
	if n.has_method("setup"):
		n.setup(amount, color)


func _spawn_enemy(difficulty: float) -> void:
	if randf() < elite_spawn_chance and elite_scene != null:
		_spawn_elite(difficulty)
		return
	if enemy_scene == null:
		return
	var e: CharacterBody2D = enemy_scene.instantiate()
	var a := randf() * TAU
	var offset := Vector2(cos(a), sin(a)) * spawn_radius
	e.global_position = player.global_position + offset
	if e.has_method("configure"):
		e.configure(difficulty)
	spawn_root.add_child(e)


func _spawn_elite(difficulty: float) -> void:
	if elite_scene == null:
		return
	var e: CharacterBody2D = elite_scene.instantiate()
	var a := randf() * TAU
	var offset := Vector2(cos(a), sin(a)) * spawn_radius
	e.global_position = player.global_position + offset
	if e.has_method("configure"):
		e.configure(difficulty)
	spawn_root.add_child(e)


func _spawn_boss(difficulty: float) -> void:
	if boss_scene == null:
		push_warning("Main: boss_scene 未设置，无法生成 Boss")
		return
	var b: CharacterBody2D = boss_scene.instantiate()
	var a := randf() * TAU
	var offset := Vector2(cos(a), sin(a)) * spawn_radius
	b.global_position = player.global_position + offset
	if b.has_method("configure"):
		b.configure(difficulty)
	spawn_root.add_child(b)


func register_kill() -> void:
	_kills += 1
	ui_kills.text = "击败: %d" % _kills


func _on_player_health_changed(current: float, max_hp: float) -> void:
	ui_hp.text = "生命: %d / %d" % [int(ceil(current)), int(ceil(max_hp))]


func _on_player_leveled_up(lv: int, _xp_next: float) -> void:
	ui_level.text = "等级: %d" % lv


func _on_player_score_changed(s: int) -> void:
	ui_score.text = "积分: %d" % s


func _on_player_died() -> void:
	GameAudio.stop_bgm()
	_playing = false
	_choosing_upgrade = false
	upgrade_timer.stop()
	boss_timer.stop()
	upgrade_picker.visible = false
	go_time.text = "%.0f 秒" % _time
	go_kills.text = "%d" % _kills
	go_score.text = "积分: %d" % player.score
	game_over.visible = true
	get_tree().paused = true


func _refresh_ui() -> void:
	ui_level.text = "等级: %d" % player.level
	ui_kills.text = "击败: 0"
	ui_score.text = "积分: %d" % player.score
	ui_time.text = "游戏时间: 0 秒"
	_on_player_health_changed(player.hp, player.max_hp)


func _unhandled_input(event: InputEvent) -> void:
	if _choosing_upgrade:
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().paused = false
		get_tree().quit()
	if not _playing and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()
