import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'isolate_executor.dart';

class IsolatePage extends StatefulWidget {
  const IsolatePage({super.key});

  @override
  State<IsolatePage> createState() => _IsolatePageState();

}

class _IsolatePageState extends State<IsolatePage> {
  final IsolateExecutor isolateExecutor = IsolateExecutor();
  Uint8List? filteredImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if(filteredImage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.memory(
                  filteredImage!,
                  gaplessPlayback: true,
                ),
              ),


            ElevatedButton(
              onPressed: () async {
                Uint8List imageData = (await _loadImage());

                isolateExecutor.start(
                  _isolateClosure,
                  imageData,
                  onData: (message) {
                    if(message is Uint8List){
                      setState(() {
                        filteredImage = message;
                      });
                    }
                  },
                  onError: (message) {
                    print("Error: ${message.toString()}");
                  },
                );

              },
              child: const Text("Isolate.spawn")
            ),

            ElevatedButton(
              onPressed: () async {
                isolateExecutor.pause();
              },
              child: const Text("Pause")
            ),

            ElevatedButton(
              onPressed: () async {
                isolateExecutor.resume();
              },
              child: const Text("Resume")
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _isolateClosure(IsolateData message) async {
    final SendPort sendPort = message.sendPort;

    Future<void> sendImage(img.Image processedImage) async{
      await Future.delayed(const Duration(seconds: 1));
      sendPort.send(Uint8List.fromList(img.encodePng(processedImage)));
    }

    try {
      final originalImage = message.data;
      img.Image? image = img.decodeImage(originalImage);

      if (image != null) {
        //Send Original Image
        sendPort.send(originalImage);

        // 1. Invert Colors
        img.Image processedImage = img.invert(image);
        await sendImage(processedImage);

        // 2. Grayscale
        processedImage = img.grayscale(processedImage);
        await sendImage(processedImage);

        // 3. Sepia Tone
        processedImage = img.sepia(processedImage);
        await sendImage(processedImage);

        // 4. Gaussian Blur
        processedImage = img.gaussianBlur(processedImage, radius: 10);
        await sendImage(processedImage);

        // 5. Brightness Adjustment
        processedImage = img.adjustColor(processedImage, brightness: 1.2);
        await sendImage(processedImage);

        // 6. Emboss Effect
        processedImage = img.emboss(processedImage);
        await sendImage(processedImage);

      }

    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> _loadImage() async {
    final ByteData data = await rootBundle.load('assets/cat.jpg');
    return data.buffer.asUint8List();
  }
}
