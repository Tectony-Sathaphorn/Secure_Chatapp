import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ชนิดของการโทร
enum CallType {
  voice,
  video,
}

class CallNotificationService {
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Callback เมื่อผู้ใช้ตอบรับหรือปฏิเสธการโทร
  Function(String callerId, bool accept)? onCallActionPressed;

  Future<void> initialize() async {
    try {
      // กำหนดค่าเริ่มต้นสำหรับ Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // กำหนดค่าเริ่มต้นสำหรับ iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      
      // กำหนดค่าเริ่มต้นรวม
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // กำหนด callback เมื่อมีการกดที่การแจ้งเตือน - ปรับให้เข้ากับ v13.0.0
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      log("Call notification service initialized");
    } catch (e) {
      log("Error initializing call notification service: $e");
    }
  }
  
  void _onNotificationResponse(NotificationResponse response) {
    _handleNotificationAction(response);
  }
  
  // แสดงการแจ้งเตือนสำหรับการโทรเข้า
  Future<void> showIncomingCallNotification({
    required String callerId,
    required String callerName,
    required CallType callType,
  }) async {
    try {
      // สร้าง Android notification details
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          const AndroidNotificationDetails(
        'call_channel',
        'Incoming Calls',
        channelDescription: 'Channel for incoming call notifications',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        sound: RawResourceAndroidNotificationSound('ringtone'),
      );
      
      // สร้าง iOS notification details
      DarwinNotificationDetails iOSPlatformChannelSpecifics =
          const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'ringtone.aiff',
      );
      
      // สร้าง notification details
      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      // แสดงการแจ้งเตือน
      await _notificationsPlugin.show(
        callerId.hashCode,  // ใช้ hash ของ callerId เป็น notification ID
        'Incoming ${callType == CallType.voice ? 'Voice' : 'Video'} Call',
        callerName,
        platformChannelSpecifics,
        payload: 'call_$callerId',
      );
      
      log("Incoming call notification shown for caller: $callerName ($callerId)");
    } catch (e) {
      log("Error showing incoming call notification: $e");
    }
  }
  
  // ยกเลิกการแจ้งเตือนการโทรเข้า
  Future<void> cancelIncomingCallNotification(String callerId) async {
    try {
      await _notificationsPlugin.cancel(callerId.hashCode);
      log("Incoming call notification canceled for caller ID: $callerId");
    } catch (e) {
      log("Error canceling incoming call notification: $e");
    }
  }
  
  // จัดการกับการกดปุ่มในการแจ้งเตือน
  void _handleNotificationAction(NotificationResponse response) {
    final String? payload = response.payload;
    final String? actionId = response.actionId;
    
    if (payload != null && payload.startsWith('call_')) {
      final String callerId = payload.substring(5);
      
      if (actionId == 'accept') {
        log("User accepted call from caller ID: $callerId");
        if (onCallActionPressed != null) {
          onCallActionPressed!(callerId, true);
        }
      } else if (actionId == 'reject') {
        log("User rejected call from caller ID: $callerId");
        if (onCallActionPressed != null) {
          onCallActionPressed!(callerId, false);
        }
      } else {
        // ถ้าผู้ใช้กดที่การแจ้งเตือนโดยตรง (ไม่ได้กดปุ่ม)
        log("User tapped on call notification from caller ID: $callerId");
        if (onCallActionPressed != null) {
          onCallActionPressed!(callerId, true);
        }
      }
      
      // ยกเลิกการแจ้งเตือนหลังจากผู้ใช้ตอบสนอง
      cancelIncomingCallNotification(callerId);
    }
  }
} 