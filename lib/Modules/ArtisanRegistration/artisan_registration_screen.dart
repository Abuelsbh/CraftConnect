import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/artisan_provider.dart';
import '../../providers/simple_auth_provider.dart';
import '../../services/artisan_service.dart';
import '../../Models/artisan_model.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';

class ArtisanRegistrationScreen extends StatefulWidget {
  const ArtisanRegistrationScreen({super.key});

  @override
  State<ArtisanRegistrationScreen> createState() => _ArtisanRegistrationScreenState();
}

class _ArtisanRegistrationScreenState extends State<ArtisanRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedCraftType = 'carpenter';
  int _yearsOfExperience = 1;
  String? _profileImagePath;
  List<String> _galleryImagePaths = [];
  bool _isLoading = false;
  bool _isLocationLoading = false;
  double? _latitude;
  double? _longitude;
  
  final List<String> _craftTypes = AppConstants.defaultCraftTypes;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('خدمة الموقع غير مفعلة');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('تم رفض إذن الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('إذن الموقع مرفوض نهائياً');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      _showErrorSnackBar('فشل في الحصول على الموقع: $e');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
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
          if (isProfile) {
            _profileImagePath = image.path;
          } else {
            _galleryImagePaths.add(image.path);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('فشل في اختيار الصورة: $e');
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImagePaths.removeAt(index);
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

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profileImagePath == null) {
      _showErrorSnackBar('يرجى اختيار صورة شخصية');
      return;
    }

    if (_galleryImagePaths.isEmpty) {
      _showErrorSnackBar('يرجى إضافة صور للمعرض');
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showErrorSnackBar('يرجى السماح بالوصول للموقع');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);

      // إنشاء معرف فريد للحرفي
      final artisanId = DateTime.now().millisecondsSinceEpoch.toString();

      // إنشاء نموذج الحرفي
      final artisan = ArtisanModel(
        id: artisanId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        profileImageUrl: _profileImagePath!,
        craftType: _selectedCraftType,
        yearsOfExperience: _yearsOfExperience,
        description: _descriptionController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        address: _addressController.text.trim(),
        galleryImages: _galleryImagePaths,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ الحرفي في Firebase
      await artisanProvider.registerArtisan(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        craftType: _selectedCraftType,
        yearsOfExperience: _yearsOfExperience,
        description: _descriptionController.text.trim(),
        profileImagePath: _profileImagePath,
        galleryImagePaths: _galleryImagePaths.isNotEmpty ? _galleryImagePaths : null,
      );

      // تحديث معرف الحرفي في حساب المستخدم
      if (authProvider.currentUser != null) {
        // محاكاة تحديث معرف الحرفي
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _showSuccessSnackBar('تم تسجيل الحرفي بنجاح!');
      
      // العودة للصفحة السابقة
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showErrorSnackBar('فشل في تسجيل الحرفي: $e');
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
          AppLocalizations.of(context)?.translate('register_as_artisan') ?? 'تسجيل كحرفي',
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
          SingleChildScrollView(
            padding: EdgeInsets.all(AppConstants.padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileImageSection(),
                  SizedBox(height: 24.h),
                  _buildBasicInfoSection(),
                  SizedBox(height: 24.h),
                  _buildCraftInfoSection(),
                  SizedBox(height: 24.h),
                  _buildLocationSection(),
                  SizedBox(height: 24.h),
                  _buildGallerySection(),
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
                      AppLocalizations.of(context)?.translate('registering_artisan') ?? 'جاري تسجيل الحرفي...',
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

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الصورة الشخصية',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: GestureDetector(
            onTap: () => _showImagePickerDialog(true),
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(60.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: _profileImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(58.r),
                      child: Image.file(
                        File(_profileImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 32.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'إضافة صورة',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المعلومات الأساسية',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _nameController,
          hint: 'الاسم الكامل',
          prefixIcon: Icon(Icons.person_rounded),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال الاسم';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _emailController,
          hint: 'البريد الإلكتروني',
          prefixIcon: Icon(Icons.email_rounded),
          textInputType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال البريد الإلكتروني';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'يرجى إدخال بريد إلكتروني صحيح';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _phoneController,
          hint: 'رقم الهاتف',
          prefixIcon: Icon(Icons.phone_rounded),
          textInputType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال رقم الهاتف';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _descriptionController,
          hint: 'وصف الخبرات والمهارات',
          prefixIcon: Icon(Icons.description_rounded),
          maxLine: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال وصف للخبرات';
            }
            if (value.trim().length < 20) {
              return 'يجب أن يكون الوصف 20 حرف على الأقل';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCraftInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الحرفة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 16.h),
        DropdownButtonFormField<String>(
          value: _selectedCraftType,
          decoration: InputDecoration(
            labelText: 'نوع الحرفة',
            prefixIcon: Icon(Icons.work_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          items: _craftTypes.map((craft) {
            return DropdownMenuItem(
              value: craft,
              child: Text(
                AppLocalizations.of(context)?.translate(craft) ?? craft,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCraftType = value!;
            });
          },
        ),
        SizedBox(height: 16.h),
        Text(
          'سنوات الخبرة: $_yearsOfExperience',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Slider(
          value: _yearsOfExperience.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: (value) {
            setState(() {
              _yearsOfExperience = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الموقع',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (_isLocationLoading)
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            if (!_isLocationLoading && (_latitude == null || _longitude == null))
              IconButton(
                onPressed: _getCurrentLocation,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'تحديث الموقع',
              ),
          ],
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _addressController,
          hint: 'العنوان التفصيلي',
          prefixIcon: Icon(Icons.location_on_rounded),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال العنوان';
            }
            return null;
          },
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إحداثيات الموقع',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _latitude != null && _longitude != null
                          ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                          : 'غير محدد',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'معرض الأعمال',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_galleryImagePaths.length}/10',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_galleryImagePaths.isEmpty)
          GestureDetector(
            onTap: () => _showImagePickerDialog(false),
            child: Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 32.w,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'إضافة صور الأعمال',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: _galleryImagePaths.length + (_galleryImagePaths.length < 10 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _galleryImagePaths.length) {
                return GestureDetector(
                  onTap: () => _showImagePickerDialog(false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      image: DecorationImage(
                        image: FileImage(File(_galleryImagePaths[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeGalleryImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 12.w,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButtonWidget(
      title: _isLoading ? 'جاري التسجيل...' : 'تسجيل الحرفي',
      onTap: _isLoading ? () {} : _submitRegistration,
      backGroundColor: _isLoading ? Colors.grey : Theme.of(context).colorScheme.primary,
    );
  }

  void _showImagePickerDialog(bool isProfile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded),
              title: Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isProfile);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded),
              title: Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isProfile);
              },
            ),
          ],
        ),
      ),
    );
  }
} 