# 06 音效分层（总线、事件名清单）

> **不变量**：音效调用统一走 `AudioManager`，禁止在游戏脚本里直接操作 `AudioStreamPlayer`。
> 事件名改动必须同步 `data/audio_config.json`。

## 当前状态

MVP 之前 **无任何音效**。以下事件名均为规划。

## 总线结构（规划）

```
Master
├── BGM          # 背景音乐
├── SFX          # 游戏音效
│   ├── Ball     # 球相关
│   └── World    # 环境 / 场景
└── UI           # 界面交互音
```

## 事件名清单

### Ball（球）

| 事件名 | 触发时机 | 优先级 |
| --- | --- | --- |
| `ball/launch` | 球被发射 | P1 |
| `ball/hit_peg` | 撞到图钉 | P1 |
| `ball/hit_wall` | 撞到左右墙 / 天花板 | P1 |
| `ball/hit_floor` | 撞到地面 | P1 |
| `ball/enter_pocket` | 进袋 | P1 |
| `ball/lost` | 球出界被清理 | P2 |

### Round（回合）

| 事件名 | 触发时机 | 优先级 |
| --- | --- | --- |
| `round/start` | 回合开始 | P2 |
| `round/end` | 回合结束 | P2 |
| `round/record` | 刷新最高分 | P3 |

### UI（界面）

| 事件名 | 触发时机 | 优先级 |
| --- | --- | --- |
| `ui/click` | 按钮点击 | P3 |
| `ui/hover` | 按钮悬停 | P3 |
| `ui/upgrade_pick` | 选择升级 | P2 |

### World（环境）

| 事件名 | 触发时机 | 优先级 |
| --- | --- | --- |
| `world/pocket_glow` | 袋洞高亮（进袋前兆） | P3 |
| `world/combo` | 连击触发 | P3 |

## 命名约定

- **格式**：`系统/动作`，全小写 snake_case。
- **动作**使用原形动词或名词（`hit_peg`、`enter_pocket`），不要 `hit_peg_sound`。
- 新增事件必须同时更新：① 本文件 ② `data/audio_config.json` ③ `99_decisions.md`（若涉及分层调整）。

## 音量默认值（规划）

| 总线 | 默认音量 | 说明 |
| --- | --- | --- |
| Master | 0 dB | — |
| BGM | −12 dB | 背景不抢戏 |
| SFX | −6 dB | 主角 |
| UI | −9 dB | 稍弱于 SFX |

## 播放策略（规划）

| 事件 | 策略 | 理由 |
| --- | --- | --- |
| `ball/hit_peg` | 随机音高 ±10% + 频率限制（> 30ms 内不重复） | 密集撞击时避免爆音 |
| `ball/launch` | 每次播放 | 关键操作，必须有反馈 |
| `ball/enter_pocket` | 优先播放，可打断其它 Ball 音 | 奖励时刻不能被淹没 |
