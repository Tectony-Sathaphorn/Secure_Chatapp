import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class FirebaseSignalingService {
  // Singleton pattern
  static final FirebaseSignalingService _instance = FirebaseSignalingService._internal();
  factory FirebaseSignalingService() => _instance;
  FirebaseSignalingService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // User ID
  String? _userId;
  
  // Active call ID
  String? _activeCallId;
  
  // Call listeners
  StreamSubscription? _callStatusSubscription;
  StreamSubscription? _offerSubscription;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _iceCandidatesSubscription;
  
  // Callbacks
  Function(String callId, String callerId, String callerName, bool isVideo)? onIncomingCall;
  Function(String callId, RTCSessionDescription sdp)? onOfferReceived;
  Function(String callId, RTCSessionDescription sdp)? onAnswerReceived;
  Function(String callId, RTCIceCandidate candidate)? onIceCandidateReceived;
  Function(String callId, String reason)? onCallEnded;
  
  // Initialize the signaling service
  Future<void> initialize() async {
    try {
      // Check if user is authenticated
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      _userId = currentUser.uid;
      log("Firebase signaling service initialized for user: $_userId");
      
      // Start listening for incoming calls
      _listenForIncomingCalls();
    } catch (e) {
      log("Error initializing Firebase signaling service: $e");
      rethrow;
    }
  }
  
  // Listen for incoming calls
  void _listenForIncomingCalls() {
    if (_userId == null) return;
    
    // Query for calls where this user is the receiver and status is pending
    final incomingCallsQuery = _database.ref()
        .child('calls')
        .orderByChild('receiverId')
        .equalTo(_userId!)
        .limitToLast(10); // Only get recent calls
    
    incomingCallsQuery.onChildAdded.listen((event) {
      final callData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (callData == null) return;
      
      final callId = event.snapshot.key ?? '';
      final status = callData['status'] as String?;
      
      // Only handle pending calls
      if (status == 'pending') {
        final callerId = callData['callerId'] as String?;
        final callerName = callData['callerName'] as String? ?? 'Unknown';
        final isVideo = callData['callType'] == 'video';
        
        if (callerId != null && callId.isNotEmpty) {
          if (onIncomingCall != null) {
            onIncomingCall!(callId, callerId, callerName, isVideo);
          }
          
          // Start listening for this specific call
          _listenForCallUpdates(callId);
        }
      }
    });
  }
  
  // Listen for updates on a specific call
  void _listenForCallUpdates(String callId) {
    // Listen for call status changes
    _callStatusSubscription = _database.ref()
        .child('calls/$callId/status')
        .onValue
        .listen((event) {
      final status = event.snapshot.value as String?;
      
      if (status == 'ended' || status == 'declined' || status == 'missed') {
        if (onCallEnded != null) {
          onCallEnded!(callId, status ?? 'unknown');
        }
        _cleanupCallListeners();
      }
    });
    
    // Listen for offer (if we're the receiver)
    _offerSubscription = _database.ref()
        .child('calls/$callId/offer')
        .onValue
        .listen((event) {
      final offerData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (offerData != null && offerData['sdp'] != null && offerData['type'] != null) {
        final sdp = RTCSessionDescription(
          offerData['sdp'] as String,
          offerData['type'] as String,
        );
        
        if (onOfferReceived != null) {
          onOfferReceived!(callId, sdp);
        }
      }
    });
    
    // Listen for answer (if we're the caller)
    _answerSubscription = _database.ref()
        .child('calls/$callId/answer')
        .onValue
        .listen((event) {
      final answerData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (answerData != null && answerData['sdp'] != null && answerData['type'] != null) {
        final sdp = RTCSessionDescription(
          answerData['sdp'] as String,
          answerData['type'] as String,
        );
        
        if (onAnswerReceived != null) {
          onAnswerReceived!(callId, sdp);
        }
      }
    });
    
    // Determine if we're the caller or receiver
    _database.ref().child('calls/$callId').get().then((snapshot) {
      final callData = snapshot.value as Map<dynamic, dynamic>?;
      if (callData == null) return;
      
      final callerId = callData['callerId'] as String?;
      final amICaller = callerId == _userId;
      
      // Listen for ICE candidates from the other party
      final otherPartyPath = amICaller ? 'receiver' : 'caller';
      
      _iceCandidatesSubscription = _database.ref()
          .child('calls/$callId/iceCandidates/$otherPartyPath')
          .onChildAdded
          .listen((event) {
        final candidateData = event.snapshot.value as Map<dynamic, dynamic>?;
        if (candidateData != null) {
          final candidate = RTCIceCandidate(
            candidateData['candidate'] as String,
            candidateData['sdpMid'] as String,
            candidateData['sdpMLineIndex'] as int,
          );
          
          if (onIceCandidateReceived != null) {
            onIceCandidateReceived!(callId, candidate);
          }
        }
      });
    });
  }
  
  // Clean up call listeners
  void _cleanupCallListeners() {
    _callStatusSubscription?.cancel();
    _offerSubscription?.cancel();
    _answerSubscription?.cancel();
    _iceCandidatesSubscription?.cancel();
    
    _callStatusSubscription = null;
    _offerSubscription = null;
    _answerSubscription = null;
    _iceCandidatesSubscription = null;
    
    _activeCallId = null;
  }
  
  // Make a call to another user
  Future<String?> makeCall({
    required String receiverId,
    required String receiverName,
    required RTCSessionDescription offer,
    bool isVideo = false,
  }) async {
    if (_userId == null) {
      throw Exception("User not initialized");
    }
    
    try {
      // Create a new call entry
      final callRef = _database.ref().child('calls').push();
      final callId = callRef.key;
      
      if (callId == null) {
        throw Exception("Failed to create call reference");
      }
      
      // Get current user display name
      final currentUser = _auth.currentUser;
      final callerName = currentUser?.displayName ?? 'Unknown';
      
      // Set call data
      await callRef.set({
        'callerId': _userId,
        'callerName': callerName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'callType': isVideo ? 'video' : 'voice',
        'status': 'pending',
        'startTime': ServerValue.timestamp,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });
      
      // Set active call
      _activeCallId = callId;
      
      // Start listening for call updates
      _listenForCallUpdates(callId);
      
      log("Call initiated to user: $receiverId, callId: $callId");
      return callId;
    } catch (e) {
      log("Error making call: $e");
      rethrow;
    }
  }
  
  // Accept an incoming call
  Future<void> acceptCall({
    required String callId,
    required RTCSessionDescription answer,
  }) async {
    if (_userId == null) {
      throw Exception("User not initialized");
    }
    
    try {
      // Update call status and set answer
      await _database.ref().child('calls/$callId').update({
        'status': 'accepted',
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      });
      
      // Set active call
      _activeCallId = callId;
      
      log("Call accepted: $callId");
    } catch (e) {
      log("Error accepting call: $e");
      rethrow;
    }
  }
  
  // Decline an incoming call
  Future<void> declineCall(String callId) async {
    if (_userId == null) return;
    
    try {
      await _database.ref().child('calls/$callId').update({
        'status': 'declined',
        'endTime': ServerValue.timestamp,
      });
      
      _cleanupCallListeners();
      log("Call declined: $callId");
    } catch (e) {
      log("Error declining call: $e");
    }
  }
  
  // End an active call
  Future<void> endCall(String callId) async {
    if (_userId == null) return;
    
    try {
      await _database.ref().child('calls/$callId').update({
        'status': 'ended',
        'endTime': ServerValue.timestamp,
      });
      
      _cleanupCallListeners();
      log("Call ended: $callId");
    } catch (e) {
      log("Error ending call: $e");
    }
  }
  
  // Add ICE candidate
  Future<void> addIceCandidate({
    required String callId,
    required RTCIceCandidate candidate,
    required bool asCaller,
  }) async {
    if (_userId == null) return;
    
    try {
      final role = asCaller ? 'caller' : 'receiver';
      await _database.ref()
          .child('calls/$callId/iceCandidates/$role')
          .push()
          .set({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
      
      log("ICE candidate added to $role for call: $callId");
    } catch (e) {
      log("Error adding ICE candidate: $e");
    }
  }
  
  // Dispose signaling service
  void dispose() {
    _cleanupCallListeners();
    log("Firebase signaling service disposed");
  }
} 