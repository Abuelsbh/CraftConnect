import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text('تسجيل الدخول بالهاتف'),
      ),
      body: const Center(
        child: Text('قريباً: تسجيل الدخول برقم الهاتف باستخدام Firebase Phone Auth'),
      ),
    );
  }
} 