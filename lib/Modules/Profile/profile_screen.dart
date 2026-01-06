import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../Utilities/app_constants.dart';
import '../../Utilities/theme_helper.dart';
import '../../Utilities/text_style_helper.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../Models/user_model.dart';
import '../../Models/artisan_model.dart';
import '../../core/Language/locales.dart';
import '../../core/Language/app_languages.dart';
import '../../core/Theme/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _userModel;
  bool _isLoading = true;
  SimpleAuthProvider? _authProvider;
  ArtisanModel? _artisanModel;
  bool _isLoadingArtisan = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // حفظ مرجع إلى Provider في didChangeDependencies
    _authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
  }

  void _loadUserData() {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    _authProvider = authProvider;
    
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      setState(() {
        _userModel = authProvider.currentUser;
        _isLoading = false;
      });
      
      // إذا كان المستخدم حرفي، جلب بيانات الحرفي
      if (_userModel?.userType == 'artisan' && _userModel?.artisanId != null) {
        _loadArtisanData(_userModel!.artisanId!);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
    
    // الاستماع لتحديثات بيانات المستخدم
    authProvider.addListener(_onUserDataChanged);
  }
  
  Future<void> _loadArtisanData(String artisanId) async {
    setState(() {
      _isLoadingArtisan = true;
    });
    
    try {
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      final artisan = await artisanProvider.getArtisanById(artisanId);
      
      if (mounted) {
        setState(() {
          _artisanModel = artisan;
          _isLoadingArtisan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingArtisan = false;
        });
      }
    }
  }
  
  void _onUserDataChanged() {
    // التحقق من أن الـ widget لا يزال mounted قبل الوصول إلى context
    if (!mounted) return;
    
    // استخدام المرجع المحفوظ بدلاً من الوصول إلى context
    final authProvider = _authProvider;
    if (authProvider == null) return;
    
    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      if (mounted) {
        setState(() {
          _userModel = authProvider.currentUser;
        });
      }
    }
  }
  
  @override
  void dispose() {
    // إزالة الـ listener قبل dispose
    _authProvider?.removeListener(_onUserDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    
    // إذا لم يكن المستخدم مسجل دخول، اعرض رسالة تسجيل الدخول
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      return Scaffold(
        backgroundColor: ThemeClass.of(context).accentColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    AppLocalizations.of(context)?.translate('login_required') ?? 'يجب تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    AppLocalizations.of(context)?.translate('login_required_message') ?? 'يجب تسجيل الدخول لعرض الملف الشخصي',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeClass.of(context).accentColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeClass.of(context).accentColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 24.h),

              // Profile Info
              _buildProfileInfo(),
              SizedBox(height: 24.h),
              
              // Availability Toggle (for artisans only)
              if (_userModel?.userType == 'artisan' && _userModel?.artisanId != null)
                _buildAvailabilitySection(),
              if (_userModel?.userType == 'artisan' && _userModel?.artisanId != null)
                SizedBox(height: 24.h),
              
              // Menu Items
              _buildMenuItems(),
              SizedBox(height: 24.h),
              
              // Logout Button
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
            final currentUser = authProvider.currentUser;
            
            // إذا كان المستخدم حرفي، اذهب إلى صفحة تعديل الملف الشخصي للحرفي
            if (currentUser != null && 
                currentUser.userType == 'artisan' && 
                currentUser.artisanId != null) {
              context.push('/edit-artisan-profile/${currentUser.artisanId}');
            } else {
              // إذا لم يكن حرفي، اذهب إلى صفحة التعديل العادية
              context.push('/edit-profile');
            }
          },
          child: Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
              image: _getProfileImageProvider(user?.profileImageUrl),
            ),
            child: _getProfileImageProvider(user?.profileImageUrl) == null
                ? Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30.sp,
                  )
                : null,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? (AppLocalizations.of(context)?.translate('user') ?? 'المستخدم'),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                user?.email ?? 'user@example.com',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
            final currentUser = authProvider.currentUser;
            
            // إذا كان المستخدم حرفي، اذهب إلى صفحة تعديل الملف الشخصي للحرفي
            if (currentUser != null && 
                currentUser.userType == 'artisan' && 
                currentUser.artisanId != null) {
              context.push('/edit-artisan-profile/${currentUser.artisanId}');
            } else {
              // إذا لم يكن حرفي، اذهب إلى صفحة التعديل العادية
              context.push('/edit-profile');
            }
          },
          icon: Icon(
            Icons.edit,

            color: Theme.of(context).colorScheme.primary,
            size: 24.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            AppLocalizations.of(context)?.translate('phone') ?? 'رقم الهاتف',
            user?.phone ?? (AppLocalizations.of(context)?.translate('not_specified') ?? 'غير محدد'),
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            AppLocalizations.of(context)?.translate('user_type') ?? 'نوع المستخدم',
            user?.userType == 'artisan'
                ? (AppLocalizations.of(context)?.translate('artisan') ?? 'حرفي')
                : (AppLocalizations.of(context)?.translate('user') ?? 'مستخدم'),
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            AppLocalizations.of(context)?.translate('join_date') ?? 'تاريخ الانضمام',
            _formatDate(user?.createdAt),
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            AppLocalizations.of(context)?.translate('last_update') ?? 'آخر تحديث',
            _formatDate(user?.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final user = authProvider.currentUser;
    
    // إذا كان المستخدم حرفي ولكن لم يتم تحميل بيانات الحرفي بعد
    if (_isLoadingArtisan) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // إذا لم يتم العثور على بيانات الحرفي
    if (_artisanModel == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.toggle_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate('availability_status') ?? 'حالة التوفر',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _artisanModel!.isAvailable
                          ? (AppLocalizations.of(context)?.translate('you_will_appear') ?? 'ستظهر للمستخدمين في البحث')
                          : (AppLocalizations.of(context)?.translate('you_will_not_appear') ?? 'لن تظهر للمستخدمين في البحث'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _artisanModel!.isAvailable,
                onChanged: (value) async {
                  await _toggleAvailability(value);
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(bool isAvailable) async {
    if (_artisanModel == null || _userModel?.artisanId == null) return;

    setState(() {
      _isLoadingArtisan = true;
    });

    try {
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      final success = await artisanProvider.updateAvailability(_userModel!.artisanId!, isAvailable);

      if (success) {
        // تحديث الحالة المحلية
        setState(() {
          _artisanModel = _artisanModel!.copyWith(isAvailable: isAvailable);
          _isLoadingArtisan = false;
        });

        // عرض رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('availability_updated') ?? 'تم تحديث حالة التوفر بنجاح',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoadingArtisan = false;
        });
        
        // عرض رسالة خطأ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('availability_update_failed') ?? 'فشل في تحديث حالة التوفر',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingArtisan = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.translate('availability_update_failed') ?? 'فشل في تحديث حالة التوفر'}: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildMenuItems() {
    final languageProvider = Provider.of<AppLanguage>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentLanguage = languageProvider.appLang;
    final isDarkMode = themeProvider.appTheme.isDark;
    
    final menuItems = [
      MenuItem(
        icon: Icons.edit,
        title: AppLocalizations.of(context)?.translate('edit_profile') ?? 'تعديل الملف الشخصي',
        onTap: () {
          final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
          final currentUser = authProvider.currentUser;
          
          // إذا كان المستخدم حرفي، اذهب إلى صفحة تعديل الملف الشخصي للحرفي
          if (currentUser != null && 
              currentUser.userType == 'artisan' && 
              currentUser.artisanId != null) {
            context.push('/edit-artisan-profile/${currentUser.artisanId}');
          } else {
            // إذا لم يكن حرفي، اذهب إلى صفحة التعديل العادية
            context.push('/edit-profile');
          }
        },
      ),
      MenuItem(
        icon: Icons.language,
        title: AppLocalizations.of(context)?.translate('language') ?? 'اللغة',
        subtitle: currentLanguage == Languages.ar 
            ? (AppLocalizations.of(context)?.translate('arabic') ?? 'العربية')
            : (AppLocalizations.of(context)?.translate('english') ?? 'English'),
        onTap: () => _showLanguageDialog(languageProvider),
      ),
      MenuItem(
        icon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
        title: AppLocalizations.of(context)?.translate('theme') ?? 'المظهر',
        subtitle: isDarkMode 
            ? (AppLocalizations.of(context)?.translate('dark_mode') ?? 'داكن')
            : (AppLocalizations.of(context)?.translate('light_mode') ?? 'فاتح'),
        onTap: () => _showThemeDialog(themeProvider),
      ),
      MenuItem(
        icon: Icons.help,
        title: AppLocalizations.of(context)?.translate('help_support') ?? 'المساعدة والدعم',
        onTap: () => context.push('/help-support'),
      ),
      MenuItem(
        icon: Icons.info,
        title: AppLocalizations.of(context)?.translate('about_app') ?? 'حول التطبيق',
        onTap: () => context.push('/about-app'),
      ),
      // رابط إدارة الحرف (يمكن إخفاؤه أو إظهاره حسب الحاجة)
      MenuItem(
        icon: Icons.admin_panel_settings,
        title: 'إدارة أنواع الحرف',
        subtitle: 'إضافة وتعديل وحذف الحرف',
        onTap: () => context.push('/admin/crafts'),
      ),
    ];

    return Column(
      children: menuItems.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            item.icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20.sp,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: item.subtitle != null
            ? Text(
                item.subtitle!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Theme.of(context).colorScheme.outline,
        ),
        onTap: item.onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
  
  void _showLanguageDialog(AppLanguage languageProvider) {
    final currentLanguage = languageProvider.appLang;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.translate('select_language') ?? 'اختر اللغة',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              title: Text(
                AppLocalizations.of(context)?.translate('arabic') ?? 'العربية',
                style: TextStyle(fontSize: 16.sp),
              ),
              trailing: currentLanguage == Languages.ar
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () async {
                if (currentLanguage != Languages.ar) {
                  await languageProvider.changeLanguage(language: Languages.ar);
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              title: Text(
                AppLocalizations.of(context)?.translate('english') ?? 'English',
                style: TextStyle(fontSize: 16.sp),
              ),
              trailing: currentLanguage == Languages.en
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () async {
                if (currentLanguage != Languages.en) {
                  await languageProvider.changeLanguage(language: Languages.en);
                }
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showThemeDialog(ThemeProvider themeProvider) {
    final isDarkMode = themeProvider.appTheme.isDark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.translate('select_theme') ?? 'اختر المظهر',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.light_mode, color: Theme.of(context).colorScheme.primary),
              title: Text(
                AppLocalizations.of(context)?.translate('light_mode') ?? 'الوضع الفاتح',
                style: TextStyle(fontSize: 16.sp),
              ),
              trailing: !isDarkMode
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () async {
                if (isDarkMode) {
                  await themeProvider.toggleDarkMode();
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
              title: Text(
                AppLocalizations.of(context)?.translate('dark_mode') ?? 'الوضع الداكن',
                style: TextStyle(fontSize: 16.sp),
              ),
              trailing: isDarkMode
                  ? Icon(Icons.check, color:Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () async {
                if (!isDarkMode) {
                  await themeProvider.toggleDarkMode();
                }
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)?.translate('logout') ?? 'تسجيل الخروج',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)?.translate('not_specified') ?? 'غير محدد';
    return '${date.day}/${date.month}/${date.year}';
  }

  DecorationImage? _getProfileImageProvider(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      return null;
    }

    // التحقق أولاً من نوع الصورة (URL أم base64)
    if (profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://')) {
      // URL قديم من Firebase Storage
      try {
        return DecorationImage(
          image: NetworkImage(profileImageUrl),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return null;
      }
    } else {
      // محاولة فك تشفير Base64
      try {
        final imageBytes = base64Decode(profileImageUrl);
        if (imageBytes.isEmpty) {
          return null;
        }
        return DecorationImage(
          image: MemoryImage(imageBytes),
          fit: BoxFit.cover,
        );
      } catch (e) {
        // إذا فشل فك التشفير، لا نعرض صورة
        return null;
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.translate('logout') ?? 'تسجيل الخروج',
        ),
        content: Text(
          AppLocalizations.of(context)?.translate('logout_confirmation') ?? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.translate('logout') ?? 'تسجيل الخروج',
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
        await authProvider.logout();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.translate('logout_error') ?? 'خطأ في تسجيل الخروج'}: $e',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
} 
