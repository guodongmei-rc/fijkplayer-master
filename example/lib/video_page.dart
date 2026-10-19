import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';
// import 'custom_ui.dart';

class VideoScreen extends StatefulWidget {
  final String url;

  VideoScreen({required this.url});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final FijkPlayer player = FijkPlayer();

  // 重拉次数，显示在按钮上，方便和 ijk_lat 日志对时间
  int _restartCount = 0;
  bool _restarting = false;

  _VideoScreenState();

  @override
  void initState() {
    super.initState();
    applyOptions();
    startPlay();
  }

  /// Dart 侧的 option。注意：这些 option 是直接透传给 native 播放器的，
  /// reset() 会销毁 native 播放器，之后只有 ets 侧 setUpPlayer() 里写死的那组会被重设，
  /// 这里设的（尤其是 previewMode=1）不会自动恢复，重拉前必须再调一次。
  Future<void> applyOptions() async {
    await player.setOption(FijkOption.hostCategory, "enable-snapshot", 1);

    await player.setOption(FijkOption.playerCategory, 'previewMode', 1);

    await player.setOption(FijkOption.playerCategory, 'infbuf', 1);
    await player.setOption(FijkOption.playerCategory, 'nobuffer', 'fflags');
    await player.setOption(FijkOption.formatCategory, 'probesize', 1024);
    await player.setOption(FijkOption.playerCategory, 'framedrop', 1);

    // RTSP 预览走软解：ohcodec 硬解在 find_stream_info=0 时拿不到宽高会直接打开失败，
    // 且 previewMode 的低延迟逻辑只对软解帧生效。本地/点播文件仍用硬解。
    if (!widget.url.startsWith("rtsp://")) {
      await player.setOption(
          FijkOption.playerCategory, "mediacodec-all-videos", 1);
    }
  }

  void startPlay() async {
    await player.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    await player.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    await player.setDataSource(widget.url, autoPlay: true).catchError((e) {
      print("setDataSource error: $e");
    });
  }

  /// 停流后重新拉流，模拟切帧率后的重连。
  /// [reapplyOptions] 为 true 时在 reset 之后把 Dart 侧 option 再设一遍；
  /// 为 false 时直接 setDataSource，用来对照“option 丢失”这一种情况。
  Future<void> restart({required bool reapplyOptions}) async {
    if (_restarting) return;
    setState(() => _restarting = true);
    final tag = reapplyOptions ? "with-options" : "no-options";
    print("ijk_restart begin $tag #${_restartCount + 1}");
    try {
      await player.reset();
      if (reapplyOptions) {
        await applyOptions();
      }
      await player.setDataSource(widget.url, autoPlay: true);
      print("ijk_restart done $tag #${_restartCount + 1}");
    } catch (e) {
      print("ijk_restart error $tag: $e");
    } finally {
      if (mounted) {
        setState(() {
          _restartCount++;
          _restarting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Video"),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FijkView(
                player: player,
                panelBuilder: fijkPanel2Builder(snapShot: true),
                fsFit: FijkFit.fill,
                // panelBuilder: simplestUI,
                // panelBuilder: (FijkPlayer player, BuildContext context,
                //     Size viewSize, Rect texturePos) {
                //   return CustomFijkPanel(
                //       player: player,
                //       buildContext: context,
                //       viewSize: viewSize,
                //       texturePos: texturePos);
                // },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _restarting ? null : () => restart(reapplyOptions: true),
                  child: Text("重拉(带option) #$_restartCount"),
                ),
                ElevatedButton(
                  onPressed: _restarting
                      ? null
                      : () => restart(reapplyOptions: false),
                  child: Text("重拉(不带option)"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
