import 'package:KidGo2/accessibility.dart';
import 'package:KidGo2/friends_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "state.dart";
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';

class AddFriendPage extends StatefulWidget {
  final FriendsManager manager;
  AddFriendPage(this.manager);

  @override
  AddFriendPageState createState() => AddFriendPageState();
}

class AddFriendPageState extends State<AddFriendPage> {
  String _status = 'Tap "begin friending" to start';
  IconData _icon = Icons.nfc;
  late final String username; // Replace with actual user ID
  bool writtenTag = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<MyAppState>();
      username = state.user;
      _writeNfcTag();
      writtenTag = true;
      state.tts.playIfNotViewedAlready("add_friend_page");
    });

    _startNfcSession();
  }

  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _icon = Icons.nearby_error;
        _status =
            'NFC is off. Try turning it on. If you can\'t, then you cannot friend from this device.';
      });
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || ndef.cachedMessage == null) {
            _icon = Icons.error;
            _status = 'Invalid tag.';
            return;
          }

          final payload = utf8.decode(
            ndef.cachedMessage!.records.first.payload,
          );
          final receivedId = payload.replaceFirst(
            '\u0000',
            '',
          ); // Remove null prefix
          setState(() {
            _icon = Icons.check_circle;
            _status = 'Friend added: $receivedId';
          });

          // Here you’d add `receivedId` to your friend list in DB
          print("Friend ID received: $receivedId");
          await widget.manager.addFriend(username, receivedId);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FriendsPage()),
          );
        } catch (e) {
          setState(() {
            _icon = Icons.error;
            _status = 'Failed to read tag: $e';
          });
        }
      },
    );
  }

  Future<void> _writeNfcTag() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _status = 'NFC not available';
        _icon = Icons.error_rounded;
      });
      return;
    }

    setState(() => _status = 'Ready to friend. Tap your friend\'s device.');

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          setState(() {
            _icon = Icons.error;
            _status = 'Tag is not writable.';
          });
          return;
        }

        final record = NdefRecord.createText(username);
        final message = NdefMessage([record]);

        try {
          await ndef.write(message);
          setState(() => _status = 'Tag written! You shared your ID.');
        } catch (e) {
          setState(() {
            _status = 'Failed to write: $e';
            _icon = Icons.error;
          });
        }

        await NfcManager.instance.stopSession();
      },
    );
  }

  @override
  void dispose() {
    var appState = Provider.of<MyAppState>(context, listen: false);
    appState.tts.stop();
    NfcManager.instance.stopSession();
    super.dispose();
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
                Icon(Icons.nfc),
                SizedBox(width: 10),
                Text("Friend via NFC"),
              ],
            ),
          ),
          body: Center(
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Icon(_icon),
                        SizedBox(height: 10),
                        Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddFriendPage(widget.manager),
                              ),
                            );
                          },
                          label: Text("Try again"),
                          icon: Icon(Icons.refresh),
                          style: ButtonColorStyle.withColor(Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        appState.tts.widget("add_friend_page", context: context),
      ],
    );
  }
}
