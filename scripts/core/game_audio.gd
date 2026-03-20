## 全局音频单例（Autoload 名：`GameAudio`，在 `project.godot` 中注册）。
##
## 职责：
##   - 循环播放 BGM（`bgm_loop.wav`，`LOOP_FORWARD`）；
##   - 用若干 `AudioStreamPlayer` 轮询播放短音效，避免高频触发时互相截断。
##
## 调用方：`Main` 在 `_ready` 里 `restart_bgm()`、玩家死亡时 `stop_bgm()`；
##   玩家/敌人脚本在对应时机调用 `play_*`（见各函数说明）。
##
## 资源路径为 `res://audio/*.wav`，可替换文件或改下方 `load()`；占位生成见 `tools/gen_placeholder_audio.py`。
## Godot 引擎不包含内置音乐/音效素材。
extends Node

## 同时可存在的「独立一声」数量；齐射/多敌受击时超过该数会复用最早一格，旧声被新声顶替。
const SFX_POOL := 12

var _bgm: AudioStreamPlayer
## 轮询用的音效播放器池；与 `_sfx_i` 组成环形队列。
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_i: int = 0

## 运行时 `load()` 得到的流；若文件缺失则为 null，`_play_one_shot` 会静默跳过。
var _sfx_player_shoot: AudioStream
var _sfx_enemy_shoot: AudioStream
var _sfx_player_hurt: AudioStream
var _sfx_enemy_hit: AudioStream


func _ready() -> void:
	# Autoload 使用 ALWAYS，避免初始化顺序问题；子 AudioStreamPlayer 默认继承同一 process_mode。
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_player_shoot = load("res://audio/sfx_player_shoot.wav")
	_sfx_enemy_shoot = load("res://audio/sfx_enemy_shoot.wav")
	_sfx_player_hurt = load("res://audio/sfx_player_hurt.wav")
	_sfx_enemy_hit = load("res://audio/sfx_enemy_hit.wav")
	# duplicate 后再设 loop：避免改掉已缓存的 Resource，且仅 BGM 需要循环。
	var bgm_raw := load("res://audio/bgm_loop.wav") as AudioStreamWAV
	var bgm := bgm_raw.duplicate() as AudioStreamWAV
	bgm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "BGM"
	_bgm.stream = bgm
	_bgm.volume_db = -9.0
	add_child(_bgm)
	for i in range(SFX_POOL):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		p.volume_db = -4.0
		add_child(p)
		_sfx.append(p)


## 从头播放 BGM。`Main` 每次进入主场景时调用（含重新开始一局），保证新局音乐从头起。
func restart_bgm() -> void:
	_bgm.stop()
	_bgm.play()


## 停止 BGM。`Main` 在玩家死亡、打开结算时调用。
func stop_bgm() -> void:
	_bgm.stop()


## 玩家成功齐射时播一次（与本次齐射打几发子弹无关）。
func play_player_shoot() -> void:
	_play_one_shot(_sfx_player_shoot)


## 精英或 Boss 开火技能时播（Boss 每个技能轮次一声，非每颗子弹一声）。
func play_enemy_shoot() -> void:
	_play_one_shot(_sfx_enemy_shoot)


## 玩家任意方式扣血：敌弹、接触等，统一走 `player.take_damage` 时播。
func play_player_hurt() -> void:
	_play_one_shot(_sfx_player_hurt)


## 普通怪 / 精英 / Boss 在 `take_damage` 里播，与飘字一致。
func play_enemy_hit() -> void:
	_play_one_shot(_sfx_enemy_hit)


## 将流赋给池中下一个播放器并 `play()`；多声重叠时靠池容量轮询，而非无限新建节点。
func _play_one_shot(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := _sfx[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx.size()
	p.stream = stream
	p.play()
