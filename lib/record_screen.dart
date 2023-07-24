import 'dart:io';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'main.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  late String _filePath;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _isRecording ? 'Recording in progress' : 'Press the button to start recording',
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  _startRecording();
                }
              },
              child: Text(_isRecording ? 'Stop' : 'Start', style: const TextStyle(fontSize: 35.0)),
            ),
          ],
        ),
      ),
    );
  }

void _prepare() async {
    await requestMicrophonePermission();
    await _recorder.openRecorder();
}

Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
    }
}

void _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
    debugPrint("File path: $_filePath");
    await _recorder.startRecorder(toFile: _filePath, codec: Codec.aacADTS);
    setState(() => _isRecording = true);
}


// void _stopRecording() async {
//   await _recorder.stopRecorder();
//   setState(() => _isRecording = false);
//   final file = File(_filePath);
//   final storageReference =
//       FirebaseStorage.instance.ref().child("audio-to-firebase/${DateTime.now()}.aac");

//   try {
//     // Upload the file and wait for the completion of the upload task
//     await storageReference.putFile(file);

//     // After the upload is complete, get the download URL
//     final url = await storageReference.getDownloadURL();
//     developer.log('URL is $url');

//     // Store user data and file link in Firestore
//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser != null) {
//       final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
//       final fileInfo = {
//         'email': currentUser.email, // Store the user's email
//         'fileLink': url,
//         'timestamp': DateTime.now(),
//         // Add any other metadata you want to store, like file name, duration, etc.
//       };
//       // Set the user data and file link in the Firestore document
//       await userRef.set(fileInfo, SetOptions(merge: true));
//     }
//   } catch (e) {
//     // Handle any errors that may occur during the upload or getting the URL
//     log.warning('Error uploading or getting URL: $e');
//   }

//   if (await file.exists()) {
//     // Proceed with file upload
//     // ... Your existing code for file upload ...
//   } else {
//     debugPrint("File not found: $_filePath");
//   }
// }

void _stopRecording() async {
  await _recorder.stopRecorder();
  setState(() => _isRecording = false);
  final file = File(_filePath);
  final storageReference =
      FirebaseStorage.instance.ref().child("audio-to-firebase/${DateTime.now()}.aac");

  try {
    // Upload the file and wait for the completion of the upload task
    await storageReference.putFile(file);

    // After the upload is complete, get the download URL
    final url = await storageReference.getDownloadURL();
    developer.log('URL is $url');

    // Store user data and file link in a new Firestore document
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final recordingData = {
        'email': currentUser.email,
        'fileLink': url,
        'timestamp': DateTime.now(),
        // Add any other metadata you want to store, like file name, duration, etc.
      };
      // Add a new document with the recordingData under the 'recordings' collection
      await userRef.collection('recordings').add(recordingData);
    }
  } catch (e) {
    // Handle any errors that may occur during the upload or getting the URL
    log.warning('Error uploading or getting URL: $e');
  }

  if (await file.exists()) {
    // Proceed with file upload
    // ... Your existing code for file upload ...
  } else {
    debugPrint("File not found: $_filePath");
  }
}


}