import 'dart:async';
import 'dart:developer';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  // Singleton pattern
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // WebRTC related variables
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<RTCIceCandidate> _pendingCandidates = [];
  bool _isCallActive = false;
  
  // สถานะการโทร
  String _callStatus = 'idle';
  String get callStatus => _callStatus;
  
  // Callbacks
  Function(MediaStream)? onLocalStreamAvailable;
  Function(MediaStream)? onRemoteStreamAvailable;
  Function(RTCPeerConnectionState)? onConnectionStateChange;
  Function()? onCallEnded;
  Function(RTCIceCandidate)? onIceCandidate;
  Function(String)? onCallStatusChanged; // Callback สำหรับการเปลี่ยนแปลงสถานะการโทร

  // Initialize WebRTC service
  Future<void> initialize() async {
    try {
      _callStatus = 'idle';
      _notifyCallStatusChanged();
      
      // Configuration for RTCPeerConnection
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      };
      
      // Create peer connection
      _peerConnection = await createPeerConnection(configuration);
      
      // Set up event listeners
      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        log("Ice candidate generated: ${candidate.candidate}");
        if (onIceCandidate != null) {
          onIceCandidate!(candidate);
        } else {
          _pendingCandidates.add(candidate);
        }
      };
      
      // เพิ่มการจัดการสถานะ ICE Connection
      _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
        log("ICE connection state changed: ${state.toString()}");
        
        switch (state) {
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
            _callStatus = 'connected';
            _notifyCallStatusChanged();
            break;
          case RTCIceConnectionState.RTCIceConnectionStateChecking:
            _callStatus = 'connecting';
            _notifyCallStatusChanged();
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            _callStatus = 'connection_failed';
            _notifyCallStatusChanged();
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            _callStatus = 'disconnected';
            _notifyCallStatusChanged();
            break;
          default:
            // ไม่ต้องเปลี่ยนสถานะสำหรับสถานะอื่นๆ
            break;
        }
      };
      
      _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        log("Connection state changed: ${state.toString()}");
        if (onConnectionStateChange != null) {
          onConnectionStateChange!(state);
        }
        
        // Handle disconnection
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed || 
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _endCall();
        }
      };
      
      // Listen for remote streams
      _peerConnection?.onAddStream = (MediaStream stream) {
        log("Remote stream added");
        _callStatus = 'connected';
        _notifyCallStatusChanged();
        if (onRemoteStreamAvailable != null) {
          onRemoteStreamAvailable!(stream);
        }
      };
      
      log("WebRTC service initialized");
    } catch (e) {
      log("Error initializing WebRTC service: $e");
      _callStatus = 'error';
      _notifyCallStatusChanged();
      rethrow;
    }
  }
  
  // แจ้งเตือนการเปลี่ยนแปลงสถานะการโทร
  void _notifyCallStatusChanged() {
    if (onCallStatusChanged != null) {
      onCallStatusChanged!(_callStatus);
    }
    log("Call status changed: $_callStatus");
  }
  
  // Get pending ICE candidates
  List<RTCIceCandidate> getPendingCandidates() {
    final candidates = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    return candidates;
  }
  
  // Create local media stream (audio only)
  Future<MediaStream> _createLocalStream() async {
    // Get user media with audio only (no video)
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false
    };
    
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      if (onLocalStreamAvailable != null) {
        onLocalStreamAvailable!(_localStream!);
      }
      
      return _localStream!;
    } catch (e) {
      log("Error getting user media: $e");
      _callStatus = 'media_error';
      _notifyCallStatusChanged();
      rethrow;
    }
  }
  
  // Make an outgoing call
  Future<RTCSessionDescription> makeCall() async {
    if (_peerConnection == null) {
      throw Exception("WebRTC service not initialized");
    }
    
    try {
      _callStatus = 'calling';
      _notifyCallStatusChanged();
      
      // Create local stream if not available
      if (_localStream == null) {
        await _createLocalStream();
      }
      
      // Add tracks from local stream to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      
      // Create offer
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false
      });
      
      // Set local description
      await _peerConnection!.setLocalDescription(offer);
      
      _isCallActive = true;
      log("Outgoing call offer created");
      
      // รอเพื่อให้ได้ ICE Candidates ที่ดีที่สุด
      await Future.delayed(Duration(milliseconds: 500));
      
      return offer;
    } catch (e) {
      log("Error making call: $e");
      _callStatus = 'error';
      _notifyCallStatusChanged();
      rethrow;
    }
  }
  
  // Accept an incoming call
  Future<RTCSessionDescription> acceptCall(RTCSessionDescription offer) async {
    if (_peerConnection == null) {
      throw Exception("WebRTC service not initialized");
    }
    
    try {
      _callStatus = 'accepting';
      _notifyCallStatusChanged();
      
      // Set remote description
      await _peerConnection!.setRemoteDescription(offer);
      
      // Create local stream if not available
      if (_localStream == null) {
        await _createLocalStream();
      }
      
      // Add tracks from local stream to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      
      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false
      });
      
      // Set local description
      await _peerConnection!.setLocalDescription(answer);
      
      _isCallActive = true;
      log("Incoming call accepted");
      
      // รอเพื่อให้ได้ ICE Candidates ที่ดีที่สุด
      await Future.delayed(Duration(milliseconds: 500));
      
      return answer;
    } catch (e) {
      log("Error accepting call: $e");
      _callStatus = 'error';
      _notifyCallStatusChanged();
      rethrow;
    }
  }
  
  // Handle received answer
  Future<void> handleAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null) {
      throw Exception("WebRTC service not initialized");
    }
    
    try {
      await _peerConnection!.setRemoteDescription(answer);
      log("Remote description set for answer");
    } catch (e) {
      log("Error handling answer: $e");
      _callStatus = 'error';
      _notifyCallStatusChanged();
      rethrow;
    }
  }
  
  // Add received ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      throw Exception("WebRTC service not initialized");
    }
    
    try {
      await _peerConnection!.addCandidate(candidate);
      log("ICE candidate added");
    } catch (e) {
      log("Error adding ICE candidate: $e");
      // ไม่เปลี่ยนสถานะการโทรเนื่องจากบางครั้ง ICE candidate อาจล้มเหลวโดยไม่กระทบการโทร
      rethrow;
    }
  }
  
  // Mute/unmute microphone
  Future<void> toggleMicrophone(bool enabled) async {
    if (_localStream == null) {
      log("No local stream available");
      return;
    }
    
    try {
      final audioTracks = _localStream!.getAudioTracks();
      for (var track in audioTracks) {
        track.enabled = enabled;
      }
      log("Microphone ${enabled ? 'enabled' : 'disabled'}");
    } catch (e) {
      log("Error toggling microphone: $e");
    }
  }
  
  // Check if microphone is muted
  bool isMicrophoneMuted() {
    if (_localStream == null) {
      return true;
    }
    
    final audioTracks = _localStream!.getAudioTracks();
    if (audioTracks.isEmpty) {
      return true;
    }
    
    return !audioTracks.first.enabled;
  }
  
  // Toggle speaker
  Future<void> toggleSpeaker(bool enabled) async {
    try {
      // Note: การเปลี่ยนลำโพงมักจะทำที่ระดับ platform-specific
      // Flutter WebRTC ไม่มี API ตรงๆ สำหรับการเปลี่ยนลำโพง
      // ในสภาพแวดล้อมจริง คุณอาจต้องใช้ platform channel หรือ package เสริม
      log("Speaker toggle requested: ${enabled ? 'enabled' : 'disabled'}");
      
      // ตัวอย่างเท่านั้น - ในการใช้งานจริงต้องใช้ platform-specific implementation
      if (_localStream != null) {
        // อาจมีการใช้ platform channels หรือ plugin เพิ่มเติม
        // เช่น flutter_webrtc_web_platform_interface
      }
    } catch (e) {
      log("Error toggling speaker: $e");
      rethrow;
    }
  }
  
  // Check if call is active
  bool isCallActive() {
    return _isCallActive;
  }
  
  // End active call
  Future<void> endCall() async {
    _callStatus = 'ending';
    _notifyCallStatusChanged();
    await _endCall();
  }
  
  // Internal method to end call and clean up resources
  Future<void> _endCall() async {
    try {
      _callStatus = 'ending';
      _notifyCallStatusChanged();
      
      // Close peer connection
      await _peerConnection?.close();
      
      // Release local media stream
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
      }
      
      // Reset variables
      _localStream = null;
      _pendingCandidates.clear();
      _isCallActive = false;
      
      _callStatus = 'ended';
      _notifyCallStatusChanged();
      
      if (onCallEnded != null) {
        onCallEnded!();
      }
      
      log("Call ended");
      
      // Re-initialize for future calls
      await initialize();
    } catch (e) {
      log("Error ending call: $e");
      _callStatus = 'error';
      _notifyCallStatusChanged();
      // Still try to re-initialize
      try {
        await initialize();
      } catch (_) {
        // Ignore errors during re-initialization
      }
      rethrow;
    }
  }
  
  // ตรวจสอบสถานะการเชื่อมต่อ
  Future<bool> checkConnectivity() async {
    try {
      if (_peerConnection == null) {
        return false;
      }
      
      final connectionState = _peerConnection!.connectionState;
      return connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
    } catch (e) {
      log("Error checking connectivity: $e");
      return false;
    }
  }
  
  // Clean up resources
  Future<void> dispose() async {
    try {
      await _endCall();
      _peerConnection = null;
      _callStatus = 'disposed';
      _notifyCallStatusChanged();
      log("WebRTC service disposed");
    } catch (e) {
      log("Error disposing WebRTC service: $e");
    }
  }
}