import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utilities/app_constants.dart';
import '../../generated/assets.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
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
          'حول التطبيق',
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
          children: [
            // App Logo and Info
            _buildAppInfo(),
            SizedBox(height: 32.h),
            
            // App Features
            _buildFeatures(),
            SizedBox(height: 32.h),
            
            // Legal and Links
            _buildLegalSection(),
            SizedBox(height: 32.h),
            
            // Social Media
            _buildSocialMedia(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Image.asset(
              Assets.iconsLogo,
              width: 100.w,
              height: 100.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'PIX & FIX',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'ربط الحرفيين بالعملاء',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'الإصدار $_version ($_buildNumber)',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            'تطبيق PIX & FIX يهدف إلى ربط الحرفيين المهرة بالعملاء الذين يحتاجون إلى خدماتهم. نحن نؤمن بأهمية الحرف التقليدية والمهارات اليدوية في مجتمعنا.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ميزات التطبيق',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildFeatureItem(
          icon: Icons.search,
          title: 'البحث عن الحرفيين',
          description: 'ابحث عن الحرفيين بحسب التخصص والموقع',
        ),
        _buildFeatureItem(
          icon: Icons.chat,
          title: 'التواصل المباشر',
          description: 'تحدث مع الحرفيين مباشرة عبر التطبيق',
        ),
        _buildFeatureItem(
          icon: Icons.star,
          title: 'التقييمات والمراجعات',
          description: 'اقرأ وأضف تقييمات للحرفيين',
        ),
        _buildFeatureItem(
          icon: Icons.location_on,
          title: 'الخرائط التفاعلية',
          description: 'اعثر على الحرفيين القريبين منك',
        ),
        _buildFeatureItem(
          icon: Icons.assignment,
          title: 'إدارة الطلبات',
          description: 'تتبع طلباتك وحالة الخدمات',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
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
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قانونية وروابط',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        _buildLegalItem(
          title: 'شروط الاستخدام',
          onTap: () => _openTermsOfService(),
        ),
        _buildLegalItem(
          title: 'سياسة الخصوصية',
          onTap: () => _openPrivacyPolicy(),
        ),
        _buildLegalItem(
          title: 'اتفاقية الترخيص',
          onTap: () => _openLicenseAgreement(),
        ),
        _buildLegalItem(
          title: 'مكتبات مفتوحة المصدر',
          onTap: () => _showOpenSourceLicenses(),
        ),
      ],
    );
  }

  Widget _buildLegalItem({
    required String title,
    required VoidCallback onTap,
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

  Widget _buildSocialMedia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تابعنا على',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              icon: Icons.facebook,
              color: const Color(0xFF1877F2),
              onTap: () => _openSocialMedia('facebook'),
            ),
            _buildSocialButton(
              icon: Icons.alternate_email,
              color: const Color(0xFF1DA1F2),
              onTap: () => _openSocialMedia('twitter'),
            ),
            _buildSocialButton(
              icon: Icons.camera_alt,
              color: const Color(0xFFE4405F),
              onTap: () => _openSocialMedia('instagram'),
            ),
            _buildSocialButton(
              icon: Icons.business,
              color: const Color(0xFF0A66C2),
              onTap: () => _openSocialMedia('linkedin'),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Center(
          child: Text(
            '© 2024 PIX & FIX. جميع الحقوق محفوظة.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  void _openTermsOfService() {
    _openUrl('https://craftconnect.com/terms');
  }

  void _openPrivacyPolicy() {
    _openUrl('https://craftconnect.com/privacy');
  }

  void _openLicenseAgreement() {
    _openUrl('https://craftconnect.com/license');
  }

  void _showOpenSourceLicenses() {
    showLicensePage(context: context);
  }

  void _openSocialMedia(String platform) {
    final urls = {
      'facebook': 'https://facebook.com/craftconnect',
      'twitter': 'https://twitter.com/craftconnect',
      'instagram': 'https://instagram.com/craftconnect',
      'linkedin': 'https://linkedin.com/company/craftconnect',
    };
    
    final url = urls[platform];
    if (url != null) {
      _openUrl(url);
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
} 