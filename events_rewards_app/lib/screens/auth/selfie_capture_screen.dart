// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

// ML Kit face detection (mobile only)
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../core/constants/colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../providers/profile_provider.dart';

class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  File? _capturedImage;
  Uint8List? _webImageBytes;
  String _instruction = 'Position your face inside the oval';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _capturedImage != null || _webImageBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Selfie'),
        elevation: 0,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // top status/instruction
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _instruction,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // preview area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _capturedImage != null
                                ? Image.file(_capturedImage!, fit: BoxFit.contain)
                                : Image.memory(_webImageBytes!, fit: BoxFit.contain),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No image captured',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to get started',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // action button -> open camera/webcam screen
                CustomButton(
                  text: 'Start Selfie Capture',
                  onPressed: () async {
                    // pick the front camera first, then push WebcamCaptureScreen
                    try {
                      final cameras = await availableCameras();
                      final front = cameras.firstWhere(
                        (c) => c.lensDirection == CameraLensDirection.front,
                        orElse: () => cameras.first,
                      );
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WebcamCaptureScreen(
                            camera: front,
                            onCaptureBytes: (bytes) {
                              setState(() {
                                _webImageBytes = bytes;
                                _capturedImage = null;
                                _instruction = 'Great! Review your selfie and continue.';
                              });
                            },
                            onCaptureFile: (file) {
                              setState(() {
                                _capturedImage = file;
                                _webImageBytes = null;
                                _instruction = 'Great! Review your selfie and continue.';
                              });
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Camera error: $e'), backgroundColor: AppColors.errorColor),
                      );
                    }
                  },
                  width: double.infinity,
                  backgroundColor: AppColors.primaryColor,
                  icon: Icons.camera_alt,
                ),

                const SizedBox(height: 12),

                // upload / continue buttons would be shown after image capture
                if (_capturedImage != null || _webImageBytes != null)
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Retake',
                          onPressed: () {
                            setState(() {
                              _capturedImage = null;
                              _webImageBytes = null;
                              _instruction = 'Position your face inside the oval';
                            });
                          },
                          isOutlined: true,
                          icon: Icons.refresh,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Continue',
                          onPressed: () async {
                            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                            bool success = false;
                            if (_webImageBytes != null) {
                              success = await profileProvider.uploadSelfieBytes(_webImageBytes!);
                            } else if (_capturedImage != null) {
                              success = await profileProvider.uploadSelfie(_capturedImage!);
                            }
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Selfie uploaded successfully!'),
                                  backgroundColor: AppColors.successColor,
                                ),
                              );
                              Navigator.of(context).pushReplacementNamed('/voice-recording');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(profileProvider.error ?? 'Upload failed'), backgroundColor: AppColors.errorColor),
                              );
                            }
                          },
                          backgroundColor: AppColors.primaryColor,
                          icon: Icons.check,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Webcam / Live-capture screen with:
/// - Mobile: ML Kit face detection + alignment enforcement
/// - Web: Manual alignment (no automatic check)
class WebcamCaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  final void Function(Uint8List bytes)? onCaptureBytes;
  final void Function(File file)? onCaptureFile;

  const WebcamCaptureScreen({
    super.key,
    required this.camera,
    this.onCaptureBytes,
    this.onCaptureFile,
  });

  @override
  State<WebcamCaptureScreen> createState() => _WebcamCaptureScreenState();
}

class _WebcamCaptureScreenState extends State<WebcamCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  // ML Kit face detector (mobile only)
  FaceDetector? _faceDetector;
  bool _faceInOval = false;
  bool _isProcessing = false;
  int _lastProcessTime = 0;

  // Oval ratios (same used in painter)
  final double _ovalWidthRatio = 0.7;
  final double _ovalHeightRatio = 0.6;

  bool get _canDetectFaces => !kIsWeb; // ML Kit face detection enabled only on mobile
  bool get _shouldEnforceAlignment => !kIsWeb; // ✅ Only enforce alignment on mobile

  @override
  void initState() {
    super.initState();

    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    _initializeControllerFuture = _controller!.initialize().then((_) async {
      if (!mounted) return;

      // Start stream + face detection on mobile platforms only
      if (_canDetectFaces) {
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            enableContours: false,
            enableClassification: false,
          ),
        );

        // start streaming camera frames to ML Kit
        try {
          await _controller!.startImageStream(_processCameraImage);
        } catch (e) {
          debugPrint('startImageStream error: $e');
        }
      }

      // ✅ For web, assume face is always "aligned" since we don't enforce it
      if (kIsWeb) {
        setState(() {
          _faceInOval = true;
        });
      }

      setState(() {});
    }).catchError((e) {
      debugPrint('Camera init error: $e');
    });
  }

  @override
  void dispose() {
    // stop stream and dispose detector
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  /// Process CameraImage frames (mobile only)
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_canDetectFaces) return;
    if (_isProcessing) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessTime < 300) return; // throttle ~300ms
    _lastProcessTime = now;

    _isProcessing = true;
    try {
      final inputImage = _cameraImageToInputImage(image, widget.camera.sensorOrientation);
      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final Rect faceRect = face.boundingBox;

        // Compute normalized center of the face relative to camera image
        final double centerX = (faceRect.left + faceRect.right) / 2.0 / image.width;
        final double centerY = (faceRect.top + faceRect.bottom) / 2.0 / image.height;

        // Check if this normalized center falls inside the centered oval
        final double dx = (centerX - 0.5);
        final double dy = (centerY - 0.5);
        final double a = _ovalWidthRatio / 2.0; // normalized half-width
        final double b = _ovalHeightRatio / 2.0; // normalized half-height

        final double ellipseValue = (dx * dx) / (a * a) + (dy * dy) / (b * b);
        final bool aligned = ellipseValue <= 1.0;

        if (mounted) {
          setState(() {
            _faceInOval = aligned;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _faceInOval = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert camera image to ML Kit InputImage
  InputImage _cameraImageToInputImage(CameraImage image, int sensorOrientation) {
    // concatenate planes
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final inputImageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final planeData = image.planes.map(
      (plane) => InputImagePlaneMetadata(bytesPerRow: plane.bytesPerRow, height: plane.height, width: plane.width),
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: inputImageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  /// User requested capture
  Future<void> _onCapturePressed() async {
    // ✅ REMOVED: Web blocking - now allows capture on web without alignment check
    
    // On mobile: still enforce alignment if face detection is working
    if (_shouldEnforceAlignment && !_faceInOval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please position your face inside the oval before capturing.'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    try {
      // Stop the stream (necessary before takePicture on some devices)
      if (_canDetectFaces) {
        try {
          await _controller?.stopImageStream();
        } catch (_) {}
      }

      final XFile taken = await _controller!.takePicture();

      if (kIsWeb) {
        // ✅ For web: return bytes
        final bytes = await taken.readAsBytes();
        widget.onCaptureBytes?.call(bytes);
      } else {
        // For mobile: return File
        final File f = File(taken.path);
        widget.onCaptureFile?.call(f);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Capture error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e'), backgroundColor: AppColors.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Align & Capture')),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && 
              _controller != null && 
              _controller!.value.isInitialized) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // camera preview
                CameraPreview(_controller!),

                // overlay + state text
                Column(
                  children: [
                    Expanded(child: Container()), // top spacer
                    // ✅ Updated message bar for web vs mobile
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.black45,
                      child: Text(
                        _getInstructionText(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // oval overlay painter (changes color based on _faceInOval)
                IgnorePointer(
                  child: CustomPaint(
                    painter: OvalOverlayPainter(
                      isAligned: _faceInOval, 
                      widthRatio: _ovalWidthRatio, 
                      heightRatio: _ovalHeightRatio,
                      showGuidance: !kIsWeb, // ✅ Only show colored guidance on mobile
                    ),
                    size: MediaQuery.of(context).size,
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCapturePressed,
        backgroundColor: (_shouldEnforceAlignment && !_faceInOval) 
            ? Colors.grey 
            : AppColors.primaryColor, // ✅ Always enabled on web
        child: const Icon(Icons.camera),
      ),
    );
  }

  String _getInstructionText() {
    if (kIsWeb) {
      return 'Position your face in the oval and tap capture';
    } else {
      return _faceInOval 
          ? 'Perfect — face is aligned' 
          : 'Move your face into the oval';
    }
  }
}

/// Oval overlay painter: dim background and cut oval
class OvalOverlayPainter extends CustomPainter {
  final bool isAligned;
  final double widthRatio;
  final double heightRatio;
  final bool showGuidance; // ✅ New parameter to control colored guidance

  OvalOverlayPainter({
    required this.isAligned, 
    this.widthRatio = 0.7, 
    this.heightRatio = 0.6,
    this.showGuidance = true, // ✅ Default to showing guidance
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final rect = Offset.zero & size;

    // dim background
    canvas.drawRect(rect, paint);

    // oval rect center
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * widthRatio,
      height: size.height * heightRatio,
    );

    // clear the oval center
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, paint);
    canvas.drawOval(ovalRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // ✅ Draw oval border (colored guidance only if enabled)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = showGuidance 
          ? (isAligned ? Colors.greenAccent : Colors.redAccent)
          : Colors.white.withOpacity(0.8); // ✅ Neutral color for web

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant OvalOverlayPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned || 
           oldDelegate.widthRatio != widthRatio || 
           oldDelegate.heightRatio != heightRatio ||
           oldDelegate.showGuidance != showGuidance;
  }
}
