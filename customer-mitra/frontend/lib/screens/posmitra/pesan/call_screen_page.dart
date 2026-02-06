import 'package:flutter/material.dart';
import 'dart:async';

class CallScreenPage extends StatefulWidget {
  final String name;
  final String avatar;

  const CallScreenPage({
    Key? key,
    required this.name,
    required this.avatar,
  }) : super(key: key);

  @override
  State<CallScreenPage> createState() => _CallScreenPageState();
}

class _CallScreenPageState extends State<CallScreenPage> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isVideoOn = false;
  
  int seconds = 1;
  int minutes = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
        if (seconds >= 60) {
          minutes++;
          seconds = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    String minuteStr = minutes.toString().padLeft(2, '0');
    String secondStr = seconds.toString().padLeft(2, '0');
    return '$minuteStr : $secondStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Name
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Timer
            Text(
              _formatTime(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(height: 60),
            // Avatar
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  widget.avatar,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Spacer(),
            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  // Row 1: Audio, FaceTime, Mute
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.volume_up,
                        label: 'Audio',
                        isActive: isSpeakerOn,
                        onTap: () {
                          setState(() {
                            isSpeakerOn = !isSpeakerOn;
                          });
                        },
                      ),
                      _buildControlButton(
                        icon: Icons.videocam,
                        label: 'FaceTime',
                        isActive: isVideoOn,
                        onTap: () {
                          setState(() {
                            isVideoOn = !isVideoOn;
                          });
                        },
                      ),
                      _buildControlButton(
                        icon: isMuted ? Icons.mic_off : Icons.mic_none,
                        label: 'Mute',
                        isActive: isMuted,
                        onTap: () {
                          setState(() {
                            isMuted = !isMuted;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Row 2: Keypad, Add, End
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.dialpad,
                        label: 'Keypad',
                        isActive: false,
                        onTap: () {},
                      ),
                      _buildControlButton(
                        icon: Icons.person_add_outlined,
                        label: 'Add',
                        isActive: false,
                        onTap: () {},
                      ),
                      _buildEndCallButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.3)
                  : const Color(0xFF424242),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFEF5350),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'End',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}