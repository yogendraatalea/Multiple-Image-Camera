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
  List<XFile> imageFiles = [];
  List<XFile> thumbnailimage = [];
  List<MediaModel> imageList = <MediaModel>[];
  late int _currIndex;
  late Animation<double> animation;
  late AnimationController _animationController;
  late AnimationController controller;
  late Animation<double> scaleAnimation;

  addImages(XFile image) {
    setState(() {
      imageFiles.add(image);
      thumbnailimage.clear();
      thumbnailimage.insert(0, image);
      print('thumbnailimage.length ${thumbnailimage.length}');
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
      // imageFiles.removeLast();
      thumbnailimage.removeLast();
    });
  }

  Widget? _animatedButton({Widget? customContent}) {
    return customContent ?? Container(
            width: 100,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(100.0),
            ),
            
            child: const Center(
              
              child: Text(
                'Done',
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    ),
              ),
              
            ),
          );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    // ignore: unnecessary_null_comparison
    if (_cameras != null) {
      _controller = CameraController(_cameras[0], ResolutionPreset.ultraHigh,
          enableAudio: false);
      _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    } else {}
  }

  @override
  void initState() {
    _initCamera();
    _currIndex = 0;

    super.initState();
  }



Widget _buildCameraPreview() {
  return Scaffold(
    extendBodyBehindAppBar: true,
    body: Container(
      color: Colors.black, // Helps avoid flickering issues
      child: SafeArea(
        child: GestureDetector(
          onScaleStart: (details) => zoom = _scaleFactor,
          onScaleUpdate: (details) {
            _scaleFactor = (zoom * details.scale).clamp(1.0, 10.0);
            if (_controller!.value.isInitialized && Platform.isAndroid) {
              _controller!.setZoomLevel(_scaleFactor);
            }
          },
          child: Stack(
            children: [
              // Camera Preview (Fix for iOS using AspectRatio)
              if (_controller != null && _controller!.value.isInitialized)
                Platform.isIOS
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      )
                    : CameraPreview(_controller!)
              else
                const Center(child: CircularProgressIndicator()),

              // Thumbnail List
              Positioned(
                bottom: Platform.isIOS ? 20 : 10,
                child: SizedBox(
                  height: 90,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 10),
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: thumbnailimage.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImagePreviewView(
                                Platform.isIOS
                                    ? File(thumbnailimage[index].path).absolute
                                    : File(thumbnailimage[index].path),
                                "",
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              Platform.isIOS
                                  ? File(thumbnailimage[index].path).absolute
                                  : File(thumbnailimage[index].path),
                              height: 58,
                              width: 58,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Camera Switch Button (Adjusted for iOS)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 16,
                    bottom: Platform.isIOS ? 30 : 16,
                  ),
                  child: IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.camera_front, color: Colors.white),
                    onPressed: _onCameraSwitch,
                  ),
                ),
              ),

              // Capture Button (Fixed for iOS)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: Platform.isIOS ? 40 : 20,
                  ),
                  child: IconButton(
                    iconSize: 80,
                    icon: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    onPressed: takePicture,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Future<void> _onCameraSwitch() async {
    final CameraDescription cameraDescription =
        (_controller!.description == _cameras[0]) ? _cameras[1] : _cameras[0];
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(
        cameraDescription, ResolutionPreset.ultraHigh,
        enableAudio: false);
    _controller!.addListener(() {
      if (mounted) setState(() {});
      if (_controller!.value.hasError) {}
    });

    try {
      await _controller!.initialize();
      // ignore: empty_catches
    } on CameraException {}
    if (mounted) {
      setState(() {});
    }
  }

  takePicture() async {
    if (_controller!.value.isTakingPicture) {
      return null;
    }
    try {
      final image = await _controller!.takePicture();
      setState(() {
        addImages(image);
        HapticFeedback.lightImpact();
      });
    } on CameraException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      if (!_controller!.value.isInitialized) {
        return Container();
      }
    } else {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Stack(
  children: [
    _buildCameraPreview(),
    Positioned(
      top: 50, // Adjust positioning as needed
      left: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Navigate back when tapped
        },
        child: Icon(Icons.arrow_back, color: Colors.black, size: 30),
      ),
    ), // This will be your camera preview as the background
    if (imageFiles.isNotEmpty)
      Positioned(
        top: 50, // Adjust positioning as needed
        right: 16,
        child: GestureDetector(
          onTap: () {
            for (int i = 0; i < imageFiles.length; i++) {
              File file = File(imageFiles[i].path);
              imageList.add(MediaModel.blob(file, "", file.readAsBytesSync()));
            }
            Navigator.pop(context, imageList);
          },
          child: _animatedButton(customContent: widget.customButton),
        ),
      ),
  ],
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
