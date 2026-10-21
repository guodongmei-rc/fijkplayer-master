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

import 'dart:async';
import 'dart:collection';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FijkPlayerTester {
  final int? id;
  final MethodChannel playerEvent;
  final MethodChannel playerMethod;

  FijkPlayerTester({this.id})
      : playerEvent = MethodChannel("befovy.com/fijkplayer/event/$id"),
        playerMethod = MethodChannel("befovy.com/fijkplayer/$id") {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playerEvent, this.eventHandler);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playerMethod, this.playerHandler);
  }

  MethodCodec get codec {
    return playerEvent.codec;
  }

  Future<dynamic>? eventHandler(MethodCall call) {
    switch (call.method) {
      case 'listen':
      case 'cancel':
        return null;
      default:
        return Future.error("event Method invalid call name ${call.method}");
    }
  }

  Future<dynamic> playerHandler(MethodCall call) async {
    switch (call.method) {
      case 'setupSurface':
        return 1;
      case 'setDataSource':
        await sendEvent(<String, dynamic>{'event': 'prepared'});
        await sendEvent(
            <String, dynamic>{'event': 'state_change', 'new': 1, 'old': 0});
        return null;
      case 'prepareAsync':
        await sendEvent(
            <String, dynamic>{'event': 'state_change', 'new': 2, 'old': 1});
        Future.delayed(Duration(milliseconds: 100), () {
          sendEvent(
              <String, dynamic>{'event': 'state_change', 'new': 3, 'old': 2});
        });
        return null;
      case 'start':
        return null;
      case 'stop':
        return null;
      case 'setLoop':
        return null;
      case 'setSpeed':
        return null;
      case 'getDuration':
        return 12345;
      case 'getBitRate':
        return 8000000;
      case 'getMediaInfo':
        return <String, dynamic>{
          'videoDecoder': 'h264, avcodec',
          'audioDecoder': 'aac, avcodec',
          'meta':
              'key:width,value:1920;key:height,value:1080;key:tbr_num,value:60;key:tbr_den,value:1;key:sample_rate,value:48000;',
        };
      default:
        return Future.error("invalid call name ${call.method}");
    }
  }

  void release() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playerEvent, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playerMethod, null);
  }

  Future<void> sendEvent(dynamic event) {
    return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage("befovy.com/fijkplayer/event/$id",
            codec.encodeSuccessEnvelope(event), (ByteData? data) {});
  }
}

/// how to mock EventChannel from native side
/// https://github.com/flutter/flutter/issues/38954
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel pluginChannel = MethodChannel('befovy.com/fijk');

  Map<int, FijkPlayerTester> playerTesters = HashMap();

  int playerIncId = 0;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pluginChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'createPlayer':
          playerIncId = playerIncId + 1;
          FijkPlayerTester tester = FijkPlayerTester(id: playerIncId);
          playerTesters[playerIncId] = tester;
          return Future.value(playerIncId);
        case 'releasePlayer':
          Map args = methodCall.arguments as Map;
          int? pid = args["pid"];
          expect(pid, isNotNull);
          FijkPlayerTester? tester = playerTesters.remove(pid);
          tester?.release();
          return null;
        case 'logLevel':
          return null;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pluginChannel, null);
  });

  group("test FijkPlayer State", () {
    test("Fijkplayer state", () async {
      FijkPlayer player = FijkPlayer();
      await player.setupSurface();
      expect(player.state, FijkState.idle);
      expect(player.value.prepared, false);
      expect(player.value.completed, false);
      await player.setDataSource("assets://butterfly.mp4");
      expect(player.state, FijkState.initialized);

      Completer<void> prepared = Completer();
      player.addListener(() {
        FijkValue value = player.value;
        if (value.state == FijkState.prepared) {
          prepared.complete();
        }
      });

      await player.prepareAsync();
      expect(player.state, FijkState.asyncPreparing);
      await prepared.future;
      expect(player.state, FijkState.prepared);

      expect(() async {
        await player.setLoop(-1);
      }, throwsArgumentError);

      expect(() async {
        await player.setLoop(-1);
      }, throwsArgumentError);

      await player.setLoop(1);

      await player.release();

      expect(player.state, FijkState.end);
    });
  });

  group("test FijkPlayer api", () {
    test("create, release", () async {
      FijkPlayer player = FijkPlayer();
      expect(player, isNotNull);
      player.release();
    });

    test("id", () async {
      FijkPlayer player = FijkPlayer();
      expect(player, isNotNull);
      int id = await player.id;
      expect(id, isNotNull);

      int nid = await player.id;
      expect(id, nid);
      nid = await player.id;
      expect(id, nid);
      nid = await player.id;
      expect(id, nid);
      nid = await player.id;
      expect(id, nid);
      player.release();
    });

    test("read only value", () async {
      FijkPlayer player = FijkPlayer();
      bool changed = false;
      player.addListener(() {
        changed = true;
      });
      FijkValue value = player.value;
      expect(player.value.prepared, false);
      value = value.copyWith(prepared: true);
      expect(player.value.prepared, false);
      expect(changed, false);
      await player.release();
    });

    test("setupSurface", () async {
      FijkPlayer player = FijkPlayer();
      int? tid = await player.setupSurface();
      expect(tid != null && tid > 0, true);
      await player.release();
    });

    test("setDataSource", () async {
      FijkPlayer player = FijkPlayer();
      expect(() async {
        await player.setDataSource("");
      }, throwsArgumentError);

      await player.setDataSource("asset://butterfly.mp4");
      expect(player.state, FijkState.initialized);
      await player.setDataSource("asset://butterfly.mp4");
      expect(player.state, FijkState.initialized);

      await player.prepareAsync();

      expect(() async {
        await player.setDataSource("asset://butterfly.mp4");
      }, throwsStateError);

      await player.release();
    });

    test("setLoop", () async {
      FijkPlayer player = FijkPlayer();
      await player.setLoop(1);
      await player.setLoop(0);
      await player.setLoop(2);
      expect(() async {
        await player.setLoop(-1);
      }, throwsArgumentError);
      expect(() async {
        await player.setLoop(-1);
      }, throwsArgumentError);
      await player.release();
    });

    test("setSpeed", () async {
      FijkPlayer player = FijkPlayer();
      expect(() async {
        await player.setSpeed(-1);
      }, throwsArgumentError);
      expect(() async {
        await player.setSpeed(0);
      }, throwsArgumentError);
      expect(() async {
        await player.setSpeed(-1);
      }, throwsArgumentError);
      await player.setSpeed(1.5);
      await player.release();
    });

    test("isPlayable", () async {
      FijkPlayer player = FijkPlayer();
      expect(player.isPlayable(), false);
      await player.setupSurface();
      expect(player.isPlayable(), false);

      Completer<void> prepared = Completer();
      player.addListener(() {
        FijkValue value = player.value;
        if (value.state == FijkState.prepared) {
          prepared.complete();
        }
      });

      await player.setDataSource("asset://butterfly.mp4");
      expect(player.isPlayable(), false);
      expect(player.state, FijkState.initialized);

      await player.prepareAsync();
      expect(player.isPlayable(), false);

      await prepared.future;
      expect(player.isPlayable(), true);

      await player.start();
      expect(player.isPlayable(), true);

      await player.release();
    });

    test("allInstance", () async {
      FijkPlayer player1 = FijkPlayer();
      FijkPlayer player2 = FijkPlayer();

      expect(FijkPlayer.all.length, 0);

      expect(player1, isNotNull);
      expect(player2, isNotNull);
      int id1 = await player1.id;
      expect(id1, player1.idSync);
      int id2 = await player2.id;
      expect(id2, player2.idSync);

      expect(id1 != id2, true);
      expect(FijkPlayer.all.length, 2);

      await player1.release();
      expect(FijkPlayer.all.length, 1);
      await player2.release();
      expect(FijkPlayer.all.length, 0);
    });

    test("seekTo", () async {
      FijkPlayer player = FijkPlayer();

      expect(() async {
        await player.seekTo(-1);
      }, throwsArgumentError);

      expect(() async {
        await player.seekTo(10);
      }, throwsStateError);

      bool argError = false;
      await player.seekTo(-1).catchError((e) {
        argError = true;
      }, test: (e) {
        return e is ArgumentError;
      });

      expect(argError, true);
      bool stateError = false;
      await player.seekTo(10).catchError((e) {
        stateError = true;
      }, test: (e) {
        return e is StateError;
      });
      expect(stateError, true);
    });

    test("start", () async {
      FijkPlayer player = FijkPlayer();

      expect(() async {
        await player.start();
      }, throwsStateError);

      bool stateError = false;
      await player.start().catchError((e) {
        stateError = true;
      }, test: (e) {
        return e is StateError;
      });
      expect(stateError, true);
    });
  });

  group("test FijkPlayer media info api", () {
    Future<FijkPlayer> preparedPlayer() async {
      FijkPlayer player = FijkPlayer();
      await player.setupSurface();
      await player.setDataSource("assets://butterfly.mp4");
      Completer<void> prepared = Completer();
      player.addListener(() {
        if (player.value.state == FijkState.prepared && !prepared.isCompleted) {
          prepared.complete();
        }
      });
      await player.prepareAsync();
      await prepared.future;
      return player;
    }

    test("getDuration, getBitRate, getMediaInfo before prepared", () async {
      FijkPlayer player = FijkPlayer();
      await player.setupSurface();
      expect(await player.getDuration(), 0);
      expect(await player.getBitRate(), 0);
      expect(await player.getMediaInfo(), isNull);
      await player.release();
    });

    test("getDuration after prepared", () async {
      FijkPlayer player = await preparedPlayer();
      expect(await player.getDuration(), 12345);
      await player.release();
    });

    test("getBitRate after prepared", () async {
      FijkPlayer player = await preparedPlayer();
      expect(await player.getBitRate(), 8000000);
      await player.release();
    });

    test("getMediaInfo after prepared", () async {
      FijkPlayer player = await preparedPlayer();
      FijkMediaInfo? info = await player.getMediaInfo();
      expect(info, isNotNull);
      expect(info!.videoDecoder, "h264, avcodec");
      expect(info.width, 1920);
      expect(info.height, 1080);
      expect(info.fps, 60);
      expect(info.hasAudio, isTrue);
      await player.release();
    });

    test("missing native implementation returns defaults", () async {
      FijkPlayer player = await preparedPlayer();
      int id = await player.id;
      // Drop the mock handlers so invokeMethod raises MissingPluginException,
      // which is what iOS / Android do until they implement these calls.
      playerTesters[id]?.release();
      expect(await player.getDuration(), 0);
      expect(await player.getBitRate(), 0);
      expect(await player.getMediaInfo(), isNull);
    });
  });
}
