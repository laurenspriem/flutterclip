import 'dart:developer' as devtools show log;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutterclip/services/clip/clip_service.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker picker = ImagePicker();
  Image? imageOriginal;
  Uint8List? imageOriginalData;
  Size imageSize = const Size(0, 0);
  late Size imageDisplaySize;
  int stockImageCounter = 0;
  final List<String> _stockImagePaths = [
    'assets/images/stock_images/one_person.jpeg',
    'assets/images/stock_images/one_person2.jpeg',
    'assets/images/stock_images/one_person3.jpeg',
    'assets/images/stock_images/one_person4.jpeg',
    'assets/images/stock_images/group_of_people.jpeg',
  ];

  bool isAnalyzed = false;
  bool isClipLoaded = false;
  bool isPredicting = false;
  late ClipService clip;
  List clipEmbedding = [];

  void _pickImage() async {
    cleanResult();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      imageOriginalData = await image.readAsBytes();
      final decodedImage = await decodeImageFromList(imageOriginalData!);
      setState(() {
        final imagePath = image.path;
        imageOriginal = Image.file(File(imagePath));
        imageSize =
            Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      });
    } else {
      devtools.log('No image selected');
    }
  }

  void _stockImage() async {
    cleanResult();
    final byteData = await rootBundle.load(_stockImagePaths[stockImageCounter]);
    imageOriginalData = byteData.buffer.asUint8List();
    final decodedImage = await decodeImageFromList(imageOriginalData!);
    setState(() {
      imageOriginal = Image.asset(_stockImagePaths[stockImageCounter]);
      imageSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      stockImageCounter = (stockImageCounter + 1) % _stockImagePaths.length;
    });
  }

  void cleanResult() {
    isAnalyzed = false;
    clipEmbedding = [];
    setState(() {});
  }

  void embedImage() async {
    if (imageOriginalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (isAnalyzed || isPredicting) {
      return;
    }

    setState(() {
      isPredicting = true;
    });

    // 'Image plane data length: ${_imageWidget.planes[0].bytes.length}');
    if (!isClipLoaded) {
      clip = await ClipService.create();
      isClipLoaded = true;
    }

    clipEmbedding = clip.predict(imageOriginalData!);

    setState(() {
      isPredicting = false;
      isAnalyzed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    imageDisplaySize = Size(
      MediaQuery.of(context).size.width * 0.8,
      MediaQuery.of(context).size.width * 0.8 * 1.5,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              height: imageDisplaySize.height,
              width: imageDisplaySize.width,
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Image container
                  Center(
                    child: imageOriginal ??
                        const Text(
                          'No image selected',
                          style: TextStyle(color: Colors.white),
                        ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.image,
                          color: Colors.black,
                          size: 16,
                        ),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(color: Colors.black, fontSize: 10),
                        ),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 30),
                          backgroundColor: Colors.grey[200], // Button color
                          foregroundColor: Colors.black,
                          elevation: 1,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.collections,
                          color: Colors.black,
                          size: 16,
                        ),
                        label: const Text(
                          'Stock',
                          style: TextStyle(color: Colors.black, fontSize: 10),
                        ),
                        onPressed: _stockImage,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 30),
                          backgroundColor: Colors.grey[200], // Button color
                          foregroundColor: Colors.black,
                          elevation: 1, // Elevation (shadow)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            isAnalyzed
                ? Text('Clip embedding: ${clipEmbedding.sublist(0, 4)}')
                : const SizedBox(height: 16),
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              child: TextButton(
                onPressed: isAnalyzed ? cleanResult : embedImage,
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isAnalyzed
                    ? const Text('Clean result')
                    : const Text('Embed image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
