import 'package:hive_flutter/adapters.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ButtonColorStyle {
  static ButtonStyle withColor(Color c) {
    return ElevatedButton.styleFrom(backgroundColor: c);
  }
}

class TTS {
  final player = AudioPlayer();
  bool playing = false;

  Future<void> playAssistFor(String page) async {
    if (playing) return;

    playing = true;
    await player.setAudioSource(AudioSource.asset("assets/audio/$page.mp3"));
    await player.play();

    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playing = false;
      }
    });
  }

  Future<void> stop() {
    return player.stop();
  }

  Future<bool> isViewed(String page) async {
    var box = Hive.box('myBox');
    bool? name = box.get(page); // 'Bobleo'

    if (name != null) {
      return name;
    } else {
      return false;
    }
  }

  void playIfNotViewedAlready(String page) async {
    var viewed = await isViewed(page);
    var box = Hive.box('myBox');
    print(viewed);

    if (!viewed) {
      playAssistFor(page);
      box.put(page, true);
    }
  }

  Widget widget(String page, {required BuildContext context}) {
    final size = MediaQuery.of(context).size;
    final leftOffset = size.width * 0.05;
    final bottomOffset = size.height * 0.05;

    return Positioned(
      bottom: bottomOffset, // x
      left: leftOffset, // y
      child: IconButton(
        onPressed: () {
          playAssistFor(page);
        },
        icon: Icon(Icons.help),
        iconSize: 70,
      ),
    );
  }
}
