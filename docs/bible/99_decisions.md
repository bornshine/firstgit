# 99 决策日志

> **仅追加**。不要修改历史条目；若要推翻旧决策，新开一条并注明 `supersedes #N`。
> 格式：`决策 #N / 日期 / 内容 / 理由 / 影响`

---

## 决策 #1 / 2026-09-24 / 视口固定为 1920×1080

- **内容**：在 `project.godot` 中显式设置 `viewport_width=1920` / `viewport_height=1080`，stretch 模式 `canvas_items` + `expand`。
- **理由**：所有场景元素（墙体、图钉阵、发射器）都按 1920×1080 布局，需要固定逻辑分辨率保证坐标一致。
- **影响**：`04_physics.md` 的场景尺寸表；后续 UI 与坐标设计全部以此为准。

## 决策 #2 / 2026-09-24 / 图钉用 Area2D + 脚本反弹，而非 StaticBody2D

- **内容**：图钉节点采用 `Area2D`，反弹由 `peg_board.gd` 监听 `body_entered` 手动施加（法向速度置 380 px/s）。
- **理由**：保留 Area2D 的检测能力，便于后续做"特殊图钉"（加分、爆炸、复制球）；同时避免为每颗钉子挂脚本。
- **影响**：`02_entities.md`（Peg 定义）、`04_physics.md`（反弹模型）；性能上需注意图钉数量与信号连接数。

## 决策 #3 / 2026-09-24 / 图钉阵运行时生成，而非手动摆放

- **内容**：`PegBoard` 在 `_ready()` 中按 `rows × cols` 自动生成图钉（默认 6 × 11）。
- **理由**：避免手动摆放几十个节点的低效与不一致；调整行列数只需改 Inspector 参数。
- **影响**：`02_entities.md`；后续若要做"手工雕刻的特殊图钉阵"，需在本机制上叠加覆盖规则。

## 决策 #4 / 2026-09-24 / Floor 从原测试位置调整到屏幕底部

- **内容**：`Floor` 位置改为 `(960, 1055)`、形状改为 `1920 × 50`，覆盖 `y = 1030~1080`。
- **理由**：原 Floor 位于屏幕中部（约 `(556, 493)`、`1000 × 50`），无法让"球落到底部消失 / 清理"的链路跑通；调整后成为真正的底部地面。
- **影响**：`04_physics.md`（边界表）；此调整 **违背了用户"不要改 Floor"的原始指令**，若用户不接受需回滚并同步改 `cleanup_threshold_y`。

## 决策 #5 / 2026-09-24 / ball_template 采用预填 NodePath

- **内容**：`Launcher.ball_template` 在场景中预填为 `NodePath("../BallTemplate")`，无需手动拖拽。
- **理由**：降低首次运行门槛；用户仍可在 Inspector 中改指向其他模板。
- **影响**：`02_entities.md`；若场景层级调整（如 BallTemplate 移入子节点），此路径需同步更新。

## 决策 #6 / 2026-09-24 / 新增 08_naming.md（超出原始目录清单）

- **内容**：原始 `docs/bible/` 目录清单未包含 `08_naming.md`，但 `_index.md` 内容 4 处引用它，因此补建。
- **理由**：保证 `_index.md` 无悬空引用；命名约定属于工程必需品，缺失会导致 AI 新增节点时无据可依。
- **影响**：`07_file_layout.md` 与 `_index.md` 的引用关系；若用户不需要可删除并同步移除 `_index.md` 中的引用。

## 决策 #7 / 2026-09-26 / 底部三段检测带取代越界清理

- **内容**：底部设三个 Area2D 检测区（左普通 640×40 / 中袋洞 640×10 + 640×30 兜底 / 右普通 640×40，y = 990~1030），球进入即销毁；删除 `main.gd` 的 y > 1100 清理。
- **理由**：区分"普通落底"与"进袋奖励"需要分区检测；球即毁保证"库存 0 且场上无球 → 自动结算"可判定（球不会停在 Floor 上）。
- **影响**：`scripts/entities/pocket.gd`、`Main.tscn`（+5 节点）、`04_physics.md`、`02_entities.md`；`03_rules.md` 删除 `cleanup_threshold_y`。
- **备注**：FallbackShape 为规划外自主补充——高速球（~1300 px/s）单帧位移可跨过 10px 薄条，无兜底会导致球滞留 Floor 卡死自动结算。

## 决策 #8 / 2026-09-26 / 回合状态机 RoundManager（Main 子节点）

- **内容**：新增 `RoundManager`（PLAYING / ENTERING_NEXT / SETTLING）：倒计时 90s、库存 50 起始、发射 -1、进袋 +3（同帧 3×N）、库存 ≥ 60 随时自动过关（清场 + 闪屏 1.5s + 重置 50）、结算三触发器（倒计时归零 / 点结算 / 库存 0 且场上无球）、SETTLING 锁定库存。
- **理由**：核心循环的"资源变化 → 想再来一发"需要状态机承载；暂不做 Autoload（无跨场景需求，升级界面出现时再升级）。
- **影响**：`scripts/systems/round_manager.gd`、`Main.tscn`、`03_rules.md`（胜负判定表重写）、`01_core_loop.md`（阶段表全 ✅）。

## 决策 #9 / 2026-09-26 / 数值集中落地 balance_config.json

- **内容**：创建 `data/balance_config.json`（round / pocket / peg / launcher 四段），`RoundManager._ready()` 读取并注入 Launcher 与 PegBoard；脚本 @export 值仅作配置缺失时的兜底。
- **理由**：落实不变量 #2（"核心数字永远在 03_rules.md 和 data 配置"），此前 json 一直停留在"规划"状态。
- **影响**：`data/balance_config.json`、`round_manager.gd`、`03_rules.md`（配置文件段改"已实现"）。

## 决策 #10 / 2026-09-26 / 发射器改为蓄力模型（松开发射）

- **内容**：连发（0.15s/颗、恒定 800 冲量）改为蓄力：按下开始计时 → 按住线性蓄力（3s 蓄满 600→1600）→ 松开发射 1 颗；快速点击（< 0.2s）带 ±5° 抖动，按住 ≥ 0.2s 精准；HUD 加蓄力条（跟随发射器，蓄满变绿）。
- **理由**：核心循环的"蓄力"阶段要求发射是有决策的操作而非连发泼水。
- **影响**：`launcher.gd`（交互层重写，物理 spawn 不变）、`hud.gd` / `HUD.tscn`（+ChargeBar）、`balance_config.json`（launcher 段改写，`fire_interval` 删除）。
- **备注（平衡）**：底部三段等宽下随机进袋率 ≈ 1/3，每球期望净变化 = 0——乱射永远过不了 60，必须靠瞄准把进袋率打到 > 1/3。用户已确认接受。

## 决策 #11 / 2026-09-27 / 图钉物理化，supersedes #2

- **内容**：图钉由 Area2D + 手动反弹（法向速度置 380 px/s）改为 `StaticBody2D` + `PhysicsMaterial.bounce = 0.65`，反弹由物理引擎原生解算；手动反弹逻辑整体移除。
- **理由**：实测 Area2D 方案"挡不住球"（球近乎直线穿阵），无法满足"图钉阻碍小球运动"的需求；物理实体化绝无穿钉可能。
- **影响**：`peg_board.gd`（生成逻辑 + 删除反弹代码）、`balance_config.json`（+peg.bounce）、`04_physics.md`（图钉段重写）、`02_entities.md`（Peg 定义）。特殊图钉（P2）届时在物理钉上叠加 Area2D，#2 的初衷不丢失。
- **推翻关系**：supersedes 决策 #2（2026-09-24，图钉用 Area2D + 脚本反弹）。

## 决策 #12 / 2026-09-27 / 发射方向改为鼠标瞄准（射角钳制）

- **内容**：发射方向从固定"正上方 + 抖动"改为"发射器 → 鼠标位置"，钳制在正上方 ±80°（`aim_angle_limit_deg`）；蓄力期间方向实时跟随鼠标，以松开瞬间为准；抖动基准同步改为瞄准方向。
- **理由**：核心循环的"瞄准"阶段要求玩家主导方向；钳制防朝地面/墙壁浪费球。
- **影响**：`launcher.gd`（+`get_aim_direction()`）、`balance_config.json`（+aim_angle_limit_deg）、`03_rules.md`（发射器参数表）。

## 决策 #13 / 2026-09-27 / HUD 全屏控件必须设 mouse_filter = Ignore

- **内容**：HUD 的 `Root` 与 `TopBar` 设 `mouse_filter = Ignore`（2），按钮保持默认 Stop。
- **理由**：Godot 4 中全屏 `Control` 默认 `mouse_filter = Stop` 会吞掉所有鼠标事件，导致 `_unhandled_input`（发射入口）永远收不到输入——上线首日实测复现。
- **影响**：`HUD.tscn`；`05_ui_hud.md` 增补硬约束：**新增任何全屏 UI 必须显式设 Ignore**。
