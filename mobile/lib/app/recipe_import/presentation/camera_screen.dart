import 'dart:io';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../data/import_repository.dart';
import '../import_provider.dart';
import '../pending_jobs_provider.dart';
import '../monthly_import_usage_provider.dart';
import '../../subscription/subscription_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isSubmitting = false;
  XFile? _capturedImage;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'camera.could_not_start'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _takePicture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      if (_flashEnabled) {
        await ctrl.setFlashMode(FlashMode.torch);
      }
      final image = await ctrl.takePicture();
      if (_flashEnabled) {
        await ctrl.setFlashMode(FlashMode.off);
      }
      if (mounted) setState(() => _capturedImage = image);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'camera.failed_take_picture'.tr(),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _capturedImage = image);
        await _submitImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'camera.could_not_open_gallery'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _submitImage(String imagePath) async {
    // Check free-tier limits.
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      final usageAsync = ref.read(monthlyImportUsageProvider);
      final usage = usageAsync.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
      if (usage != null && usage.used >= usage.limit) {
        await ref.read(subscriptionProvider.notifier).showPaywall();
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(importRepositoryProvider);
      final result = await repo.submitImage(imagePath);
      if (!mounted) return;

      ref.read(pendingJobsProvider.notifier).addJob(
        ContentJob(
          id: result.jobId,
          status: 'pending',
          savedContentId: result.savedContentId,
        ),
      );

      ref.invalidate(monthlyImportUsageProvider);

      AppSnackBar.show(
        context,
        message: 'import.generating_photo'.tr(),
        type: SnackBarType.success,
      );

      context.go('/recipes');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _useCapturedImage() async {
    if (_capturedImage != null) {
      await _submitImage(_capturedImage!.path);
    }
  }

  void _retake() {
    setState(() => _capturedImage = null);
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/recipes');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // ──────────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Preview
            if (_capturedImage != null)
              Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
            else if (_isInitialized && _controller != null)
              CameraPreview(_controller!)
            else
              const Center(
                child: CupertinoActivityIndicator(color: Colors.white),
              ),

            // Submitting overlay
            if (_isSubmitting)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(
                        radius: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'camera.submitting_photo'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top bar
            if (!_isSubmitting)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PillButton(
                      icon: Icons.close,
                      onTap: _close,
                    ),
                    if (_capturedImage == null)
                      _PillButton(
                        icon: _flashEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onTap: () {
                          setState(() => _flashEnabled = !_flashEnabled);
                        },
                      ),
                  ],
                ),
              ),

            // Bottom controls
            if (!_isSubmitting)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    bottomPadding + 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: _capturedImage != null
                      ? _buildImageControls()
                      : _buildCaptureControls(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gallery
        GestureDetector(
          onTap: _pickFromGallery,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),

        // Shutter
        GestureDetector(
          onTap: _isCapturing ? null : _takePicture,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: _isCapturing ? 30 : 62,
                height: _isCapturing ? 30 : 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    _isCapturing ? 8 : 31,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Spacer to balance the row
        const SizedBox(width: 48, height: 48),
      ],
    );
  }

  Widget _buildImageControls() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _retake,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(
                child: Text(
                  'camera.retake'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _useCapturedImage,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(
                child: Text(
                  'camera.use_photo'.tr(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
