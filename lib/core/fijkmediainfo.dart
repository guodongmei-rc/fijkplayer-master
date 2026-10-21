//MIT License
//
//Copyright (c) [2019] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//

part of fijkplayer;

/// Media information reported by the native player after prepared.
///
/// Currently only the OpenHarmony plugin implements `getMediaInfo`.
/// [meta] is the raw ijkplayer stream meta parsed into a flat map.
///
/// Notes on the OpenHarmony meta map:
/// * all streams are flattened into one map, so shared keys such as `type`,
///   `codec_name` and `bitrate` hold the value of whichever stream came last;
/// * `fps_den` is not exported, use `tbr_num` / `tbr_den` (both taken from
///   `avg_frame_rate`) which is what [fps] does;
/// * video-only keys (`width`, `height`, `tbr_*`, `sar_*`) and audio-only
///   keys (`sample_rate`, `channel_layout`) never collide.
class FijkMediaInfo {
  /// "codec, decoder" string, e.g. "h264, avcodec".
  final String videoDecoder;

  /// "codec, decoder" string, e.g. "aac, avcodec".
  final String audioDecoder;

  /// Flat key/value meta map, see class doc.
  final Map<String, String> meta;

  const FijkMediaInfo({
    this.videoDecoder = "",
    this.audioDecoder = "",
    this.meta = const {},
  });

  factory FijkMediaInfo.fromMap(Map<dynamic, dynamic> map) {
    String str(dynamic v) => v is String ? v : "";
    return FijkMediaInfo(
      videoDecoder: str(map["videoDecoder"]),
      audioDecoder: str(map["audioDecoder"]),
      meta: parseMeta(str(map["meta"])),
    );
  }

  /// Parse the OpenHarmony napi meta string.
  ///
  /// Format: `key:<k>,value:<v>;key:<k>,value:<v>;...`
  /// Values may contain commas, so each segment is split on the first
  /// `,value:` marker instead of on `,`.
  static Map<String, String> parseMeta(String raw) {
    const keyPrefix = "key:";
    const valueMarker = ",value:";
    final result = <String, String>{};
    for (final segment in raw.split(";")) {
      if (!segment.startsWith(keyPrefix)) continue;
      final idx = segment.indexOf(valueMarker, keyPrefix.length);
      if (idx < 0) continue;
      final key = segment.substring(keyPrefix.length, idx);
      final value = segment.substring(idx + valueMarker.length);
      if (key.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }

  int _metaInt(String key) => int.tryParse(meta[key] ?? "") ?? 0;

  /// Video width in pixels, 0 if unknown.
  int get width => _metaInt("width");

  /// Video height in pixels, 0 if unknown.
  int get height => _metaInt("height");

  /// Nominal frame rate from `avg_frame_rate`, 0 if unknown.
  double get fps {
    final num = _metaInt("tbr_num");
    final den = _metaInt("tbr_den");
    if (num <= 0 || den <= 0) return 0;
    return num / den;
  }

  /// Whether the media has an audio stream.
  bool get hasAudio =>
      meta.containsKey("sample_rate") || meta.containsKey("channel_layout");

  @override
  String toString() =>
      "FijkMediaInfo(video:$videoDecoder, audio:$audioDecoder, ${width}x$height, fps:$fps, hasAudio:$hasAudio)";
}
