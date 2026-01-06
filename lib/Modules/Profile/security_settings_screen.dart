import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Utilities/app_constants.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../../Widgets/custom_button_widget.dart';
import '../../core/Language/locales.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'الأمان والخصوصية',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityOptions(),
            SizedBox(height: 24.h),
            _buildChangePasswordSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إعدادات الأمان',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildSecurityOption(
          icon: Icons.fingerprint,
          title: 'المصادقة البيومترية',
          subtitle: 'استخدام البصمة أو الوجه لتسجيل الدخول',
          onTap: () => _showBiometricSettings(),
        ),
        _buildSecurityOption(
          icon: Icons.lock,
          title: 'المصادقة الثنائية',
          subtitle: 'حماية إضافية لحسابك',
          onTap: () => _showTwoFactorSettings(),
        ),
        _buildSecurityOption(
          icon: Icons.devices,
          title: 'الأجهزة المتصلة',
          subtitle: 'إدارة الأجهزة التي تسجل الدخول من خلالها',
          onTap: () => _showConnectedDevices(),
        ),
        _buildSecurityOption(
          icon: Icons.history,
          title: 'سجل النشاط',
          subtitle: 'عرض سجل تسجيل الدخول والأنشطة',
          onTap: () => _showActivityLog(),
        ),
      ],
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: AppConstants.primaryColor,
            size: 20.sp,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16.sp,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildChangePasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تغيير كلمة المرور',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _currentPasswordController,
          hint: 'كلمة المرور الحالية',
          prefixIcon: const Icon(Icons.lock),
          obscure: true,
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _newPasswordController,
          hint: 'كلمة المرور الجديدة',
          prefixIcon: const Icon(Icons.lock_outline),
          obscure: true,
        ),
        SizedBox(height: 16.h),
        CustomTextFieldWidget(
          controller: _confirmPasswordController,
          hint: 'تأكيد كلمة المرور الجديدة',
          prefixIcon: const Icon(Icons.lock_outline),
          obscure: true,
        ),
        SizedBox(height: 24.h),
        CustomButtonWidget(
          title: _isLoading ? 'جاري التحديث...' : 'تحديث كلمة المرور',
          onTap: _isLoading ? () {} : _changePassword,
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.translate('password_mismatch') ?? 'كلمة المرور الجديدة وتأكيدها غير متطابقين'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.translate('password_min_6_chars') ?? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        await user.updatePassword(_newPasswordController.text);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('password_updated_success') ?? 'تم تحديث كلمة المرور بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Clear fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('password_update_failed') ?? 'خطأ في تحديث كلمة المرور'}: $e'),
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

  void _showBiometricSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('biometric_auth') ?? 'المصادقة البيومترية'),
        content: Text(AppLocalizations.of(context)?.translate('feature_coming_soon') ?? 'هذه الميزة ستكون متاحة في التحديث القادم'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.translate('ok') ?? 'موافق'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('two_factor_auth') ?? 'المصادقة الثنائية'),
        content: Text(AppLocalizations.of(context)?.translate('feature_coming_soon') ?? 'هذه الميزة ستكون متاحة في التحديث القادم'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.translate('ok') ?? 'موافق'),
          ),
        ],
      ),
    );
  }

  void _showConnectedDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('connected_devices') ?? 'الأجهزة المتصلة'),
        content: Text(AppLocalizations.of(context)?.translate('feature_coming_soon') ?? 'هذه الميزة ستكون متاحة في التحديث القادم'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.translate('ok') ?? 'موافق'),
          ),
        ],
      ),
    );
  }

  void _showActivityLog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('activity_log') ?? 'سجل النشاط'),
        content: Text(AppLocalizations.of(context)?.translate('feature_coming_soon') ?? 'هذه الميزة ستكون متاحة في التحديث القادم'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.translate('ok') ?? 'موافق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 