import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:KidGo2/accessibility.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const apiUrl =
    "https://o0v9kizy1b.execute-api.ap-south-1.amazonaws.com/testing1";

class Message {
  String from;
  String group;
  String key;
  String url;
  int timestamp;

  Message(this.from, this.timestamp, this.group, this.key, this.url);
}

class MyAppState extends ChangeNotifier {
  var friends = <String>["Loading..."];
  late final String user;
  var messages = <Message>[];
  final tts = TTS();
  late final String email;
  String friendCode = "";
  bool loading = false;

  Future<void> init() async {
    var currUser = await Amplify.Auth.getCurrentUser();
    var attributes = await Amplify.Auth.fetchUserAttributes();
    user = currUser.username;
    print(user);
    email = attributes
        .firstWhere((attr) => attr.userAttributeKey.key == 'email')
        .value;

    loadFriends();
    notifyListeners();
  }

  Future<void> loadFriends() async {
    loading = true;
    await FriendsManager.load(user); // assuming this is async too?
    friends = FriendsManager.friends;
    loading = false;
  }

  String processPresignUrl(String url) {
    return url.replaceAll("\u0026", "&");
  }
}

class FriendsManager {
  static var friends = <String>[];
  static var loaded = false;

  static bool isStubUser(Map<String, dynamic> user) {
    return user["email"] == "" ||
        user["username"] == "" ||
        user["friends"] == null ||
        user["groups"] == null;
  }

  static Future<void> load(String user) async {
    loaded = false;
    var url = Uri.parse("$apiUrl/users/get/get?username=$user");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("wee coooked");
        if (isStubUser(jsonDecode(response.body))) {
          friends = [];
          return;
        }
        print(response.body);

        final List<dynamic> data = jsonDecode(response.body)["friends"];
        friends = List<String>.from(data);
      } else {
        friends = ["Error loading friends"];
      }
    } catch (e) {
      friends = ["Error: $e"];
    }

    loaded = true;
  }

  static Future<String> getCode(String user) async {
    var url = Uri.parse("$apiUrl/friends/code/code?username=$user");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.body);
        return response.body;
      }
    } catch (e) {
      return "error $e";
    }

    return "";
  }

  static Future<bool> gotCode(String user, String code) async {
    var url = Uri.parse("$apiUrl/friends/got/got?username=$user&code=$code");

    try {
      final response = await http.get(url);
      load(user);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteFriend(String user, String friend) async {
    final url = Uri.parse('$apiUrl/friends/delete/delete');

    try {
      final request = http.Request("DELETE", url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'name': user, 'friend_name': friend});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        friends.remove(friend);
      } else {
        friends = ['Error deleting friend (${response.statusCode})'];
      }
    } catch (e) {
      friends = ['Error: $e'];
    }
  }
}

class MessageLoader {
  var messages = <Message>[];
  late final String username;

  MessageLoader(this.username);

  String processPresignUrl(String url) {
    return url.replaceAll("\u0026", "&");
  }

  Future<void> loadAllMessages(String group) async {
    print("porjheohsowrjohi");
    await loadMessages(group);
  }

  Future<void> loadMessages(String group, {bool second = false}) async {
    final url = Uri.parse(
      "$apiUrl/msgs/get/get?group=${Uri.encodeComponent(group)}&limit=10&user=${Uri.encodeComponent(username)}",
    );

    try {
      final response = await http.get(url);
      print(response.body);

      if (response.statusCode == 200) {
        print("status 200");
        final decoded = jsonDecode(response.body);
        var msgs = decoded["messages"];
        print(response.body);

        if (!second) messages.clear();
        print(messages);

        var i = 0;

        for (var msg in msgs) {
          messages.add(
            Message(
              msg["from"],
              msg["timestamp"],
              msg["group"],
              msg["key"],
              processPresignUrl(decoded["download_urls"][i]),
            ),
          );

          i++;
        }

        print(messages);
      }
    } catch (e) {
      print("Error: $e");
    }

    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
