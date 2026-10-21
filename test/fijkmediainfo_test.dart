import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FijkMediaInfo.parseMeta", () {
    test("splits key/value pairs on ';'", () {
      final meta = FijkMediaInfo.parseMeta(
          "key:width,value:1920;key:height,value:1080;key:tbr_num,value:60;key:tbr_den,value:1;");
      expect(meta, {
        "width": "1920",
        "height": "1080",
        "tbr_num": "60",
        "tbr_den": "1",
      });
    });

    test("keeps commas inside a value", () {
      final meta = FijkMediaInfo.parseMeta(
          "key:codec_long_name,value:H.264 / AVC, MPEG-4 part 10;key:width,value:1920;");
      expect(meta["codec_long_name"], "H.264 / AVC, MPEG-4 part 10");
      expect(meta["width"], "1920");
    });

    test("ignores malformed segments and empty input", () {
      expect(FijkMediaInfo.parseMeta(""), isEmpty);
      expect(FijkMediaInfo.parseMeta("garbage;key:width,value:1;;novalue"),
          {"width": "1"});
    });
  });

  group("FijkMediaInfo.fromMap", () {
    test("exposes decoders, size, fps and hasAudio", () {
      final info = FijkMediaInfo.fromMap({
        "videoDecoder": "h264, avcodec",
        "audioDecoder": "aac, avcodec",
        "meta":
            "key:width,value:1920;key:height,value:1080;key:tbr_num,value:60000;key:tbr_den,value:1001;key:sample_rate,value:48000;",
      });
      expect(info.videoDecoder, "h264, avcodec");
      expect(info.audioDecoder, "aac, avcodec");
      expect(info.width, 1920);
      expect(info.height, 1080);
      expect(info.fps, closeTo(59.94, 0.01));
      expect(info.hasAudio, isTrue);
    });

    test("fps is 0 when tbr_den is missing or zero", () {
      final noDen = FijkMediaInfo.fromMap({
        "meta": "key:tbr_num,value:60;",
      });
      expect(noDen.fps, 0);
      final zeroDen = FijkMediaInfo.fromMap({
        "meta": "key:tbr_num,value:60;key:tbr_den,value:0;",
      });
      expect(zeroDen.fps, 0);
    });

    test("hasAudio is false without audio keys", () {
      final info = FijkMediaInfo.fromMap({
        "meta": "key:width,value:1920;key:height,value:1080;",
      });
      expect(info.hasAudio, isFalse);
      expect(info.audioDecoder, "");
    });

    test("tolerates null and non-string values from the channel", () {
      final info = FijkMediaInfo.fromMap({
        "videoDecoder": null,
        "meta": null,
      });
      expect(info.videoDecoder, "");
      expect(info.meta, isEmpty);
      expect(info.width, 0);
      expect(info.fps, 0);
    });
  });
}
