# 02 实体定义

> 每新增一个实体，必须同步：① 本文件 ② `08_naming.md` ③ `03_rules.md`（数值）④ `04_physics.md`（若参与物理）

## 命名与实现对照（当前程序）

| 实体 | 节点类型 | 脚本 | 职责 | 状态 |
| --- | --- | --- | --- | --- |
| `Main` | Node2D | `scripts/main.gd` | 根节点（协调者，无运行逻辑） | ✅ |
| `Floor` | StaticBody2D | 无 | 底部地面（1920×50） | ✅ |
| `LeftWall` | StaticBody2D | 无 | 左边界（20×1080） | ✅ |
| `RightWall` | StaticBody2D | 无 | 右边界（20×1080） | ✅ |
| `Ceiling` | StaticBody2D | 无 | 顶边界（1920×20） | ✅ |
| `PegBoard` | Node2D | `scripts/peg_board.gd` | 图钉阵容器（运行时生成） | ✅ |
| `Peg` | StaticBody2D | 无 | 单颗图钉（半径 12，物理阻挡） | ✅ |
| `BottomZoneLeft` / `BottomZoneRight` | Area2D | `scripts/entities/pocket.gd` | 普通底部区（球进入即销毁） | ✅ |
| `Pocket` | Area2D | `scripts/entities/pocket.gd` | 奖励袋洞（+3，即销毁） | ✅ |
| `Launcher` | Node2D | `scripts/launcher.gd` | 发射器（蓄力 + 鼠标瞄准，位置 1600, 900） | ✅ |
| `BallTemplate` | RigidBody2D | 无 | 球模板（freeze + 隐藏） | ✅ |
| `Ball` | RigidBody2D | 无 | 发射出的球实例 | ✅ |
| `RoundManager` | Node2D | `scripts/systems/round_manager.gd` | 回合状态机 + 倒计时 + 库存 + json 注入 | ✅ |
| `HUD` | CanvasLayer | `scripts/ui/hud.gd`（场景 `scenes/ui/HUD.tscn`） | 时间 / 库存 / 目标 / 结算 / 蓄力条 / 面板 | ✅ |

## 实体详细定义

### Ball / BallTemplate

- **类型**：`RigidBody2D`
- **物理材质**：`physics_material_override.bounce = 0.8`
- **碰撞形状**：`CircleShape2D`，半径 20，偏移 `(0, -39)`
- **视觉**：`Sprite2D`（`icon.svg`），scale `0.3`，偏移 `(2, -37)`
- **模板状态**：`freeze = true`、`visible = false`
- **实例状态**：`freeze = false`、`visible = true`
- **生命周期**：加入 `&"balls"` 组；进入底部检测区（普通区/袋洞）即被销毁

### Peg（图钉）

- **类型**：`StaticBody2D`（2026-09-27 由 Area2D 改为物理实体，见决策 #11）
- **碰撞形状**：`CircleShape2D`，半径 12
- **物理材质**：`PhysicsMaterial.bounce = 0.65`（可调，json 注入）
- **视觉**：`Sprite2D`（运行时生成的 64×64 白色柔边圆），视觉半径 18
- **反弹**：物理引擎原生解算（球撞钉自动反弹，不可能穿钉）
- **生成方式**：`PegBoard` 在 `_ready()` 中按行列自动生成（6 行 × 11 列）
- **命名规则**：`Peg_{row}_{col}`（如 `Peg_0_3`）
- **特殊图钉扩展口**：未来加事件类图钉时在其上叠加 Area2D，不影响物理阻挡

### 底部检测区（BottomZoneLeft / BottomZoneRight / Pocket）

- **类型**：`Area2D`（`monitoring` = true），共用 `scripts/entities/pocket.gd`
- **区分**：`@export is_pocket`（true = 奖励袋洞 +3；false = 普通区，不扣不加）
- **行为**：球（RigidBody2D 且非 freeze）进入 → 立即 `queue_free()`；袋洞额外发 `ball_entered_pocket` 信号
- **视觉**：`_ready()` 时按碰撞形状生成半透明 `Polygon2D`（袋洞绿色 / 普通区灰色）
- **坐标**：见 `04_physics.md` 底部检测带表

### Launcher（发射器）

- **类型**：`Node2D`，位置 `(1600, 900)`
- **视觉**：`Sprite2D`（`icon.svg`），scale `0.3`，灰色 modulate `(0.5, 0.5, 0.5, 0.9)`
- **行为**：按下左键开始蓄力（门禁 `can_fire()`）→ 按住期间力度线性增长（3s 蓄满）且瞄准方向实时跟随鼠标 → 松开发射 1 颗
- **瞄准**：方向 = 发射器 → 鼠标，钳制在正上方 ±80°；按住 < 0.2s 带 ±5° 抖动，≥ 0.2s 精准
- **信号**：`ball_launched`（发射成功）、`charge_updated(ratio)`（蓄力进度）
- **模板引用**：`ball_template = NodePath("../BallTemplate")`（已预填）

### RoundManager（回合管理器）

- **类型**：`Node2D`（Main 子节点，暂不做 Autoload，见决策 #8）
- **状态机**：`RoundState` = `PLAYING` / `ENTERING_NEXT` / `SETTLING`
- **职责**：倒计时（90s）、库存（50 起始 / ≥60 过关 / 发射 -1 / 进袋 +3）、结算与重试、启动时从 `data/balance_config.json` 读取数值并注入 Launcher / PegBoard
- **信号**：`state_changed` / `stock_changed` / `time_changed`

### HUD（界面层）

- **类型**：`CanvasLayer`（场景 `scenes/ui/HUD.tscn`）
- **子节点**：`Root/TopBar`（TimeLabel / StockLabel / TargetLabel）、`SettleButton`、`ChargeBar`（Background + Fill）、`PassFlash`、`FailPanel`（ResultLabel / SubLabel / RetryButton）
- **输入穿透**：`Root` 与 `TopBar` 设 `mouse_filter = Ignore`（否则吃掉全部鼠标点击，发射失效，见决策 #13）；按钮保持默认 Stop
- **信号**：`settle_requested` / `retry_requested`（出）；订阅 RoundManager 三信号与 Launcher 的 `charge_updated`（入）

### Floor / 三面墙

- **类型**：`StaticBody2D` + `RectangleShape2D`
- **职责**：物理边界，确保球不飞出场景
- **详细坐标**：见 `04_physics.md`

## 未来实体（规划，见 `../Priority_Backlog.md`）

| 实体 | 优先级 | 说明 |
| --- | --- | --- |
| `UpgradeCard` | P2 | 肉鸽升级三选一 |
| `SpecialPeg` | P2 | 特殊图钉（加分 / 爆炸 / 复制球），在物理钉上叠加 Area2D |
| `AudioManager` | P1 | 全局音效总线（Autoload） |
| `AimLine` | P1 | 瞄准预览线（蓄力期间显示轨迹） |
