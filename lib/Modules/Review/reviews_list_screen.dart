import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/review_model.dart';
import '../../Models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../services/review_service.dart';
import 'add_review_screen.dart';

class ReviewsListScreen extends StatefulWidget {
  final String artisanId;
  final String artisanName;

  const ReviewsListScreen({
    super.key,
    required this.artisanId,
    required this.artisanName,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];
  ArtisanModel? _artisan;
  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reviews = await _reviewService.getReviewsByArtisanId(widget.artisanId);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('فشل في تحميل التقييمات: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _navigateToAddReview() async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn) {
      _showLoginDialog();
      return;
    }

    final result = await context.push(
      '/add-review/${widget.artisanId}?name=${Uri.encodeComponent(widget.artisanName)}',
    );
    
    if (result == true || result == null) {
      _loadReviews();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('login_required') ?? ''),
        content: Text(AppLocalizations.of(context)?.translate('login_message') ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
            child: Text(AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  bool _isBase64Image(String? imageData) {
    if (imageData == null || imageData.isEmpty) return false;
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return false;
    }
    try {
      base64Decode(imageData);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildImageFromData(String? imageData, {BoxFit fit = BoxFit.cover}) {
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.image_rounded,
          size: 40.w,
          color: Colors.grey[400],
        ),
      );
    }

    if (_isBase64Image(imageData)) {
      try {
        final imageBytes = base64Decode(imageData);
        return Image.memory(
          imageBytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.broken_image_rounded,
                size: 40.w,
                color: Colors.grey[400],
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image_rounded,
            size: 40.w,
            color: Colors.grey[400],
          ),
        );
      }
    } else {
      return Image.network(
        imageData,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image_rounded,
              size: 40.w,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التقييمات',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add Review Button
          if (authProvider.isLoggedIn && currentUser != null)
            Container(
              padding: EdgeInsets.all(16.w),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddReview,
                  icon: Icon(Icons.star_rounded, size: 20.w),
                  label: Text(
                    'إضافة تقييم',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : _reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_outline_rounded,
                              size: 64.w,
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'لا توجد تقييمات بعد',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'كن أول من يقيم هذا الحرفي',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                              ),
                            ),
                            if (authProvider.isLoggedIn) ...[
                              SizedBox(height: 24.h),
                              ElevatedButton.icon(
                                onPressed: _navigateToAddReview,
                                icon: Icon(Icons.add_rounded, size: 20.w),
                                label: Text(AppLocalizations.of(context)?.translate('add_review') ?? 'إضافة تقييم'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewCard(_reviews[index], currentUser);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, dynamic currentUser) {
    final bool isMyReview = currentUser != null && review.userId == currentUser.id;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: review.userProfileImage.isNotEmpty
                      ? ClipOval(
                          child: _buildImageFromData(
                            review.userProfileImage,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24.w,
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.userName,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isMyReview)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'تقييمك',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          ...List.generate(5, (starIndex) {
                            return Icon(
                              Icons.star_rounded,
                              size: 16.w,
                              color: starIndex < review.rating.round()
                                  ? Colors.amber
                                  : Colors.grey[300]!,
                            );
                          }),
                          SizedBox(width: 8.w),
                          Text(
                            _getTimeAgo(review.createdAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isMyReview)
                  IconButton(
                    onPressed: () => _navigateToAddReview(),
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 20.w,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'تعديل التقييم',
                  ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
            if (review.images.isNotEmpty) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 80.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      width: 80.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: _buildImageFromData(
                          review.images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}


