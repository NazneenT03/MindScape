import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MaterialApp(
    home: MyJournalPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class DoodlePainter extends CustomPainter {
  final Map<Color, List<Offset?>> pointsMap;
  final Color currentColor;
  final bool isErasing;

  DoodlePainter({
    required this.pointsMap,
    required this.currentColor,
    required this.isErasing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    pointsMap.forEach((color, points) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.0;

      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
      }
    });
  }

  @override
  bool shouldRepaint(DoodlePainter oldDelegate) {
    return oldDelegate.currentColor != currentColor ||
        oldDelegate.pointsMap != pointsMap ||
        oldDelegate.isErasing != isErasing;
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    const double gap = 10.0;
    const double dashWidth = 5.0;

    // Calculate number of lines based on available height
    double lineHeight = 40.0; // Height of each line
    int numberOfLines = (size.height / (lineHeight + gap)).ceil();

    // Calculate the total height needed to cover the screen
    double totalHeightNeeded = numberOfLines * (lineHeight + gap);

    // Adjust numberOfLines if it doesn't cover the entire height
    if (totalHeightNeeded < size.height) {
      numberOfLines +=
          ((size.height - totalHeightNeeded) / (lineHeight + gap)).ceil();
    }

    for (int i = 0; i < numberOfLines; i++) {
      double y = i * (lineHeight + gap);
      double startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DottedLinePainter oldDelegate) => false;
}

class MyJournalPage extends StatefulWidget {
  const MyJournalPage({super.key});

  @override
  _MyJournalPageState createState() => _MyJournalPageState();
}

class _MyJournalPageState extends State<MyJournalPage> {
  String content = '';
  List<String> imagePaths = []; // List to store paths of selected images
  String? audioPath;
  List<Offset?> points = [];
  late AudioRecorder recorder;
  bool isRecording = false;
  bool isErasing = false;
  Color currentColor = Colors.black;
  Map<Color, List<Offset?>> pointsMap = {};
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    recorder = AudioRecorder();
    initRecorder();
    // Initialize points map with default color
    pointsMap[currentColor] = [];
  }

  Future<void> initRecorder() async {
    await recorder.init();
  }

  @override
  void dispose() {
    _player.dispose();
    recorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final images = await ImagePicker().pickMultiImage();
    setState(() {
      imagePaths = images.map((image) => image.path).toList();
    });
  }

  Future<void> _showBrushOptions(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BrushOptionsDialog(
          onSelected: (option, color) {
            setState(() {
              if (option == BrushOption.eraser) {
                isErasing = true; // Toggle to erasing mode
              } else if (option == BrushOption.colorPicker) {
                currentColor = color ?? currentColor;
                isErasing = false;

                // Initialize points for the selected color if not already done
                if (!pointsMap.containsKey(currentColor)) {
                  pointsMap[currentColor] = [];
                }
              }
            });
            Navigator.pop(context); // Close the dialog
          },
        );
      },
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    Color selectedColor = currentColor;

    Color? newColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );

    if (newColor != null) {
      setState(() {
        currentColor = newColor;
        isErasing = false;
      });
    }
  }

  Future<void> _showRecordingOptions(BuildContext context) async {
    if (recorder.isRecording && !recorder.isPaused) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Recording'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.pause),
                    title: const Text('Pause'),
                    onTap: () {
                      _pauseRecording();
                      Navigator.pop(context); // Close the current dialog
                      _showResumeDialog(context); // Show the resume dialog
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.stop),
                    title: const Text('Stop'),
                    onTap: () {
                      Navigator.pop(context); // Close the dialog
                      _stopRecording();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _showResumeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recording Paused'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Resume'),
                  onTap: () {
                    _resumeRecording();
                    Navigator.pop(context); // Close the resume dialog
                    _showRecordingOptions(
                        context); // Show the pause/stop dialog again
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playAudio() async {
    try {
      if (audioPath != null && await File(audioPath!).exists()) {
        await _player.setFilePath(audioPath!);
        await _player.play();
        setState(() {}); // Ensure state is updated after starting playback
      } else {
        if (kDebugMode) {
          print('File does not exist or audioPath is null: $audioPath');
        }
        // Handle the case where the file does not exist or audioPath is null
      }
    } catch (e) {
      print('Error playing audio: $e');
      // Handle other potential errors, such as permissions or playback failures
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _player.stop();
      setState(() {}); // Ensure state is updated after stopping playback
    } catch (e) {
      print('Error stopping audio: $e');
      // Handle error as needed
    }
  }

  Future<void> _recordAudio() async {
    setState(() {
      isRecording = true;
    });
    await recorder.start();
    await _showRecordingOptions(context);
  }

  Future<void> _pauseRecording() async {
    await recorder.pause();
    setState(() {
      isRecording = true;
    });
    await _showRecordingOptions(context);
  }

  Future<void> _resumeRecording() async {
    await recorder.resume();
    setState(() {
      isRecording = true;
    });
    await _showRecordingOptions(context);
  }

  Future<void> _stopRecording() async {
    String? filePath = await recorder.stop();

    if (filePath != null && filePath.isNotEmpty) {
      setState(() {
        audioPath = filePath;
        isRecording = false;
      });
      setState(() {
        content = filePath; // Update content with the file path
      });
    } else {
      print('Error: File path is null or empty');
      // Handle the error as needed, e.g., show an error message to the user
    }

    await _player.stop();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      if (isErasing) {
        for (var colorPoints in pointsMap.values) {
          for (int i = 0; i < colorPoints.length; i++) {
            if (colorPoints[i] != null &&
                (colorPoints[i]! - details.localPosition).distanceSquared <
                    100.0) {
              colorPoints[i] =
                  null; // Erase the point if within the erasing threshold
            }
          }
        }
      } else {
        pointsMap[currentColor]!.add(details.localPosition);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      pointsMap[currentColor]!.add(null);
    });
  }

  void _handleDeleteImage(int index) {
    setState(() {
      imagePaths.removeAt(index);
    });
  }

  void _handleDeleteAudio() {
    setState(() {
      audioPath = null;
      _stopAudio(); // Stop audio playback if playing
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> imageWidgets = [];
    List<Widget> audioWidgets = [];

    // Display selected images with delete icon
    for (int index = 0; index < imagePaths.length; index++) {
      final imagePath = imagePaths[index];
      Widget imageWidget = Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Stack(
          children: [
            Image.file(
              File(imagePath),
              width: 300, // Adjust as needed
              height: 300, // Adjust as needed
              fit: BoxFit.contain, // or BoxFit.cover, BoxFit.fill, etc.
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8.0), // Adjust radius as needed
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete,
                          color: Color.fromARGB(255, 142, 191, 231)),
                      onPressed: () => _handleDeleteImage(index),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      imageWidgets.add(imageWidget);
    }

    // Audio control toggle below images
    if (audioPath != null) {
      Widget audioWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _player.playing ? Icons.replay : Icons.play_arrow,
              ),
              onPressed: () {
                if (_player.playing) {
                  _stopAudio();
                } else {
                  _playAudio();
                }
              },
            ),
            Text(
              _player.playing ? 'Replay' : 'Play Audio',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlaywriteUSTrad',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8.0), // Adjust radius as needed
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete,
                        color: Color.fromARGB(255, 142, 196, 240)),
                    onPressed: () => _handleDeleteAudio(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      audioWidgets.add(audioWidget);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Journal',
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'PlaywriteUSTrad',
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB3E5FC),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 150.0,
                    width: double.infinity,
                    child: Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/images/clouds.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 1.0),
                        Text(
                          'Today, ${DateTime.now().toString().split(' ').first}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontFamily: 'PlaywriteNZ',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          initialValue: content,
                          onChanged: (value) {
                            setState(() {
                              content = value;
                            });
                          },
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Write your thoughts...',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontFamily: 'PlaywriteUSTrad',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Display selected images with gaps between them
                        Column(
                          children: imageWidgets,
                        ),
                        // Audio control toggle below images
                        Column(
                          children: audioWidgets,
                        ),
                        GestureDetector(
                          onPanUpdate: _handlePanUpdate,
                          onPanEnd: _handlePanEnd,
                          child: SizedBox(
                            height: 300.0,
                            child: CustomPaint(
                              painter: DoodlePainter(
                                pointsMap: pointsMap,
                                currentColor: currentColor,
                                isErasing: isErasing,
                              ),
                              child: Container(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: CircleBorder(),
                color: Color.fromARGB(255, 230, 230, 231),
              ),
              child: IconButton(
                icon: Icon(Icons.check, color: Colors.black),
                onPressed: () {
                  // Implement save functionality here
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBrushOptions(context),
        child: const Icon(Icons.brush),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
              ),
              IconButton(
                onPressed: () => _recordAudio(),
                icon: Icon(_player.playing ? Icons.stop : Icons.mic),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

enum BrushOption {
  eraser,
  colorPicker,
}

class BrushOptionsDialog extends StatelessWidget {
  final Function(BrushOption, Color?) onSelected;

  const BrushOptionsDialog({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Brush Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Eraser'),
            onTap: () => onSelected(BrushOption.eraser, null),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Color Picker'),
            onTap: () async {
              Color? color = await _pickColor(context);
              if (color != null) {
                onSelected(BrushOption.colorPicker, color);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<Color?> _pickColor(BuildContext context) async {
    Color selectedColor = Colors.black;
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                selectedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );
  }
}

class AudioRecorder {
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isPaused = false;
  bool _isRecording = false; // Added

  bool get isRecording => _isRecording; // Getter for isRecording

  bool get isPaused => _isPaused; // Getter for isPaused

  Future<void> init() async {
    _recorder = FlutterSoundRecorder();
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder!.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> start() async {
    if (!_isRecorderInitialized || _recorder == null) {
      throw Exception('Recorder is not initialized properly');
    }

    try {
      await _recorder!.startRecorder(
        toFile: 'audio.aac',
        codec: Codec.aacADTS,
      );
      _isRecording = true; // Update recording state
    } catch (e) {
      print('Error starting recorder: $e');
      // Handle error as needed
      rethrow;
    }
  }

  Future<void> pause() async {
    if (!_isRecorderInitialized || _recorder == null) {
      return;
    }

    try {
      await _recorder!.pauseRecorder();
      _isPaused = true;
    } catch (e) {
      print('Error pausing recorder: $e');
      // Handle error as needed
    }
  }

  Future<void> resume() async {
    if (!_isRecorderInitialized || _recorder == null) {
      return;
    }

    try {
      await _recorder!.resumeRecorder();
      _isPaused = false;
    } catch (e) {
      print('Error resuming recorder: $e');
      // Handle error as needed
    }
  }

  Future<String?> stop() async {
    if (!_isRecorderInitialized || _recorder == null) {
      return null;
    }

    try {
      String? path = await _recorder!.stopRecorder();
      _isRecording = false; // Update recording state
      _isPaused = false; // Reset pause state when stopping

      if (path == null || path.isEmpty) {
        print('Error: File path is null or empty');
        return null;
      }

      return path;
    } catch (e) {
      print('Error stopping recorder: $e');
      // Handle error as needed
      return null;
    }
  }

  void dispose() {
    if (_isRecorderInitialized) {
      _recorder!.closeRecorder();
    }
    _recorder = null;
    _isRecorderInitialized = false;
  }
}
