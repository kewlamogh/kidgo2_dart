import 'dart:convert';
import 'package:record/record.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const apiUrl =
    "https://o0v9kizy1b.execute-api.ap-south-1.amazonaws.com/testing1";

class Recorder {
  late AudioRecorder record;
  bool recording = false;

  Future<void> startRecording() async {
    if (recording) {
      return;
    }

    recording = true;
    record = AudioRecorder();

    // Ask for microphone permission
    bool micPermission = await record.hasPermission();
    if (!micPermission) {
      print("mic perms denied");
      return;
    }

    // // Ask for storage permission
    // var storageStatus = await Permission.storage.status;
    // if (!storageStatus.isGranted) {
    //   print("requesting storage perms");
    //   storageStatus = await Permission.storage.request();
    //   if (!storageStatus.isGranted) {
    //     print("Storage permission denied.");
    //     return;
    //   }
    // }

    // Get a safe external directory path
    final dir = await getExternalStorageDirectory();
    print(dir);
    if (dir == null) {
      print("Could not get external storage directory.");
      return;
    }

    // Optional: create subfolder if needed
    final folder = Directory('${dir.path}/KidGo2');
    if (!(await folder.exists())) {
      await folder.create(recursive: true);
    }

    final path = '${folder.path}/myFile.m4a';
    print("Saving to: $path");

    // Start recording
    await record.start(const RecordConfig(), path: path);
  }

  bool isRecording() {
    return recording;
  }

  Future<String?> stopRecording() async {
    if (!recording) {
      return "";
    }

    final path = await record.stop();
    print("quitting recording with path $path");
    record.dispose();
    recording = false;
    return path;
  }

  Future<String> send(String username, String group) async {
    final url = Uri.parse("$apiUrl/msgs/send/send");

    try {
      final response = await http.post(
        url,
        body:
            "{ \"from\": ${jsonEncode(username)}, \"group\": ${jsonEncode(group)} }",
      );

      print(
        "{ \"from\": ${jsonEncode(username)}, \"to\": ${jsonEncode(group)} }",
      );

      if (response.statusCode == 200) {
        return "${jsonDecode(response.body)["url"]}#${jsonDecode(response.body)["key"]}";
      }
    } catch (e) {
      print("err $e");
    }

    return "";
  }
}
