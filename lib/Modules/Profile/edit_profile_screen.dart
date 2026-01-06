import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'dart:typed_data';
import 'dart:convert';
import '../../Utilities/app_constants.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../providers/simple_auth_provider.dart';
import '../../Models/user_model.dart';
import '../../core/Language/locales.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _profileImageBase64;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
    _loadUserData();
  }

  void _checkAuthentication() {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      Navigator.of(context).pop();
      context.push('/login');
    }
  }

  void _loadUserData() {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      // تحميل Base64 من profileImageUrl (إذا كان Base64) أو من Firestore
      _profileImageBase64 = user.profileImageUrl.isNotEmpty ? user.profileImageUrl : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تعديل الملف الشخصي',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Profile Image Section
            _buildProfileImageSection(),
            SizedBox(height: 32.h),
            
            // Form Section
            _buildFormSection(),
            SizedBox(height: 32.h),
            
            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePicker,
          child: Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: _getImageProvider(),
            ),
            child: _getImageProvider() == null
                ? Icon(
                    Icons.person,
                    size: 60.sp,
                    color: Colors.grey[400],
                  )
                : null,
          ),
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: _showImagePicker,
          child: Text(
            'تغيير الصورة',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  DecorationImage? _getImageProvider() {
    // عرض الصورة المختارة حديثاً
    if (_selectedImageBytes != null) {
      return DecorationImage(
        image: MemoryImage(_selectedImageBytes!),
        fit: BoxFit.cover,
      );
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      // عرض الصورة من Base64
      try {
        final imageBytes = base64Decode(_profileImageBase64!);
        return DecorationImage(
          image: MemoryImage(imageBytes),
          fit: BoxFit.cover,
        );
      } catch (e) {
        // إذا فشل فك التشفير، قد تكون URL قديمة
        return null;
      }
    }
    return null;
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        CustomTextFieldWidget(
          controller: _nameController,
          hint: 'الاسم',
          prefixIcon: const Icon(Icons.person),
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _phoneController,
          hint: 'رقم الهاتف',
          prefixIcon: const Icon(Icons.phone),

          textInputType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return CustomButtonWidget(
      title: _isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات',
      onTap: _isLoading ? () {} : _saveProfile,
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر مصدر الصورة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'المعرض',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 30.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Navigator.pop(context);
      
      // محاولة أولى بجودة عالية
      XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400, // تقليل الحجم بشكل أكبر لتقليل حجم Base64
        maxHeight: 400,
        imageQuality: 70, // تقليل الجودة لتقليل الحجم
      );
      
      // إذا كانت الصورة كبيرة جداً، جرب بجودة أقل
      if (image != null) {
        var imageBytes = await image.readAsBytes();
        var base64String = base64Encode(imageBytes);
        
        // Firestore limit هو حوالي 1MB، نستخدم 900KB كحد آمن
        const maxBase64Size = 900 * 1024; // 900KB
        
        // إذا كان Base64 كبير جداً، جرب بجودة أقل
        if (base64String.length > maxBase64Size) {
          // إعادة اختيار الصورة بجودة أقل
          image = await _imagePicker.pickImage(
            source: source,
            maxWidth: 300,
            maxHeight: 300,
            imageQuality: 50, // جودة أقل
          );
          
          if (image != null) {
            imageBytes = await image.readAsBytes();
            base64String = base64Encode(imageBytes);
            
            // إذا كانت لا تزال كبيرة، رفضها
            if (base64String.length > maxBase64Size) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)?.translate('image_too_large_quality') ?? 'الصورة كبيرة جداً. يرجى اختيار صورة أصغر أو بجودة أقل'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
              return;
            }
          } else {
            return;
          }
        }
        
        setState(() {
          _selectedImageBytes = imageBytes;
          _profileImageBase64 = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failed_to_pick_image') ?? 'خطأ في اختيار الصورة'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('login_required_first') ?? 'يجب تسجيل الدخول أولاً'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // استخدام Base64 String (يتم تحويله تلقائياً عند اختيار الصورة)
      final imageBase64 = _profileImageBase64 ?? '';

      // Update Firebase Auth profile (الاسم فقط، بدون صورة لأننا نخزن Base64)
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(_nameController.text);
        await firebaseUser.reload();
      }

      // Update UserModel with new data
      final updatedUser = currentUser.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        profileImageUrl: imageBase64, // تخزين Base64 String
        updatedAt: DateTime.now(),
      );

      // التحقق من حجم Base64 قبل الحفظ (Firestore limit ~1MB)
      const maxBase64Size = 900 * 1024; // 900KB كحد آمن
      if (imageBase64.length > maxBase64Size) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('image_too_large') ?? 'الصورة كبيرة جداً. يرجى اختيار صورة أصغر'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update Firestore user document مع Base64
      await _firestore.collection('users').doc(currentUser.id).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profileImageUrl': imageBase64, // حفظ Base64 String في قاعدة البيانات
        'email': currentUser.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update the provider
      await authProvider.updateUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('changes_saved_success') ?? 'تم حفظ التغييرات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('failed_to_save_changes') ?? 'خطأ في حفظ التغييرات'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 