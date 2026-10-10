# fijkplayer

本项目基于 [fijkplayer](https://pub.dev/packages/fijkplayer/versions/0.11.0) 开发。

## 简介

fijkplayer 是一个基于 ijkplayer 的视频播放器 Flutter 插件，支持大多数流行的协议和编解码器。<br/>

## 下载安装

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

```yaml
dependencies:
  fijkplayer:
    git: 
      url: https://gitcode.com/CPF-Flutter/fijkplayer.git
      ref: 0.11.0-ohos-1.0.0-beta.1
```

执行命令

```bash
flutter pub get
```
TAG 版本对应表

| Flutter 框架版本 | TAG 名称 | 分支名 |
| --- | --- | --- |
| 3.35| 0.11.0-ohos-1.0.0-beta.1 | v0.11.0_ohos_3.7.12 |

## 约束与限制

### 兼容性

在下述版本中已验证通过：

1. Flutter: 3.35.8-ohos-0.0.1; SDK: 6.0.1(21); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### 权限要求

如果播放网络视频，需要添加网络权限。

打开 `entry/src/main/module.json5`，添加：

```json
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET",
    "reason": "$string:network_reason",
    "usedScene": {
      "abilities": [
        "EntryAbility"
      ],
      "when": "inuse"
    }
  }
]
```

在 `entry/src/main/resources/base/element/string.json`，添加：

```json
{
  "string": [
    {
      "name": "network_reason",
      "value": "使用网络播放视频"
    }
  ]
}
```

## 使用示例

fijkplayer 提供了 `FijkView` Widget 和 `FijkPlayer` 播放控制器，以下是最简单的视频播放方式：

```dart
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final FijkPlayer player = FijkPlayer();

  @override
  void initState() {
    super.initState();
    // 设置数据源并自动播放
    player.setDataSource(
      'https://example.com/video.mp4',
      autoPlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FijkView(
      player: player, // 绑定播放器
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release(); // 释放播放器资源
  }
}
```

## 使用说明

### 1. 创建播放器与播放视频

`FijkPlayer` 是核心播放控制器，通过 MethodChannel 与原生播放引擎交互。

```dart
final FijkPlayer player = FijkPlayer();

// 设置数据源并自动播放
await player.setDataSource('https://example.com/video.mp4', autoPlay: true);

// 也可以先设置数据源再手动准备和播放
await player.setDataSource('asset:///assets/butterfly.mp4');
await player.prepareAsync();
await player.start();
```

> `asset:///` 协议用于访问 Flutter 资源文件。在 OHOS 平台上，资源文件会先从 rawfile 拷贝到沙箱目录，再通过沙箱路径访问。

### 2. 播放控制

```dart
await player.pause();       // 暂停播放
await player.start();       // 恢复/开始播放
await player.stop();        // 停止播放
await player.reset();       // 重置到 idle 状态
await player.seekTo(30000); // 跳转到 30 秒位置（毫秒）
await player.setVolume(0.5); // 设置播放器音量（OHOS 取值范围 0.0～1.0）
await player.setLoop(0);    // 设置循环次数，0 为无限循环
await player.setSpeed(1.5); // 设置播放速度，必须 > 0
```

### 3. 视频显示与 FijkView

`FijkView` 是用于显示视频帧的 Widget，内部使用 `Texture` 组件渲染视频画面。

```dart
FijkView(
  player: player,
  fit: FijkFit.contain,    // 正常模式下的视频适配方式
  fsFit: FijkFit.fill,     // 全屏模式下的视频适配方式
  color: Colors.black,     // 背景颜色
  panelBuilder: fijkPanel2Builder(), // 使用内置面板2
  fs: true,                // 启用全屏响应
)
```

**FijkFit 预设值说明**：

| 预设 | 说明 |
|------|------|
| `FijkFit.fill` | 拉伸填满 FijkView |
| `FijkFit.contain` | 保持比例，完整显示视频 |
| `FijkFit.cover` | 保持比例，覆盖整个 FijkView |
| `FijkFit.fitWidth` | 保持比例，宽度填满 |
| `FijkFit.fitHeight` | 保持比例，高度填满 |
| `FijkFit.ar4_3` | 4:3 比例 |
| `FijkFit.ar16_9` | 16:9 比例 |

### 4. 全屏控制

```dart
player.enterFullScreen(); // 进入全屏（仅改变 FijkValue.fullScreen 状态）
player.exitFullScreen();  // 退出全屏
```

> `enterFullScreen` 和 `exitFullScreen` 仅改变 Dart 层的 `fullScreen` 状态标记。FijkView 会监听该状态变化并自动切换全屏/非全屏页面。

### 5. 播放器选项设置

```dart
// 通过 FijkOption 批量设置
final FijkOption option = FijkOption();
option.setPlayerOption('mediacodec-all-videos', 1);
option.setFormatOption('timeout', 10000);
await player.applyOptions(option);

// 通过 setOption 单个设置
await player.setOption(FijkOption.playerCategory, 'start-on-prepared', 1);
await player.setOption(FijkOption.hostCategory, 'request-audio-focus', 1);
```

**FijkOption 选项类别常量**：

| 常量 | 值 | 说明 |
|------|---|------|
| `hostCategory` | 0 | 宿主选项 |
| `formatCategory` | 1 | avformat 选项 |
| `codecCategory` | 2 | avcodec 选项 |
| `swsCategory` | 3 | swscale 选项 |
| `playerCategory` | 4 | 播放器选项 |
| `swrCategory` | 5 | swresample 选项 |

### 6. 事件监听

`FijkPlayer` 提供多个 Stream 用于监听播放状态变化：

```dart
player.onCurrentPosUpdate.listen((Duration pos) {
  // 当前播放位置更新
});

player.onBufferPosUpdate.listen((Duration pos) {
  // 缓冲位置更新
});

player.onBufferStateUpdate.listen((bool isBuffering) {
  // 缓冲状态变化
});

player.onBufferPercentUpdate.listen((int percent) {
  // 缓冲百分比更新
});

// FijkValue 变化监听（通过 ChangeNotifier）
player.addListener(() {
  FijkValue value = player.value;
  print('state: ${value.state}, prepared: ${value.prepared}');
});
```

### 7. 系统功能

```dart
// 屏幕方向
await FijkPlugin.setOrientationLandscape(); // 设置横屏
await FijkPlugin.setOrientationPortrait();  // 设置竖屏
await FijkPlugin.setOrientationAuto();      // 设置自动旋转

// 屏幕常亮
await FijkPlugin.keepScreenOn(true);  // 保持屏幕常亮
bool isOn = await FijkPlugin.isScreenKeptOn(); // 查询屏幕常亮状态

// 屏幕亮度
await FijkPlugin.setScreenBrightness(0.8); // 设置亮度 [0.0, 1.0]
double brightness = await FijkPlugin.screenBrightness(); // 获取亮度

// 音频焦点
await FijkPlugin.requestAudioFocus(); // 请求音频焦点
await FijkPlugin.releaseAudioFocus(); // 释放音频焦点

// 系统音量（仅支持读取）
double vol = await FijkVolume.getVol(); // 获取系统媒体音量
```

### 8. 自定义面板

fijkplayer 提供两种内置面板构建器：

```dart
// 默认面板
FijkView(player: player, panelBuilder: defaultFijkPanelBuilder);

// 面板2（推荐，功能更丰富）
FijkView(
  player: player,
  panelBuilder: fijkPanel2Builder(
    fill: false,           // 是否填满视频区域
    duration: 4000,        // 自动隐藏时间（毫秒）
    doubleTap: true,       // 双击暂停/播放
    snapShot: false,       // 截图按钮（OHOS 不支持）
    onBack: () => Navigator.pop(context), // 返回回调
  ),
);
```

> `snapShot` 参数在 OHOS 平台上不可用，即使设为 `true` 也无法截图。

### 9. 进度条控件

```dart
FijkSlider(
  value: player.currentPos.inMilliseconds / player.value.duration.inMilliseconds,
  cacheValue: player.bufferPos.inMilliseconds / player.value.duration.inMilliseconds,
  min: 0.0,
  max: 1.0,
  onChanged: (double v) => player.seekTo((v * player.value.duration.inMilliseconds).toInt()),
  colors: FijkSliderColors(
    playedColor: Colors.red.withOpacity(0.6),
    bufferedColor: Colors.blue.withOpacity(0.4),
  ),
)
```

## 接口说明

### 组件

| 名称 | 描述 | 参数类型 | 必填 | OHOS平台支持 |
|------|------|----------|------|---------------------|
| `FijkView` | 视频显示 Widget | `FijkView({player, panelBuilder, ...})` | 是 | 是 |
| `FijkSlider` | 进度条 Widget | `FijkSlider({value, onChanged, ...})` | 是 | 是 |
| `FijkVolumeWatcher` | 音量监听 Widget | `FijkVolumeWatcher({watcher, child, ...})` | 是 | [部分](#遗留问题)（无真实音量事件） |

### 属性

**FijkView 属性**

| 名称 | 描述 | 参数类型 | 必填 | OHOS平台支持 |
|------|------|----------|------|---------------------|
| `player` | 绑定的播放器 | `FijkPlayer` | 是 | 是 |
| `panelBuilder` | 面板构建器 | `FijkPanelWidgetBuilder` | 否 | 是 |
| `onDispose` | 释放回调 | `void Function(FijkData)?` | 否 | 是 |
| `color` | 背景颜色 | `Color` | 否 | 是 |
| `cover` | 封面图片 | `ImageProvider?` | 否 | 是 |
| `fit` | 视频适配方式 | `FijkFit` | 否 | 是 |
| `fsFit` | 全屏适配方式 | `FijkFit` | 否 | 是 |
| `width` | 宽度 | `double?` | 否 | 是 |
| `height` | 高度 | `double?` | 否 | 是 |
| `fs` | 启用全屏 | `bool` | 否 | 是 |

**FijkSlider 属性**

| 名称 | 描述 | 参数类型 | 必填 | OHOS平台支持 |
|------|------|----------|------|---------------------|
| `value` | 当前位置 | `double` | 是 | 是 |
| `cacheValue` | 缓冲位置 | `double` | 否 | 是 |
| `onChanged` | 拖动回调 | `ValueChanged<double>` | 是 | 是 |
| `onChangeStart` | 拖动开始回调 | `ValueChanged<double>?` | 否 | 是 |
| `onChangeEnd` | 拖动结束回调 | `ValueChanged<double>?` | 否 | 是 |
| `min` | 最小值 | `double` | 否 | 是 |
| `max` | 最大值 | `double` | 否 | 是 |
| `colors` | 颜色配置 | `FijkSliderColors` | 否 | 是 |

### API

**FijkPlayer**

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OHOS平台支持 |
|------|------|------|----------|--------|------|---------------------|
| `FijkPlayer()` | 创建播放器实例 | 方法 | 无 | `FijkPlayer` | 是 | 是 |
| `setDataSource` | 设置数据源 | 方法 | `String, {autoPlay, showCover}` | `Future<void>` | 是 | 是 |
| `prepareAsync` | 异步准备 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `start` | 开始播放 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `pause` | 暂停播放 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `stop` | 停止播放 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `reset` | 重置播放器 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `seekTo` | 跳转位置 | 方法 | `int msec` | `Future<void>` | 否 | 是 |
| `setVolume` | 设置播放器音量 | 方法 | `double volume [0.0,1.0]` | `Future<void>` | 否 | 是 |
| `setLoop` | 设置循环次数 | 方法 | `int loopCount` | `Future<void>` | 否 | 是 |
| `setSpeed` | 设置播放速度 | 方法 | `double speed` | `Future<void>` | 否 | 是 |
| `setOption` | 设置单个选项 | 方法 | `int, String, dynamic` | `Future<void>` | 否 | 是 |
| `applyOptions` | 批量应用选项 | 方法 | `FijkOption` | `Future<void>` | 否 | 是 |
| `setupSurface` | 设置渲染表面 | 方法 | 无 | `Future<int?>` | 否 | 是 |
| `takeSnapShot` | 截图 | 方法 | 无 | `Future<Uint8List>` | 否 | [**否**](#遗留问题) |
| `release` | 释放播放器 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `enterFullScreen` | 进入全屏 | 方法 | 无 | `void` | 否 | 是 |
| `exitFullScreen` | 退出全屏 | 方法 | 无 | `void` | 否 | 是 |
| `isPlayable` | 是否可播放 | 方法 | 无 | `bool` | 否 | 是 |
| `id` | 播放器ID | 属性 | 无 | `Future<int>` | — | 是 |
| `idSync` | 同步播放器ID | 属性 | 无 | `int` | — | 是 |
| `state` | 当前状态 | 属性 | 无 | `FijkState` | — | 是 |
| `value` | 当前值 | 属性 | 无 | `FijkValue` | — | 是 |
| `dataSource` | 数据源地址 | 属性 | 无 | `String?` | — | 是 |
| `bufferPos` | 缓冲位置 | 属性 | 无 | `Duration` | — | 是 |
| `currentPos` | 当前位置 | 属性 | 无 | `Duration` | — | 是 |
| `bufferPercent` | 缓冲百分比 | 属性 | 无 | `int` | — | 是 |
| `isBuffering` | 是否缓冲中 | 属性 | 无 | `bool` | — | 是 |
| `onBufferPosUpdate` | 缓冲位置流 | 属性 | 无 | `Stream<Duration>` | — | 是 |
| `onBufferPercentUpdate` | 缓冲百分比流 | 属性 | 无 | `Stream<int>` | — | 是 |
| `onCurrentPosUpdate` | 当前位置流 | 属性 | 无 | `Stream<Duration>` | — | 是 |
| `onBufferStateUpdate` | 缓冲状态流 | 属性 | 无 | `Stream<bool>` | — | 是 |
| `all` | 所有播放器实例 | 属性(静态) | 无 | `Iterable<FijkPlayer>` | — | 是 |

**FijkPlugin（静态API）**

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OHOS平台支持 |
|------|------|------|----------|--------|------|---------------------|
| `setOrientationPortrait` | 设置竖屏 | 方法 | 无 | `Future<bool>` | 否 | 是 |
| `setOrientationLandscape` | 设置横屏 | 方法 | 无 | `Future<bool>` | 否 | 是 |
| `setOrientationAuto` | 设置自动旋转 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `keepScreenOn` | 保持屏幕常亮 | 方法 | `bool` | `Future<void>` | 否 | 是 |
| `isScreenKeptOn` | 查询屏幕常亮 | 方法 | 无 | `Future<bool>` | 否 | 是 |
| `setScreenBrightness` | 设置屏幕亮度 | 方法 | `double [0.0,1.0]` | `Future<void>` | 否 | 是 |
| `screenBrightness` | 获取屏幕亮度 | 方法 | 无 | `Future<double>` | 否 | [部分](#遗留问题) |
| `requestAudioFocus` | 请求音频焦点 | 方法 | 无 | `Future<void>` | 否 | 是 |
| `releaseAudioFocus` | 释放音频焦点 | 方法 | 无 | `Future<void>` | 否 | 是 |

**FijkVolume（静态API）**

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OHOS平台支持 |
|------|------|------|----------|--------|------|---------------------|
| `getVol` | 获取系统音量 | 方法 | 无 | `Future<double>` | 否 | 是 |
| `mute` | 静音 | 方法 | 无 | `Future<double>` | 否 | [**否**](#遗留问题) |
| `setVol` | 设置系统音量 | 方法 | `double` | `Future<double>` | 否 | [**否**](#遗留问题) |
| `up` | 增加音量 | 方法 | `{double step}` | `Future<double>` | 否 | [**否**](#遗留问题) |
| `down` | 减少音量 | 方法 | `{double step}` | `Future<double>` | 否 | [**否**](#遗留问题) |
| `setUIMode` | 设置音量UI模式 | 方法 | `int` | `Future<void>` | 否 | [**否**](#遗留问题) |
| `addListener` | 添加音量监听 | 方法 | `VoidCallback` | `void` | 否 | [部分](#遗留问题) |
| `removeListener` | 移除音量监听 | 方法 | `VoidCallback` | `void` | 否 | [部分](#遗留问题) |
| `value` | 当前音量事件 | 属性(静态) | 无 | `FijkVolumeEvent` | — | [部分](#遗留问题) |

**FijkLog（静态API）**

| 名称 | 描述 | 类型 | 参数类型 | 返回值 | 必填 | OHOS平台支持 |
|------|------|------|----------|--------|------|---------------------|
| `setLevel` | 设置日志级别 | 方法 | `FijkLogLevel` | `void` | 否 | [部分](#遗留问题)（Dart层有效，原生层无操作） |
| `log` | 输出日志 | 方法 | `FijkLogLevel, String, String` | `void` | 否 | 是 |
| `v` | Verbose日志 | 方法 | `String, {String tag}` | `void` | 否 | 是 |
| `d` | Debug日志 | 方法 | `String, {String tag}` | `void` | 否 | 是 |
| `i` | Info日志 | 方法 | `String, {String tag}` | `void` | 否 | 是 |
| `w` | Warn日志 | 方法 | `String, {String tag}` | `void` | 否 | 是 |
| `e` | Error日志 | 方法 | `String, {String tag}` | `void` | 否 | 是 |

**FijkState 枚举**

| 名称 | 值 | 描述 | OHOS平台支持 |
|------|---|------|---------------------|
| `idle` | 0 | 初始状态，无数据源 | 是 |
| `initialized` | 1 | 数据源已设置 | 是 |
| `asyncPreparing` | 2 | 异步准备中 | 是 |
| `prepared` | 3 | 准备完成 | 是 |
| `started` | 4 | 正在播放 | 是 |
| `paused` | 5 | 已暂停 | 是 |
| `completed` | 6 | 播放完成 | 是 |
| `stopped` | 7 | 已停止 | 是 |
| `error` | 8 | 错误状态 | 是 |
| `end` | 9 | 已释放 | 是 |

**FijkValue 类**

| 名称 | 描述 | 类型 | OHOS平台支持 |
|------|------|------|---------------------|
| `prepared` | 是否准备完成 | `bool` | 是 |
| `completed` | 是否播放完成 | `bool` | 是 |
| `audioRenderStart` | 音频渲染是否开始 | `bool` | 是 |
| `videoRenderStart` | 视频渲染是否开始 | `bool` | 是 |
| `state` | 当前状态 | `FijkState` | 是 |
| `size` | 视频像素尺寸 | `Size?` | 是 |
| `rotate` | 旋转角度 | `int` | 是 |
| `duration` | 播放时长 | `Duration` | 是 |
| `fullScreen` | 是否全屏 | `bool` | 是 |
| `exception` | 异常信息 | `FijkException` | 是 |

**FijkOption 类**

| 名称 | 描述 | 类型 | OHOS平台支持 |
|------|------|------|---------------------|
| `hostCategory` | 宿主选项类别 | `int (0)` | 是 |
| `formatCategory` | 格式选项类别 | `int (1)` | 是 |
| `codecCategory` | 编解码选项类别 | `int (2)` | 是 |
| `swsCategory` | swscale选项类别 | `int (3)` | 是 |
| `playerCategory` | 播放器选项类别 | `int (4)` | 是 |
| `swrCategory` | swresample选项类别 | `int (5)` | 是 |
| `setHostOption` | 设置宿主选项 | 方法 | 是 |
| `setPlayerOption` | 设置播放器选项 | 方法 | 是 |
| `setFormatOption` | 设置格式选项 | 方法 | 是 |
| `setCodecOption` | 设置编解码选项 | 方法 | 是 |
| `setSwsOption` | 设置swscale选项 | 方法 | 是 |
| `setSwrOption` | 设置swresample选项 | 方法 | 是 |
| `data` | 获取选项数据副本 | getter | 是 |

**FijkFit 类**

| 名称 | 描述 | 类型 | OHOS平台支持 |
|------|------|------|---------------------|
| `alignment` | 对齐方式 | `Alignment` | 是 |
| `aspectRatio` | 宽高比 | `double` | 是 |
| `sizeFactor` | 尺寸系数 | `double` | 是 |
| `fill` | 填满预设 | `FijkFit` | 是 |
| `contain` | 包含预设 | `FijkFit` | 是 |
| `cover` | 覆盖预设 | `FijkFit` | 是 |
| `fitWidth` | 适配宽度预设 | `FijkFit` | 是 |
| `fitHeight` | 适配高度预设 | `FijkFit` | 是 |
| `ar4_3` | 4:3 比例预设 | `FijkFit` | 是 |
| `ar16_9` | 16:9 比例预设 | `FijkFit` | 是 |

**顶层函数**

| 名称 | 描述 | 参数类型 | 返回值 | OHOS平台支持 |
|------|------|----------|--------|---------------------|
| `defaultFijkPanelBuilder` | 默认面板构建器 | `FijkPlayer, FijkData, BuildContext, Size, Rect` | `Widget` | 是 |
| `fijkPanel2Builder` | 面板2构建器 | `{Key, bool fill, int duration, bool doubleTap, bool snapShot, VoidCallback? onBack}` | `FijkPanelWidgetBuilder` | 是 |
| `defaultFijkVolumeToast` | 音量提示 | `double, Stream<double>` | `Widget` | 是 |
| `defaultFijkBrightnessToast` | 亮度提示 | `double, Stream<double>` | `Widget` | 是 |

## 遗留问题

- 不支持 `takeSnapShot()` 截图功能。OHOS 原生实现返回 `notImplemented`，`enable-snapshot` 宿主选项已识别但功能未实现。
- 不支持 `FijkVolume.mute()`、`FijkVolume.setVol()`、`FijkVolume.up()`、`FijkVolume.down()` 系统音量写操作。OHOS 音量控制 API 仅系统级应用可使用。
- 不支持 `FijkVolume.setUIMode()` 音量 UI 模式设置。OHOS 无系统音量 UI 机制，MethodChannel 收到调用但不执行操作。
- `FijkPlugin.screenBrightness()` 返回缓存值而非实时系统亮度。
- `FijkLog.setLevel()` 原生层 MethodChannel 调用为空操作（no-op），Dart 层日志级别设置有效。
- `FijkVolumeWatcher` 和 `FijkVolume.addListener()` 监听器基础设施可用，但 OHOS 平台不会产生真实的系统音量变化事件。

## 常见问题

**1. asset:/// 资源无法播放**<br/>
确保资源文件在 `pubspec.yaml` 的 `assets` 部分正确声明，路径格式为 `asset:///assets/xxx.mp4`。OHOS 会在插件初始化时自动将 rawfile 中的资源拷贝到沙箱目录。

**2. 全屏切换后画面不显示**<br/>
OHOS 使用 Texture Surface 渲染模式，全屏切换后 FijkView 会重新调用 `setupSurface()`，确保 textureId 正确绑定。

**3. 系统音量控制不生效**<br/>
OHOS 平台上系统音量写操作（mute/set/up/down）仅系统级应用可用。如需调整播放音量，请使用 `FijkPlayer.setVolume()` 设置播放器音轨音量。

## 开源协议

本项目基于 [MIT](https://gitcode.com/CPF-Flutter/fijkplayer/blob/v0.11.0_ohos_3.7.12/LICENSE) ，请自由地享受和参与开源。