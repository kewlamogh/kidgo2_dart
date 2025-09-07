import 'package:KidGo2/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "../state.dart";

class FriendCard extends StatelessWidget {
  final String friend;
  FriendCard({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    // final th = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: GestureDetector(
        child: Card(
          color: Colors.lightBlue,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(friend, style: TextStyle(fontSize: 30)),
                  Text("Tap to talk to $friend • Hold to unfriend"),
                ],
              ),
            ),
          ),
        ),
        onTap: () {
          print("let's tallk frewn");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage(username: friend)),
          );
        },
        onLongPress: () {
          print("i'm not your fwend");
          showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text("Remove $friend?"),
                content: Text("Are you sure you want to unfriend $friend?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      print("i'm not your fwend");
                      FriendsManager.deleteFriend(appState.user, friend);
                      appState.loadFriends();
                    },
                    child: Text("Unfriend"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/*
class FriendCard extends StatelessWidget {
  final String friend;
  FriendCard({super.key, required this.friend});
  final friendLoader = FriendsManager();

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(friend, style: th.textTheme.displaySmall),
              const SizedBox(width: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      print("i'm not your fwend");
                      friendLoader.deleteFriend(appState.user, friend);
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      print("let's tallk frewn");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(username: friend),
                        ),
                      );
                    },
                    label: Text(
                      "Talk to $friend",
                      style: const TextStyle(fontSize: 18),
                    ),
                    icon: Icon(Icons.message),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
