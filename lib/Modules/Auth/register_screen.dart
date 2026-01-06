import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../core/Language/app_languages.dart';
import '../../providers/simple_auth_provider.dart';
import '../../services/craft_service.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';

class RegisterScreen extends StatefulWidget {
  final bool isArtisanRegistration;
  
  const RegisterScreen({super.key, this.isArtisanRegistration = false});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // متغيرات جديدة للحرفي
  final _descriptionController = TextEditingController();
  String _selectedCraftType = 'carpenter';
  int _yearsOfExperience = 1;
  String? _profileImagePath;
  List<String> _galleryImagePaths = [];
  
  // متغيرات الموقع
  double? _latitude;
  double? _longitude;
  bool _isLocationLoading = false;
  
  // تحديد نوع التسجيل
  bool get _isArtisanMode => widget.isArtisanRegistration;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // أنواع الحرف - يتم تحميلها من Firebase
  final CraftService _craftService = CraftService();
  List<Map<String, String>> _craftTypes = [];
  bool _isLoadingCrafts = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
    _loadCrafts();
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
        });
      }
    } catch (e) {
      print('خطأ في تحميل الحرف: $e');
      if (mounted) {
        setState(() {
          _isLoadingCrafts = false;
          // استخدام القيم الافتراضية في حالة الخطأ
          final languageProvider = Provider.of<AppLanguage>(context, listen: false);
          final languageCode = languageProvider.appLang.name;
          _craftService.getCraftsAsMap(languageCode).then((crafts) {
            if (mounted) {
              setState(() {
                _craftTypes = crafts;
              });
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.padding),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  _buildHeader(),
                  SizedBox(height: 30.h),
                  _buildRegisterForm(),
                  SizedBox(height: 20.h),
                  _buildTermsCheckbox(),
                  SizedBox(height: 30.h),
                  _buildRegisterButton(),
                  SizedBox(height: 20.h),
                  _buildDivider(),
                  SizedBox(height: 20.h),
                  _buildSocialRegister(),
                  SizedBox(height: 30.h),
                  _buildLoginPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            // زر تسجيل الحرفي - يظهر فقط في وضع التسجيل العادي
            if (!_isArtisanMode)
              TextButton.icon(
                onPressed: () {
                  context.push('/register?artisan=true');
                },
                icon: Icon(
                  Icons.handyman_rounded,
                  size: 20.w,
                ),
                label: Text(
                  AppLocalizations.of(context)?.translate('register_as_artisan') ?? 'تسجيل حرفي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          _isArtisanMode
              ? (AppLocalizations.of(context)?.translate('register_as_artisan') ?? 'تسجيل كحرفي')
              : (AppLocalizations.of(context)?.translate('create_account') ?? 'إنشاء حساب جديد'),
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _isArtisanMode
              ? (AppLocalizations.of(context)?.translate('register_artisan_subtitle') ?? 'سجل حسابك كحرفي وابدأ في تقديم خدماتك')
              : (AppLocalizations.of(context)?.translate('register_subtitle') ?? 'انضم إلينا واستمتع بخدماتنا'),
          style: TextStyle(
            fontSize: 16.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFieldWidget(
            controller: _nameController,
            hint: AppLocalizations.of(context)?.translate('full_name') ?? 'الاسم الكامل',
            prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.outline),
            textInputType: TextInputType.name,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppLocalizations.of(context)?.translate('name_required') ?? 'الاسم مطلوب';
              }
              if (value!.length < 2) {
                return AppLocalizations.of(context)?.translate('name_min_length') ?? 'الاسم يجب أن يكون حرفين على الأقل';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.padding),
          CustomTextFieldWidget(
            controller: _emailController,
            hint: AppLocalizations.of(context)?.translate('enter_email') ?? 'أدخل بريدك الإلكتروني',
            textInputType: TextInputType.emailAddress,
            prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.outline),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppLocalizations.of(context)?.translate('email_required') ?? 'البريد الإلكتروني مطلوب';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return AppLocalizations.of(context)?.translate('invalid_email') ?? 'بريد إلكتروني غير صحيح';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.padding),
          CustomTextFieldWidget(
            controller: _phoneController,
            hint: AppLocalizations.of(context)?.translate('phone_number') ?? 'رقم الهاتف',
            textInputType: TextInputType.phone,
            prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.outline),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppLocalizations.of(context)?.translate('phone_required') ?? 'رقم الهاتف مطلوب';
              }
              if (value!.length < 10) {
                return AppLocalizations.of(context)?.translate('invalid_phone') ?? 'رقم هاتف غير صحيح';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.padding),
          CustomTextFieldWidget(
            controller: _passwordController,
            hint: AppLocalizations.of(context)?.translate('enter_password') ?? 'أدخل كلمة المرور',
            prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.outline),
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            onSuffixTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppLocalizations.of(context)?.translate('password_required') ?? 'كلمة المرور مطلوبة';
              }
              if (value!.length < 6) {
                return AppLocalizations.of(context)?.translate('password_min_length') ?? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),
          SizedBox(height: AppConstants.padding),
          CustomTextFieldWidget(
            controller: _confirmPasswordController,
            hint: AppLocalizations.of(context)?.translate('confirm_password') ?? 'تأكيد كلمة المرور',
            prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.outline),
            obscure: _obscureConfirmPassword,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            onSuffixTap: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return AppLocalizations.of(context)?.translate('confirm_password_required') ?? 'تأكيد كلمة المرور مطلوب';
              }
              if (value != _passwordController.text) {
                return AppLocalizations.of(context)?.translate('passwords_not_match') ?? 'كلمات المرور غير متطابقة';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }


  Widget _buildArtisanFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('craft_type') ?? 'نوع الحرفة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _selectedCraftType,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.translate('select_craft_type') ?? 'اختر نوع الحرفة',
            prefixIcon: Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          items: _isLoadingCrafts
              ? [const DropdownMenuItem(value: null, child: Center(child: CircularProgressIndicator()))]
              : _craftTypes.map((craft) {
                  return DropdownMenuItem(
                    value: craft['value'],
                    child: Text(craft['label'] ?? craft['value'] ?? ''),
                  );
                }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCraftType = value ?? 'carpenter';
            });
          },
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context)?.translate('craft_type_required') ?? 'نوع الحرفة مطلوب';
            }
            return null;
          },
        ),
        SizedBox(height: 15.h),
        CustomTextFieldWidget(
          controller: _descriptionController,
          hint: AppLocalizations.of(context)?.translate('craft_description') ?? 'وصف الحرفة',
          prefixIcon: Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.outline),
          textInputType: TextInputType.multiline,
          maxLine: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return AppLocalizations.of(context)?.translate('craft_description_required') ?? 'وصف الحرفة مطلوب';
            }
            return null;
          },
        ),
        SizedBox(height: 15.h),
        Text(
          AppLocalizations.of(context)?.translate('years_of_experience') ?? 'سنوات الخبرة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<int>(
          value: _yearsOfExperience,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.translate('select_experience') ?? 'اختر سنوات الخبرة',
            prefixIcon: Icon(Icons.trending_up_outlined, color: Theme.of(context).colorScheme.outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          items: List.generate(10, (index) => index + 1).map((years) {
            return DropdownMenuItem(
              value: years,
              child: Text(
                years.toString(),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _yearsOfExperience = value ?? 1;
            });
          },
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context)?.translate('experience_required') ?? 'سنوات الخبرة مطلوبة';
            }
            return null;
          },
        ),
        SizedBox(height: 15.h),
        _buildLocationSection(),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('location') ?? 'الموقع',
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
              color: _latitude != null && _longitude != null
                  ? Colors.green
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Row(
            children: [
              Icon(
                _latitude != null && _longitude != null
                    ? Icons.location_on
                    : Icons.location_off,
                color: _latitude != null && _longitude != null
                    ? Colors.green
                    : Theme.of(context).colorScheme.outline,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _latitude != null && _longitude != null
                          ? AppLocalizations.of(context)?.translate('location_detected') ?? 
                            'تم تحديد الموقع بنجاح'
                          : AppLocalizations.of(context)?.translate('location_not_detected') ?? 
                            'لم يتم تحديد الموقع',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _latitude != null && _longitude != null
                            ? Colors.green
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (_latitude != null && _longitude != null)
                      Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
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
                  tooltip: AppLocalizations.of(context)?.translate('get_location') ?? 'الحصول على الموقع',
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppLocalizations.of(context)?.translate('location_required_note') ?? 
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

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context)?.translate('agree_to_terms') ?? 'أوافق على ',
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)?.translate('terms_conditions') ?? 'الشروط والأحكام',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)?.translate('and') ?? ' و ',
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)?.translate('privacy_policy') ?? 'سياسة الخصوصية',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildRegisterButton() {
    return Consumer<SimpleAuthProvider>(
      builder: (context, authProvider, child) {
        return CustomButtonWidget(
          title: AppLocalizations.of(context)?.translate('create_account') ?? 'إنشاء الحساب',
          width: double.infinity,
          height: 56.h,
          onTap: authProvider.isLoading ? () {} : () => _handleRegister(authProvider),
          titleWidget: authProvider.isLoading 
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.padding),
          child: Text(
            AppLocalizations.of(context)?.translate('or') ?? 'أو',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialRegister() {
    return Column(
      children: [
        _buildSocialButton(
          icon: Icons.g_mobiledata_rounded,
          text: AppLocalizations.of(context)?.translate('continue_with_google') ?? 'المتابعة مع Google',
          onPressed: () => _handleGoogleRegister(),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.w),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('already_have_account') ?? 'لديك حساب بالفعل؟',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        TextButton(
          onPressed: () {
            context.push('/login');
          },
          child: Text(
            AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
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
        try {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('location_service_disabled') ?? 
                'خدمة الموقع غير مفعلة. يرجى تفعيل GPS من الإعدادات',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.translate('open_settings') ?? 'فتح الإعدادات',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Could not show snackbar: $e');
          }
        }
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
          try {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.translate('location_permission_denied') ?? 
                  'تم رفض إذن الموقع. يرجى السماح بالوصول للموقع',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } catch (e) {
            if (kDebugMode) {
              print('Could not show snackbar: $e');
            }
          }
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        try {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('location_permission_denied_forever') ?? 
                'إذن الموقع مرفوض نهائياً. يرجى تفعيله من إعدادات التطبيق',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.translate('open_settings') ?? 'فتح الإعدادات',
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Could not show snackbar: $e');
          }
        }
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }

      // الحصول على الموقع
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLocationLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLocationLoading = false;
      });
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('location_error') ?? 
              'فشل في الحصول على الموقع: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } catch (err) {
        if (kDebugMode) {
          print('Could not show snackbar: $err');
        }
      }
    }
  }

  Future<void> _handleRegister(SimpleAuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      if (!mounted) return;
      try {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('must_agree_terms') ?? 'يجب الموافقة على الشروط والأحكام',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Could not show snackbar: $e');
        }
      }
      return;
    }

    // إذا كان تسجيل حرفي، استخدم التسجيل المبسط
    if (_isArtisanMode) {
      // التحقق من صحة البيانات الأساسية
      if (!_formKey.currentState!.validate()) return;
      
      if (!_agreeToTerms) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('must_agree_terms') ?? 'يجب الموافقة على الشروط والأحكام',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // تسجيل الحساب بالبيانات الأساسية فقط (بدون موقع أو بيانات إضافية)
      final success = await authProvider.registerArtisanBasic(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        try {
          if (!mounted) return;
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('account_created_successfully') ?? 'تم إنشاء الحساب بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
          
          // الانتظار قليلاً ثم التوجيه إلى صفحة تعديل الملف الشخصي
          await Future.delayed(const Duration(milliseconds: 500));
          
          // إعادة تحميل بيانات المستخدم للتأكد من الحصول على artisanId
          await authProvider.reloadUser();
          
          // الحصول على معرف الحرفي من المستخدم الحالي
          final currentUser = authProvider.currentUser;
          if (currentUser != null && currentUser.artisanId != null && currentUser.artisanId!.isNotEmpty) {
            context.go('/edit-artisan-profile/${currentUser.artisanId}');
          } else {
            // إذا لم يكن artisanId متاحاً بعد، انتظر قليلاً ثم حاول مرة أخرى
            await Future.delayed(const Duration(milliseconds: 1000));
            await authProvider.reloadUser();
            final user = authProvider.currentUser;
            if (user != null && user.artisanId != null && user.artisanId!.isNotEmpty) {
              context.go('/edit-artisan-profile/${user.artisanId}');
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)?.translate('account_created_complete_profile') ?? 'تم إنشاء الحساب. يرجى إكمال بيانات الملف الشخصي من الصفحة الرئيسية'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
                context.go('/home');
              }
            }
          }
        } catch (e) {
          if (mounted) {
            context.go('/home');
          }
        }
      } else {
        try {
          if (!mounted) return;
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 
                (AppLocalizations.of(context)?.translate('registration_failed') ?? 'فشل في إنشاء الحساب'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Could not show snackbar: $e');
          }
        }
      }
      return;
    }

    // تسجيل حساب عادي (مستخدم)
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      userType: 'user',
      craftType: null,
      description: null,
      yearsOfExperience: null,
      latitude: null,
      longitude: null,
    );

    if (!mounted) return;

    if (success) {
      // Get fresh references after mounted check and wrap in try-catch for safety
      try {
        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('account_created_successfully') ?? 'تم إنشاء الحساب بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      } catch (e) {
        // Widget was deactivated, just navigate
        if (mounted) context.go('/home');
      }
    } else {
      // Get fresh references after mounted check and wrap in try-catch for safety
      try {
        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 
              (AppLocalizations.of(context)?.translate('registration_failed') ?? 'فشل في إنشاء الحساب'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        // Widget was deactivated, ignore the error
        if (kDebugMode) {
          print('Could not show snackbar: $e');
        }
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);

    final success = await authProvider.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      // Get fresh references after mounted check and wrap in try-catch for safety
      try {
        if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 
              (AppLocalizations.of(context)?.translate('google_register_failed') ?? 'فشل في التسجيل مع Google'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        // Widget was deactivated, ignore the error
        if (kDebugMode) {
          print('Could not show snackbar: $e');
        }
      }
    }
  }

} 