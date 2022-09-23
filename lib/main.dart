import 'dart:io';

import 'package:download/download.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as crop;
import 'package:path/path.dart' as path;
import 'package:widgets_to_image/widgets_to_image.dart';

void main() {
  runApp(const MyApp());
}

class CropInputModel {
  final crop.Image imgBytes;
  final int x;
  final int y;
  final int pixelHeight;
  final int pixelWidth;

  CropInputModel({
    required this.imgBytes,
    required this.x,
    required this.y,
    required this.pixelHeight,
    required this.pixelWidth,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gif crop test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Gif crop test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? imageBytesRoot;
  Uint8List? croppedImageBytesRoot;
  Uint8List? widgetToImageRoot;
  String? fileNameRoot;
  TextEditingController? cX = TextEditingController(text: '0');
  TextEditingController? cY = TextEditingController(text: '0');
  TextEditingController? cHeight = TextEditingController(text: '300');
  TextEditingController? cwidth = TextEditingController(text: '300');

  WidgetsToImageController cWTI = WidgetsToImageController();

  Uint8List cropImage(CropInputModel input) {
    var cropedImage = crop.copyCrop(
      input.imgBytes,
      input.x,
      input.y,
      input.pixelWidth,
      input.pixelHeight,
    );
    return Uint8List.fromList(crop.encodePng(
      cropedImage,
    ));
  }

  Uint8List? cropImageAnim({
    required Uint8List imgFileBytes,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    crop.Animation? anim = crop.decodeAnimation(imgFileBytes);
    if (anim != null) {
      for (int f = 0; f < anim.length; ++f) {
        anim.frames[f] = crop.copyCrop(anim.frames[f], x, y, width, height);
      }

      return crop.encodeGifAnimation(anim) as Uint8List;
    }
    return null;
  }

  Future<List<dynamic>?> inputImage() async {
    String fileName = '';
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpeg', 'gif', 'ttf'],
      dialogTitle: 'Seleted only image file',
    );

    if (result != null && result.files.isNotEmpty) {
      Uint8List? imageBytes;
      PlatformFile single = result.files.first;
      if (!kIsWeb) {
        File file = File(single.path.toString());
        if (kDebugMode) {
          print('Picked file -> ${file.path}');
        }

        imageBytes = await file.readAsBytes();
        fileName = path.basename(file.path);
      } else {
        imageBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      }

      if (imageBytes != null) {
        return [imageBytes, fileName];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  label: const Text('Input'),
                  onPressed: () async {
                    var rawImgbytes = await inputImage();
                    setState(() {
                      if (rawImgbytes != null) {
                        imageBytesRoot = rawImgbytes[0];
                        fileNameRoot = rawImgbytes[1];
                      }
                    });
                  },
                  icon: const Icon(Icons.upload_file),
                ),
                if (imageBytesRoot != null)
                  Tooltip(
                    message: 'Widget to image',
                    child: TextButton.icon(
                      label: const Text('Capture'),
                      onPressed: () async {
                        var widgetToImage = await cWTI.capture();
                        setState(() {
                          if (widgetToImage != null) {
                            widgetToImageRoot = widgetToImage;
                          }
                        });
                      },
                      icon: const Icon(Icons.camera),
                    ),
                  ),
                if (imageBytesRoot != null)
                  TextButton.icon(
                    label: const Text('Crop'),
                    onPressed: () {
                      Uint8List rawCroppedImage;
                      int h = int.parse(cHeight!.text);
                      int w = int.parse(cwidth!.text);
                      int x = int.parse(cX!.text);
                      int y = int.parse(cY!.text);
                      if (path.extension(fileNameRoot!) == '.gif') {
                        var cropAnim = cropImageAnim(
                          imgFileBytes: imageBytesRoot!,
                          height: h,
                          width: w,
                          x: x,
                          y: y,
                        );
                        if (cropAnim == null) {
                          return;
                        }
                        rawCroppedImage = cropAnim;
                      } else {
                        rawCroppedImage = cropImage(CropInputModel(
                          imgBytes:
                              crop.decodeImage(imageBytesRoot!) as crop.Image,
                          pixelHeight: h,
                          pixelWidth: w,
                          x: x,
                          y: y,
                        ));
                      }
                      setState(() {
                        croppedImageBytesRoot = rawCroppedImage;
                      });
                    },
                    icon: const Icon(Icons.crop),
                  ),
                if (croppedImageBytesRoot != null && fileNameRoot != null)
                  TextButton.icon(
                    label: Text('Download crop_$fileNameRoot'),
                    onPressed: () {
                      download(croppedImageBytesRoot!, 'crop_$fileNameRoot');
                    },
                    icon: const Icon(Icons.download),
                  ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageBytesRoot != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: [
                        WidgetsToImage(
                          controller: cWTI,
                          child: SizedBox(
                            height: 300,
                            width: 300,
                            child: Image.memory(imageBytesRoot!),
                          ),
                        ),
                        const Text('Main')
                      ],
                    ),
                  ),
                if (widgetToImageRoot != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          width: 300,
                          child: Image.memory(widgetToImageRoot!),
                        ),
                        const Text('Captured')
                      ],
                    ),
                  ),
                if (croppedImageBytesRoot != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          width: 300,
                          child: Image.memory(croppedImageBytesRoot!),
                        ),
                        const Text('Cropped')
                      ],
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cX,
                      decoration: const InputDecoration(label: Text('x')),
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Expanded(
                    child: TextField(
                      controller: cY,
                      decoration: const InputDecoration(label: Text('y')),
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Expanded(
                    child: TextField(
                      controller: cHeight,
                      decoration: const InputDecoration(label: Text('height')),
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Expanded(
                    child: TextField(
                      controller: cwidth,
                      decoration: const InputDecoration(label: Text('width')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
