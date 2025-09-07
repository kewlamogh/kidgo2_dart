import 'package:KidGo2/friends_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "state.dart";

class AddFriendPage extends StatefulWidget {
  final FriendsManager manager;
  AddFriendPage(this.manager);

  @override
  AddFriendPageState createState() => AddFriendPageState();
}

class AddFriendPageState extends State<AddFriendPage> {
  late final String username; // Replace with actual user ID
  String code = "not generated";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<MyAppState>();
      username = state.user;
      state.tts.playIfNotViewedAlready("add_friend_page");
    });
  }

  @override
  void dispose() {
    super.dispose();
    try {
      var appState = Provider.of<MyAppState>(context, listen: false);
      appState.tts.stop();
    } catch (e) {
      print(e);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final TextEditingController controller = TextEditingController();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Row(
              children: const [
                Icon(Icons.group_add),
                SizedBox(width: 10),
                Text("Add a Friend"),
              ],
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Choose how you want to add a friend",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Generate code section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final newCode = await FriendsManager.getCode(
                              username,
                            );
                            setState(() {
                              code = newCode;
                            });
                          },
                          icon: const Icon(Icons.vpn_key),
                          label: const Text("Generate my code"),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Your friend code:",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Enter code section
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Enter friend code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.keyboard),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final entered = controller.text;
                            print('Friend code entered: $entered');

                            if (await FriendsManager.gotCode(
                              username,
                              entered,
                            )) {
                              await appState.loadFriends();
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Submit"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // TTS overlay
        appState.tts.widget("add_friend_page", context: context),
      ],
    );
  }
}
