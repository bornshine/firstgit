# 08 命名约定

> **不变量**：AI 新增变量 / 节点 / 信号时必须先查本文件，不得自造格式。

## 通用原则

1. 全部使用英文，禁止拼音 / 中文标识符。
2. 不在名字里重复类型（不要 `ball_rigidbody`，用 `ball`）。
3. 缩写仅限公认的（`ui`、`hud`、`id`、`hp`），其余写全。
4. 名字表达"是什么"，不表达"怎么实现的"。

## 按类别

### 文件

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 脚本 | snake_case.gd | `peg_board.gd` |
| 场景 | PascalCase.tscn | `Main.tscn` |
| 资源 | snake_case | `ball_metal.png` |
| 文档 | 编号_名称.md（小写 + 下划线） | `04_physics.md` |

### 节点（Node）

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 节点名 | PascalCase | `LeftWall`、`BallTemplate`、`PegBoard` |
| 模板 / 根节点 | 加后缀 `Template` / `Root` | `BallTemplate` |
| 编号实例 | 类别_行_列 | `Peg_0_3` |

### 变量 / 属性

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 普通变量 | snake_case | `fire_interval` |
| `@export` 变量 | snake_case | `launch_impulse` |
| 私有成员 | `_` + snake_case | `_firing`、`_timer` |
| `@onready` 节点引用 | snake_case，**不带 `_` 前缀**（豁免，2026-09-27 决策） | `time_label`、`charge_bar` |
| 常量 | UPPER_SNAKE_CASE | `PEG_TEXTURE_SIZE` |
| 布尔 | `is_` / `has_` / `can_` 前缀 | `is_firing`、`has_ammo` |

### 函数

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 公开函数 | snake_case，动词开头 | `spawn_ball()`、`generate_pegs()` |
| 私有函数 | `_` + snake_case | `_spawn_ball()`、`_make_peg()` |
| 信号回调 | `_on_` + 来源 + 事件 | `_on_peg_body_entered()` |
| 虚函数 | Godot 内置格式 | `_ready()`、`_physics_process()` |

### 信号

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 信号名 | snake_case，**过去式 / 名词短语** | `ball_entered`、`round_finished` |
| 禁止 | 不要 `Signal` 后缀、不要 `On` 前缀 | ❌ `OnBallEnter` |

### 枚举

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 枚举类型 | PascalCase | `BallState` |
| 枚举成员 | UPPER_SNAKE_CASE | `BallState.IN_FLIGHT` |

### 组（Group）

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 组名 | snake_case，`StringName` | `&"balls"`、`&"pegs"` |

### 碰撞层 / 掩码

| 规则 | 示例 |
| --- | --- |
| `layer_` + 用途 | `layer_ball`、`layer_peg`、`layer_wall` |
| 在 `project.godot` 中统一编号，禁止脚本内硬编码数字 | 待补充 |

## 与本项目已用命名对照（校验）

| 位置 | 已用名 | 符合 |
| --- | --- | --- |
| 图钉生成 | `_generate_pegs` / `_make_peg` | ✅ |
| 图钉回调 | `_on_peg_body_entered` | ✅ |
| 发射器成员 | `_firing` / `_timer` | ✅ |
| 发射函数 | `_spawn_ball` | ✅ |
| 组名 | `&"balls"` | ✅ |
| 常量 | `PEG_TEXTURE_SIZE` | ✅ |
| 节点 | `BallTemplate` / `LeftWall` | ✅ |
| 场景 | `Main.tscn` | ✅ |

## 违规示例（反面教材）

| 违规 | 问题 | 正确写法 |
| --- | --- | --- |
| `BallRigidBody` | 名字里带类型 | `Ball` |
| `fireInterval` | 非 snake_case | `fire_interval` |
| `OnBallEntered` | 信号用了 On 前缀 | `ball_entered` |
| `pegboard` | 节点未用 PascalCase | `PegBoard` |
| `TEMP_SPEED` | 用途不明 | `PEG_BOUNCE_SPEED` |
