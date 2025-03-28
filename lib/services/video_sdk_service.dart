import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:developer';

class VideoSDKService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCSessionDescription? _localSdp;
  
  // Callbacks
  Function(String)? onConnectionStateChange;
  Function(MediaStream)? onRemoteStreamAdd;
  Function(MediaStream)? onRemoteStreamRemove;

  Future<void> initialize() async {
    try {
      // Create peer connection
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      };
      
      _peerConnection = await createPeerConnection(configuration);
      
      // Set up event listeners
      _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
        log("ICE Connection State: ${state.toString()}");
        if (onConnectionStateChange != null) {
          String stateString = "unknown";
          
          switch (state) {
            case RTCIceConnectionState.RTCIceConnectionStateConnected:
              stateString = "connected";
              break;
            case RTCIceConnectionState.RTCIceConnectionStateFailed:
              stateString = "failed";
              break;
            case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
              stateString = "disconnected";
              break;
            default:
              stateString = state.toString().split('.').last;
          }
          
          onConnectionStateChange!(stateString);
        }
      };
      
      _peerConnection?.onAddStream = (MediaStream stream) {
        log("Remote stream added");
        _remoteStream = stream;
        if (onRemoteStreamAdd != null) {
          onRemoteStreamAdd!(stream);
        }
      };
      
      _peerConnection?.onRemoveStream = (MediaStream stream) {
        log("Remote stream removed");
        if (onRemoteStreamRemove != null) {
          onRemoteStreamRemove!(stream);
        }
      };

      // Initialize audio only stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      
      // Add local stream to peer connection
      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });
      
      log("WebRTC initialized successfully");
    } catch (e) {
      log("Error initializing WebRTC: $e");
      rethrow;
    }
  }

  // สำหรับเริ่มการโทรออก (caller)
  Future<void> startCall(String remoteUserId, bool withVideo) async {
    try {
      // Create offer
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      
      // Set local description
      await _peerConnection!.setLocalDescription(offer);
      _localSdp = offer;
      
      // TODO: ส่ง offer ไปยัง remote user ผ่าน signaling server
      // ในที่นี้จำลองว่ามีการส่งสำเร็จ
      log("Call offer created for user: $remoteUserId");
      
      if (onConnectionStateChange != null) {
        onConnectionStateChange!("calling");
      }
    } catch (e) {
      log("Error starting call: $e");
      rethrow;
    }
  }

  // สำหรับรับสาย (callee)
  Future<void> acceptCall(String remoteUserId, RTCSessionDescription remoteSdp) async {
    try {
      // Set remote description
      await _peerConnection!.setRemoteDescription(remoteSdp);
      
      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      });
      
      // Set local description
      await _peerConnection!.setLocalDescription(answer);
      
      // TODO: ส่ง answer กลับไปยัง caller ผ่าน signaling server
      // ในที่นี้จำลองว่ามีการส่งสำเร็จ
      log("Call accepted from user: $remoteUserId");
      
      if (onConnectionStateChange != null) {
        onConnectionStateChange!("connected");
      }
    } catch (e) {
      log("Error accepting call: $e");
      rethrow;
    }
  }

  // เปิด/ปิดไมโครโฟน
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = enabled;
      });
    }
  }

  // เปิด/ปิดลำโพง (ในกรณีของมือถือ)
  Future<void> setSpeakerEnabled(bool enabled) async {
    // Note: This requires platform-specific implementation on mobile
    // For Flutter Web, it's handled differently
    // ในที่นี้เราจำลองว่าสามารถทำได้
    log("Speaker ${enabled ? 'enabled' : 'disabled'}");
  }

  // จบการโทร
  Future<void> dispose() async {
    try {
      // Close peer connection and release resources
      await _peerConnection?.close();
      _peerConnection = null;
      
      // Stop all local tracks
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream = null;
      
      _remoteStream = null;
      _localSdp = null;
      
      log("Call resources released");
    } catch (e) {
      log("Error disposing WebRTC resources: $e");
    }
  }
} 