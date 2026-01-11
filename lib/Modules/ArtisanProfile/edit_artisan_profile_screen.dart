import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../core/Language/app_languages.dart';
import '../../Models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../services/artisan_service.dart';
import '../../services/craft_service.dart';

class EditArtisanProfileScreen extends StatefulWidget {
  final String artisanId;

  const EditArtisanProfileScreen({super.key, required this.artisanId});

  @override
  State<EditArtisanProfileScreen> createState() =>
      _EditArtisanProfileScreenState();
}

class _EditArtisanProfileScreenState extends State<EditArtisanProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ArtisanService _artisanService = ArtisanService();
  final CraftService _craftService = CraftService();

  bool _isLoading = false;
  bool _isLoadingProfile = true;
  ArtisanModel? _artisan;

  // الصور
  String? _profileImageBase64;
  Uint8List? _selectedProfileImageBytes;
  List<String> _galleryImagesBase64 = [];
  List<Uint8List> _selectedGalleryImagesBytes = [];
  List<String> _existingGalleryImages =
      []; // الصور الموجودة بالفعل (URLs أو base64)
  List<String> _skills = []; // المهارات

  // أنواع الحرف - يتم تحميلها من Firebase
  List<Map<String, String>> _craftTypes = [];
  bool _isLoadingCrafts = true;
  String? _selectedCraftType; // لا قيمة افتراضية
  int _yearsOfExperience = 1;

  // متغيرات الموقع
  double? _latitude;
  double? _longitude;
  String _address = '';
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    // تحميل الحرف أولاً، ثم تحميل بيانات الحرفي
    _loadCrafts().then((_) => _loadArtisanProfile());
  }

  /// تحميل أنواع الحرف من Firebase
  Future<void> _loadCrafts() async {
    setState(() {
      _isLoadingCrafts = true;
    });

    try {
      final languageProvider = Provider.of<AppLanguage>(context, listen: false);
      final languageCode = languageProvider.appLang.name;

      final crafts = await _craftService.getCraftsAsMap(languageCode);

      if (mounted) {
        setState(() {
          _craftTypes = crafts;
          _isLoadingCrafts = false;

          // التحقق من أن _selectedCraftType موجود في القائمة الجديدة
          if (_selectedCraftType != null && _craftTypes.isNotEmpty) {
            final exists = _craftTypes
                .any((craft) => craft['value'] == _selectedCraftType);
            if (!exists) {
              // إذا لم تكن القيمة موجودة، اتركها null
              _selectedCraftType = null;
              print('⚠️ الحرفة المحددة غير موجودة - تم تعيينها إلى: null');
            }
          }
        });
      }
    } catch (e) {
      print('خطأ في تحميل الحرف: $e');
      if (mounted) {
        setState(() {
          _isLoadingCrafts = false;
          // استخدام القيم الافتراضية في حالة الخطأ
          final languageProvider =
              Provider.of<AppLanguage>(context, listen: false);
          final languageCode = languageProvider.appLang.name;
          _craftService.getCraftsAsMap(languageCode).then((crafts) {
            if (mounted) {
              setState(() {
                _craftTypes = crafts;
                // التحقق من أن _selectedCraftType موجود في القائمة
                if (_selectedCraftType != null && _craftTypes.isNotEmpty) {
                  final exists = _craftTypes
                      .any((craft) => craft['value'] == _selectedCraftType);
                  if (!exists) {
                    _selectedCraftType = null;
                  }
                }
              });
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _loadArtisanProfile() async {
    try {
      final artisanDoc =
          await _firestore.collection('artisans').doc(widget.artisanId).get();

      if (artisanDoc.exists) {
        final artisanData = artisanDoc.data()!;
        final artisan = ArtisanModel.fromJson(artisanData);

        setState(() {
          _artisan = artisan;
          _nameController.text = artisan.name;
          _phoneController.text = artisan.phone;
          _emailController.text = artisan.email;
          _descriptionController.text = artisan.description;

          // التحقق من أن craftType موجود في قائمة الحرف المحملة
          final craftType = artisan.craftType;
          if (craftType.isNotEmpty && _craftTypes.isNotEmpty) {
            final exists =
                _craftTypes.any((craft) => craft['value'] == craftType);
            if (exists) {
              _selectedCraftType = craftType;
            } else {
              // إذا لم تكن القيمة موجودة، اتركها null
              _selectedCraftType = null;
              print(
                  '⚠️ الحرفة "$craftType" غير موجودة في Firebase - تم تعيينها إلى: null');
            }
          } else if (craftType.isNotEmpty) {
            _selectedCraftType = craftType;
          } else {
            _selectedCraftType = null;
          }

          _yearsOfExperience = artisan.yearsOfExperience;
          _profileImageBase64 = artisan.profileImageUrl;
          _existingGalleryImages = List<String>.from(artisan.galleryImages);
          _skills = List<String>.from(artisan.skills);
          _latitude = artisan.latitude != 0.0 ? artisan.latitude : null;
          _longitude = artisan.longitude != 0.0 ? artisan.longitude : null;
          _address = artisan.address;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                      ?.translate('artisan_data_not_found') ??
                  'لم يتم العثور على بيانات الحرفي'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.translate('failed_to_load_artisan') ?? 'فشل في تحميل بيانات الحرفي'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)?.translate('camera') ??
                    'الكاميرا'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                    AppLocalizations.of(context)?.translate('gallery') ??
                        'المعرض'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64String = base64Encode(imageBytes);

        // التحقق من حجم Base64 (Firestore limit ~1MB)
        const maxBase64Size = 900 * 1024; // 900KB كحد آمن
        if (base64String.length > maxBase64Size) {
          // جرب بجودة أقل
          final compressedImage = await _imagePicker.pickImage(
            source: source,
            maxWidth: 300,
            maxHeight: 300,
            imageQuality: 50,
          );

          if (compressedImage != null) {
            final compressedBytes = await compressedImage.readAsBytes();
            final compressedBase64 = base64Encode(compressedBytes);

            if (compressedBase64.length > maxBase64Size) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)
                            ?.translate('image_too_large') ??
                        'الصورة كبيرة جداً. يرجى اختيار صورة أصغر'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return;
            }

            setState(() {
              _selectedProfileImageBytes = compressedBytes;
              _profileImageBase64 = compressedBase64;
            });
          }
        } else {
          setState(() {
            _selectedProfileImageBytes = imageBytes;
            _profileImageBase64 = base64String;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.translate('failed_to_pick_image') ?? 'خطأ في اختيار الصورة'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickGalleryImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (images.isEmpty) return;

      final List<Uint8List> newImagesBytes = [];
      final List<String> newImagesBase64 = [];

      for (final image in images) {
        final imageBytes = await image.readAsBytes();
        final base64String = base64Encode(imageBytes);

        // التحقق من حجم Base64
        const maxBase64Size = 900 * 1024; // 900KB
        if (base64String.length > maxBase64Size) {
          // تخطي الصور الكبيرة جداً
          continue;
        }

        newImagesBytes.add(imageBytes);
        newImagesBase64.add(base64String);
      }

      setState(() {
        _selectedGalleryImagesBytes.addAll(newImagesBytes);
        _galleryImagesBase64.addAll(newImagesBase64);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.translate('failed_to_pick_images') ?? 'خطأ في اختيار الصور'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      if (index < _existingGalleryImages.length) {
        // حذف صورة موجودة
        _existingGalleryImages.removeAt(index);
      } else {
        // حذف صورة جديدة
        final newIndex = index - _existingGalleryImages.length;
        _selectedGalleryImagesBytes.removeAt(newIndex);
        _galleryImagesBase64.removeAt(newIndex);
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider =
          Provider.of<SimpleAuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null || currentUser.artisanId != widget.artisanId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                      ?.translate('no_permission_to_edit') ??
                  'ليس لديك صلاحية لتعديل هذا الملف الشخصي'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // دمج الصور الموجودة مع الصور الجديدة
      final allGalleryImages = <String>[];
      allGalleryImages.addAll(_existingGalleryImages);
      allGalleryImages.addAll(_galleryImagesBase64);

      // التحقق من أن المهنة محددة
      if (_selectedCraftType == null || _selectedCraftType!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                      ?.translate('select_profession') ??
                  'يرجى اختيار المهنة'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // تحديث بيانات الحرفي في Firestore
      await _firestore.collection('artisans').doc(widget.artisanId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'craftType': _selectedCraftType!,
        'yearsOfExperience': _yearsOfExperience,
        'profileImageUrl':
            _profileImageBase64 ?? _artisan?.profileImageUrl ?? '',
        'galleryImages': allGalleryImages,
        'skills': _skills,
        'latitude': _latitude ?? 0.0,
        'longitude': _longitude ?? 0.0,
        'address': _address,
        'isAvailable': _latitude != null &&
            _longitude != null &&
            _latitude != 0.0 &&
            _longitude != 0.0, // متاح فقط إذا كان الموقع محدد
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // تحديث بيانات المستخدم أيضاً
      await _firestore.collection('users').doc(currentUser.id).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                    ?.translate('changes_saved_success') ??
                'تم حفظ التعديلات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // الانتظار قليلاً ثم التوجيه إلى الصفحة الرئيسية
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.translate('failed_to_save_changes') ?? 'فشل في حفظ التعديلات'}: $e'),
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
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              AppLocalizations.of(context)?.translate('edit_profile_title') ??
                  'تعديل الملف الشخصي'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_artisan == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              AppLocalizations.of(context)?.translate('edit_profile_title') ??
                  'تعديل الملف الشخصي'),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)
                  ?.translate('artisan_data_not_found') ??
              'لم يتم العثور على بيانات الحرفي'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة الملف الشخصي
                    Center(
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                image: _getProfileImageProvider(),
                              ),
                              child: _getProfileImageProvider() == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20.w,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // الاسم
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context)?.translate('name') ??
                                'الاسم',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context)
                                  ?.translate('name_required_error') ??
                              'الاسم مطلوب';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // رقم الهاتف
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                                ?.translate('phone_number') ??
                            'رقم الهاتف',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context)
                                  ?.translate('phone_required_error') ??
                              'رقم الهاتف مطلوب';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: false, // البريد الإلكتروني لا يمكن تعديله
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16.h),

                    // اختيار المهنة
                    _isLoadingCrafts
                        ? const Center(child: CircularProgressIndicator())
                        : _craftTypes.isEmpty
                            ? Center(
                                child: Text(AppLocalizations.of(context)
                                        ?.translate('no_crafts_available') ??
                                    'لا توجد حرف متاحة'))
                            : DropdownButtonFormField<String?>(
                                value: _selectedCraftType,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)
                                          ?.translate('select_profession') ??
                                      'اختيار المهنة',
                                  prefixIcon: const Icon(Icons.category),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadius),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)?.translate(
                                              'select_profession') ??
                                          'اختيار المهنة',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  ..._craftTypes.map((craft) {
                                    return DropdownMenuItem<String?>(
                                      value: craft['value'],
                                      child: Text(craft['label'] ??
                                          craft['value'] ??
                                          ''),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCraftType = value;
                                  });
                                },
                              ),
                    SizedBox(height: 16.h),

                    // سنوات الخبرة
                    DropdownButtonFormField<int>(
                      value: _yearsOfExperience,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                                ?.translate('years_of_experience') ??
                            'سنوات الخبرة',
                        prefixIcon: const Icon(Icons.work_history),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      items:
                          List.generate(20, (index) => index + 1).map((years) {
                        return DropdownMenuItem(
                          value: years,
                          child: Text(
                              '$years ${AppLocalizations.of(context)?.translate('year') ?? 'سنة'}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _yearsOfExperience = value ?? 1;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),

                    // الوصف
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)
                                ?.translate('description_label') ??
                            'الوصف',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return AppLocalizations.of(context)
                                  ?.translate('description_required') ??
                              'الوصف مطلوب';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // الموقع
                    _buildLocationSection(),
                    SizedBox(height: 24.h),

                    // إدارة المهارات
                    _buildSkillsSection(),
                    SizedBox(height: 24.h),

                    // معرض الصور
                    Text(
                      AppLocalizations.of(context)?.translate('work_gallery') ??
                          'معرض الأعمال',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // عرض الصور الموجودة والجديدة
                    _buildGalleryGrid(),

                    SizedBox(height: 16.h),

                    // زر إضافة صور
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickGalleryImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(AppLocalizations.of(context)
                                ?.translate('add_to_gallery') ??
                            'إضافة صور للمعرض'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // زر الحفظ المثبت في الأسفل
          SafeArea(
            child: Container(
              padding: EdgeInsets.all(AppConstants.padding),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    AppLocalizations.of(context)?.translate('save') ?? 'حفظ',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _getProfileImageProvider() {
    if (_selectedProfileImageBytes != null) {
      return DecorationImage(
        image: MemoryImage(_selectedProfileImageBytes!),
        fit: BoxFit.cover,
      );
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        // محاولة فك تشفير Base64
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

  Widget _buildGalleryGrid() {
    final allImages = <Widget>[];

    // إضافة الصور الموجودة
    for (int i = 0; i < _existingGalleryImages.length; i++) {
      allImages.add(_buildGalleryImageItem(i, true));
    }

    // إضافة الصور الجديدة
    for (int i = 0; i < _selectedGalleryImagesBytes.length; i++) {
      allImages.add(_buildGalleryImageItem(i, false));
    }

    if (allImages.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 48.w, color: Colors.grey),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context)
                        ?.translate('no_gallery_images_text') ??
                    'لا توجد صور في المعرض',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) => allImages[index],
    );
  }

  Widget _buildGalleryImageItem(int index, bool isExisting) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: isExisting
                ? _buildExistingImage(_existingGalleryImages[index])
                : Image.memory(
                    _selectedGalleryImagesBytes[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeGalleryImage(
                isExisting ? index : index + _existingGalleryImages.length),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImage(String imageData) {
    try {
      // محاولة فك تشفير Base64
      final imageBytes = base64Decode(imageData);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } catch (e) {
      // إذا فشل فك التشفير، قد تكون URL قديمة
      if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image, size: 40.w, color: Colors.grey);
          },
        );
      }
      return Icon(Icons.broken_image, size: 40.w, color: Colors.grey);
    }
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('skills') ?? 'المهارات',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),

        // عرض المهارات الحالية
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _skills.asMap().entries.map((entry) {
              final index = entry.key;
              final skill = entry.value;
              return Chip(
                label: Text(skill),
                onDeleted: () {
                  setState(() {
                    _skills.removeAt(index);
                  });
                },
                deleteIcon: Icon(Icons.close, size: 18.w),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),

        SizedBox(height: 12.h),

        // إضافة مهارة جديدة
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillController,
                decoration: InputDecoration(
                  labelText: 'إضافة مهارة جديدة',
                  hintText: AppLocalizations.of(context)
                          ?.translate('enter_skill_name') ??
                      'أدخل اسم المهارة',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                onFieldSubmitted: (value) {
                  _addSkill();
                },
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              onPressed: _addSkill,
              icon: const Icon(Icons.add),
              label: Text(
                  AppLocalizations.of(context)?.translate('add') ?? 'إضافة'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    } else if (_skills.contains(skill)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)?.translate('skill_already_exists') ??
                  'هذه المهارة موجودة بالفعل'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('location_label') ?? 'الموقع',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: _latitude != null &&
                      _longitude != null &&
                      _latitude != 0.0 &&
                      _longitude != 0.0
                  ? Colors.green
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Row(
            children: [
              Icon(
                _latitude != null &&
                        _longitude != null &&
                        _latitude != 0.0 &&
                        _longitude != 0.0
                    ? Icons.location_on
                    : Icons.location_off,
                color: _latitude != null &&
                        _longitude != null &&
                        _latitude != 0.0 &&
                        _longitude != 0.0
                    ? Colors.green
                    : Theme.of(context).colorScheme.outline,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _latitude != null &&
                              _longitude != null &&
                              _latitude != 0.0 &&
                              _longitude != 0.0
                          ? (AppLocalizations.of(context)
                                  ?.translate('location_set_success') ??
                              'تم تحديد الموقع بنجاح')
                          : (AppLocalizations.of(context)
                                  ?.translate('location_undefined') ??
                              'لم يتم تحديد الموقع'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _latitude != null &&
                                _longitude != null &&
                                _latitude != 0.0 &&
                                _longitude != 0.0
                            ? Colors.green
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (_latitude != null &&
                        _longitude != null &&
                        _latitude != 0.0 &&
                        _longitude != 0.0) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      if (_address.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          _address,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (_isLocationLoading)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _getCurrentLocation,
                  icon: Icon(
                    Icons.my_location,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip:
                      AppLocalizations.of(context)?.translate('get_location') ??
                          'الحصول على الموقع',
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppLocalizations.of(context)?.translate('enable_gps_message') ??
              'يجب تفعيل GPS للحصول على موقعك بدقة',
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                      ?.translate('location_service_disabled_message') ??
                  'خدمة الموقع غير مفعلة. يرجى تفعيل GPS من الإعدادات',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'فتح الإعدادات',
              textColor: Colors.white,
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)
                      ?.translate('location_permission_denied') ??
                  'تم رفض إذن الموقع. يرجى السماح بالوصول للموقع'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                      ?.translate('location_permission_permanently_denied') ??
                  'إذن الموقع مرفوض نهائياً. يرجى تفعيله من إعدادات التطبيق',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'فتح الإعدادات',
              textColor: Colors.white,
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // الحصول على الموقع
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // الحصول على العنوان
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'
                  .trim();
          if (_address.startsWith(',')) {
            _address = _address.substring(1).trim();
          }
        }
      } catch (e) {
        _address =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocationLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                    ?.translate('location_set_success') ??
                'تم تحديد الموقع بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)?.translate('failed_to_get_location') ?? 'فشل في الحصول على الموقع'}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
