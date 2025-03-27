import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime_type/mime_type.dart';

Future<String?> uploadData(String path, Uint8List data) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(
      contentType: mime(path),
      customMetadata: {
        'Access-Control-Allow-Origin': '*',
      },
    );
    final result = await storageRef.putData(data, metadata);
    if (result.state == TaskState.success) {
      // เพิ่มคำสั่ง cache-control เพื่อหลีกเลี่ยงปัญหา CORS
      final downloadURL = await result.ref.getDownloadURL();
      return downloadURL;
    }
    return null;
  } catch (e) {
    print('Error uploading to Firebase Storage: $e');
    return null;
  }
}
