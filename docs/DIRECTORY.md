# 目录结构说明

Godot 4.x 项目根目录下主要文件夹如下（不含 `.godot/` 缓存与导入资源）。

```
test/
├── project.godot          # 工程配置；入口场景 run/main_scene = scenes/main.tscn；[autoload] GameAudio
├── icon.svg               # 应用图标
├── README.md              # 项目简介（指向本 docs）
├── .vscode/
│   └── settings.json      # 可选：Godot 扩展路径、files.exclude 隐藏 *.uid / *.import（仅 Cursor/VS Code）
├── audio/                 # BGM / SFX（占位 WAV，可替换；见 tools/gen_placeholder_audio.py）
├── tools/
│   └── gen_placeholder_audio.py   # 生成 audio/ 下占位 WAV（Python 标准库）
│
├── scenes/                # 所有 .tscn 场景（按功能分子目录）
│   ├── main.tscn          # 主场景：世界根节点、UI、计时器、玩家实例
│   ├── player/
│   │   └── player.tscn
│   ├── enemies/           # 敌对单位（小怪 / 精英 / Boss）
│   │   ├── enemy.tscn
│   │   ├── elite.tscn
│   │   └── boss.tscn
│   ├── combat/              # 战斗实体：玩家弹、敌弹、环绕球
│   │   ├── projectile.tscn
│   │   ├── enemy_bullet.tscn
│   │   └── orbit_orb.tscn
│   ├── pickups/
│   │   └── xp_orb.tscn
│   └── fx/
│       └── damage_float.tscn
│
├── scripts/               # 与 scenes 目录一一对应（同名脚本在子路径下）
│   ├── core/
│   │   ├── main.gd
│   │   └── game_audio.gd  # 全局音效（project.godot 中 autoload 为 GameAudio）
│   ├── player/
│   │   └── player.gd
│   ├── enemies/
│   │   ├── enemy.gd
│   │   ├── elite.gd
│   │   └── boss.gd
│   ├── combat/
│   │   ├── projectile.gd
│   │   ├── enemy_bullet.gd
│   │   └── orbit_orb.gd
│   ├── pickups/
│   │   └── xp_orb.gd
│   ├── fx/
│   │   └── damage_float.gd
│   └── data/
│       └── upgrade_definitions.gd   # 强化 id、文案、随机池（无场景）
│
└── docs/                  # 给人与 AI 阅读的说明（本目录）
	├── assets/
	│   └── preview.png    # README 等引用的画面预览图（可替换）
	├── DIRECTORY.md       # 本文件：目录树
	└── GAMEPLAY.md        # 玩法流程与扩展点
```

## 约定

- **场景路径**：`res://scenes/<分类>/xxx.tscn`
- **脚本路径**：`res://scripts/<分类>/xxx.gd`（与场景分类一致，便于检索）
- **数据脚本**：纯逻辑/表数据放在 `scripts/data/`，无对应 `.tscn`
- **主入口**：始终为 `scenes/main.tscn`，勿随意改名；若改名需同步 `project.godot` 的 `run/main_scene`
- **Autoload**：`GameAudio`（`scripts/core/game_audio.gd`），在 `project.godot` 的 `[autoload]` 中配置
- **Godot 生成文件**：`.uid`（脚本 UID）、资源旁的 `.import` 由编辑器维护；仓库若提交它们，协作时以编辑器为准；侧栏隐藏见 `.vscode/settings.json` 的 `files.exclude`
