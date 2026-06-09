# 贪吃蛇游戏 - HarmonyOS NEXT

完成了贪吃蛇游戏的基本内容，优化了布局，补充了多端通用和自由流转。

## 项目概述

基于 HarmonyOS NEXT (ArkTS + ArkUI) 开发贪吃蛇游戏，实现一次开发、多端部署与自由流转。

## 完成功能

### 1. 核心游戏功能
- Canvas 2D 绘制：蛇身渐变色、食物、网格背景、蛇头眼睛、道具、障碍墙
- 方向控制按钮（上下左右）
- 碰撞检测（边界 + 自身 + 障碍墙）
- 分数计算与最高分记录
- 速度随分数递增（初始160ms → 最快60ms）
- 暂停/继续/重新开始
- **等级系统**：每100分升一级，等级越高障碍墙越多
- **道具系统**（5种道具，随机刷新，限时消失）：
  - 🔴 **S 加速**（橙色）：临时加速蛇的移动
  - 🟢 **W 减速**（绿色）：临时减速，更容易操控
  - 🟡 **2 双倍分**（黄色）：吃到直接加20分
  - 🟡 **D 护盾**（金色）：5步内免疫碰撞（蛇头变金色）
  - 🟣 **X 缩短**（紫色）：蛇身缩短3节
- **障碍墙系统**：随等级增加，地图上随机出现障碍墙，增加难度

### 2. 一次开发，多端部署 ✅
- **module.json5** 配置 `deviceTypes: ["phone", "tablet", "2in1"]`
- 支持手机、平板、2in1设备三种形态
- **自适应布局**：Canvas用百分比+layoutWeight自适应，按钮固定底部
- 界面显示当前设备类型标签 `[手机]` / `[平板]`

### 3. 自由流转 ✅
- **module.json5** 配置 `continueType: ["async"]` 启用流转能力
- **EntryAbility** 实现流转回调：
  - `onContinue()`: 同意流转请求，返回 `AGREE`
  - `onRestoreData()`: 从源端恢复游戏数据
  - `onNewWant()`: 在目标设备接收流转数据
- **流转数据内容**：蛇身坐标、食物位置、道具列表、方向、分数、最高分、速度、游戏状态、障碍墙、等级、护盾步数
- 流转到新设备后自动恢复游戏进度，若游戏进行中则自动继续

## 技术架构

```
HarmonySnake/
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/EntryAbility.ets  # 流转回调实现
│   │   └── pages/Index.ets               # 游戏主页面 + 自适应布局
│   ├── module.json5                       # 多端设备 + 流转配置
│   └── resources/                         # 多语言 + 颜色资源
├── AppScope/                              # 应用级配置
└── build-profile.json5                    # 构建配置
```

## 关键代码说明

**多端部署 - module.json5：**
```json5
"deviceTypes": ["phone", "tablet", "2in1"]
```

**自由流转 - EntryAbility.ets：**
```typescript
onContinue(wantParam): OnContinueResult {
  return AbilityConstant.OnContinueResult.AGREE;
}

onRestoreData(want): void {
  AppStorage.setOrCreate<string>('restoreGameData', gameDataStr);
}
```

**自适应布局 - Index.ets：**
```typescript
@State isTablet: boolean = false;
@State gridSize: number = 18;
@State cellSize: number = 16;
// Canvas用百分比+layoutWeight自适应，按钮固定底部
```
