import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/review_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../services/review_service.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';

class AddReviewScreen extends StatefulWidget {
  final String artisanId;
  final String artisanName;
  
  const AddReviewScreen({
    super.key, 
    required this.artisanId,
    required this.artisanName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  
  double _rating = 5.0;
  List<String> _reviewImages = [];
  bool _isLoading = false;
  bool _isLoadingReview = false;
  ReviewModel? _existingReview;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    setState(() {
      _isLoadingReview = true;
    });

    try {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        final reviewService = ReviewService();
        final review = await reviewService.getUserReview(
          authProvider.currentUser!.id,
          widget.artisanId,
        );

        if (review != null) {
          setState(() {
            _existingReview = review;
            _isEditMode = true;
            _rating = review.rating;
            _commentController.text = review.comment;
            _reviewImages = List<String>.from(review.images);
          });
        }
      }
    } catch (e) {
      // في حالة الخطأ، نستمر كأنه تقييم جديد
      print('خطأ في تحميل التقييم الحالي: $e');
    } finally {
      setState(() {
        _isLoadingReview = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _reviewImages.add(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصورة: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _reviewImages.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      
      if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
        _showErrorSnackBar('يجب تسجيل الدخول لإضافة تقييم');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final user = authProvider.currentUser!;
      final now = DateTime.now();

      // إنشاء نموذج التقييم
      final review = ReviewModel(
        id: '${user.id}_${widget.artisanId}', // ID ثابت بناءً على userId + artisanId
        artisanId: widget.artisanId,
        userId: user.id,
        userName: user.name,
        userProfileImage: user.profileImageUrl,
        rating: _rating,
        comment: _commentController.text.trim(),
        images: _reviewImages,
        createdAt: _existingReview?.createdAt ?? now, // الحفاظ على تاريخ الإنشاء الأصلي
        updatedAt: now,
      );

      // حفظ أو تحديث التقييم في Firebase
      final reviewService = ReviewService();
      await reviewService.addOrUpdateReview(review);

      _showSuccessSnackBar(_isEditMode ? 'تم تحديث التقييم بنجاح!' : 'تم إضافة التقييم بنجاح!');
      
      // العودة للصفحة السابقة
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showErrorSnackBar('فشل في حفظ التقييم: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'تعديل التقييم' : 'إضافة تقييم',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_isLoadingReview)
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          else
            SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildArtisanInfo(),
                    if (_isEditMode) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'لديك تقييم سابق. يمكنك تعديله الآن.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    _buildRatingSection(),
                    SizedBox(height: 24.h),
                    _buildCommentSection(),
                    SizedBox(height: 32.h),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'جاري إضافة التقييم...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtisanInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 30.w,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.artisanName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'تقييم الحرفي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التقييم',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16.h),
        Center(
          child: Column(
            children: [
              // النجوم
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40.w,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
              SizedBox(height: 12.h),
              // قيمة التقييم
              Text(
                _getRatingText(_rating),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${_rating.toStringAsFixed(1)} من 5',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التعليق',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        CustomTextFieldWidget(
          controller: _commentController,
          hint: 'اكتب تجربتك مع الحرفي...',
          prefixIcon: Icon(Icons.rate_review_rounded),
          maxLine: 4,
          validator: (value) {
            // لا يوجد حد أدنى للتعليق - التعليق اختياري
            return null;
          },
        ),
      ],
    );
  }


  Widget _buildSubmitButton() {
    return CustomButtonWidget(
      height: 48.h,
      title: _isLoading 
          ? (_isEditMode ? 'جاري التحديث...' : 'جاري الإضافة...')
          : (_isEditMode ? 'تحديث التقييم' : 'إضافة التقييم'),
      onTap: _isLoading ? () {} : _submitReview,
      backGroundColor: _isLoading ? Colors.grey : Theme.of(context).colorScheme.primary,
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded),
              title: Text(AppLocalizations.of(context)?.translate('take_photo_title') ?? 'التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded),
              title: Text(AppLocalizations.of(context)?.translate('select_from_gallery_title') ?? 'اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'ممتاز';
    if (rating >= 4.0) return 'جيد جداً';
    if (rating >= 3.5) return 'جيد';
    if (rating >= 3.0) return 'مقبول';
    if (rating >= 2.0) return 'ضعيف';
    return 'سيء';
  }
} 