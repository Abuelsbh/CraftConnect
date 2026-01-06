import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Utilities/app_constants.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _chatNotifications = true;
  bool _orderNotifications = true;
  bool _promotionalNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _chatNotifications = prefs.getBool('chat_notifications') ?? true;
      _orderNotifications = prefs.getBool('order_notifications') ?? true;
      _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('chat_notifications', _chatNotifications);
    await prefs.setBool('order_notifications', _orderNotifications);
    await prefs.setBool('promotional_notifications', _promotionalNotifications);
    await prefs.setBool('sound_enabled', _soundEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

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
          'إعدادات الإشعارات',
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
            _buildSectionTitle('الإشعارات العامة'),
            _buildNotificationTile(
              title: 'الإشعارات المدفوعة',
              subtitle: 'استقبال الإشعارات على الجهاز',
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
                _saveSettings();
              },
            ),
            _buildNotificationTile(
              title: 'إشعارات البريد الإلكتروني',
              subtitle: 'استقبال الإشعارات عبر البريد الإلكتروني',
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
                _saveSettings();
              },
            ),
            
            SizedBox(height: 24.h),
            _buildSectionTitle('إشعارات التطبيق'),
            _buildNotificationTile(
              title: 'إشعارات المحادثة',
              subtitle: 'رسائل جديدة من الحرفيين',
              value: _chatNotifications,
              onChanged: (value) {
                setState(() {
                  _chatNotifications = value;
                });
                _saveSettings();
              },
            ),
            _buildNotificationTile(
              title: 'إشعارات الطلبات',
              subtitle: 'تحديثات حالة الطلبات',
              value: _orderNotifications,
              onChanged: (value) {
                setState(() {
                  _orderNotifications = value;
                });
                _saveSettings();
              },
            ),
            _buildNotificationTile(
              title: 'الإشعارات الترويجية',
              subtitle: 'عروض خاصة وتخفيضات',
              value: _promotionalNotifications,
              onChanged: (value) {
                setState(() {
                  _promotionalNotifications = value;
                });
                _saveSettings();
              },
            ),
            
            SizedBox(height: 24.h),
            _buildSectionTitle('إعدادات الصوت'),
            _buildNotificationTile(
              title: 'الصوت',
              subtitle: 'تشغيل الأصوات مع الإشعارات',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _saveSettings();
              },
            ),
            _buildNotificationTile(
              title: 'الاهتزاز',
              subtitle: 'اهتزاز الجهاز مع الإشعارات',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppConstants.primaryColor,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }
} 