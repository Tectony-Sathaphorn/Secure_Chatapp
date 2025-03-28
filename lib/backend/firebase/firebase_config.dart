import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '/firebase_options.dart';

Future initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    print('Firebase initialization error: $e');
    return false;
  }
}
