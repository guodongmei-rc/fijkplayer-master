# fijkplayer

This project is based on [fijkplayer](https://pub.dev/packages/fijkplayer/versions/0.11.0).

## Introduction

fijkplayer is a video player Flutter plugin based on ijkplayer, supporting most popular protocols and codecs.<br/>

## Download and Installation

Navigate to the project directory and add the following dependency in pubspec.yaml:

```yaml
dependencies:
  fijkplayer:
    git: 
      url: https://gitcode.com/CPF-Flutter/fijkplayer.git
      ref: 0.11.0-ohos-1.0.0-beta.1
```

Run the command

```bash
flutter pub get
```
TAG Version Mapping

| Flutter Framework Version | TAG Name | Branch |
| --- | --- | --- |
| 3.35| 0.11.0-ohos-1.0.0-beta.1 | v0.11.0_ohos_3.7.12 |

## Constraints and Limitations

### Compatibility

Verified on the following versions:

1. Flutter: 3.35.8-ohos-0.0.1; SDK: 6.0.1(21); IDE: DevEco Studio: 6.0.1.260; ROM: 6.0.0.120 SP6;

### Permission Requirements

If playing network video, Internet permission is required.

Open `entry/src/main/module.json5` and add:

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

In `entry/src/main/resources/base/element/string.json`, add:

```json
{
  "string": [
    {
      "name": "network_reason",
      "value": "Playing network video"
    }
  ]
}
```

## Usage Example

fijkplayer provides `FijkView` Widget and `FijkPlayer` controller. The simplest video playback method is as follows:

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
    // Set data source and auto play
    player.setDataSource(
      'https://example.com/video.mp4',
      autoPlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FijkView(
      player: player, // Bind player
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release(); // Release player resources
  }
}
```

## Usage Instructions

### 1. Creating Player and Playing Video

`FijkPlayer` is the core player controller that interacts with the native playback engine via MethodChannel.

```dart
final FijkPlayer player = FijkPlayer();

// Set data source with auto play
await player.setDataSource('https://example.com/video.mp4', autoPlay: true);

// Alternatively, set data source then manually prepare and play
await player.setDataSource('asset:///assets/butterfly.mp4');
await player.prepareAsync();
await player.start();
```

> The `asset:///` scheme is used to access Flutter asset files. On OHOS, asset files are first copied from rawfile to the sandbox directory, then accessed via the sandbox path.

### 2. Playback Control

```dart
await player.pause();       // Pause playback
await player.start();       // Resume/start playback
await player.stop();        // Stop playback
await player.reset();       // Reset to idle state
await player.seekTo(30000); // Seek to 30 seconds position (milliseconds)
await player.setVolume(0.5); // Set player volume (OHOS range 0.0～1.0)
await player.setLoop(0);    // Set loop count, 0 means infinite loop
await player.setSpeed(1.5); // Set playback speed, must be > 0
```

### 3. Video Display with FijkView

`FijkView` is the Widget for displaying video frames. It uses a `Texture` widget internally to render video frames.

```dart
FijkView(
  player: player,
  fit: FijkFit.contain,    // Video fit mode for normal display
  fsFit: FijkFit.fill,     // Video fit mode for full screen
  color: Colors.black,     // Background color
  panelBuilder: fijkPanel2Builder(), // Use built-in panel2
  fs: true,                // Enable full screen response
)
```

**FijkFit preset descriptions:**

| Preset | Description |
|------|------|
| `FijkFit.fill` | Stretch to fill FijkView |
| `FijkFit.contain` | Maintain aspect ratio, fully display video |
| `FijkFit.cover` | Maintain aspect ratio, cover entire FijkView |
| `FijkFit.fitWidth` | Maintain aspect ratio, fill width |
| `FijkFit.fitHeight` | Maintain aspect ratio, fill height |
| `FijkFit.ar4_3` | 4:3 aspect ratio |
| `FijkFit.ar16_9` | 16:9 aspect ratio |

### 4. Full Screen Control

```dart
player.enterFullScreen(); // Enter full screen (only changes FijkValue.fullScreen state)
player.exitFullScreen();  // Exit full screen
```

> `enterFullScreen` and `exitFullScreen` only change the `fullScreen` state flag at the Dart level. FijkView monitors this state change and automatically switches between full screen and non-full screen pages.

### 5. Player Options

```dart
// Batch setting via FijkOption
final FijkOption option = FijkOption();
option.setPlayerOption('mediacodec-all-videos', 1);
option.setFormatOption('timeout', 10000);
await player.applyOptions(option);

// Single setting via setOption
await player.setOption(FijkOption.playerCategory, 'start-on-prepared', 1);
await player.setOption(FijkOption.hostCategory, 'request-audio-focus', 1);
```

**FijkOption category constants:**

| Constant | Value | Description |
|------|---|------|
| `hostCategory` | 0 | Host options |
| `formatCategory` | 1 | avformat options |
| `codecCategory` | 2 | avcodec options |
| `swsCategory` | 3 | swscale options |
| `playerCategory` | 4 | Player options |
| `swrCategory` | 5 | swresample options |

### 6. Event Listening

`FijkPlayer` provides multiple Streams for monitoring playback state changes:

```dart
player.onCurrentPosUpdate.listen((Duration pos) {
  // Current playback position update
});

player.onBufferPosUpdate.listen((Duration pos) {
  // Buffer position update
});

player.onBufferStateUpdate.listen((bool isBuffering) {
  // Buffering state change
});

player.onBufferPercentUpdate.listen((int percent) {
  // Buffer percentage update
});

// FijkValue change listening (via ChangeNotifier)
player.addListener(() {
  FijkValue value = player.value;
  print('state: ${value.state}, prepared: ${value.prepared}');
});
```

### 7. System Functions

```dart
// Screen orientation
await FijkPlugin.setOrientationLandscape(); // Set landscape
await FijkPlugin.setOrientationPortrait();  // Set portrait
await FijkPlugin.setOrientationAuto();      // Set auto rotation

// Screen on
await FijkPlugin.keepScreenOn(true);  // Keep screen on
bool isOn = await FijkPlugin.isScreenKeptOn(); // Check screen on state

// Screen brightness
await FijkPlugin.setScreenBrightness(0.8); // Set brightness [0.0, 1.0]
double brightness = await FijkPlugin.screenBrightness(); // Get brightness

// Audio focus
await FijkPlugin.requestAudioFocus(); // Request audio focus
await FijkPlugin.releaseAudioFocus(); // Release audio focus

// System volume (read only)
double vol = await FijkVolume.getVol(); // Get system media volume
```

### 8. Custom Panel

fijkplayer provides two built-in panel builders:

```dart
// Default panel
FijkView(player: player, panelBuilder: defaultFijkPanelBuilder);

// Panel2 (recommended, richer features)
FijkView(
  player: player,
  panelBuilder: fijkPanel2Builder(
    fill: false,           // Whether to fill the video area
    duration: 4000,        // Auto-hide duration (milliseconds)
    doubleTap: true,       // Double tap to pause/play
    snapShot: false,       // Screenshot button (not supported on OHOS)
    onBack: () => Navigator.pop(context), // Back callback
  ),
);
```

> The `snapShot` parameter is not functional on OHOS. Setting it to `true` will not enable screenshot capability.

### 9. Progress Slider Widget

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

## API Reference

### Components

| Name | Description | Parameter Type | Required | OHOS Support |
|------|------|----------|------|---------------------|
| `FijkView` | Video display Widget | `FijkView({player, panelBuilder, ...})` | Yes | Yes |
| `FijkSlider` | Progress slider Widget | `FijkSlider({value, onChanged, ...})` | Yes | Yes |
| `FijkVolumeWatcher` | Volume watch Widget | `FijkVolumeWatcher({watcher, child, ...})` | Yes | [Partial](#known-issues) (no real volume events) |

### Properties

**FijkView Properties**

| Name | Description | Parameter Type | Required | OHOS Support |
|------|------|----------|------|---------------------|
| `player` | Bound player | `FijkPlayer` | Yes | Yes |
| `panelBuilder` | Panel builder | `FijkPanelWidgetBuilder` | No | Yes |
| `onDispose` | Dispose callback | `void Function(FijkData)?` | No | Yes |
| `color` | Background color | `Color` | No | Yes |
| `cover` | Cover image | `ImageProvider?` | No | Yes |
| `fit` | Video fit mode | `FijkFit` | No | Yes |
| `fsFit` | Full screen fit mode | `FijkFit` | No | Yes |
| `width` | Width | `double?` | No | Yes |
| `height` | Height | `double?` | No | Yes |
| `fs` | Enable full screen | `bool` | No | Yes |

**FijkSlider Properties**

| Name | Description | Parameter Type | Required | OHOS Support |
|------|------|----------|------|---------------------|
| `value` | Current position | `double` | Yes | Yes |
| `cacheValue` | Buffer position | `double` | No | Yes |
| `onChanged` | Drag callback | `ValueChanged<double>` | Yes | Yes |
| `onChangeStart` | Drag start callback | `ValueChanged<double>?` | No | Yes |
| `onChangeEnd` | Drag end callback | `ValueChanged<double>?` | No | Yes |
| `min` | Minimum value | `double` | No | Yes |
| `max` | Maximum value | `double` | No | Yes |
| `colors` | Color configuration | `FijkSliderColors` | No | Yes |

### API

**FijkPlayer**

| Name | Description | Type | Parameter Type | Return Value | Required | OHOS Support |
|------|------|------|----------|--------|------|---------------------|
| `FijkPlayer()` | Create player instance | Method | None | `FijkPlayer` | Yes | Yes |
| `setDataSource` | Set data source | Method | `String, {autoPlay, showCover}` | `Future<void>` | Yes | Yes |
| `prepareAsync` | Async prepare | Method | None | `Future<void>` | No | Yes |
| `start` | Start playback | Method | None | `Future<void>` | No | Yes |
| `pause` | Pause playback | Method | None | `Future<void>` | No | Yes |
| `stop` | Stop playback | Method | None | `Future<void>` | No | Yes |
| `reset` | Reset player | Method | None | `Future<void>` | No | Yes |
| `seekTo` | Seek position | Method | `int msec` | `Future<void>` | No | Yes |
| `setVolume` | Set player volume | Method | `double volume [0.0,1.0]` | `Future<void>` | No | Yes |
| `setLoop` | Set loop count | Method | `int loopCount` | `Future<void>` | No | Yes |
| `setSpeed` | Set playback speed | Method | `double speed` | `Future<void>` | No | Yes |
| `setOption` | Set single option | Method | `int, String, dynamic` | `Future<void>` | No | Yes |
| `applyOptions` | Batch apply options | Method | `FijkOption` | `Future<void>` | No | Yes |
| `setupSurface` | Setup render surface | Method | None | `Future<int?>` | No | Yes |
| `takeSnapShot` | Take screenshot | Method | None | `Future<Uint8List>` | No | [**No**](#known-issues) |
| `release` | Release player | Method | None | `Future<void>` | No | Yes |
| `enterFullScreen` | Enter full screen | Method | None | `void` | No | Yes |
| `exitFullScreen` | Exit full screen | Method | None | `void` | No | Yes |
| `isPlayable` | Is playable | Method | None | `bool` | No | Yes |
| `id` | Player ID | Property | None | `Future<int>` | — | Yes |
| `idSync` | Sync player ID | Property | None | `int` | — | Yes |
| `state` | Current state | Property | None | `FijkState` | — | Yes |
| `value` | Current value | Property | None | `FijkValue` | — | Yes |
| `dataSource` | Data source URL | Property | None | `String?` | — | Yes |
| `bufferPos` | Buffer position | Property | None | `Duration` | — | Yes |
| `currentPos` | Current position | Property | None | `Duration` | — | Yes |
| `bufferPercent` | Buffer percentage | Property | None | `int` | — | Yes |
| `isBuffering` | Is buffering | Property | None | `bool` | — | Yes |
| `onBufferPosUpdate` | Buffer position stream | Property | None | `Stream<Duration>` | — | Yes |
| `onBufferPercentUpdate` | Buffer percent stream | Property | None | `Stream<int>` | — | Yes |
| `onCurrentPosUpdate` | Current position stream | Property | None | `Stream<Duration>` | — | Yes |
| `onBufferStateUpdate` | Buffer state stream | Property | None | `Stream<bool>` | — | Yes |
| `all` | All player instances | Property (static) | None | `Iterable<FijkPlayer>` | — | Yes |

**FijkPlugin (Static API)**

| Name | Description | Type | Parameter Type | Return Value | Required | OHOS Support |
|------|------|------|----------|--------|------|---------------------|
| `setOrientationPortrait` | Set portrait orientation | Method | None | `Future<bool>` | No | Yes |
| `setOrientationLandscape` | Set landscape orientation | Method | None | `Future<bool>` | No | Yes |
| `setOrientationAuto` | Set auto rotation | Method | None | `Future<void>` | No | Yes |
| `keepScreenOn` | Keep screen on | Method | `bool` | `Future<void>` | No | Yes |
| `isScreenKeptOn` | Check screen on | Method | None | `Future<bool>` | No | Yes |
| `setScreenBrightness` | Set screen brightness | Method | `double [0.0, 1.0]` | `Future<void>` | No | Yes |
| `screenBrightness` | Get screen brightness | Method | None | `Future<double>` | No | [Partial](#known-issues) |
| `requestAudioFocus` | Request audio focus | Method | None | `Future<void>` | No | Yes |
| `releaseAudioFocus` | Release audio focus | Method | None | `Future<void>` | No | Yes |

**FijkVolume (Static API)**

| Name | Description | Type | Parameter Type | Return Value | Required | OHOS Support |
|------|------|------|----------|--------|------|---------------------|
| `getVol` | Get system volume | Method | None | `Future<double>` | No | Yes |
| `mute` | Mute volume | Method | None | `Future<double>` | No | [**No**](#known-issues) |
| `setVol` | Set system volume | Method | `double` | `Future<double>` | No | [**No**](#known-issues) |
| `up` | Increase volume | Method | `{double step}` | `Future<double>` | No | [**No**](#known-issues) |
| `down` | Decrease volume | Method | `{double step}` | `Future<double>` | No | [**No**](#known-issues) |
| `setUIMode` | Set volume UI mode | Method | `int` | `Future<void>` | No | [**No**](#known-issues) |
| `addListener` | Add volume listener | Method | `VoidCallback` | `void` | No | [Partial](#known-issues) |
| `removeListener` | Remove volume listener | Method | `VoidCallback` | `void` | No | [Partial](#known-issues) |
| `value` | Current volume event | Property (static) | None | `FijkVolumeEvent` | — | [Partial](#known-issues) |

**FijkLog (Static API)**

| Name | Description | Type | Parameter Type | Return Value | Required | OHOS Support |
|------|------|------|----------|--------|------|---------------------|
| `setLevel` | Set log level | Method | `FijkLogLevel` | `void` | No | [Partial](#known-issues) (Dart-side works, native-side no-op) |
| `log` | Output log | Method | `FijkLogLevel, String, String` | `void` | No | Yes |
| `v` | Verbose log | Method | `String, {String tag}` | `void` | No | Yes |
| `d` | Debug log | Method | `String, {String tag}` | `void` | No | Yes |
| `i` | Info log | Method | `String, {String tag}` | `void` | No | Yes |
| `w` | Warn log | Method | `String, {String tag}` | `void` | No | Yes |
| `e` | Error log | Method | `String, {String tag}` | `void` | No | Yes |

**FijkState Enum**

| Name | Value | Description | OHOS Support |
|------|---|------|---------------------|
| `idle` | 0 | Initial state, no data source | Yes |
| `initialized` | 1 | Data source set | Yes |
| `asyncPreparing` | 2 | Preparing asynchronously | Yes |
| `prepared` | 3 | Preparation complete | Yes |
| `started` | 4 | Playing | Yes |
| `paused` | 5 | Paused | Yes |
| `completed` | 6 | Playback completed | Yes |
| `stopped` | 7 | Stopped | Yes |
| `error` | 8 | Error state | Yes |
| `end` | 9 | Released | Yes |

**FijkValue Class**

| Name | Description | Type | OHOS Support |
|------|------|------|---------------------|
| `prepared` | Is preparation complete | `bool` | Yes |
| `completed` | Is playback completed | `bool` | Yes |
| `audioRenderStart` | Has audio rendering started | `bool` | Yes |
| `videoRenderStart` | Has video rendering started | `bool` | Yes |
| `state` | Current state | `FijkState` | Yes |
| `size` | Video pixel size | `Size?` | Yes |
| `rotate` | Rotation degrees | `int` | Yes |
| `duration` | Playback duration | `Duration` | Yes |
| `fullScreen` | Is full screen | `bool` | Yes |
| `exception` | Exception info | `FijkException` | Yes |

**FijkOption Class**

| Name | Description | Type | OHOS Support |
|------|------|------|---------------------|
| `hostCategory` | Host option category | `int (0)` | Yes |
| `formatCategory` | Format option category | `int (1)` | Yes |
| `codecCategory` | Codec option category | `int (2)` | Yes |
| `swsCategory` | Swscale option category | `int (3)` | Yes |
| `playerCategory` | Player option category | `int (4)` | Yes |
| `swrCategory` | Swresample option category | `int (5)` | Yes |
| `setHostOption` | Set host option | Method | Yes |
| `setPlayerOption` | Set player option | Method | Yes |
| `setFormatOption` | Set format option | Method | Yes |
| `setCodecOption` | Set codec option | Method | Yes |
| `setSwsOption` | Set swscale option | Method | Yes |
| `setSwrOption` | Set swresample option | Method | Yes |
| `data` | Get options data copy | getter | Yes |

**FijkFit Class**

| Name | Description | Type | OHOS Support |
|------|------|------|---------------------|
| `alignment` | Alignment | `Alignment` | Yes |
| `aspectRatio` | Aspect ratio | `double` | Yes |
| `sizeFactor` | Size factor | `double` | Yes |
| `fill` | Fill preset | `FijkFit` | Yes |
| `contain` | Contain preset | `FijkFit` | Yes |
| `cover` | Cover preset | `FijkFit` | Yes |
| `fitWidth` | Fit width preset | `FijkFit` | Yes |
| `fitHeight` | Fit height preset | `FijkFit` | Yes |
| `ar4_3` | 4:3 aspect preset | `FijkFit` | Yes |
| `ar16_9` | 16:9 aspect preset | `FijkFit` | Yes |

**Top-level Functions**

| Name | Description | Parameter Type | Return Value | OHOS Support |
|------|------|----------|--------|---------------------|
| `defaultFijkPanelBuilder` | Default panel builder | `FijkPlayer, FijkData, BuildContext, Size, Rect` | `Widget` | Yes |
| `fijkPanel2Builder` | Panel2 builder | `{Key, bool fill, int duration, bool doubleTap, bool snapShot, VoidCallback? onBack}` | `FijkPanelWidgetBuilder` | Yes |
| `defaultFijkVolumeToast` | Volume toast | `double, Stream<double>` | `Widget` | Yes |
| `defaultFijkBrightnessToast` | Brightness toast | `double, Stream<double>` | `Widget` | Yes |

## Known Issues

- `takeSnapShot()` screenshot is not supported. The OHOS native implementation returns `notImplemented`; the `enable-snapshot` host option is recognized but not functional.
- `FijkVolume.mute()`, `FijkVolume.setVol()`, `FijkVolume.up()`, `FijkVolume.down()` system volume write operations are not supported. OHOS volume control APIs are only available for system-level applications.
- `FijkVolume.setUIMode()` volume UI mode setting is not supported. OHOS has no system volume UI mechanism; the MethodChannel call is received but no action is taken.
- `FijkPlugin.screenBrightness()` returns a cached value rather than the real-time system brightness.
- `FijkLog.setLevel()` native MethodChannel call is a no-op; only the Dart-side log level setting is effective.
- `FijkVolumeWatcher` and `FijkVolume.addListener()` listener infrastructure works, but OHOS does not generate real system volume change events.

## Common Issues

**1. asset:/// resources fail to play**<br/>
Ensure asset files are correctly declared in the `assets` section of `pubspec.yaml` with the path format `asset:///assets/xxx.mp4`. OHOS automatically copies assets from rawfile to the sandbox directory during plugin initialization.

**2. Video does not display after full screen switch**<br/>
OHOS uses Texture Surface rendering mode. After a full screen switch, FijkView will re-call `setupSurface()` to ensure the textureId is correctly bound.

**3. System volume control does not work**<br/>
On OHOS, system volume write operations (mute/set/up/down) are only available for system-level applications. Use `FijkPlayer.setVolume()` to control the player's audio track volume instead.

## License

This project is based on [MIT](https://gitcode.com/CPF-Flutter/fijkplayer/blob/v0.11.0_ohos_3.7.12/LICENSE). Please feel free to enjoy and participate in open source.
