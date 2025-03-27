import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyB_IwJm1GyK2PBOLkNZI9-EpDKcDHFs5Iw",
            authDomain: "messenger-mpv.firebaseapp.com",
            projectId: "messenger-mpv",
            storageBucket: "messenger-mpv.firebasestorage.app",
            messagingSenderId: "114218863625",
            appId: "1:114218863625:web:f6da557dbf8db5850afcd8",
            measurementId: "G-RCL0ZVS9NY"));
  } else {
    await Firebase.initializeApp();
  }
}
