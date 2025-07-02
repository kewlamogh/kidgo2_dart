import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class GatePage extends StatefulWidget {
  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> {
  bool? _hasInternet;

  Future<bool> hasInternet() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void checkConnection() async {
    final result = await hasInternet();
    setState(() {
      _hasInternet = result;
    });
  }

  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData? icon;
    final String upper;
    print("hello");
    if (_hasInternet == null) {
      label = "Loading...";
      upper = "Checking if you have Internet access";
      icon = null;
    } else {
      label = _hasInternet! ? "Continue to KidGo!" : "Refresh";
      upper = _hasInternet!
          ? "You have Internet and are ready to go!"
          : "Looks like you don't have Internet access. Try connecting to a Wi-Fi network or using mobile data.";
      icon = _hasInternet! ? Icons.arrow_right : Icons.refresh;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth * 0.8, // 80% of screen width
                    child: Column(
                      children: [
                        Image.asset("assets/images/logo.jpeg"),
                        Text("KidGo", style: const TextStyle(fontSize: 20.0)),
                        const SizedBox(height: 15),
                        Text(upper, softWrap: true),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _hasInternet == null
                    ? null
                    : () {
                        print("Do whatever");
                        if (_hasInternet!) {
                          Navigator.pushReplacementNamed(context, '/friends');
                        } else {
                          checkConnection();
                        }
                      },
                label: Text(label),
                icon: icon == null ? const SizedBox.shrink() : Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
