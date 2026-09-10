import 'package:atlas/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.heroTagPrefix,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() {
      if (_transformationController.value != Matrix4.identity()) {
        _transformationController.value = Matrix4.identity();
        _isZoomed = false;
      } else {
        final position = _doubleTapDetails!.localPosition;
        _transformationController.value = Matrix4.identity()
          ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0, 1)
          ..scaleByDouble(2.5, 2.5, 2.5, 1);
        _isZoomed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _transformationController.value = Matrix4.identity();
                _isZoomed = false;
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index];
              return Semantics(
                image: true,
                label: 'image_of_total'.trParams({
                  'index': '${index + 1}',
                  'total': '${widget.images.length}',
                }),
                child: Hero(
                  tag: '${widget.heroTagPrefix}_$index',
                  child: GestureDetector(
                    onDoubleTapDown: (details) => _doubleTapDetails = details,
                    onDoubleTap: _handleDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 5.0,
                      onInteractionStart: (_) {
                        // Optionally handle start
                      },
                      onInteractionUpdate: (details) {
                        if (_transformationController.value
                                .getMaxScaleOnAxis() >
                            1.0) {
                          if (!_isZoomed) {
                            setState(() {
                              _isZoomed = true;
                            });
                          }
                        } else {
                          if (_isZoomed) {
                            setState(() {
                              _isZoomed = false;
                            });
                          }
                        }
                      },
                      onInteractionEnd: (details) {
                        if (_transformationController.value
                                .getMaxScaleOnAxis() <=
                            1.0) {
                          setState(() {
                            _isZoomed = false;
                            _transformationController.value =
                                Matrix4.identity();
                          });
                        }
                      },
                      child: Center(
                        child: imageUrl.startsWith('assets')
                            ? Image.asset(
                                imageUrl,
                                fit: BoxFit.contain,
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                // No memCache clamp: this view exists to show the
                                // photo at full quality. The thumbnail caches
                                // elsewhere stay small on their own.
                                progressIndicatorBuilder: (_, __, progress) =>
                                    Center(
                                  child: CircularProgressIndicator(
                                    value: progress.progress,
                                    color: AppColors.green,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: _buildActionButton(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: () => Get.back(),
            ),
          ),

          // Actions (Share & Download)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Row(
              children: [
                _buildActionButton(
                  icon: HugeIcons.strokeRoundedDownload01,
                  label: 'download'.tr,
                  onTap: () {
                    Get.snackbar(
                      'Success',
                      'Image saved to gallery'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(15),
                      borderRadius: 10,
                    );
                  },
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: HugeIcons.strokeRoundedShare01,
                  label: 'share'.tr,
                  onTap: () {
                    Get.snackbar(
                      'Share',
                      'Sharing current image...'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.green,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(15),
                      borderRadius: 10,
                    );
                  },
                ),
              ],
            ),
          ),

          // Page Indicator
          if (widget.images.length > 1 && !_isZoomed)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? AppColors.green
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Icon-only, so it needs a real 44x44 target and a spoken label — the old
  /// bare `GestureDetector` gave it neither.
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
