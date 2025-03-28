import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/call_manager.dart';
import '../../services/webrtc_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer';

class VoiceCallPageWidget extends StatefulWidget {
  final String remoteName;
  final String remoteUserId;
  final bool isIncoming;
  final RTCSessionDescription? incomingOffer;
  final String? remoteProfileImage;

  const VoiceCallPageWidget({
    Key? key,
    required this.remoteName,
    required this.remoteUserId,
    required this.isIncoming,
    this.incomingOffer,
    this.remoteProfileImage,
  }) : super(key: key);

  @override
  State<VoiceCallPageWidget> createState() => _VoiceCallPageWidgetState();
}

class _VoiceCallPageWidgetState extends State<VoiceCallPageWidget> {
  final WebRTCService _webRTCService = WebRTCService();
  final CallManager _callManager = CallManager();
  
  bool _isMicEnabled = true;
  bool _isSpeakerEnabled = true;
  String _callDuration = '00:00';
  Timer? _callTimer;
  int _seconds = 0;
  String _callStatus = 'Connecting...';
  bool _isCallActive = true;
  MediaStream? _remoteStream;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus.isGranted) {
      await _initializeServices();
      _initializeCall();
    } else {
      setState(() {
        _callStatus = 'Microphone permission denied';
      });
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Microphone permission is required for voice calls.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  Future<void> _initializeServices() async {
    try {
      // Set up callbacks for WebRTC events
      _webRTCService.onRemoteStreamAvailable = (MediaStream stream) {
        setState(() {
          _remoteStream = stream;
          _callStatus = 'Connected';
          if (_callTimer == null) {
            _startCallTimer();
          }
        });
      };
      
      _webRTCService.onConnectionStateChange = (RTCPeerConnectionState state) {
        String statusText;
        
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            statusText = 'Connected';
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            statusText = 'Connection failed';
            _endCall();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            statusText = 'Disconnected';
            _endCall();
            break;
          default:
            statusText = state.toString().split('.').last;
        }
        
        setState(() {
          _callStatus = statusText;
        });
      };
      
      log("Services initialized successfully");
    } catch (e) {
      log("Error initializing services: $e");
      setState(() {
        _callStatus = 'Error: $e';
      });
    }
  }

  Future<void> _initializeCall() async {
    setState(() {
      _callStatus = widget.isIncoming ? 'Incoming call...' : 'Calling...';
    });
    
    try {
      _startCallTimer();
    } catch (e) {
      log("Error initializing call: $e");
      setState(() {
        _callStatus = 'Error: $e';
      });
      _endCall();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCallActive && mounted) {
        setState(() {
          _seconds++;
          _callDuration = '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });
  }

  Future<void> _toggleMic() async {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
    
    await _callManager.toggleMicrophone(_isMicEnabled);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    
    await _webRTCService.toggleSpeaker(_isSpeakerEnabled);
  }

  Future<void> _endCall() async {
    if (!_isCallActive) return;
    
    setState(() {
      _isCallActive = false;
      _callStatus = 'Call ended';
    });
    
    _callTimer?.cancel();
    
    try {
      await _callManager.endCall();
    } catch (e) {
      log("Error ending call: $e");
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when trying to exit
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('End Call?'),
            content: const Text('Are you sure you want to end this call?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('End Call'),
              ),
            ],
          ),
        );
        if (shouldPop == true) {
          _endCall();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.remoteProfileImage != null
                          ? NetworkImage(widget.remoteProfileImage!)
                          : null,
                      child: widget.remoteProfileImage == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.remoteName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _callStatus,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _callDuration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section with controls
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
                      label: 'Mute',
                      onPressed: _toggleMic,
                    ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      onPressed: _endCall,
                      backgroundColor: Colors.red,
                    ),
                    _buildControlButton(
                      icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
                      label: 'Speaker',
                      onPressed: _toggleSpeaker,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? Colors.white24,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 