import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../services/image_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'photo_review_screen.dart';

/// "Scan Homework" — a live camera preview with a capture button, so the user
/// can frame their worksheet and snap it.
///
/// The `camera` package isn't available on every platform (e.g. some desktop
/// setups). If it can't start, we show a friendly fallback that offers the
/// regular photo picker instead — the app never crashes or dead-ends.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFuture = _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release/re-acquire the camera as the app is backgrounded/resumed.
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _initFuture = _initCamera());
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      // Prefer the back camera for scanning documents.
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _error = null;
      });
    } catch (e) {
      // Camera unsupported or permission denied — show the fallback.
      if (mounted) setState(() => _error = 'Camera unavailable on this device.');
    }
  }

  /// Captures a frame and sends it to the review/OCR screen.
  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final XFile shot = await controller.takePicture();
      final bytes = await shot.readAsBytes();
      final PickedImage image =
          await ref.read(imageServiceProvider).fromCameraBytes(bytes, name: shot.name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PhotoReviewScreen(image: image)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't capture the photo. Try again.")),
      );
    }
  }

  /// Fallback path: use the system photo picker instead of the live camera.
  Future<void> _useFallback({required bool camera}) async {
    try {
      final image = camera
          ? await ref.read(imageServiceProvider).takePhoto()
          : await ref.read(imageServiceProvider).pickFromGallery();
      if (image == null || !mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PhotoReviewScreen(image: image)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Failure: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Homework'),
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          // If the camera failed, offer the friendly fallback.
          if (_error != null) return _buildFallback();
          if (snapshot.connectionState == ConnectionState.waiting ||
              _controller == null) {
            return const LoadingView(message: 'Starting camera…');
          }
          return _buildCamera();
        },
      ),
    );
  }

  Widget _buildCamera() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(child: CameraPreview(_controller!)),
        // A helper hint at the top.
        Positioned(
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Point at your homework and tap the button',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        // The big capture button.
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: GestureDetector(
            onTap: _capturing ? null : _capture,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white70, width: 4),
              ),
              child: _capturing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
            ),
          ),
        ),
      ],
    );
  }

  /// Shown when the live camera can't be used. Keeps the feature usable.
  Widget _buildFallback() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ErrorView(
              error: _error!,
              onRetry: () => setState(() => _initFuture = _initCamera()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // On mobile the picker can still open the camera app.
                if (!kIsWeb)
                  FilledButton.icon(
                    onPressed: () => _useFallback(camera: true),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take a Photo instead'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _useFallback(camera: false),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload a Photo instead'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
