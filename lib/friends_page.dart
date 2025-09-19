import 'package:http/http.dart' as http;
import 'package:KidGo2/add_friend_page.dart';
import 'package:KidGo2/accessibility.dart';

import './widgets/friend_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "state.dart";

const apiUrl =
    "https://o0v9kizy1b.execute-api.ap-south-1.amazonaws.com/testing1";

class FriendsPage extends StatefulWidget {
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FriendsManager fm = FriendsManager();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final state = context.read<MyAppState>();
    await state.init();
    final user = state.user;
    state.tts.playIfNotViewedAlready("friends_page");
    await FriendsManager.load(user);
    setState(() {
      isLoading = false;
    });

    var url = Uri.parse("$apiUrl/users/add/add");
    print(state.user + state.email);

    try {
      var request = http.Request('POST', url);
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body =
          '{"username": "${state.user}", "email": "${state.email}", "friends":[], "groups": []}';
      request.send();
    } catch (e) {
      print("err boring $e");
    }
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
                Icon(Icons.forum),
                SizedBox(width: 10),
                Text("Your Chats"),
              ],
            ),
          ),
          body: Center(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    children: [
                      Expanded(
                        child: isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ListView(
                                children: FriendsManager.friends
                                    .map(
                                      (friend) => Center(
                                        child: FriendCard(friend: friend),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFriendPage(fm),
                        ),
                      );
                    },
                    label: Text("Add Friend"),
                    icon: Icon(Icons.add),
                    style: ButtonColorStyle.withColor(Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
        appState.tts.widget("friends_page", context: context),
      ],
    );
  }
}
