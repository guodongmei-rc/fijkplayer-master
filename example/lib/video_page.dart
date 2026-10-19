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

  _VideoScreenState();

  @override
  void initState() {
    super.initState();
    player.setOption(FijkOption.hostCategory, "enable-snapshot", 1);

    player.setOption(FijkOption.playerCategory, 'previewMode', 1);

    player.setOption(FijkOption.playerCategory, 'infbuf', 1);
    player.setOption(FijkOption.playerCategory, 'nobuffer', 'fflags');
    player.setOption(FijkOption.formatCategory, 'probesize', 1024);
    player.setOption(FijkOption.playerCategory, 'framedrop', 1);

    // RTSP 预览走软解：ohcodec 硬解在 find_stream_info=0 时拿不到宽高会直接打开失败，
    // 且 previewMode 的低延迟逻辑只对软解帧生效。本地/点播文件仍用硬解。
    if (!widget.url.startsWith("rtsp://")) {
      player.setOption(FijkOption.playerCategory, "mediacodec-all-videos", 1);
    }
    startPlay();
  }

  void startPlay() async {
    await player.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    await player.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    await player.setDataSource(widget.url, autoPlay: true).catchError((e) {
      print("setDataSource error: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "Video"),
      body: Container(
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
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}
