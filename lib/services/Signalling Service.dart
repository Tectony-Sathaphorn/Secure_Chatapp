import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignallingService {
  // Singleton pattern
  static final SignallingService _instance = SignallingService._internal();
  factory SignallingService() => _instance;
  SignallingService._internal();

  // Socket instance
  IO.Socket? _socket;
  String? _userId;
  String? _roomId;
  
  // Callbacks
  Function(String userId, RTCSessionDescription sdp)? onOfferReceived;
  Function(String userId, RTCSessionDescription sdp)? onAnswerReceived;
  Function(String userId, RTCIceCandidate candidate)? onIceCandidateReceived;
  Function(String userId)? onCallEnded;
  Function(String userId, bool withVideo)? onCallReceived;

  // Initialize the signalling service with a user ID
  Future<void> initialize(String userId, String serverUrl) async {
    _userId = userId;
    
    try {
      // Initialize Socket.IO connection
      _socket = IO.io(serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
      );
      
      // Connect to server
      _socket?.connect();
      
      // Register event listeners
      _setupSocketListeners();
      
      log("Signalling service initialized with user ID: $userId");
    } catch (e) {
      log("Error initializing signalling service: $e");
      rethrow;
    }
  }
  
  void _setupSocketListeners() {
    _socket?.on('connect', (_) {
      log("Connected to signalling server with socket ID: ${_socket?.id}");
      
      // Register user to the server
      _socket?.emit('register', {
        'userId': _userId,
      });
    });
    
    _socket?.on('call-offer', (data) {
      final Map<String, dynamic> message = json.decode(data);
      final String callerId = message['userId'];
      final String sdpString = message['sdp'];
      final bool withVideo = message['withVideo'] ?? false;
      
      log("Received call offer from user: $callerId");
      
      if (onCallReceived != null) {
        onCallReceived!(callerId, withVideo);
      }
      
      if (onOfferReceived != null) {
        final sdp = RTCSessionDescription(
          sdpString,
          message['type'],
        );
        onOfferReceived!(callerId, sdp);
      }
    });
    
    _socket?.on('call-answer', (data) {
      final Map<String, dynamic> message = json.decode(data);
      final String calleeId = message['userId'];
      final String sdpString = message['sdp'];
      
      log("Received call answer from user: $calleeId");
      
      if (onAnswerReceived != null) {
        final sdp = RTCSessionDescription(
          sdpString,
          message['type'],
        );
        onAnswerReceived!(calleeId, sdp);
      }
    });
    
    _socket?.on('ice-candidate', (data) {
      final Map<String, dynamic> message = json.decode(data);
      final String userId = message['userId'];
      
      log("Received ICE candidate from user: $userId");
      
      if (onIceCandidateReceived != null) {
        final candidate = RTCIceCandidate(
          message['candidate'],
          message['sdpMid'],
          message['sdpMLineIndex'],
        );
        onIceCandidateReceived!(userId, candidate);
      }
    });
    
    _socket?.on('call-ended', (data) {
      final Map<String, dynamic> message = json.decode(data);
      final String userId = message['userId'];
      
      log("Call ended by user: $userId");
      
      if (onCallEnded != null) {
        onCallEnded!(userId);
      }
    });
    
    _socket?.on('disconnect', (_) {
      log("Disconnected from signalling server");
    });
    
    _socket?.on('error', (error) {
      log("Socket error: $error");
    });
  }
  
  // Send a call offer to a remote user
  Future<void> sendCallOffer(String remoteUserId, RTCSessionDescription sdp, bool withVideo) async {
    if (_socket == null || !(_socket!.connected)) {
      throw Exception("Socket is not connected");
    }
    
    try {
      final message = {
        'userId': _userId,
        'targetUserId': remoteUserId,
        'type': sdp.type,
        'sdp': sdp.sdp,
        'withVideo': withVideo,
      };
      
      _socket?.emit('call-offer', json.encode(message));
      log("Call offer sent to user: $remoteUserId");
    } catch (e) {
      log("Error sending call offer: $e");
      rethrow;
    }
  }
  
  // Send a call answer to a remote user
  Future<void> sendCallAnswer(String remoteUserId, RTCSessionDescription sdp) async {
    if (_socket == null || !(_socket!.connected)) {
      throw Exception("Socket is not connected");
    }
    
    try {
      final message = {
        'userId': _userId,
        'targetUserId': remoteUserId,
        'type': sdp.type,
        'sdp': sdp.sdp,
      };
      
      _socket?.emit('call-answer', json.encode(message));
      log("Call answer sent to user: $remoteUserId");
    } catch (e) {
      log("Error sending call answer: $e");
      rethrow;
    }
  }
  
  // Send an ICE candidate to a remote user
  Future<void> sendIceCandidate(String remoteUserId, RTCIceCandidate candidate) async {
    if (_socket == null || !(_socket!.connected)) {
      throw Exception("Socket is not connected");
    }
    
    try {
      final message = {
        'userId': _userId,
        'targetUserId': remoteUserId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      };
      
      _socket?.emit('ice-candidate', json.encode(message));
      log("ICE candidate sent to user: $remoteUserId");
    } catch (e) {
      log("Error sending ICE candidate: $e");
      rethrow;
    }
  }
  
  // Send a call end notification to a remote user
  Future<void> sendCallEnd(String remoteUserId) async {
    if (_socket == null || !(_socket!.connected)) {
      throw Exception("Socket is not connected");
    }
    
    try {
      final message = {
        'userId': _userId,
        'targetUserId': remoteUserId,
      };
      
      _socket?.emit('call-ended', json.encode(message));
      log("Call end notification sent to user: $remoteUserId");
    } catch (e) {
      log("Error sending call end notification: $e");
      rethrow;
    }
  }
  
  // Join a room for group calls (future implementation)
  Future<void> joinRoom(String roomId) async {
    if (_socket == null || !(_socket!.connected)) {
      throw Exception("Socket is not connected");
    }
    
    try {
      _roomId = roomId;
      
      final message = {
        'userId': _userId,
        'roomId': roomId,
      };
      
      _socket?.emit('join-room', json.encode(message));
      log("Joined room: $roomId");
    } catch (e) {
      log("Error joining room: $e");
      rethrow;
    }
  }
  
  // Leave a room
  Future<void> leaveRoom() async {
    if (_socket == null || !(_socket!.connected) || _roomId == null) {
      return;
    }
    
    try {
      final message = {
        'userId': _userId,
        'roomId': _roomId,
      };
      
      _socket?.emit('leave-room', json.encode(message));
      log("Left room: $_roomId");
      _roomId = null;
    } catch (e) {
      log("Error leaving room: $e");
      rethrow;
    }
  }
  
  // Disconnect from the signalling server
  Future<void> disconnect() async {
    try {
      if (_roomId != null) {
        await leaveRoom();
      }
      
      _socket?.disconnect();
      _socket = null;
      log("Disconnected from signalling server");
    } catch (e) {
      log("Error disconnecting from signalling server: $e");
      rethrow;
    }
  }
  
  // Check if the socket is connected
  bool isConnected() {
    return _socket != null && _socket!.connected;
  }
  
  // Get the user ID
  String? getUserId() {
    return _userId;
  }
}