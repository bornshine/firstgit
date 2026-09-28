# 07 工程目录结构与放置约定

> 改完目录必须同步更新 `_index.md` 的速查表。

## 当前结构（截至 2026-09-27）

```
res://
├── project.godot
├── icon.svg
├── icon.svg.import
├── scenes/
│   ├── Main.tscn              # 主场景
│   └── ui/
│       └── HUD.tscn           # HUD 界面
├── scripts/
│   ├── main.gd                # Main 节点：根节点占位（无运行逻辑）
│   ├── launcher.gd            # 发射器（蓄力 + 鼠标瞄准）
│   ├── peg_board.gd           # 图钉阵生成（物理图钉）
│   ├── entities/
│   │   └── pocket.gd          # 底部检测区（普通区 / 袋洞共用）
│   ├── systems/
│   │   └── round_manager.gd   # 回合状态机 + 数值注入
│   └── ui/
│       └── hud.gd             # HUD 逻辑
├── data/
│   └── balance_config.json    # 全部数值（round / pocket / peg / launcher）
├── docs/
│   ├── bible/                 # 本目录（项目圣经）
│   ├── MVP_Scope.md
│   ├── Priority_Backlog.md
│   └── Core_Loop.md
├── node_2d.tscn               # ⚠️ 遗留空场景
├── _sim_mai.gd                # ⚠️ 遗留测试脚本（SceneTree）
└── _sim_mai.gd.uid
```

## 目标结构（规划）

```
res://
├── project.godot
├── scenes/
│   ├── Main.tscn
│   ├── entities/              # Ball.tscn / Peg.tscn / Pocket.tscn
│   └── ui/                    # HUD.tscn / RoundEnd.tscn
├── scripts/
│   ├── autoload/              # AudioManager.gd / Balance.gd
│   ├── entities/              # ball.gd / peg.gd / pocket.gd
│   ├── systems/               # ball_counter.gd / score.gd
│   └── ui/                    # hud.gd
├── data/
│   ├── balance_config.json    # 所有数值（见 03_rules.md）
│   └── audio_config.json      # 音效事件 → 资源映射（见 06_audio.md）
├── art/
│   ├── sprites/
│   └── fonts/
├── audio/
│   ├── bgm/
│   └── sfx/
└── docs/
```

## 放置约定

| 资源类型 | 目录 | 命名 | 备注 |
| --- | --- | --- | --- |
| 场景 | `scenes/` | PascalCase.tscn | 子目录按模块分（entities / ui） |
| 脚本 | `scripts/` | snake_case.gd | 与场景同名（`Main.tscn` ↔ `main.gd`） |
| 自动加载 | `scripts/autoload/` | PascalCase.gd | 全局单例，见 `_index.md` 不变量 #3 |
| 数值配置 | `data/` | snake_case.json | 见 `_index.md` 不变量 #2 |
| 图片 | `art/sprites/` | snake_case.png | — |
| 音频 | `audio/` | snake_case.ogg | 按 bgm / sfx 分开 |
| 文档 | `docs/bible/` | 见目录树 | 编号前缀保证排序 |

## 脚本与场景的对应关系

| 脚本 | 挂载节点 | 职责 |
| --- | --- | --- |
| `scripts/main.gd` | `Main` | 根节点占位（无运行逻辑） |
| `scripts/launcher.gd` | `Launcher` | 蓄力 + 鼠标瞄准发射 |
| `scripts/peg_board.gd` | `PegBoard` | 运行时生成物理图钉 |
| `scripts/entities/pocket.gd` | `BottomZoneLeft` / `Pocket` / `BottomZoneRight` | 底部检测区（销毁 + 袋洞奖励） |
| `scripts/systems/round_manager.gd` | `RoundManager` | 回合状态机 + json 数值注入 |
| `scripts/ui/hud.gd` | `HUD` | 界面刷新 + 按钮信号 |

## 迁移待办

| 项 | 处理 | 优先级 |
| --- | --- | --- |
| `node_2d.tscn` | 遗留测试场景，可删除 | P2 |
| `_sim_mai.gd` / `.uid` | 遗留 SceneTree 测试脚本，可删除或移入 `tests/` | P2 |
| `launcher.gd` / `peg_board.gd` / `main.gd` 迁入 `scripts/entities/` | 待实体增多后重构 | P2 |
