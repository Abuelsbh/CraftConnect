import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import '../../../core/Language/locales.dart';

/// Widget للخطوة الأولى: التقاط الصور والفيديو
class Step1ImagesVideoWidget extends StatelessWidget {
  final List<String> selectedImages;
  final List<String> existingImageUrls;
  final String? selectedVideoPath;
  final String? existingVideoUrl;
  final VideoPlayerController? videoPlayerController;
  final bool isUploading;
  final Function() onTakePhoto;
  final Function() onPickFromGallery;
  final Function() onTakeVideo;
  final Function() onPickVideo;
  final Function(int) onRemoveImage;
  final Function() onRemoveVideo;

  const Step1ImagesVideoWidget({
    super.key,
    required this.selectedImages,
    required this.existingImageUrls,
    this.selectedVideoPath,
    this.existingVideoUrl,
    this.videoPlayerController,
    required this.isUploading,
    required this.onTakePhoto,
    required this.onPickFromGallery,
    required this.onTakeVideo,
    required this.onPickVideo,
    required this.onRemoveImage,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('problem_images') ?? 'صور المشكلة',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)?.translate('problem_images_description') ?? 
            'التقط أو اختر صور توضح المشكلة بوضوح (يمكن إضافة أكثر من صورة)',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          SizedBox(height: 32.h),
          
          // Video Section
          if (selectedVideoPath != null || existingVideoUrl != null) ...[
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: selectedVideoPath != null && videoPlayerController != null
                        ? videoPlayerController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: videoPlayerController!.value.aspectRatio,
                                child: VideoPlayer(videoPlayerController!),
                              )
                            : Center(child: CircularProgressIndicator())
                        : existingVideoUrl != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.videocam, size: 48.w, color: Theme.of(context).colorScheme.primary),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'فيديو موجود',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onError, size: 18),
                        onPressed: onRemoveVideo,
                      ),
                    ),
                  ),
                  if (selectedVideoPath != null && videoPlayerController != null && videoPlayerController!.value.isInitialized)
                    Positioned(
                      bottom: 8.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (videoPlayerController!.value.isPlaying) {
                                videoPlayerController!.pause();
                              } else {
                                videoPlayerController!.play();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
          
          // Images Grid
          if (selectedImages.isNotEmpty || existingImageUrls.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
                childAspectRatio: 1,
              ),
              itemCount: existingImageUrls.length + selectedImages.length,
              itemBuilder: (context, index) {
                // الصور الموجودة أولاً
                if (index < existingImageUrls.length) {
                  final imageUrl = existingImageUrls[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.broken_image, color: Theme.of(context).colorScheme.outline),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4.h,
                        right: 4.w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onErrorContainer, size: 18),
                            onPressed: () {
                              // إنشاء callback منفصل للصور الموجودة
                              onRemoveImage(index);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // الصور الجديدة
                  final newImageIndex = index - existingImageUrls.length;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          File(selectedImages[newImageIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4.h,
                        right: 4.w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onError, size: 18),
                            onPressed: () => onRemoveImage(newImageIndex + existingImageUrls.length),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            )
          else
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80.w,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context)?.translate('no_images') ?? 'لا توجد صور',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          
          if (selectedImages.isNotEmpty)
            SizedBox(height: 16.h),
          SizedBox(height: 24.h),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : onTakePhoto,
                  icon: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(AppLocalizations.of(context)?.translate('take_photo') ?? 'التقط صورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : onPickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppLocalizations.of(context)?.translate('select_from_gallery') ?? 'اختر من المعرض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Video Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : onTakeVideo,
                  icon: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.videocam),
                  label: Text(AppLocalizations.of(context)?.translate('record_video_minute') ?? 'التقط فيديو (دقيقة)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : onPickVideo,
                  icon: const Icon(Icons.video_library),
                  label: Text(AppLocalizations.of(context)?.translate('select_video_minute') ?? 'اختر فيديو (دقيقة)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

