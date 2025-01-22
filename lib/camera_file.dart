import 'dart:async';
import 'dart:io';
import "package:flutter/material.dart";
import "package:camera/camera.dart";
import 'package:flutter/services.dart';
import 'package:multiple_image_camera/image_preview.dart';

class CameraFile extends StatefulWidget {
  final Widget? customButton;
  const CameraFile({super.key, this.customButton});

  @override
  State<CameraFile> createState() => _CameraFileState();
}

class _CameraFileState extends State<CameraFile> with TickerProviderStateMixin {
  double zoom = 0.0;
  double _scaleFactor = 1.0;
  double scale = 1.0;
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  XFile? lastImageFile; // Changed to store only the last image
  List<MediaModel> imageList = <MediaModel>[];
  late int _currIndex;
  late Animation<double> animation;
  late AnimationController _animationController;
  late AnimationController controller;
  late Animation<double> scaleAnimation;

  addImage(XFile image) { // Modified to handle single image
    setState(() {
      lastImageFile = image;
      _animationController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 1500));
      animation = Tween<double>(begin: 400, end: 1).animate(scaleAnimation =
          CurvedAnimation(
              parent: _animationController, curve: Curves.elasticOut))
        ..addListener(() {});
      _animationController.forward();
    });
  }

  removeImage() {
    setState(() {
      lastImageFile = null; // Clear the last image
    });
  }

  // ... (keep other existing methods unchanged until _buildCameraPreview)

  Widget _buildCameraPreview() {
    return GestureDetector(
        onScaleStart: (details) {
          zoom = _scaleFactor;
        },
        onScaleUpdate: (details) {
          _scaleFactor = zoom * details.scale;
          _controller!.setZoomLevel(_scaleFactor);
        },
        child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              CameraPreview(_controller!),
              if (lastImageFile != null) // Modified to show only last image
                Positioned(
                  left: 10,
                  bottom: 100,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    ImagePreviewView(
                                      File(lastImageFile!.path),
                                      "",
                                    )));
                      },
                      child: Stack(
                        children: [
                          Image.file(
                            File(lastImageFile!.path),
                            height: 90,
                            width: 60,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  removeImage();
                                });
                              },
                              child: Image.network(
                                "https://logowik.com/content/uploads/images/close1437.jpg",
                                height: 30,
                                width: 30,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              // ... (keep the rest of the Stack children unchanged)
            ])));
  }

  takePicture() async {
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      final image = await _controller!.takePicture();
      setState(() {
        addImage(image);
        HapticFeedback.lightImpact();
      });
    } on CameraException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (keep the existing build method unchanged until the actions list)
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        actions: [
          lastImageFile != null // Modified condition
              ? GestureDetector(
                  onTap: () {
                    File file = File(lastImageFile!.path);
                    imageList.add(
                        MediaModel.blob(file, "", file.readAsBytesSync()));
                    Navigator.pop(context, imageList);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _animatedButton(customContent: widget.customButton),
                  ))
              : const SizedBox()
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      extendBody: true,
      body: _buildCameraPreview(),
    );
  }

  @override

  void dispose() {

    if (_controller != null) {

      _controller!.dispose();

    } else {

      _animationController.dispose();

    }
    super.dispose();

  }
}

class MediaModel {
  File file;
  String filePath;
  Uint8List blobImage;
  MediaModel.blob(this.file, this.filePath, this.blobImage);
}
