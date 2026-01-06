import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utilities/app_constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'المساعدة والدعم',
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
            _buildContactSection(),
            SizedBox(height: 24.h),
            _buildFAQSection(),
            SizedBox(height: 24.h),
            _buildHelpOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تواصل معنا',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildContactOption(
          icon: Icons.phone,
          title: 'اتصال هاتفي',
          subtitle: '+966 50 123 4567',
          onTap: () => _makePhoneCall('+966501234567'),
        ),
        _buildContactOption(
          icon: Icons.email,
          title: 'البريد الإلكتروني',
          subtitle: 'support@craftconnect.com',
          onTap: () => _sendEmail('support@craftconnect.com'),
        ),
        _buildContactOption(
          icon: Icons.chat,
          title: 'الدردشة المباشرة',
          subtitle: 'متاح من 9 صباحاً إلى 9 مساءً',
          onTap: () => _startLiveChat(),
        ),
        _buildContactOption(
          icon: Icons.location_on,
          title: 'العنوان',
          subtitle: 'الرياض، المملكة العربية السعودية',
          onTap: () => _openLocation(),
        ),
      ],
    );
  }

  Widget _buildContactOption({
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

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأسئلة الشائعة',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildFAQItem(
          question: 'كيف يمكنني العثور على حرفي؟',
          answer: 'يمكنك البحث عن الحرفيين من خلال الصفحة الرئيسية أو استخدام خدمة الخرائط للعثور على الحرفيين القريبين منك.',
        ),
        _buildFAQItem(
          question: 'كيف يمكنني تقييم الحرفي؟',
          answer: 'بعد انتهاء الخدمة، ستتمكن من تقييم الحرفي وكتابة مراجعة عن الخدمة المقدمة.',
        ),
        _buildFAQItem(
          question: 'ماذا لو لم أكن راضياً عن الخدمة؟',
          answer: 'يمكنك التواصل مع خدمة العملاء وسنعمل على حل المشكلة بأفضل طريقة ممكنة.',
        ),
        _buildFAQItem(
          question: 'كيف يتم الدفع؟',
          answer: 'يمكنك الدفع نقداً أو عبر التطبيق باستخدام البطاقات البنكية أو المحافظ الإلكترونية.',
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مساعدة إضافية',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildHelpOption(
          icon: Icons.description,
          title: 'دليل الاستخدام',
          subtitle: 'تعلم كيفية استخدام التطبيق',
          onTap: () => _openUserGuide(),
        ),
        _buildHelpOption(
          icon: Icons.video_library,
          title: 'فيديوهات تعليمية',
          subtitle: 'شاهد فيديوهات توضيحية',
          onTap: () => _openVideoTutorials(),
        ),
        _buildHelpOption(
          icon: Icons.bug_report,
          title: 'الإبلاغ عن مشكلة',
          subtitle: 'أبلغ عن خطأ أو مشكلة تقنية',
          onTap: () => _reportBug(),
        ),
        _buildHelpOption(
          icon: Icons.feedback,
          title: 'اقتراحات وملاحظات',
          subtitle: 'شاركنا آرائك لتحسين التطبيق',
          onTap: () => _sendFeedback(),
        ),
      ],
    );
  }

  Widget _buildHelpOption({
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=طلب دعم - PIX & FIX',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _startLiveChat() {
    // Implementation for live chat
  }

  void _openLocation() {
    // Implementation for opening location
  }

  void _openUserGuide() {
    // Implementation for user guide
  }

  void _openVideoTutorials() {
    // Implementation for video tutorials
  }

  void _reportBug() {
    // Implementation for bug reporting
  }

  void _sendFeedback() {
    // Implementation for feedback
  }
} 