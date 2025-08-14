import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/simple_auth_provider.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../Widgets/custom_textfield_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isEmailSent = false;

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
                  SizedBox(height: 40.h),
                  if (!_isEmailSent) ...[
                    _buildForgotPasswordForm(),
                    SizedBox(height: 30.h),
                    _buildResetButton(),
                  ] else ...[
                    _buildSuccessMessage(),
                    SizedBox(height: 30.h),
                    _buildBackToLoginButton(),
                  ],
                  SizedBox(height: 30.h),
                  _buildHelpSection(),
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
          AppLocalizations.of(context)?.translate('forgot_password') ?? 'نسيت كلمة المرور؟',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppLocalizations.of(context)?.translate('forgot_password_subtitle') ?? 
          'لا تقلق! أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور',
          style: TextStyle(
            fontSize: 16.sp,
            color: Theme.of(context).colorScheme.outline,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordForm() {
    return Form(
          key: _formKey,
          child: Column(
            children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.translate('reset_password_info') ?? 
                    'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
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
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Consumer<SimpleAuthProvider>(
      builder: (context, authProvider, child) {
                  return CustomButtonWidget(
          title: AppLocalizations.of(context)?.translate('send_reset_link') ?? 'إرسال رابط إعادة التعيين',
                    width: double.infinity,
                    height: 56.h,
          onTap: authProvider.isLoading ? () {} : () => _handleResetPassword(authProvider),
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

  Widget _buildSuccessMessage() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 32.w,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)?.translate('email_sent_successfully') ?? 'تم إرسال البريد بنجاح',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)?.translate('check_email_instructions') ?? 
            'تحقق من بريدك الإلكتروني واتبع التعليمات لإعادة تعيين كلمة المرور',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _emailController.text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Column(
      children: [
        CustomButtonWidget(
          title: AppLocalizations.of(context)?.translate('back_to_login') ?? 'العودة لتسجيل الدخول',
          width: double.infinity,
          height: 56.h,
          onTap: () => context.go('/login'),
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: () {
            setState(() {
              _isEmailSent = false;
              _emailController.clear();
            });
          },
          child: Text(
            AppLocalizations.of(context)?.translate('try_another_email') ?? 'جرب بريد إلكتروني آخر',
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

  Widget _buildHelpSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context)?.translate('need_help') ?? 'تحتاج مساعدة؟',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context)?.translate('help_instructions') ?? 
            '• تحقق من مجلد الرسائل غير المرغوب فيها\n• تأكد من صحة البريد الإلكتروني\n• انتظر بضع دقائق قبل المحاولة مرة أخرى',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: () {
              // يمكن إضافة رابط للدعم أو الاتصال
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.translate('contact_support') ?? 'سيتم إضافة معلومات الدعم قريباً',
                  ),
                ),
              );
            },
            icon: Icon(Icons.support_agent, size: 18.w),
            label: Text(
              AppLocalizations.of(context)?.translate('contact_support') ?? 'تواصل مع الدعم',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetPassword(SimpleAuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.resetPassword(_emailController.text.trim());

    if (success && mounted) {
      setState(() {
        _isEmailSent = true;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 
            (AppLocalizations.of(context)?.translate('reset_password_failed') ?? 'فشل في إرسال رابط إعادة التعيين'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 