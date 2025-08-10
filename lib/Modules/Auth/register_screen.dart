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

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
        title: Text(AppLocalizations.of(context)?.translate('sign_up') ?? 'إنشاء حساب'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFieldWidget(
                controller: _nameController,
                hint: AppLocalizations.of(context)?.translate('name') ?? 'الاسم',
                prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.outline),
                validator: (v) => (v?.isEmpty ?? true) ? 'الاسم مطلوب' : null,
              ),
              SizedBox(height: AppConstants.padding),
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
              SizedBox(height: AppConstants.padding),
              CustomTextFieldWidget(
                controller: _phoneController,
                hint: AppLocalizations.of(context)?.translate('phone') ?? 'رقم الهاتف',
                textInputType: TextInputType.phone,
                prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.outline),
                validator: (v) => (v?.isEmpty ?? true) ? 'رقم الهاتف مطلوب' : null,
              ),
              SizedBox(height: AppConstants.padding),
              CustomTextFieldWidget(
                controller: _passwordController,
                hint: AppLocalizations.of(context)?.translate('enter_password') ?? 'أدخل كلمة المرور',
                obscure: true,
                prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.outline),
                validator: (v) {
                  if ((v?.length ?? 0) < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              Consumer<SimpleAuthProvider>(
                builder: (context, auth, _) {
                  return CustomButtonWidget(
                    title: AppLocalizations.of(context)?.translate('sign_up') ?? 'سجل الآن',
                    width: double.infinity,
                    height: 56.h,
                    onTap: auth.isLoading ? () {} : () async {
                      if (!_formKey.currentState!.validate()) return;
                      final ok = await auth.register(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                      );
                      if (ok && mounted) {
                        context.go('/home');
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(auth.errorMessage ?? 'فشل إنشاء الحساب')),
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