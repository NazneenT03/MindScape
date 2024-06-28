import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deep Breathing App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const DeepBreathe(),
    );
  }
}

class DeepBreathe extends StatefulWidget {
  const DeepBreathe({Key? key}) : super(key: key);

  @override
  _DeepBreatheState createState() => _DeepBreatheState();
}

class _DeepBreatheState extends State<DeepBreathe>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  bool _showCountdown = false;
  bool _showEndText = false;
  String _countdownText = "Ready";
  bool _isPaused = false;
  Timer? _countdownTimer;
  int _countdownValue = 5;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = Tween(begin: 2.0, end: 15.0).animate(_animationController);

    _audioPlayer = AudioPlayer()
      ..setAsset(
          'assets/audio/healing-meditation-ringing-background-music-for-meditation-200223 (mp3cut.net).mp3');

    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _animationController.stop();
        setState(() {
          _isAudioPlaying = false;
          _showEndText = true;
        });
      }
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        _vibrate("breathe in");
      } else if (status == AnimationStatus.reverse) {
        _vibrate("breathe out");
      }
    });
  }

  void _vibrate(String phase) {
    if (Vibrate.canVibrate == true) {
      if (phase == "breathe in") {
        Vibrate.vibrateWithPauses([
          const Duration(milliseconds: 1000),
          const Duration(milliseconds: 500),
          const Duration(milliseconds: 1000),
        ]);
      } else if (phase == "breathe out") {
        Vibrate.vibrateWithPauses([
          const Duration(milliseconds: 500),
          const Duration(milliseconds: 1000),
          const Duration(milliseconds: 500),
        ]);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  void _resetState() {
    setState(() {
      _isAudioPlaying = false;
      _showCountdown = false;
      _showEndText = false;
      _countdownText = "Ready";
      _animationController.stop();
      _audioPlayer.seek(Duration.zero);
    });
  }

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownText = "Get Ready";
      _isAudioPlaying = false;
      _countdownValue = 5;
    });

    _audioPlayer.stop(); // Stop the audio before starting countdown

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownValue > 1) {
          _countdownValue--;
          _countdownText = _countdownValue.toString();
        } else {
          _countdownText = "";
          _showCountdown = false;
          _isAudioPlaying = true;
          _animationController.repeat(reverse: true);
          _audioPlayer.play();
          timer.cancel();
        }
      });
    });
  }

  void _resetAndStartCountdown() {
    _resetState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _startCountdown();
    });
  }

  void _showExitDialog() {
    _pause(); // Pause the current state
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/mindscape-high-resolution-logo-transparent.png', // Replace with your image path
                height: 100, // Adjust height as needed
              ),
              const SizedBox(height: 16),
              const Text(
                "Are you sure you want to exit?",
                style: TextStyle(fontFamily: 'PlaywriteUSTrad'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resume(); // Resume the state when "Go Back" is pressed
              },
              child: const Text(
                "Go Back",
                style: TextStyle(fontFamily: 'PlaywriteNZ'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Add any other action you want to perform on "I'm Done"
              },
              child: const Text(
                "I'm Done",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontFamily: 'PlaywriteNZ',
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (_isPaused) {
        _resume(); // Ensure the state resumes if the dialog is dismissed
      }
    });
  }

  void _pause() {
    _animationController.stop();
    _audioPlayer.pause();
    _countdownTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resume() {
    if (_showCountdown) {
      _startCountdown(); // Resume countdown if it was active
    } else {
      _animationController.repeat(reverse: true); // Resume animation
      _audioPlayer.play(); // Resume audio playback
    }
    setState(() {
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(255, 215, 185, 233),
      appBar: AppBar(
        title: const Text(
          'Deep Breathing',
          style: TextStyle(
            fontFamily: 'PlaywriteUSTrad',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 80),
                if (_showCountdown)
                  Text(
                    _countdownText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontFamily: 'Rowdies',
                    ),
                  )
                else
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color.fromARGB(255, 215, 185, 233),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(130, 45, 4, 46),
                                  blurRadius: _animation.value,
                                  spreadRadius: _animation.value,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/icons8-meditation-64.png',
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            _isAudioPlaying
                                ? _animationController.status ==
                                        AnimationStatus.forward
                                    ? "Breathe In"
                                    : "Breathe Out"
                                : "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'ChakraPetch',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Container(
                      width: 350,
                      child: StreamBuilder<PositionData>(
                        stream: _positionDataStream,
                        builder: (context, snapshot) {
                          final positionData = snapshot.data;
                          return ProgressBar(
                            barHeight: 4,
                            baseBarColor: Colors.grey[600],
                            bufferedBarColor: Colors.grey,
                            progressBarColor:
                                const Color.fromARGB(130, 45, 4, 46),
                            thumbColor: const Color.fromARGB(130, 45, 4, 46),
                            timeLabelTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            progress: positionData?.position ?? Duration.zero,
                            buffered:
                                positionData?.bufferedPosition ?? Duration.zero,
                            total: positionData?.duration ?? Duration.zero,
                            onSeek: (duration) {}, // Disable seeking
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Controls(
                      audioPlayer: _audioPlayer,
                      startCountdown: _resetAndStartCountdown,
                      isAudioPlaying: _isAudioPlaying,
                    ),
                    const SizedBox(height: 20),
                    if (_showEndText)
                      const Column(
                        children: [
                          Text(
                            "Great Job!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'PlaywriteUSTrad',
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "\"Be present. This is it. This is life.\" - Eckhart Tolle",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'IndieFlower',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: 20,
            child: GestureDetector(
              onTap: _showExitDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "I Am Done",
                    style: TextStyle(
                      fontFamily: 'Rowdies',
                      fontSize: 18,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PositionData {
  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class Controls extends StatelessWidget {
  const Controls({
    Key? key,
    required this.audioPlayer,
    required this.startCountdown,
    required this.isAudioPlaying,
  }) : super(key: key);

  final AudioPlayer audioPlayer;
  final Function startCountdown;
  final bool isAudioPlaying;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        if (!(playing ?? false) && !isAudioPlaying) {
          return IconButton(
            onPressed: () => startCountdown(),
            iconSize: 50,
            color: Colors.white,
            icon: const Icon(Icons.play_arrow_rounded),
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            onPressed: () {}, // Disable pause functionality
            iconSize: 50,
            color: Colors.white,
            icon: const Icon(Icons.pause_rounded),
          );
        } else {
          return IconButton(
            onPressed: () {
              startCountdown();
            },
            iconSize: 50,
            color: Colors.white,
            icon: const Icon(Icons.replay_rounded),
          );
        }
      },
    );
  }
}
