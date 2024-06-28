// ignore_for_file: unused_import, unused_field

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
      title: 'Boost Mood App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const BoostMood(),
    );
  }
}

class BoostMood extends StatefulWidget {
  const BoostMood({Key? key}) : super(key: key);

  @override
  _BoostMoodState createState() => _BoostMoodState();
}

class _BoostMoodState extends State<BoostMood> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  bool _showCountdown = false;
  bool _showEndText = false;
  String _countdownText = "Ready";
  bool _isPaused = false;
  Timer? _countdownTimer;
  Timer? _holdTimer;
  int _countdownValue = 5;
  var _breathe = 0.0;
  bool _isHolding = false;
  bool _holdAfterInhale = true;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startHold(isAfterInhale: true);
        Vibrate.feedback(FeedbackType.success); // Vibration for inhale
      } else if (status == AnimationStatus.dismissed) {
        _startHold(isAfterInhale: false);
        Vibrate.feedback(FeedbackType.success); // Vibration for exhale
      }
    });

    _breathingController.addListener(() {
      setState(() {
        _breathe = _breathingController.value;
      });
    });

    _audioPlayer = AudioPlayer()
      ..setAsset('assets/audio/deep-meditation-192828 (mp3cut.net).mp3');

    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _breathingController.stop();
        setState(() {
          _isAudioPlaying = false;
          _showEndText = true;
        });
      }
    });
  }

  void _resetAndStartCountdown() {
    _resetState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _audioPlayer.dispose();
    _countdownTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold({required bool isAfterInhale}) {
    setState(() {
      _isHolding = true;
      _holdAfterInhale = isAfterInhale;
    });
    _breathingController.stop();
    _holdTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _isHolding = false;
      });
      if (isAfterInhale) {
        _breathingController.reverse();
      } else {
        _breathingController.forward();
      }
    });
  }

  void _resetState() {
    setState(() {
      _isAudioPlaying = false;
      _showCountdown = false;
      _showEndText = false;
      _countdownText = "Ready";
      _breathingController.stop();
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

    _audioPlayer.stop();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownValue > 1) {
          _countdownValue--;
          _countdownText = _countdownValue.toString();
        } else {
          _countdownText = "";
          _showCountdown = false;
          _isAudioPlaying = true;
          _breathingController.forward();
          _audioPlayer.play();
          _animationStarted = true;
          timer.cancel();
        }
      });
    });
  }

  void _showExitDialog() {
    _pause();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/mindscape-high-resolution-logo-transparent.png',
                height: 100,
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
                _resume();
              },
              child: const Text(
                "Go Back",
                style: TextStyle(fontFamily: 'PlaywriteNZ'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
        _resume();
      }
    });
  }

  void _pause() {
    _breathingController.stop();
    _audioPlayer.pause();
    _countdownTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resume() {
    if (_showCountdown) {
      _startCountdown();
    } else if (_isHolding) {
      _startHold(isAfterInhale: _holdAfterInhale);
    } else {
      _breathingController.forward();
      _audioPlayer.play();
    }
    setState(() {
      _isPaused = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final size = 200.0 - 100.0 * _breathe;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color.fromARGB(255, 215, 185, 233),
      appBar: AppBar(
        title: const Text(
          'Boost Your Mood',
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
                  Column(
                    children: [
                      Container(
                        width: size,
                        height: size,
                        child: Material(
                          borderRadius: BorderRadius.circular(size / 3),
                          color: Colors.deepPurple,
                          child: Image.asset(
                            'assets/images/icons8-easy-listening-50.png',
                            width: 100,
                            height: 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      AnimatedBuilder(
                        animation: _breathingController,
                        builder: (context, child) {
                          return Text(
                            _isAudioPlaying
                                ? _isHolding
                                    ? "Hold"
                                    : _breathingController.status ==
                                            AnimationStatus.forward
                                        ? "Inhale"
                                        : "Exhale"
                                : "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontFamily: 'ChakraPetch',
                            ),
                          );
                        },
                      ),
                    ],
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
                      onReplay: _resetAndStartCountdown, // Pass the callback
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showExitDialog,
                      child: const Text(
                        'I Am Done',
                        style: TextStyle(fontFamily: 'Rowdies'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_showEndText)
                      Text(
                        "Well done! One breathe at a time.",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'PlaywriteNZ',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Controls extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final VoidCallback startCountdown;
  final VoidCallback onReplay;
  final bool isAudioPlaying;

  const Controls({
    Key? key,
    required this.audioPlayer,
    required this.startCountdown,
    required this.isAudioPlaying,
    required this.onReplay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (audioPlayer.playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                color: Colors.white,
                onPressed: startCountdown,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                color: Colors.white,
                onPressed: () {}, // Disable the pause button
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                color: Colors.white,
                onPressed: onReplay, // Call the onReplay callback
              );
            }
          },
        ),
      ],
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
