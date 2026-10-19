import {
  EventChannel,
  EventSink,
  FlutterInjector,
  FlutterManager,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler
} from '@ohos/flutter_ohos';
import { IjkMediaPlayer, MessageType, OnMessageCallback } from '@ohos/ijkplayer';
import { HashMap, uri } from '@kit.ArkTS';
import { MediaInfoType, OptionsCategory, PlayerState } from '../common/Constants';
import HostOption from '../common/HostOption';
import { getFilePathByAssetsPath } from '../common/AssetsCopyUtil';

const TAG = "FIjkPlayerTag";
const DEFAULT_WIDTH = 500;
const DEFAULT_HEIGHT = 500;

export class FIjkPlayer implements MethodCallHandler, StreamHandler, OnMessageCallback {
  private channel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private binding: FlutterPluginBinding;
  private id: number;
  private textureId?: number;
  private surfaceId?: number;
  private player?: IjkMediaPlayer;
  private currentPlayerState: number = PlayerState.unkown;
  private mWidth: number = 0;
  private mHeight: number = 0;
  private mRotate: number = 0;
  private hasReset: boolean = false;
  private mHostOption: HostOption = new HostOption();

  constructor(id: number, binding: FlutterPluginBinding) {
    this.id = id;
    this.binding = binding;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "befovy.com/fijkplayer/" + this.id);
    this.channel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), "befovy.com/fijkplayer/event/" + this.id);
    this.eventChannel.setStreamHandler(this);
    this.initPlayer();
  }

  onListen(args: ESObject, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: ESObject): void {
    this.eventSink?.endOfStream();
  }

  initPlayer() {
    this.player = new IjkMediaPlayer();
    //surface模式下，其它方法都依赖surfaceId，需要先设置surfaceId
    this.setSurfaceId();
    this.player.setDebug(true);
    this.setUpPlayer();
    this.player.setOnMessageCallback(this);
    this.player.setMessageListener();
  }

  setUpPlayer() {
    if (!this.player) {
      return;
    }
    this.player.native_setup();
    const PLAYER = OptionsCategory.OPT_CATEGORY_PLAYER.toString();
    const FORMAT = OptionsCategory.OPT_CATEGORY_FORMAT.toString();
    const CODEC = OptionsCategory.OPT_CATEGORY_CODEC.toString();

    this.player.setOption(PLAYER, "enable-position-notify", '1');
    // fijkplayer 由 Dart 层控制起播时机，保持 0，不随 iOS 配置改为 1
    this.player.setOption(PLAYER, "start-on-prepared", '0');

    // ---------- 低延迟预览配置（与 iOS FijkPlayer.m 对齐） ----------
    // 解码：关闭硬解走软解（previewMode 的帧间隔改动只对软解帧生效）
    // this.player.setOption(PLAYER, "mediacodec-hevc", '0');
    // this.player.setOption(PLAYER, "mediacodec", '0');
    // this.player.setOption(PLAYER, "mediacodec-auto-rotate", '1');
    // 低延迟第 2 步：fast 开 AV_CODEC_FLAG2_FAST 非规范加速，补偿单线程解码的吞吐损失，画质基本无感
    this.player.setOption(PLAYER, "fast", '1');
    // this.player.setOption(PLAYER, "low_pic", '0');
    // 低延迟第 2 步：解码器去延迟。
    // threads=1 关掉帧级多线程（默认 auto 要攒 线程数-1 帧才出图，8 核约 230ms）；
    // flags=+low_delay 不为重排序囤帧，省 1~2 帧；
    // skip_loop_filter=48 跳过去块滤波，解码快 15%~25%，代价是轻微块状感。
    // 若单核跟不上（画面周期卡顿、延迟缓慢爬升），改为 threads=auto + thread_type=slice，再不行退到 threads=2。
    this.player.setOption(CODEC, "threads", '1');
    this.player.setOption(CODEC, "flags", '+low_delay');
    this.player.setOption(CODEC, "skip_loop_filter", '48');
    // 探测
    this.player.setOption(FORMAT, "analyzeduration", '3000000');
    this.player.setOption(FORMAT, "probesize", '1048576');
    this.player.setOption(PLAYER, "find_stream_info", '0');
    // 缓冲
    this.player.setOption(FORMAT, "max_delay", '0'); // 禁用缓冲延迟
    this.player.setOption(FORMAT, "fflags", 'nobuffer');
    this.player.setOption(FORMAT, "flush_packets", '1');
    this.player.setOption(PLAYER, "packet-buffering", '0');
    this.player.setOption(PLAYER, "max-buffer-size", '2097152');
    this.player.setOption(PLAYER, "infbuf", '1');
    this.player.setOption(PLAYER, "min-frames", '30');
    this.player.setOption(PLAYER, "framedrop", '60');
    this.player.setOption(PLAYER, "video-pictq-size", '9');
    // 预览模式
    // 低延迟第 1 步：previewMode=1 后 video_refresh 以 10ms 节拍尽快排空图像队列、不做时钟修正，
    // 把 pictq 积压（最多 9 帧，30fps 下约 300ms）压掉。预览画面节拍跟随到达节拍。
    // 必须放在这里而不是 Dart 侧：reset() 会销毁 native 播放器，只有这里的 option 会在重拉时重设，
    // Dart 侧 setOption 不会自动恢复。实测 reset 后 previewMode 丢失会让 pictq 常满、积压永不排空。
    this.player.setOption(PLAYER, "previewMode", '1');
    // 预览追帧：Wi-Fi 断流后突发补包会在视频包队列留下永久积压（软解只比 60fps 多几帧，排不动）。
    // 包数超过 20（60fps 约 330ms）就丢到队列里最后一个关键帧，相机 GOP 1s，画面最多前跳 1s，不卡顿。
    this.player.setOption(PLAYER, "preview_max_backlog", '20');
    this.player.setOption(PLAYER, "preview_drop_firstframe", '30'); // 丢首次开屏帧
    this.player.setOption(PLAYER, "an", '1'); // 不解码音频
    this.player.setOption(PLAYER, "overlay-format", '844318047'); // SDL_FCC__GLES2 = FOURCC('_','E','S','2')，OHOS 的 FFmpeg 不解析 "fcc-" 字符串，必须传数值
    // 网络
    // 对照验证：去掉此行后已确认能出流（默认先 UDP、失败再回落 TCP）。
    // 现单独加回，若再次出现 prepare 阻塞约 60 秒后 FijkException(-10000, 0)，即可确定是此行导致。
    this.player.setOption(FORMAT, "rtsp_transport", 'tcp');
    this.player.setOption(FORMAT, "dns_cache_clear", '1');
    // 以下选项来自 iOS 定制版 ijkplayer，本 OpenHarmony 版 ijkplayer / FFmpeg 中不存在，设置了也不会生效，保留注释以便对照：
    // this.player.setOption(PLAYER, "video-pictq-size-min", '3');
    // this.player.setOption(PLAYER, "video-pictq-size-max", '6');
    // this.player.setOption(PLAYER, "max_cached_duration", '10');
    // this.player.setOption(PLAYER, "keyframe_start", '1');
    // this.player.setOption(PLAYER, "reconnect", '5');
    // this.player.setOption(FORMAT, "analyzemaxduration", '100');
    // this.player.setOption(FORMAT, "http-detect-range-support", '0');
  }

  /**
   * 纹理导出模式下，需更新bufferSize配置
   * @param width
   * @param height
   */
  updateSurfaceWH(width: number, height: number) {
    this.binding.getTextureRegistry().setTextureBufferSize(this.textureId, width, height);
  }

  setSurfaceId() {
    this.textureId = this.binding.getTextureRegistry().getTextureId();
    this.surfaceId = this.binding.getTextureRegistry().registerTexture(this.textureId).getSurfaceId();
    this.player?.setSurfaceId(this.surfaceId);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const methodName = call.method;
    Log.d(TAG, 'onMethodCall=' + methodName);
    switch (methodName) {
      case "setupSurface":
        result.success(this.textureId);
        break;
      case "setOption":
        // reset() 已销毁 native 播放器，此时 Dart 侧的 setOption 到 native 层会因 mp 为空被静默丢弃。
        // 和 setDataSource 一样先重建，保证顺序仍是 ets 默认 option 在前、Dart 覆盖在后。
        if (this.hasReset) {
          this.setUpPlayer();
          this.hasReset = false;
        }
        const category: number = call.argument('cat');
        const key: string = call.argument("key");
        if (call.hasArgument('long')) {
          const value: number = call.argument('long');
          this.setOption(category, key, value);
        } else if (call.hasArgument('str')) {
          const value: string = call.argument('str');
          this.setOption(category, key, value);
        }
        result.success(null);
        break;
      case "applyOptions":
        if (this.hasReset) {
          this.setUpPlayer();
          this.hasReset = false;
        }
        if (call.args instanceof Map) {
          const map: Map<ESObject, ESObject> = call.args as Map<ESObject, ESObject>;
          map.forEach((key: ESObject, value: ESObject) => {
            if (typeof key === 'number' && value instanceof Map) {
              const category = key as number;
              const valueMap: Map<ESObject, ESObject> = value as Map<ESObject, ESObject>;
              valueMap.forEach((key: ESObject, value: ESObject) => {
                if (typeof key === 'string') {
                  const keyStr = key as string;
                  this.setOption(category, keyStr, value);
                }
              })
            }
          })
        }
        result.success(null);
        break;
      case "setDataSource":
        if(this.hasReset){
            this.setUpPlayer();
            this.hasReset = false;
        }
        const url: string = call.argument('url');
        const uriObj = new uri.URI(url);
        if (uriObj.scheme === 'asset') {
          const filePath = uriObj.path;
          this.player?.setDataSource(getFilePathByAssetsPath(this.binding.getApplicationContext(),filePath));
        } else {
          this.player?.setDataSource(url);
        }
        this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.initialized, PlayerState.unkown, null);
        result.success(null);
        break;
      case "prepareAsync":
        if (this.player) {
          this.player.prepareAsync();
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.asyncPreparing,
            this.currentPlayerState,
            null);
        }
        result.success(null);
        break;
      case "start":
        if (this.player) {
          this.player.start();
        }
        result.success(null);
        break;
      case "pause":
        if (this.player) {
          this.player.pause();
        }
        result.success(null);
        break;
      case "stop":
        if (this.player) {
          this.player.stop();
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.stopped, this.currentPlayerState,
            null);
        }
        result.success(null);
        break;
      case "reset":
        if (this.player) {
          this.player.reset();
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.idle, this.currentPlayerState, null);
          this.hasReset = true;
        }
        result.success(null);
        break;
      case "getCurrentPosition":
        const position: number | undefined = this.player?.getCurrentPosition();
        result.success(position ? position : 0);
        break;
      case "setVolume":
        const volume: number = call.argument('volume');
        const volumeStr = volume == undefined ? '1.0' : volume.toString();
        this.player?.setVolume(volumeStr, volumeStr);
        result.success(null);
        break;
      case "seekTo":
        const msec: number = call.argument('msec');
        if (this.currentPlayerState == PlayerState.completed) {
          this.handleEvent(MessageType.MEDIA_PLAYBACK_STATE_CHANGED, PlayerState.paused, this.currentPlayerState, null);
        }
        const msecStr = msec == undefined ? '0' : msec.toString();
        this.player?.seekTo(msecStr);
        result.success(null);
        break;
      case "setLoop":
        const loop: number = call.argument('loop');
        const loopLocal = loop == undefined ? 1 : loop;
        this.player?.setLoopCountNum(loopLocal);
        result.success(null);
        break;
      case "setSpeed":
        const speed: number = call.argument('speed');
        const speedLocal = speed == undefined ? 1 : speed;
        this.player?.setSpeed(speedLocal.toString());
        result.success(null);
        break;
      case "snapshot":
        result.notImplemented;
        break;

    }
  }

  onPlayerStateChangeLocal(newState: number, oldState: number) {

  }

  onMessage(what: number, arg1: number, arg2: number, obj: string) {
    this.handleEvent(what, arg1, arg2, obj);
  }

  handleEvent(what: number, arg1: number, arg2: number, extra: ESObject) {
    Log.d(TAG, 'handleEvent(),what' + what);
    const event: HashMap<string, ESObject> = new HashMap();
    switch (what) {
      case MessageType.MEDIA_PREPARED:
        event.set('event', 'prepared');
        event.set('duration', this.player?.getDuration());
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_PLAYBACK_STATE_CHANGED:
        this.currentPlayerState = arg1;
        Log.d(TAG, `state_change(),new=${arg1},old=${arg2}`);
        event.set("event", "state_change");
        event.set("new", arg1);
        event.set("old", arg2);
        this.onPlayerStateChangeLocal(arg1, arg2);
        this.eventSink?.success(event)
        break;
      case MessageType.MEDIA_INFO:
        switch (arg1) {
          case MediaInfoType.MEDIA_INFO_VIDEO_RENDERING_START:
          case MediaInfoType.MEDIA_INFO_AUDIO_RENDERING_START:
            event.set("event", "rendering_start");
            event.set("type", arg1 === MediaInfoType.MEDIA_INFO_VIDEO_RENDERING_START ? 'video' : 'audio');
            this.eventSink?.success(event)
            break;
          case MediaInfoType.MEDIA_INFO_BUFFERING_START:
          case MediaInfoType.MEDIA_INFO_BUFFERING_END:
            event.set("event", "freeze");
            event.set("value", arg1 == MediaInfoType.MEDIA_INFO_BUFFERING_START);
            this.eventSink?.success(event)
            break;
          case MediaInfoType.MEDIA_INFO_VIDEO_ROTATION_CHANGED:
            event.set("event", "rotate");
            event.set("degree", arg2);
            this.mRotate = arg2;
            this.eventSink?.success(event);
            if (this.mWidth > 0 && this.mWidth > 0) {
              this.handleEvent(MessageType.MEDIA_SET_VIDEO_SIZE, this.mWidth, this.mHeight, null);
            }
            break;
        }
        break;
      case MessageType.MEDIA_CURRENT_POSITION_UPDATE:
        event.set("event", "pos");
        event.set("pos", arg1);
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_BUFFERING_UPDATE:
        event.set("event", "buffering");
        event.set("head", arg1);
        event.set("percent", arg2);
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_SET_VIDEO_SIZE:
        event.set("event", "size_changed");
        if (this.mRotate == 0 || this.mRotate == 180) {
          event.set('width', arg1);
          event.set('height', arg2);
        } else {
          event.set('width', arg2);
          event.set('height', arg1);
        }
        this.eventSink?.success(event);
        this.mWidth = arg1;
        this.mHeight = arg2;
        this.updateSurfaceWH(this.mWidth, this.mHeight);
        break;
      case MessageType.MEDIA_SEEK_COMPLETE:
        event.set("event", "seek_complete");
        event.set("pos", arg1);
        event.set("err", arg2);
        this.eventSink?.success(event);
        break;
      case MessageType.MEDIA_ERROR:
        this.eventSink?.error(arg1.toString(), arg2.toString(), extra);
        break;
    }
  }

  setOption(category: number | undefined, key: string, value: ESObject) {
    if (typeof value === 'number') {
      if (category != undefined && category != 0) {
        this.player?.setOption(category.toString(), key, (value != undefined ? value : 0).toString());
        Log.d(TAG, `setOption1,category=${category},key=${key},value=${value}`);
      } else if (category != undefined) {
        // cat == 0, hostCategory
        this.mHostOption.addNumberOption(key, value);
      }
    } else if (typeof value === 'string') {
      if (category != undefined && category != 0) {
        this.player?.setOption(category.toString(), key, value != undefined ? value : '0');
        Log.d(TAG, `setOption2,category=${category},key=${key},value=${value}`);
      } else if (category != undefined) {
        // cat == 0, hostCategory
        this.mHostOption.addStrOption(key, value);
      } else {
        Log.d(TAG, "error arguments for setOptions");
      }
    }
  }

  getPlayId() {
    return this.id;
  }

  release() {
    Log.d(TAG, "releaseAsync()");
    if(this.textureId != undefined){
      this.binding.getTextureRegistry().unregisterTexture(this.textureId);
    }
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.eventChannel?.setStreamHandler(null);
    this.eventChannel = null;
    this.eventSink = null;
    this.player?.releaseAsync();
    this.player = undefined;
  }
}