import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../app_state.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Initialize notification permissions and handlers
  Future<void> initialize(BuildContext context) async {
    try {
      // Request permission on iOS and web
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      developer.log('Notification permission status: ${settings.authorizationStatus}', 
          name: 'NotificationService');

      // Get the token
      String? token = await _messaging.getToken();
      if (token != null) {
        _saveTokenToDatabase(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Got a message whilst in the foreground!', name: 'NotificationService');
        developer.log('Message data: ${message.data}', name: 'NotificationService');

        if (message.notification != null) {
          developer.log(
            'Message also contained a notification: ${message.notification}',
            name: 'NotificationService',
          );
          
          // แสดงการแจ้งเตือนในแอป
          // ในนี้สามารถเพิ่มโค้ดเพื่อแสดงการแจ้งเตือนในแอปโดยใช้ Dialog หรือ SnackBar
          _showInAppNotification(context, message);
        }
      });

      // Handle when app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('App opened from notification: ${message.data}', 
            name: 'NotificationService');
        // จัดการการนำทางเมื่อกดที่การแจ้งเตือน
        _handleNotificationNavigation(context, message);
      });

    } catch (e) {
      developer.log('Error initializing notification service: $e', name: 'NotificationService');
    }
  }

  // Save FCM token to database
  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database.ref().child('users/${user.uid}/tokens').set({
        'token': token,
        'updated': ServerValue.timestamp,
      });
      developer.log('Saved FCM token to database: ${token.substring(0, 10)}...', 
          name: 'NotificationService');
    }
  }
  
  // Show in-app notification
  void _showInAppNotification(BuildContext context, RemoteMessage message) {
    if (context.mounted) {
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.title ?? 'New Notification'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                _handleNotificationNavigation(context, message);
              },
            ),
          ),
        );
      }
    }
  }
  
  // Handle navigation based on notification data
  void _handleNotificationNavigation(BuildContext context, RemoteMessage message) {
    final data = message.data;
    
    // ตรวจสอบประเภทการแจ้งเตือนและนำทางไปยังหน้าที่เหมาะสม
    if (data.containsKey('type')) {
      final type = data['type'];
      
      switch (type) {
        case 'chat':
          if (data.containsKey('chatId')) {
            // นำทางไปยังหน้าแชท
            Navigator.of(context).pushNamed('/chat/${data['chatId']}');
          }
          break;
        default:
          // นำทางไปยังหน้าหลัก
          Navigator.of(context).pushNamed('/');
      }
    }
  }
  
  // ส่งข้อความแจ้งเตือนไปยังผู้ใช้อื่น (ใช้ cloud functions)
  Future<void> sendNotificationToUser(String userId, String title, String body, Map<String, dynamic> data) async {
    try {
      // ในการใช้งานจริง ควรใช้ Cloud Functions เพื่อส่งการแจ้งเตือน
      // แต่ในนี้เราจะจำลองการส่งโดยการบันทึกลงในฐานข้อมูล
      await _database.ref().child('notifications/$userId').push().set({
        'title': title,
        'body': body,
        'data': data,
        'timestamp': ServerValue.timestamp,
        'read': false,
      });
      
      developer.log('Saved notification to database for user: $userId', 
          name: 'NotificationService');
    } catch (e) {
      developer.log('Error sending notification: $e', name: 'NotificationService');
    }
  }
}

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Handling a background message: ${message.messageId}', 
      name: 'NotificationService');
} 