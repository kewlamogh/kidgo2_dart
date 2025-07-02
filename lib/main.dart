// import 'package:KidGo2/accessibility.dart';
import 'package:KidGo2/gate_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'friends_page.dart';
import "state.dart";
import 'package:flutter/services.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'amplify_outputs.dart';

const apiUrl =
    "https://o0v9kizy1b.execute-api.ap-south-1.amazonaws.com/testing1";

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await Hive.initFlutter();
    await Hive.openBox("myBox");
    await _configureAmplify();
    runApp(
      Authenticator(
        child: ChangeNotifierProvider(
          create: (context) => MyAppState(),
          child: MyApp(),
        ),
      ),
    );
  } on Exception catch (e) {
    runApp(Text("error $e"));
  }
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(amplifyConfig);
    safePrint('Successfully configured');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => GatePage(),
        '/friends': (_) => AuthenticatedView(child: FriendsPage()),
      },
    );
  }
}
