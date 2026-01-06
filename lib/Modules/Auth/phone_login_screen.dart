import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/Language/locales.dart';

class PhoneLoginScreen extends StatelessWidget {
  const PhoneLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(AppLocalizations.of(context)?.translate('phone_login_title') ?? 'تسجيل الدخول بالهاتف'),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)?.translate('phone_login_coming_soon') ?? 'قريباً: تسجيل الدخول برقم الهاتف باستخدام Firebase Phone Auth'),
      ),
    );
  }
} 