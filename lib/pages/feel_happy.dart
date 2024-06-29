import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class TextSwipeExample extends StatefulWidget {
  const TextSwipeExample({Key? key}) : super(key: key);

  @override
  _TextSwipeExampleState createState() => _TextSwipeExampleState();
}

class _TextSwipeExampleState extends State<TextSwipeExample> {
  int currentIndex = 0;
  ScreenshotController screenshotController = ScreenshotController();

  List<String> texts = [
    "I am grateful for the experiences that bring me happiness",
    "I am capable of finding beauty and joy in the world around me",
    "I am deserving of feeling happy and fulfilled",
    "I choose to surround myself with positivity and good energy",
    "I am worthy of experiencing love and connection",
    "I am confident in my ability to create a life that makes me happy",
    "I am capable of finding happiness in the present moment",
    "I am grateful for all the big and small blessings in my life",
    "I choose to focus on the positive aspects of my life",
    "I am worthy of experiencing joy and happiness",
    "Happiness is my natural state of being",
  ];

  List<Color> pastelColors = [
    Colors.blue[200]!,
    Colors.green[200]!,
    Colors.orange[200]!,
    Colors.pink[200]!,
    Colors.purple[200]!,
    Colors.teal[200]!,
    Colors.yellow[200]!,
    Colors.red[200]!,
    Colors.cyan[200]!,
    Colors.amber[200]!,
    Colors.indigo[200]!,
  ];

  // Set a fixed background color for the Scaffold and AppBar
  Color backgroundColor = Color(0xFFFFF9C4); // Very pale pastel yellow color

  Future<void> shareCardAsImage(int index) async {
    final directory = await getTemporaryDirectory();
    String fileName = '${directory.path}/card_image.png';

    screenshotController
        .captureFromWidget(
      Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: pastelColors[index],
            ),
            padding: EdgeInsets.all(50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“',
                  style: TextStyle(
                    fontSize: 120,
                    fontFamily: 'SpaceGrotesk',
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  texts[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontFamily: 'SpaceGrotesk',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Image.asset(
              'assets/images/mindscape-high-resolution-logo-transparent.png',
              width: 100,
              height: 100,
            ),
          ),
        ],
      ),
    )
        .then((capturedImage) async {
      final file = File(fileName);
      await file.writeAsBytes(capturedImage);
      Share.shareFiles([file.path],
          text: 'Check out this inspirational message!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        centerTitle: true,
        title: Text(
          'Feel Happy',
          style: TextStyle(
            fontSize: 29,
            fontFamily: 'PlaywriteNZ',
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              height: 650,
              child: CardSwiper(
                cardsCount: texts.length,
                cardBuilder: (context, index, x, y) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: pastelColors[index],
                    ),
                    padding: EdgeInsets.all(50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '“',
                          style: TextStyle(
                            fontSize: 120,
                            fontFamily: 'SpaceGrotesk',
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          texts[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'SpaceGrotesk',
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.bookmark),
                              onPressed: () {
                                // Implement bookmark functionality if needed
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () {
                                print(
                                    "Share button pressed for: ${texts[index]}"); // Debug message
                                shareCardAsImage(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                onSwipe: (previous, current, direction) {
                  currentIndex = current!;
                  setState(() {});
                  return true;
                },
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10), // Add a small bottom margin
            alignment: Alignment.center,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement button functionality here
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12, // Adjust vertical padding as needed
                        ),
                      ),
                      child: Text('Button $index'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TextSwipeExample(),
  ));
}
