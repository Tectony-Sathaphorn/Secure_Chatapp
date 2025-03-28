 import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../services/video_sdk_service.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCallPageWidget extends StatefulWidget {
  final String remoteName;
  final String remoteUserId;
  final bool isIncoming;
  final String? remoteProfileImage;

  const VoiceCallPageWidget({
    Key? key,
    required this.remoteName,
    required this.remoteUserId,
    required this.isIncoming,
    this.remoteProfileImage,
  }) : super(key: key);

  @override
  State<VoiceCallPageWidget> createState() => _VoiceCallPageWidgetState();
}

class _VoiceCallPageWidgetState extends State<VoiceCallPageWidget> {
  final VideoSDKService _videoSDKService = VideoSDKService();
  bool _isMicEnabled = true;
  bool _isSpeakerEnabled = true;
  String _callDuration = '00:00';
  Timer? _callTimer;
  int _seconds = 0;
  String _callStatus = 'Connecting...';
  bool _isCallActive = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus.isGranted) {
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

  Future<void> _initializeCall() async {
    try {
      if (widget.isIncoming) {
        // Handle incoming call
        await _videoSDKService.acceptCall(widget.remoteUserId, RTCSessionDescription('answer', ''));
      } else {
        // Start outgoing call
        await _videoSDKService.startCall(widget.remoteUserId, false);
      }

      // Set up call state listeners
      _videoSDKService.onConnectionStateChange = (state) {
        setState(() {
          _callStatus = state;
          if (state == 'connected') {
            _startCallTimer();
          } else if (state == 'disconnected' || state == 'failed') {
            _endCall();
          }
        });
      };

      _videoSDKService.onRemoteStreamAdd = (stream) {
        // Handle remote audio stream
        setState(() {
          _callStatus = 'Connected';
        });
      };

      _videoSDKService.onRemoteStreamRemove = (stream) {
        // Handle remote stream removal
        setState(() {
          _callStatus = 'Disconnected';
        });
        _endCall();
      };
    } catch (e) {
      setState(() {
        _callStatus = 'Error: $e';
      });
      _endCall();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCallActive) {
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
    await _videoSDKService.setMicrophoneEnabled(_isMicEnabled);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    await _videoSDKService.setSpeakerEnabled(_isSpeakerEnabled);
  }

  Future<void> _endCall() async {
    _isCallActive = false;
    _callTimer?.cancel();
    await _videoSDKService.dispose();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _videoSDKService.dispose();
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