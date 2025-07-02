import 'dart:async';
import 'dart:convert';
import 'package:KidGo2/accessibility.dart';

import "./widgets/message_card.dart";
import 'package:KidGo2/recording.dart';
import 'package:flutter/material.dart';
import "state.dart";
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

const apiUrl =
    "https://o0v9kizy1b.execute-api.ap-south-1.amazonaws.com/testing1";

class ChatPage extends StatefulWidget {
  final String username;
  late final MessageLoader messageLoader = MessageLoader(username);

  ChatPage({required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  var messages = <Message>[];
  final rec = Recorder();
  int lastRead = 0;
  bool recording = false;
  late final String group;
  late Timer _timer2;
  late Timer timer;

  @override
  void dispose() {
    var appState = context.watch<MyAppState>();
    appState.tts.stop();
    _timer2.cancel();
    try {
      timer.cancel();
    } catch (e) {
      print("error $e");
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<MyAppState>(context, listen: false);
    group = generateGroupName(widget.username, appState.user);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.messageLoader.loadAllMessages(group);
      appState.tts.playIfNotViewedAlready("chat_page");

      setState(() {
        messages = widget.messageLoader.messages;
        print(lastRead);
      });
    });

    // Auto-refresh every 30 seconds
    _timer2 = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await widget.messageLoader.loadAllMessages(group);
      setState(() {
        messages = widget.messageLoader.messages;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.chat),
                SizedBox(width: 10),
                Text("Your chat with ${widget.username}"),
              ],
            ),
          ),
          body: Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: messages
                          .map(
                            (msg) => Center(
                              child: MessageCard(
                                from: msg.from,
                                downloadUrl: msg.url,
                                timestamp: msg.timestamp,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          child: recording ? Text("Recording...") : null,
                        ),
                        ElevatedButton.icon(
                          style: ButtonColorStyle.withColor(Colors.lightBlue),
                          onPressed: !recording
                              ? () async {
                                  await rec.startRecording();
                                  setState(() {
                                    recording = true;
                                  });
                                }
                              : () {
                                  rec.stopRecording().then((path) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Message sent")),
                                    );
                                    endRecordingAndUpload(path!, rec);
                                    setState(() {
                                      recording = false;
                                    });
                                  });
                                },
                          label: Text(
                            recording
                                ? "Stop recording and send"
                                : "Start recording your message",
                          ),
                          icon: Icon(
                            !recording ? Icons.fiber_manual_record : Icons.send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        appState.tts.widget("chat_page", context: context),
      ],
    );
  }

  String generateGroupName(String one, String two) {
    List<String> names = [one, two];
    names.sort((a, b) => b.compareTo(a)); // Reverse alphabetical sort
    String groupName = '${names[0]}~${names[1]}';
    return groupName;
  }

  void endRecordingAndUpload(String path, Recorder rec) async {
    var appState = Provider.of<MyAppState>(context, listen: false);
    var info = await rec.send(appState.user, group);

    var key = info.split("#")[1];
    var uploadUrl = info.split("#")[0];
    uploadUrl = widget.messageLoader.processPresignUrl(uploadUrl);

    // Read the audio file as bytes
    var fileBytes = await File(path).readAsBytes();

    // Upload to S3 using PUT
    var response = await http.put(
      Uri.parse(uploadUrl),
      body: fileBytes,
      headers: {
        'Content-Type': 'audio/mpeg', // or 'audio/mp4', depending on encoding
      },
    );

    if (response.statusCode == 200) {
      print("Upload successful");

      // continue to load messages until it appears
      timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        await widget.messageLoader.loadAllMessages(group);

        setState(() {
          print("refreshing");
          messages = widget.messageLoader.messages;
        });

        if (messages.any((msg) {
          return msg.key == key;
        })) {
          timer.cancel();
        }
      });
    } else {
      // confess it hasn't happened
      http.post(
        Uri.parse("$apiUrl/msgs/confess/confess"),
        body: jsonEncode({'key': key}),
      );

      print("Upload failed: ${response.statusCode} - ${response.body}");
    }
  }
}
