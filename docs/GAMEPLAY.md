# 玩法架构与扩展指南（给开发者 / AI 助手）

本文描述当前「类吸血鬼幸存者」原型的**数据流**、**关键节点**与**常见扩展方式**，便于在不破坏结构的前提下加内容。

---

## 1. 一局游戏从哪开始

| 项目 | 说明 |
|------|------|
| 入口 | `project.godot` → `run/main_scene` = `res://scenes/main.tscn` |
| 根脚本 | `scripts/core/main.gd` 挂在 `Main` 节点上 |
| 处理模式 | `Main` 为 `PROCESS_MODE_ALWAYS`，以便在 `get_tree().paused = true`（强化菜单/结算）时仍能驱动 Timer、接收 UI 输入 |

子节点中：**玩家、刷怪容器、各种 Timer、CanvasLayer UI** 均在 `main.tscn` 里搭好；**不要在运行时改主场景文件名**，否则导出与引用会断。

---

## 2. 时间轴与暂停

- **游戏内时间** `_time`：仅在 `Main._process` 且未打开强化菜单、未死亡时累加（用于 `diff` 难度曲线等）。
- **强化间隔**：`UpgradeTimer`（`process_mode = PAUSABLE`），`timeout` → 打开三选一，`get_tree().paused = true`。
- **Boss 间隔**：`BossTimer`（循环），`timeout` → 生成 Boss 场景。
- **暂停时**：小怪/玩家/子弹/敌弹等均为 `PAUSABLE`，会停止；`Main` 与 `UpgradePicker`（ALWAYS）仍可处理菜单。

扩展新「定时事件」：复制 **Timer** 模式，挂在 `Main` 下，**PAUSABLE** 与游戏时间同步。

---

## 3. 刷怪与难度

- `_spawn_timer` 每帧扣减，到期调用 `_spawn_enemy(diff)` 或按概率 `_spawn_elite(diff)`。
- `diff := 1.0 + _time / 28.0` 传入各单位的 `configure(difficulty)`，用于缩放血量、速度等。

**加新敌人类型**：

1. 在 `scenes/enemies/`（或新子目录）建场景，根节点多为 `CharacterBody2D`。
2. 脚本实现 `configure(difficulty: float)`（若需要随时间变强）。
3. 加入 `enemies` 组（玩家索敌逻辑依赖 `get_nodes_in_group("enemies")`）。
4. 在 `main.gd` 里增加 `@export` 的 `PackedScene` 与对应的 `_spawn_*`。

---

## 4. 碰撞与物理层（2D）

约定（代码里以 bitmask 为准）：

| Layer 含义 | 典型用途 |
|------------|----------|
| 1 | 玩家 `CharacterBody2D` |
| 2 | 敌人身体 |
| 8 | 玩家子弹 `Area2D` |
| 16 | 环绕球 |
| 32 | 敌弹 `Area2D`（只 mask 玩家） |

**玩家子弹**只打 `enemies` 组；**敌弹**不要进 `enemies` 组，否则会被玩家子弹误伤逻辑命中（若以后要做对撞，再单独加层或 mask）。

---

## 5. 强化（三选一）

| 文件 | 作用 |
|------|------|
| `scripts/data/upgrade_definitions.gd` | `DEFS`（id → 标题/描述）、`POOL`、`pick_three()` |
| `scripts/player/player.gd` | `apply_upgrade(id)` 里 `match` 实现效果 |

**新增一条强化**：

1. 在 `DEFS` 里增加 `id` 与中文字符串。
2. 在 `POOL` 里加入该 `id`（否则随机不到）。
3. 在 `player.gd` 的 `apply_upgrade` 中增加对应分支（改数值、换场景引用等）。

---

## 6. 伤害数字与受击

- `Main.spawn_damage_float(...)` 在 `SpawnContainer` 下生成 `scenes/fx/damage_float.tscn`。
- 敌人/Boss/精英在 `take_damage` 里调主场景；玩家在 `take_damage` 里也会调（显示红色受伤数字）。

---

## 7. 经验与积分

- 经验球：`xp_orb.gd` → `player.add_xp`；积分在 `player.gd` 的 `add_xp` 内与经验同步增加。
- 升级（等级成长）在 `_do_level_up()`，与「三选一强化」是两套系统。

---

## 8. 给 AI 助手的检索提示

扩展玩法时优先搜索：

- `apply_upgrade` — 所有强化效果入口
- `configure` — 敌人难度缩放
- `register_kill` — 击杀统计
- `spawn_damage_float` — 飘字
- `group("enemies")` — 索敌与伤害判定

主场景节点路径：`Main` / `Player` / `SpawnContainer` / `UpgradeTimer` / `BossTimer` / `CanvasLayer` …（见 `main.tscn`）。
