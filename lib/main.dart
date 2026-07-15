import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Audio player import kiya

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WakeUpVisualTimer(),
  ));
}

class WakeUpVisualTimer extends StatefulWidget {
  const WakeUpVisualTimer({super.key});

  @override
  State<WakeUpVisualTimer> createState() => _WakeUpVisualTimerState();
}

class _WakeUpVisualTimerState extends State<WakeUpVisualTimer>
    with SingleTickerProviderStateMixin {
  // Time states
  int hours = 0;
  int minutes = 0;
  int seconds = 30;

  int _totalTimeInSeconds = 30;
  int _currentTimeInSeconds = 30;
  bool _isRunning = false;
  AnimationController? _controller;
  Timer? _timer;

  // Audio Player Instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Customization & Settings States
  final TextEditingController _labelController =
  TextEditingController(text: "Bhai Uth Jao! Timer khatam ho gaya hai.");
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _tickSoundEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalTimeInSeconds),
    );
    _controller?.value = 1.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _labelController.dispose();
    _audioPlayer.dispose(); // Player dispose karna zaroori hai
    super.dispose();
  }

  void _updateTime({int? h, int? m, int? s}) {
    if (_isRunning) return;

    setState(() {
      if (h != null) hours = (hours + h).clamp(0, 23);
      if (m != null) minutes = (minutes + m).clamp(0, 59);
      if (s != null) seconds = (seconds + s).clamp(0, 59);

      _totalTimeInSeconds = (hours * 3600) + (minutes * 60) + seconds;
      _currentTimeInSeconds = _totalTimeInSeconds;
    });

    _controller?.value = 1.0;
  }

  void _startTimer() {
    if (_isRunning || _totalTimeInSeconds <= 0) return;

    setState(() {
      _isRunning = true;
    });

    _controller!.duration = Duration(seconds: _totalTimeInSeconds);
    _controller?.reverse(from: _currentTimeInSeconds / _totalTimeInSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTimeInSeconds > 0) {
        setState(() {
          _currentTimeInSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        _triggerAlarmEffects(); // Alarm bajega yahan
        _showTimesUpDialog();
      }
    });
  }

  // Real Sound Trigger Function
  void _triggerAlarmEffects() async {
    if (_soundEnabled) {
      try {
        // Assets folder se alarm.mp3 play karega
        await _audioPlayer.play(AssetSource('audio/alarm.mp3'));
      } catch (e) {
        debugPrint("Sound play karne mein error: $e");
      }
    }
    if (_vibrationEnabled) {
      debugPrint("📳 VIBRATING DEVICE... Bzzzz Bzzzz!");
    }
  }

  void _showTimesUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.alarm, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text("⏰ Time's Up!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            _labelController.text.isNotEmpty
                ? _labelController.text
                : "Timer khatam ho gaya hai!",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetTimer(); // OK dabate hi sound band ho jayega
              },
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _resetTimer() {
    _timer?.cancel();
    _controller?.stop();
    _audioPlayer.stop(); // Sound ko turant band karne ke liye

    setState(() {
      _isRunning = false;
      hours = 0;
      minutes = 0;
      seconds = 30;
      _totalTimeInSeconds = 30;
      _currentTimeInSeconds = 30;
    });
    _controller!.duration = const Duration(seconds: 30);
    _controller?.value = 1.0;
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, size: 28, color: Colors.blue),
                      SizedBox(width: 10),
                      Text("Timer Settings",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  SwitchListTile(
                    title: const Text("Alarm Sound", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Timer complete hone par sound bajayein"),
                    value: _soundEnabled,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setModalState(() => _soundEnabled = val);
                      setState(() => _soundEnabled = val);
                    },
                  ),
                  SwitchListTile(
                    title: const Text("Vibration", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Time up hone par phone vibrate karein"),
                    value: _vibrationEnabled,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setModalState(() => _vibrationEnabled = val);
                      setState(() => _vibrationEnabled = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}";
  }

  Widget buildTimerSection(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: _isRunning ? Colors.white60 : Colors.grey,
                fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.arrow_drop_up, size: 36, color: Colors.blue),
          onPressed: () => onChanged(1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isRunning ? Colors.white12 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isRunning ? Colors.white : Colors.black87),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down, size: 36, color: Colors.blue),
          onPressed: () => onChanged(-1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = _isRunning ? const Color(0xFF1A1F2C) : Colors.white;
    Color textColor = _isRunning ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Visual WakeUp Timer"),
        backgroundColor: _isRunning ? const Color(0xFF131722) : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            tooltip: "Settings",
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: backgroundColor,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                if (!_isRunning)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: TextField(
                      controller: _labelController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: "Alarm Message (Custom Title)",
                        prefixIcon: const Icon(Icons.edit_note, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 230,
                  height: 230,
                  child: AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, child) {
                      Color needleColor = Color.lerp(
                          Colors.red, Colors.green, _controller!.value) ??
                          Colors.green;
                      return CustomPaint(
                        painter: ClockPainter(
                          progress: _controller!.value,
                          needleColor: needleColor,
                          isRunning: _isRunning,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _formatTime(_currentTimeInSeconds),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 15),
                AnimatedOpacity(
                  opacity: _isRunning ? 0.2 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  child: IgnorePointer(
                    ignoring: _isRunning,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildTimerSection("Hours", hours, (val) => _updateTime(h: val)),
                          buildTimerSection("Minutes", minutes, (val) => _updateTime(m: val)),
                          buildTimerSection("Seconds", seconds, (val) => _updateTime(s: val)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: (_isRunning || _totalTimeInSeconds <= 0) ? null : _startTimer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Start", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: _resetTimer,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        side: BorderSide(color: _isRunning ? Colors.blue.shade300 : Colors.blue, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Reset",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isRunning ? Colors.blue.shade300 : Colors.blue)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final double progress;
  final Color needleColor;
  final bool isRunning;

  ClockPainter({required this.progress, required this.needleColor, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2;

    Paint silverPaint = Paint()
      ..color = isRunning ? Colors.grey.shade700 : Colors.grey.shade300
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, silverPaint);

    if (progress > 0) {
      Paint sweepPaint = Paint()
        ..color = needleColor.withOpacity(0.15)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 5),
        -math.pi / 2,
        progress * 2 * math.pi,
        true,
        sweepPaint,
      );
    }

    Paint tickPaint = Paint()
      ..color = isRunning ? Colors.white30 : Colors.grey.shade400
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      double angle = (i * 30) * (math.pi / 180);
      Offset startTick = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );
      Offset endTick = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(startTick, endTick, tickPaint);
    }

    Paint needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round;

    double angle = (progress * 2 * math.pi) - (math.pi / 2);
    double needleLength = radius * 0.85;

    Offset needleEnd = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    Paint centerPaint = Paint()..color = needleColor;
    canvas.drawCircle(center, 8, centerPaint);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.isRunning != isRunning;
  }
}