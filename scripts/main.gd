extends Node2D
##
## Main：场景根节点（协调者）。
##
## 2026-09-26 职责变化：
## - 球的销毁改由底部检测区负责（BottomZoneLeft / Pocket / BottomZoneRight），
##   本脚本不再做 y > 1100 的越界清理。
## - 回合流程（倒计时 / 库存 / 结算 / 重试）由子节点 RoundManager 负责。
## - 界面反馈由子节点 HUD（CanvasLayer）负责。
##
## 目前本脚本无运行逻辑，仅作为根节点脚本占位与未来扩展入口。
##
