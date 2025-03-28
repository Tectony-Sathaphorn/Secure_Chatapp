import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Future<void> initialize() async {
    // Create a peer connection
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    _peerConnection = await createPeerConnection(configuration);

    // Add local stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    _peerConnection?.addStream(_localStream!);
  }

  MediaStream? get localStream => _localStream;

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
  }
}