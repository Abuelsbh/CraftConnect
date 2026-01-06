import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Models/artisan_model.dart';
import '../../Models/fault_report_model.dart';
import '../../Models/user_model.dart';
import '../../providers/fault_provider.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/artisan_service.dart';
import '../../services/fault_service.dart';
import '../../Utilities/app_constants.dart';
import '../../Utilities/theme_helper.dart';
import '../../Utilities/text_style_helper.dart';
import '../../core/Language/locales.dart';
import 'fault_report_screen.dart';
import 'widgets/video_player_dialog.dart';

class FaultReportsScreen extends StatefulWidget {
  const FaultReportsScreen({super.key});

  @override
  State<FaultReportsScreen> createState() => _FaultReportsScreenState();
}

class _FaultReportsScreenState extends State<FaultReportsScreen> {
  final ArtisanService _artisanService = ArtisanService();
  final FaultService _faultService = FaultService();
  String? _artisanCraftType;
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _isPlayingMap = {};
  final Map<String, Duration> _audioDurationMap = {};
  final Map<String, Duration> _audioPositionMap = {};
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _isVideoPlayingMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // التحقق من تسجيل الدخول أولاً
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
        // توجيه المستخدم إلى صفحة تسجيل الدخول مباشرة
        context.push('/login');
        return;
      }
      _loadReportsIfUser();
    });
  }

  @override
  void dispose() {
    // إيقاف وإغلاق جميع مشغلات الصوت
    for (var player in _audioPlayers.values) {
      player.stop();
      player.dispose();
    }
    _audioPlayers.clear();
    
    // إيقاف وإغلاق جميع مشغلات الفيديو
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    
    super.dispose();
  }

  // تحميل التقارير حسب نوع المستخدم
  Future<void> _loadReportsIfUser() async {
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    
    print('👤 تحميل التقارير - نوع المستخدم: ${currentUser?.userType}');
    print('   - معرف المستخدم: ${currentUser?.id}');
    print('   - معرف الحرفي: ${currentUser?.artisanId}');
    
    if (currentUser == null) {
      print('⚠️ لا يوجد مستخدم مسجل دخول');
      return;
    }
    
    if (currentUser.userType == 'user') {
      // إذا كان المستخدم عادي، جلب تقاريره
      print('📋 جلب تقارير المستخدم العادي...');
      context.read<FaultProvider>().loadUserFaultReports();
    } else if (currentUser.userType == 'artisan') {
      // إذا كان المستخدم حرفي، جلب بياناته ثم جلب الأعطال المناسبة
      print('🔧 المستخدم حرفي - جلب بيانات الحرفي...');
      ArtisanModel? artisan;
      
      // محاولة جلب الحرفي باستخدام artisanId
      if (currentUser.artisanId != null) {
        try {
          print('   - معرف الحرفي: ${currentUser.artisanId}');
          artisan = await _artisanService.getArtisanById(currentUser.artisanId!);
        } catch (e) {
          print('⚠️ خطأ في جلب الحرفي باستخدام artisanId: $e');
        }
      }
      
      // إذا لم يتم العثور على الحرفي، جرب البحث باستخدام userId
      if (artisan == null) {
        try {
          print('🔄 محاولة البحث عن الحرفي باستخدام userId: ${currentUser.id}');
          artisan = await _artisanService.getArtisanByUserId(currentUser.id);
        } catch (e) {
          print('⚠️ خطأ في جلب الحرفي باستخدام userId: $e');
        }
      }
      
      if (artisan != null) {
        print('✅ تم جلب بيانات الحرفي:');
        print('   - الاسم: ${artisan.name}');
        print('   - نوع الحرفة: ${artisan.craftType}');
        
        if (mounted) {
          setState(() {
            _artisanCraftType = artisan!.craftType;
          });
          // جلب الأعطال المناسبة لتخصص الحرفي
          print('🔍 جلب الأعطال المناسبة لنوع الحرفة: ${artisan.craftType}');
          // استخدام artisanId إذا كان متوفراً، وإلا استخدام userId
          final artisanIdForFilter = currentUser.artisanId ?? currentUser.id;
          await context.read<FaultProvider>().loadArtisanFaultReports(artisan.craftType, artisanId: artisanIdForFilter);
        }
      } else {
        print('⚠️ لم يتم العثور على بيانات الحرفي');
        print('   - artisanId: ${currentUser.artisanId}');
        print('   - userId: ${currentUser.id}');
        print('   - email: ${currentUser.email}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
      floatingActionButton: Consumer<SimpleAuthProvider>(
        builder: (context, authProvider, child) {
          final currentUser = authProvider.currentUser;
          // إخفاء زر الإضافة للحرفيين (لا يمكنهم إنشاء أعطال)
          if (currentUser?.userType == 'artisan') {
            return const SizedBox.shrink();
          }
          
          // فحص تسجيل الدخول
          if (!authProvider.isLoggedIn || currentUser == null) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: () {
              // إذا كان مسجل دخول، انتقل إلى صفحة رفع المشكلة
              context.push('/problem-report-stepper');
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              AppLocalizations.of(context)?.translate('problem_picture') ?? 'صورة المشكلة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Text(
              AppLocalizations.of(context)?.translate('fault_reports_title') ?? 'تقارير الأعطال الفنية',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            // Content
            Expanded(
              child: Consumer2<FaultProvider, SimpleAuthProvider>(
                builder: (context, faultProvider, authProvider, child) {
                  final currentUser = authProvider.currentUser;

                  // التحقق من نوع المستخدم - إذا لم يكن مسجل دخول، لن يصل هنا
                  if (currentUser == null) {
                    return const SizedBox.shrink();
                  }

                  if (faultProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (faultProvider.faultReports.isEmpty) {
                    if (currentUser.userType == 'artisan') {
                      return _buildArtisanEmptyState();
                    }
                    return _buildEmptyState();
                  }

                  return _buildReportsList(faultProvider.faultReports);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)?.translate('no_fault_reports') ?? 'لا توجد تقارير أعطال',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)?.translate('no_fault_reports_description') ?? 'لم تقم بإنشاء أي تقرير عطل فني بعد',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.push('/fault-report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)?.translate('create_new_report') ?? 'إنشاء تقرير جديد',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)?.translate('no_faults_available') ?? 'لا توجد أعطال متاحة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)?.translate('no_faults_available_description') ?? 'لا توجد أعطال في انتظار المعالجة تتوافق مع تخصصك حالياً',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)?.translate('login_required') ?? 'يجب تسجيل الدخول أولاً',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(List<FaultReportModel> reports) {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<SimpleAuthProvider>();
        final currentUser = authProvider.currentUser;
        if (currentUser == null) return;
        
        if (currentUser.userType == 'user') {
          await context.read<FaultProvider>().loadUserFaultReports();
        } else if (currentUser.userType == 'artisan') {
          // إعادة تحميل الأعطال للحرفي
          ArtisanModel? artisan;
          
          if (currentUser.artisanId != null) {
            artisan = await _artisanService.getArtisanById(currentUser.artisanId!);
          }
          
          if (artisan == null) {
            artisan = await _artisanService.getArtisanByUserId(currentUser.id);
          }
          
          if (artisan != null) {
            final artisanIdForFilter = currentUser.artisanId ?? currentUser.id;
            await context.read<FaultProvider>().loadArtisanFaultReports(artisan.craftType, artisanId: artisanIdForFilter);
          }
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildVideoThumbnail(FaultReportModel report) {
    final reportId = report.id;
    final videoUrl = report.videoUrl!;

    // إنشاء مشغل فيديو للحصول على الإطار الأول كمعاينة
    if (!_videoControllers.containsKey(reportId)) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      controller.initialize().then((_) {
        if (mounted) {
          // التأكد من أن الفيديو متوقف عند الإطار الأول
          controller.pause();
          controller.seekTo(Duration.zero);
          setState(() {});
        }
      });
      _videoControllers[reportId] = controller;
    }

    final controller = _videoControllers[reportId];
    final isInitialized = controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      child: Container(
        width: double.infinity,
        height: 200.h,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isInitialized)
              AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            else
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            // طبقة شفافة مع أيقونة التشغيل
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(FaultReportModel report) {
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    final isOwner = currentUser != null && currentUser.id == report.userId;
    final isInactive = !report.isActive;
    final isArtisan = currentUser?.userType == 'artisan';
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة أو فيديو العطل في الأعلى
            if (report.videoUrl != null && report.videoUrl!.isNotEmpty)
              _buildVideoThumbnail(report)
            else if (report.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: CachedNetworkImage(
                  imageUrl: report.imageUrls.first,
                  width: double.infinity,
                  height: 200.h,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200.h,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200.h,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48.sp,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            
            // محتوى الكارد
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات الموقع والوقت
                  FutureBuilder<UserModel?>(
                    future: _getUserInfo(report.userId),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final userName = user?.name ?? (AppLocalizations.of(context)?.translate('user') ?? 'مستخدم');
                      final locationText = report.address ?? (AppLocalizations.of(context)?.translate('location_undefined') ?? 'موقع غير محدد');
                      final hasProfileImage = user != null && user.profileImageUrl.isNotEmpty;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16.sp,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              SizedBox(width: 4.w),
                              if (hasProfileImage) ...[
                                CircleAvatar(
                                  radius: 12.r,
                                  backgroundImage: CachedNetworkImageProvider(user.profileImageUrl),
                                  onBackgroundImageError: (_, __) {},
                                ),
                                SizedBox(width: 6.w),
                              ],
                              Expanded(
                                child: Text(
                                  '$userName • $locationText',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          
                          // الوقت
                          Text(
                            _formatDate(report.createdAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 12.h),
                  
                  // علامات الحالة والأزرار
                  Row(
                    children: [
                      // علامة URGENT (إذا كان pending)
                      if (report.status == 'pending' && report.isActive)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.translate('urgent') ?? 'URGENT',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      // علامة Normal (دائماً تظهر)
                      if (report.status == 'pending' && report.isActive)
                        SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: const Color(0xFF17A2B8), width: 1),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.translate('normal') ?? 'Normal',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF17A2B8),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // زر Decline للحرفيين
                      if (isArtisan && !isOwner && report.isActive)
                        ElevatedButton(
                          onPressed: () {
                            _declineReport(report);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B1FA2), // بنفسجي
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.translate('decline') ?? 'Decline',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // دالة لجلب معلومات المستخدم
  Future<UserModel?> _getUserInfo(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return UserModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('خطأ في جلب معلومات المستخدم: $e');
      return null;
    }
  }
  
  // دالة لرفض التقرير
  void _declineReport(FaultReportModel report) async {
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.translate('login_required') ?? 'يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // استخدام artisanId إذا كان متوفراً، وإلا استخدام userId
    final artisanId = currentUser.artisanId ?? currentUser.id;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('decline_report') ?? 'رفض التقرير'),
        content: Text(AppLocalizations.of(context)?.translate('decline_report_confirmation') ?? 'هل أنت متأكد من رفض هذا التقرير؟ لن يظهر لك مرة أخرى.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // إظهار مؤشر التحميل
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)?.translate('declining_report') ?? 'جاري رفض التقرير...'),
                  duration: const Duration(seconds: 1),
                ),
              );
              
              // استدعاء دالة Decline
              final success = await context.read<FaultProvider>().declineFaultReport(report.id, artisanId);
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)?.translate('report_declined_success') ?? 'تم رفض التقرير بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)?.translate('report_declined_failed') ?? 'فشل في رفض التقرير'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)?.translate('confirm') ?? 'تأكيد'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    final localizations = AppLocalizations.of(context);
    switch (status) {
      case 'pending':
        return localizations?.translate('pending') ?? 'في الانتظار';
      case 'in_progress':
        return localizations?.translate('in_progress') ?? 'قيد التنفيذ';
      case 'completed':
        return localizations?.translate('completed') ?? 'مكتمل';
      case 'cancelled':
        return localizations?.translate('cancelled') ?? 'ملغي';
      default:
        return localizations?.translate('unknown_status') ?? 'غير محدد';
    }
  }

  String _getFaultTypeText(String faultType) {
    final localizations = AppLocalizations.of(context);
    switch (faultType) {
      case 'carpenter':
        return localizations?.translate('fault_type_carpenter') ?? 'عطل نجارة';
      case 'electrical':
        return localizations?.translate('fault_type_electrical') ?? 'عطل كهربائي';
      case 'plumbing':
        return localizations?.translate('fault_type_plumbing') ?? 'عطل سباكة';
      case 'painter':
        return localizations?.translate('fault_type_painter') ?? 'عطل دهان';
      case 'mechanic':
        return localizations?.translate('fault_type_mechanic') ?? 'عطل ميكانيكي';
      case 'hvac':
        return localizations?.translate('fault_type_hvac') ?? 'عطل تكييف';
      case 'satellite':
        return localizations?.translate('fault_type_satellite') ?? 'عطل ستالايت';
      case 'internet':
        return localizations?.translate('fault_type_internet') ?? 'عطل إنترنت';
      case 'tiler':
        return localizations?.translate('fault_type_tiler') ?? 'عطل بلاط';
      case 'locksmith':
        return localizations?.translate('fault_type_locksmith') ?? 'عطل أقفال';
      case 'appliance':
        return localizations?.translate('fault_type_appliance') ?? 'عطل جهاز';
      case 'other':
        return localizations?.translate('fault_type_other') ?? 'عطل آخر';
      default:
        return faultType;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final localizations = AppLocalizations.of(context);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${localizations?.translate('days') ?? 'يوم'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${localizations?.translate('hours') ?? 'ساعة'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${localizations?.translate('minutes') ?? 'دقيقة'}';
    } else {
      return localizations?.translate('now') ?? 'الآن';
    }
  }

  void _showReportDetails(FaultReportModel report) {
    context.push('/fault-report-details/${report.id}');
  }

  void _showReportDetailsOld(FaultReportModel report) async {
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    
    // تحديث عدد المشاهدات إذا كان المستخدم حرفي وليس صاحب العطل
    if (currentUser != null && 
        currentUser.userType == 'artisan' && 
        currentUser.id != report.userId) {
      try {
        await _faultService.incrementFaultViews(report.id);
        // تحديث التقرير محلياً
        final updatedReport = report.copyWith(viewsCount: report.viewsCount + 1);
        context.read<FaultProvider>().updateReportLocally(updatedReport);
      } catch (e) {
        print('⚠️ خطأ في تحديث عدد المشاهدات: $e');
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context)?.translate('report_details') ?? 'تفاصيل التقرير',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Active Status
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _getStatusColor(report.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _getStatusText(report.status),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(report.status),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (!report.isActive)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.block, size: 14.sp, color: Theme.of(context).colorScheme.error),
                                SizedBox(width: 4.w),
                                Text(
                                  AppLocalizations.of(context)?.translate('inactive') ?? 'غير فعال',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // Fault Type
                    _buildDetailRow(
                      AppLocalizations.of(context)?.translate('fault_type_label') ?? 'نوع العطل', 
                      _getFaultTypeText(report.faultType)
                    ),
                    _buildDetailRow(
                      AppLocalizations.of(context)?.translate('service_type') ?? 'نوع الخدمة', 
                      report.serviceType
                    ),
                    _buildDetailRow(
                      AppLocalizations.of(context)?.translate('created_date') ?? 'تاريخ الإنشاء', 
                      _formatDate(report.createdAt)
                    ),
                    
                    // Scheduled Date
                    if (report.isScheduled && report.scheduledDate != null)
                      _buildDetailRow(
                        AppLocalizations.of(context)?.translate('scheduled_date_label') ?? 'تاريخ مجدول', 
                        _formatScheduledDate(report.scheduledDate!)
                      ),
                    
                    // Address
                    if (report.address != null)
                      _buildLocationRow(
                        AppLocalizations.of(context)?.translate('address') ?? 'العنوان', 
                        report.address!, 
                        report.latitude, 
                        report.longitude
                      ),
                    
                    // Location
                    if (report.latitude != null && report.longitude != null)
                      _buildLocationRow(
                        AppLocalizations.of(context)?.translate('location_label') ?? 'الموقع', 
                        '${report.latitude!.toStringAsFixed(6)}, ${report.longitude!.toStringAsFixed(6)}', 
                        report.latitude, 
                        report.longitude
                      ),
                    
                    // Views Count (for report owner only)
                    if (currentUser != null && currentUser.id == report.userId && report.viewsCount > 0)
                      _buildDetailRow(
                        AppLocalizations.of(context)?.translate('views_count') ?? 'عدد المشاهدات', 
                        '${report.viewsCount} ${AppLocalizations.of(context)?.translate('artisan_viewed') ?? 'حرفي شاهد هذا العطل'}'
                      ),
                    
                    SizedBox(height: 16.h),
                    
                    // Description
                    Text(
                      AppLocalizations.of(context)?.translate('description_label') ?? 'الوصف',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      report.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    
                    // Images
                    if (report.imageUrls.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        AppLocalizations.of(context)?.translate('attached_images') ?? 'الصور المرفقة',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 100.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: report.imageUrls.length,
                          itemBuilder: (context, index) {
                            final imageUrl = report.imageUrls[index];
                            return GestureDetector(
                              onTap: () {
                                _showImagePreview(report.imageUrls, index);
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: 8.w),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    imageUrl,
                                    width: 100.w,
                                    height: 100.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    
                    // Video
                    if (report.videoUrl != null && report.videoUrl!.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        AppLocalizations.of(context)?.translate('attached_video') ?? 'الفيديو المرفق',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () => _showVideoPlayerDialog(report),
                        child: _buildVideoPlayer(report),
                      ),
                    ],
                    
                    // Voice Recording
                    if (report.voiceRecordingUrl != null) ...[
                      SizedBox(height: 16.h),
                      Text(
                        AppLocalizations.of(context)?.translate('voice_recording_label') ?? 'التسجيل الصوتي',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _buildAudioPlayer(report),
                    ],
                    
                    // Notes (if assigned)
                    if (report.notes != null && report.notes!.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        AppLocalizations.of(context)?.translate('notes') ?? 'ملاحظات',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          report.notes!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 24.h),
                    
                    // Action Buttons
                    Column(
                      children: [
                        // Edit Button (only for owner)
                        if (currentUser != null && currentUser.id == report.userId)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // إغلاق bottom sheet
                                context.push('/problem-report-stepper?reportId=${report.id}');
                              },
                              icon: Icon(Icons.edit, size: 20.sp),
                              label: Text(
                                AppLocalizations.of(context)?.translate('edit_report') ?? 'تعديل التقرير',
                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        
                        // Deactivate/Activate Button (only for owner)
                        if (currentUser != null && currentUser.id == report.userId)
                          SizedBox(height: 12.h),
                        if (currentUser != null && currentUser.id == report.userId)
                          Consumer<FaultProvider>(
                            builder: (context, faultProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: faultProvider.isLoading
                                      ? null
                                      : () => _toggleFaultActiveStatus(report, faultProvider),
                                  icon: Icon(
                                    report.isActive ? Icons.block : Icons.check_circle,
                                    size: 20.sp,
                                  ),
                                  label: Text(
                                    report.isActive 
                                        ? (AppLocalizations.of(context)?.translate('deactivate_fault') ?? 'إلغاء تفعيل العطل')
                                        : (AppLocalizations.of(context)?.translate('activate_fault') ?? 'تفعيل العطل'),
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: report.isActive ? Colors.orange : Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        
                        // Message Button (only if not the owner and fault is active)
                        if (currentUser != null && 
                            currentUser.id != report.userId && 
                            report.isActive)
                          SizedBox(height: 12.h),
                        if (currentUser != null && 
                            currentUser.id != report.userId && 
                            report.isActive)
                          Consumer<ChatProvider>(
                            builder: (context, chatProvider, child) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _startChatWithUser(report.userId, chatProvider),
                                  icon: Icon(Icons.message, size: 20.sp),
                                  label: Text(
                                    AppLocalizations.of(context)?.translate('message_fault_owner') ?? 'مراسلة صاحب العطل',
                                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
      },
    );
  }
  
  String _formatScheduledDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _startChatWithUser(String userId, ChatProvider chatProvider) async {
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.translate('login_required') ?? 'يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final room = await chatProvider.createChatRoomAndReturn(userId);
      
      if (room != null) {
        await chatProvider.openChatRoom(room.id);
        if (mounted) {
          Navigator.pop(context); // إغلاق صفحة التفاصيل
          context.push('/chat-room');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('chat_creation_failed') ?? 'فشل في إنشاء المحادثة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('chat_creation_error') ?? 'خطأ في إنشاء المحادثة'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// عرض معاينة مكبرة للصور المرفقة في التقرير
  void _showImagePreview(List<String> imageUrls, int initialIndex) {
    if (imageUrls.isEmpty) return;

    final PageController pageController = PageController(initialPage: initialIndex);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                // الصور مع إمكانية التكبير
                PageView.builder(
                  controller: pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final url = imageUrls[index];
                    return GestureDetector(
                      // إغلاق عند الضغط على الخلفية (وليس على الصورة)
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 5.0,
                            panEnabled: true,
                            scaleEnabled: true,
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.white,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 48.sp,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        AppLocalizations.of(context)?.translate('image_load_failed') ?? 'فشل تحميل الصورة',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // زر الإغلاق
                Positioned(
                  top: 40.h,
                  right: 16.w,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                
                // مؤشر الصورة الحالية (إذا كان هناك أكثر من صورة)
                if (imageUrls.length > 1)
                  Positioned(
                    bottom: 30.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${imageUrls.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String value, double? latitude, double? longitude) {
    final canOpenMap = latitude != null && longitude != null;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: canOpenMap ? () => _openLocationInMaps(latitude!, longitude!) : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: canOpenMap 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: canOpenMap ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ),
                  if (canOpenMap) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.map,
                      size: 18.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLocationInMaps(double latitude, double longitude) async {
    // إنشاء رابط جوجل ماب
    final url = 'https://www.google.com/maps?q=$latitude,$longitude';
    
    try {
      print('📍 فتح الموقع في الخرائط: $url');
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('location_opened_success') ?? 'تم فتح الموقع في الخرائط'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('لا يمكن فتح الرابط');
      }
    } catch (e) {
      print('❌ خطأ في فتح الخرائط: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.translate('location_open_failed') ?? 'فشل في فتح الخرائط'}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAudioPlayer(FaultReportModel report) {
    final reportId = report.id;
    final isPlaying = _isPlayingMap[reportId] ?? false;
    final duration = _audioDurationMap[reportId] ?? Duration.zero;
    final position = _audioPositionMap[reportId] ?? Duration.zero;

    // إنشاء مشغل صوتي إذا لم يكن موجوداً
    if (!_audioPlayers.containsKey(reportId)) {
      final player = AudioPlayer();
      _audioPlayers[reportId] = player;
      _isPlayingMap[reportId] = false;
      _audioDurationMap[reportId] = Duration.zero;
      _audioPositionMap[reportId] = Duration.zero;

      // إعداد listeners
      player.onDurationChanged.listen((newDuration) {
        if (mounted) {
          setState(() {
            _audioDurationMap[reportId] = newDuration;
          });
        }
      });

      player.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() {
            _audioPositionMap[reportId] = newPosition;
          });
        }
      });

      player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingMap[reportId] = state == PlayerState.playing;
            if (state == PlayerState.completed) {
              _audioPositionMap[reportId] = Duration.zero;
            }
          });
        }
      });
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: Colors.blue[700],
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.translate('voice_recording_label') ?? 'التسجيل الصوتي',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // شريط التقدم
          if (duration.inMilliseconds > 0) ...[
            Slider(
              value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
              max: duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _audioPlayers[reportId]?.seek(Duration(milliseconds: value.toInt()));
              },
              activeColor: Colors.blue[700],
              inactiveColor: Colors.blue[200],
            ),
            SizedBox(height: 8.h),
          ],
          
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () => _playAudioFromUrl(report.voiceRecordingUrl!, reportId),
                child: Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _playAudioFromUrl(String url, String reportId) async {
    final player = _audioPlayers[reportId];
    if (player == null) return;

    try {
      if (_isPlayingMap[reportId] == true) {
        await player.pause();
      } else {
        await player.play(UrlSource(url));
      }
    } catch (e) {
      print('❌ خطأ في تشغيل التسجيل الصوتي: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('play_voice_failed') ?? 'فشل في تشغيل التسجيل الصوتي'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildVideoPlayer(FaultReportModel report) {
    final reportId = report.id;
    final videoUrl = report.videoUrl!;
    final isPlaying = _isVideoPlayingMap[reportId] ?? false;

    // إنشاء مشغل فيديو إذا لم يكن موجوداً
    if (!_videoControllers.containsKey(reportId)) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      controller.initialize().then((_) {
        if (mounted) {
          setState(() {});
          // إضافة listener لتتبع حالة التشغيل
          controller.addListener(() {
            if (mounted) {
              setState(() {
                _isVideoPlayingMap[reportId] = controller.value.isPlaying;
              });
            }
          });
        }
      });
      _videoControllers[reportId] = controller;
    }

    final controller = _videoControllers[reportId];
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 200.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 64.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppLocalizations.of(context)?.translate('tap_to_zoom') ?? 'اضغط للتكبير',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoPlayerDialog(FaultReportModel report) {
    final videoUrl = report.videoUrl!;
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => VideoPlayerDialog(videoUrl: videoUrl),
    );
  }

  Future<void> _toggleFaultActiveStatus(FaultReportModel report, FaultProvider faultProvider) async {
    final newStatus = !report.isActive;
    
    // تأكيد من المستخدم
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus 
              ? (AppLocalizations.of(context)?.translate('activate_fault') ?? 'تفعيل العطل')
              : (AppLocalizations.of(context)?.translate('deactivate_fault') ?? 'إلغاء تفعيل العطل')
        ),
        content: Text(
          newStatus
              ? (AppLocalizations.of(context)?.translate('activate_fault_confirmation') ?? 'هل أنت متأكد من تفعيل هذا العطل؟ سيظهر مرة أخرى للحرفيين.')
              : (AppLocalizations.of(context)?.translate('deactivate_fault_confirmation') ?? 'هل أنت متأكد من إلغاء تفعيل هذا العطل؟ لن يظهر للحرفيين بعد الآن.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text(AppLocalizations.of(context)?.translate('confirm') ?? 'تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await faultProvider.updateFaultActiveStatus(report.id, newStatus);
      
      if (success && mounted) {
        Navigator.pop(context); // إغلاق صفحة التفاصيل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? (AppLocalizations.of(context)?.translate('fault_activated_success') ?? 'تم تفعيل العطل بنجاح')
                  : (AppLocalizations.of(context)?.translate('fault_deactivated_success') ?? 'تم إلغاء تفعيل العطل بنجاح'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('fault_status_update_failed') ?? 'فشل في تحديث حالة العطل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}