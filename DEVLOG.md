# 开发日志

## 2026-06-09 贪吃蛇游戏开发

### 项目概述
基于 HarmonyOS NEXT (ArkTS + ArkUI) 开发贪吃蛇游戏，实现一次开发、多端部署与自由流转。

### 完成功能

#### 1. 核心游戏功能
- 20×20（手机）/ 24×24（平板）网格贪吃蛇游戏
- Canvas 2D 绘制：蛇身渐变色、食物、网格背景、蛇头眼睛
- 方向控制按钮（上下左右）
- 碰撞检测（边界 + 自身）
- 分数计算与最高分记录
- 速度随分数递增（初始180ms → 最快80ms）
- 暂停/继续/重新开始

#### 2. 一次开发，多端部署 ✅
- **module.json5** 配置 `deviceTypes: ["phone", "tablet", "2in1"]`
- 支持手机、平板、2in1设备三种形态
- **自适应布局**：
  - 手机：20×20网格，cellSize=18，小按钮
  - 平板：24×24网格，cellSize=22，大按钮
  - 字体大小、按钮尺寸根据设备类型动态调整
- 界面显示当前设备类型标签 `[手机]` / `[平板]`

#### 3. 自由流转 ✅
- **module.json5** 配置 `continueType: "async"` 启用流转能力
- **EntryAbility** 实现流转回调：
  - `onContinue()`: 同意流转请求，返回 `AGREE`
  - `onRestoreData()`: 从源端恢复游戏数据
  - `onNewWant()`: 在目标设备接收流转数据
- **流转数据内容**：蛇身坐标、食物位置、方向、分数、最高分、速度、游戏状态
- 流转到新设备后自动恢复游戏进度，若游戏进行中则自动继续

### 技术架构
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

### 关键代码说明

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
@State gridSize: number = 20;
@State cellSize: number = 18;
// 根据设备类型动态调整网格大小和UI尺寸
```