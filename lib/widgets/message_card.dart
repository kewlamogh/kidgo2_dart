import 'package:KidGo2/accessibility.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import "../state.dart";
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class MessageCard extends StatefulWidget {
  final String from;
  final String downloadUrl;
  final int timestamp;

  const MessageCard({
    super.key,
    required this.from,
    required this.downloadUrl,
    required this.timestamp,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  bool isPlaying = false;
  bool loading = false;
  late AudioPlayer _player;
  late StreamSubscription<PlayerState> _playerSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return; // ✅ only update if still in the tree
      setState(() {
        print(state.processingState);

        isPlaying = state.playing;
        if (state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering) {
          loading = true;
        } else {
          if (loading) {
            loading = false;
          }
        }

        if (state.processingState == ProcessingState.completed) {
          isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    var appState = context.watch<MyAppState>();
    appState.tts.stop();
    _playerSubscription.cancel(); // ✅ stop listening
    _player.dispose(); // optional but good cleanup
    super.dispose();
  }

  Future<void> playMessage() async {
    try {
      final response = await http.get(Uri.parse(widget.downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp3'; // unique filename
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await _player.setFilePath(filePath);
      await _player.play();
      // isPlaying = false;
    } catch (e) {
      print('Error in playMessage: $e');
    }
  }

  String formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedDate = DateFormat('MMM d, y · h:mm a').format(date);
    final relativeTime = timeago.format(date);

    return '$formattedDate ($relativeTime)';
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final name = widget.from == appState.user ? "You" : widget.from;
    var label = "";

    if (isPlaying) {
      label = "Playing...";
    } else if (loading) {
      label = "Loading...";
    } else if (!isPlaying) {
      label = "Play";
    }

    final formatted = formatTimestamp(widget.timestamp);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("$name sent a message"),
              const SizedBox(height: 12),
              Text(formatted),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (isPlaying || loading) ? null : playMessage,
                label: Text(label),
                icon: Icon(Icons.play_arrow),
                style: ButtonColorStyle.withColor(Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
