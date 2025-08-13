import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/simple_auth_provider.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

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
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          AppLocalizations.of(context)?.translate('create_account') ?? 'إنشاء حساب جديد',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppLocalizations.of(context)?.translate('register_subtitle') ?? 'انضم إلينا واستمتع بخدماتنا',
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
        SizedBox(height: AppConstants.smallPadding),
        _buildSocialButton(
          icon: Icons.phone_android_rounded,
          text: AppLocalizations.of(context)?.translate('continue_with_phone') ?? 'المتابعة برقم الهاتف',
          onPressed: () => _handlePhoneRegister(),
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

  Future<void> _handleRegister(SimpleAuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
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

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.translate('account_created_successfully') ?? 'تم إنشاء الحساب بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 
            (AppLocalizations.of(context)?.translate('registration_failed') ?? 'فشل في إنشاء الحساب'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 
            (AppLocalizations.of(context)?.translate('google_register_failed') ?? 'فشل في التسجيل مع Google'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePhoneRegister() async {
    context.push('/phone-login');
  }
} 