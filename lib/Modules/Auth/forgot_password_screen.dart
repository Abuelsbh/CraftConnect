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

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)?.translate('forgot_password') ?? 'استعادة كلمة المرور'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFieldWidget(
                controller: _emailController,
                hint: AppLocalizations.of(context)?.translate('enter_email') ?? 'أدخل بريدك الإلكتروني',
                textInputType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.outline),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'البريد الإلكتروني مطلوب';
                  final auth = context.read<SimpleAuthProvider>();
                  if (!auth.isEmailValid(value!)) return 'بريد إلكتروني غير صحيح';
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Consumer<SimpleAuthProvider>(
                builder: (context, auth, _) {
                  return CustomButtonWidget(
                    title: AppLocalizations.of(context)?.translate('send_reset_link') ?? 'إرسال رابط الاستعادة',
                    width: double.infinity,
                    height: 56.h,
                    onTap: auth.isLoading ? () {} : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final ok = await auth.resetPassword(_emailController.text.trim());
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إرسال رابط الاستعادة إلى بريدك')),
                        );
                        context.pop();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(auth.errorMessage ?? 'فشل إرسال الرابط')),
                        );
                      }
                    },
                    titleWidget: auth.isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 