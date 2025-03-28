import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'firebase_signaling_service.dart';
import 'webrtc_service.dart';
import 'call_notification_service.dart';
import '../pages/voice_call_page/voice_call_page_widget.dart';
import 'dart:developer';

class CallManager {
  // Singleton pattern
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();
  
  // Services
  final FirebaseSignalingService _signalingService = FirebaseSignalingService();
  final WebRTCService _webRTCService = WebRTCService();
  final CallNotificationService _notificationService = CallNotificationService();
  
  // Getters สำหรับเข้าถึงบริการจากภายนอก
  WebRTCService get webRTCService => _webRTCService;
  
  // Active call data
  String? _activeCallId;
  String? _remoteUserId;
  String? _remoteName;
  bool _isCallInitiator = false;
  
  // Initialize call manager
  Future<void> initialize() async {
    try {
      // Initialize WebRTC
      await _webRTCService.initialize();
      
      // Initialize Firebase Signaling
      await _signalingService.initialize();
      
      // Initialize Call Notifications
      await _notificationService.initialize();
      
      // Set up signaling callbacks
      _setupSignalingCallbacks();
      
      // Set up WebRTC callbacks
      _setupWebRTCCallbacks();
      
      // Set up notification callbacks
      _setupNotificationCallbacks();
      
      log("Call manager initialized");
    } catch (e) {
      log("Error initializing call manager: $e");
      rethrow;
    }
  }
  
  // Set up signaling callbacks
  void _setupSignalingCallbacks() {
    // Incoming call callback
    _signalingService.onIncomingCall = (callId, callerId, callerName, isVideo) {
      _activeCallId = callId;
      _remoteUserId = callerId;
      _remoteName = callerName;
      _isCallInitiator = false;
      
      // Show incoming call notification
      _notificationService.showIncomingCallNotification(
        callerId: callerId,
        callerName: callerName,
        callType: isVideo ? CallType.video : CallType.voice,
      );
    };
    
    // Offer received callback
    _signalingService.onOfferReceived = (callId, sdp) async {
      if (callId == _activeCallId) {
        try {
          // Accept the WebRTC call with the received offer
          final answer = await _webRTCService.acceptCall(sdp);
          
          // Send answer back via signaling
          await _signalingService.acceptCall(
            callId: callId,
            answer: answer,
          );
          
          // Process any pending ICE candidates
          _processPendingIceCandidates();
        } catch (e) {
          log("Error accepting WebRTC call: $e");
        }
      }
    };
    
    // Answer received callback
    _signalingService.onAnswerReceived = (callId, sdp) async {
      if (callId == _activeCallId) {
        try {
          // Set remote description with the received answer
          await _webRTCService.handleAnswer(sdp);
          
          // Process any pending ICE candidates
          _processPendingIceCandidates();
        } catch (e) {
          log("Error handling WebRTC answer: $e");
        }
      }
    };
    
    // ICE candidate received callback
    _signalingService.onIceCandidateReceived = (callId, candidate) async {
      if (callId == _activeCallId) {
        try {
          // Add received ICE candidate
          await _webRTCService.addIceCandidate(candidate);
        } catch (e) {
          log("Error adding ICE candidate: $e");
        }
      }
    };
    
    // Call ended callback
    _signalingService.onCallEnded = (callId, reason) {
      if (callId == _activeCallId) {
        _endCall(notify: false);
      }
    };
  }
  
  // Set up WebRTC callbacks
  void _setupWebRTCCallbacks() {
    // Callback when WebRTC generates ICE candidates
    _webRTCService.onIceCandidate = (RTCIceCandidate candidate) {
      if (_activeCallId != null) {
        _signalingService.addIceCandidate(
          callId: _activeCallId!,
          candidate: candidate,
          asCaller: _isCallInitiator,
        );
      }
    };
    
    // Callback when WebRTC connection state changes
    _webRTCService.onConnectionStateChange = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _endCall();
      }
    };
    
    // Callback when call ends on WebRTC side
    _webRTCService.onCallEnded = () {
      _endCall();
    };
  }
  
  // Set up notification callbacks
  void _setupNotificationCallbacks() {
    _notificationService.onCallActionPressed = (callerId, accept) {
      if (_activeCallId != null && _remoteUserId == callerId) {
        if (accept) {
          // User accepted call from notification, navigate to call screen
          if (_activeCallId != null && _remoteUserId != null && _remoteName != null) {
            // This is just a notification - need context to navigate
            log("Call accepted from notification - need to navigate to call screen");
          }
        } else {
          // User rejected call
          if (_activeCallId != null) {
            _signalingService.declineCall(_activeCallId!);
          }
          _cleanup();
        }
      }
    };
  }
  
  // Process pending ICE candidates
  void _processPendingIceCandidates() {
    if (_activeCallId == null) return;
    
    final candidates = _webRTCService.getPendingCandidates();
    for (var candidate in candidates) {
      _signalingService.addIceCandidate(
        callId: _activeCallId!,
        candidate: candidate,
        asCaller: _isCallInitiator,
      );
    }
  }
  
  // Start a call to another user
  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    bool isVideo = false,
    BuildContext? context,
  }) async {
    try {
      // Initialize WebRTC offer
      final offer = await _webRTCService.makeCall();
      
      // Create call via signaling
      final callId = await _signalingService.makeCall(
        receiverId: receiverId,
        receiverName: receiverName,
        offer: offer,
        isVideo: isVideo,
      );
      
      if (callId != null) {
        _activeCallId = callId;
        _remoteUserId = receiverId;
        _remoteName = receiverName;
        _isCallInitiator = true;
        
        // Process any pending ICE candidates
        _processPendingIceCandidates();
        
        // If context is provided, navigate to call screen
        if (context != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => VoiceCallPageWidget(
              remoteName: receiverName,
              remoteUserId: receiverId,
              isIncoming: false,
              incomingOffer: null,
            ),
          ));
        }
      }
    } catch (e) {
      log("Error starting call: $e");
      _cleanup();
      rethrow;
    }
  }
  
  // Accept an incoming call (to be called from UI)
  Future<void> acceptCall({
    required BuildContext context,
    required String callId,
    required String callerId,
    required String callerName,
  }) async {
    if (_activeCallId == null || _remoteUserId == null) {
      log("No active incoming call to accept");
      return;
    }
    
    try {
      // Cancel notification
      _notificationService.cancelIncomingCallNotification(callerId);
      
      // Navigate to call screen - the actual WebRTC accept will happen there
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => VoiceCallPageWidget(
          remoteName: callerName,
          remoteUserId: callerId,
          isIncoming: true,
          // Note: the offer will be retrieved from Firebase, not needed here
        ),
      ));
    } catch (e) {
      log("Error accepting call: $e");
      _cleanup();
      rethrow;
    }
  }
  
  // Decline an incoming call
  Future<void> declineCall() async {
    if (_activeCallId == null) {
      log("No active incoming call to decline");
      return;
    }
    
    try {
      // Update call status in Firebase
      await _signalingService.declineCall(_activeCallId!);
      
      // Cancel notification
      if (_remoteUserId != null) {
        _notificationService.cancelIncomingCallNotification(_remoteUserId!);
      }
      
      _cleanup();
    } catch (e) {
      log("Error declining call: $e");
      _cleanup();
    }
  }
  
  // End an active call
  Future<void> endCall({bool notify = true}) async {
    if (_activeCallId == null) return;
    
    try {
      if (notify) {
        // Update call status in Firebase
        await _signalingService.endCall(_activeCallId!);
      }
      
      // End WebRTC call
      await _webRTCService.endCall();
      
      _cleanup();
    } catch (e) {
      log("Error ending call: $e");
      _cleanup();
    }
  }
  
  // Internal method to end call
  Future<void> _endCall({bool notify = true}) async {
    // Delegate to public endCall method
    await endCall(notify: notify);
  }
  
  // Toggle microphone
  Future<void> toggleMicrophone(bool enabled) async {
    await _webRTCService.toggleMicrophone(enabled);
  }
  
  // Clean up call resources
  void _cleanup() {
    _activeCallId = null;
    _remoteUserId = null;
    _remoteName = null;
    _isCallInitiator = false;
  }
  
  // Dispose call manager
  void dispose() {
    _signalingService.dispose();
    _webRTCService.dispose();
    _cleanup();
    log("Call manager disposed");
  }
} 