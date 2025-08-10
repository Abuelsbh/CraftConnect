import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/simple_auth_provider.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    _emailController.dispose();
    _passwordController.dispose();
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
                  SizedBox(height: 40.h),
                  _buildHeader(),
                  SizedBox(height: 40.h),
                  _buildLoginForm(),
                  SizedBox(height: 20.h),
                  _buildForgotPassword(),
                  SizedBox(height: 30.h),
                  _buildLoginButton(),
                  SizedBox(height: 20.h),
                  _buildDivider(),
                  SizedBox(height: 20.h),
                  _buildSocialLogin(),
                  SizedBox(height: 30.h),
                  _buildSignUpPrompt(),
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
          AppLocalizations.of(context)?.translate('welcome_back') ?? 'مرحباً بعودتك',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppLocalizations.of(context)?.translate('login_subtitle') ?? 'سجل دخولك للمتابعة',
          style: TextStyle(
            fontSize: 16.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔧 حساب تجريبي:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'البريد: test@example.com',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                'كلمة المرور: 123456',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextFieldWidget(
            controller: _emailController,
            hint: AppLocalizations.of(context)?.translate('enter_email') ?? 'أدخل بريدك الإلكتروني',
            prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.outline),
            textInputType: TextInputType.emailAddress,
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
          SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              Text(
                AppLocalizations.of(context)?.translate('remember_me') ?? 'تذكرني',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: () {
          context.push('/forgot-password');
        },
        child: Text(
          AppLocalizations.of(context)?.translate('forgot_password') ?? 'نسيت كلمة المرور؟',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<SimpleAuthProvider>(
      builder: (context, authProvider, child) {
        return CustomButtonWidget(
          title: AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
          width: double.infinity,
          height: 56.h,
          onTap: authProvider.isLoading ? () {} : () => _handleLogin(authProvider),
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

  Widget _buildSocialLogin() {
    return Column(
      children: [
        _buildSocialButton(
          icon: Icons.g_mobiledata_rounded,
          text: AppLocalizations.of(context)?.translate('continue_with_google') ?? 'المتابعة مع Google',
          onPressed: () => _handleGoogleLogin(),
        ),
        SizedBox(height: AppConstants.smallPadding),
        _buildSocialButton(
          icon: Icons.phone_android_rounded,
          text: AppLocalizations.of(context)?.translate('continue_with_phone') ?? 'المتابعة برقم الهاتف',
          onPressed: () => _handlePhoneLogin(),
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

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('dont_have_account') ?? 'ليس لديك حساب؟',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        TextButton(
          onPressed: () {
            context.push('/register');
          },
          child: Text(
            AppLocalizations.of(context)?.translate('sign_up') ?? 'سجل الآن',
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

  Future<void> _handleLogin(SimpleAuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 
            (AppLocalizations.of(context)?.translate('login_failed') ?? 'فشل في تسجيل الدخول'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 
            (AppLocalizations.of(context)?.translate('google_login_failed') ?? 'فشل في تسجيل الدخول مع Google'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handlePhoneLogin() async {
    context.push('/phone-login');
  }
} 