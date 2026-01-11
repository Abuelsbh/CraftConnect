import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Models/fault_report_model.dart';
import '../../Models/user_model.dart';
import '../../providers/fault_provider.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/fault_service.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../generated/assets.dart';
import 'widgets/video_player_dialog.dart';

class FaultReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const FaultReportDetailsScreen({super.key, required this.reportId});

  @override
  State<FaultReportDetailsScreen> createState() => _FaultReportDetailsScreenState();
}

class _FaultReportDetailsScreenState extends State<FaultReportDetailsScreen> {
  final FaultService _faultService = FaultService();
  FaultReportModel? _report;
  bool _isLoading = true;
  int _declinedCount = 0;
  
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _isPlayingMap = {};
  final Map<String, Duration> _audioDurationMap = {};
  final Map<String, Duration> _audioPositionMap = {};
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _isVideoPlayingMap = {};

  @override
  void initState() {
    super.initState();
    _loadReport().then((_) {
      _incrementViews();
      _loadDeclinedCount();
    });
  }

  Future<void> _loadReport() async {
    try {
      final report = await _faultService.getFaultReport(widget.reportId);
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل التقرير: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('load_report_failed') ?? 'فشل في تحميل التقرير'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _incrementViews() async {
    if (_report == null) return;
    
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null && 
        currentUser.userType == 'artisan' && 
        currentUser.id != _report!.userId) {
      try {
        await _faultService.incrementFaultViews(widget.reportId);
        final updatedReport = _report!.copyWith(viewsCount: _report!.viewsCount + 1);
        context.read<FaultProvider>().updateReportLocally(updatedReport);
        if (mounted) {
          setState(() {
            _report = updatedReport;
          });
        }
      } catch (e) {
        print('⚠️ خطأ في تحديث عدد المشاهدات: $e');
      }
    }
  }

  Future<void> _loadDeclinedCount() async {
    if (_report == null) return;
    
    try {
      final declinedArtisanIds = await _faultService.getDeclinedArtisanIds(widget.reportId);
      if (mounted) {
        setState(() {
          _declinedCount = declinedArtisanIds.length;
        });
      }
    } catch (e) {
      print('⚠️ خطأ في جلب عدد المرفوضين: $e');
    }
  }

  @override
  void dispose() {
    for (var player in _audioPlayers.values) {
      player.stop();
      player.dispose();
    }
    _audioPlayers.clear();
    
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.translate('report_details') ?? 'تفاصيل التقرير'),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.translate('report_details') ?? 'تفاصيل التقرير'),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)?.translate('report_not_found') ?? 'التقرير غير موجود'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(
                  Assets.iconsLogo,
                  width: 32.w,
                  height: 32.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(AppLocalizations.of(context)?.translate('report_details') ?? 'تفاصيل التقرير'),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                    color: _getStatusColor(_report!.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _getStatusText(_report!.status),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(_report!.status),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (!_report!.isActive)
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
              _getFaultTypeText(_report!.faultType)
            ),

            _buildDetailRow(
              AppLocalizations.of(context)?.translate('created_date') ?? 'تاريخ الإنشاء', 
              _formatDate(_report!.createdAt)
            ),
            
            // Scheduled Date
            if (_report!.isScheduled && _report!.scheduledDate != null)
              _buildDetailRow(
                AppLocalizations.of(context)?.translate('scheduled_date_label') ?? 'تاريخ مجدول', 
                _formatScheduledDate(_report!.scheduledDate!)
              ),
            
            // Address
            if (_report!.address != null)
              _buildLocationRow(
                AppLocalizations.of(context)?.translate('address') ?? 'العنوان', 
                _report!.address!, 
                _report!.latitude, 
                _report!.longitude
              ),
            
            // Location
           /* if (_report!.latitude != null && _report!.longitude != null)
              _buildLocationRow('الموقع', '${_report!.latitude!.toStringAsFixed(6)}, ${_report!.longitude!.toStringAsFixed(6)}', _report!.latitude, _report!.longitude),
            */
            SizedBox(height: 16.h),
            
            // Statistics (for report owner only)
            if (Provider.of<SimpleAuthProvider>(context).currentUser?.id == _report!.userId)
              _buildStatisticsSection(),
            
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
              _report!.description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            
            // Images
            if (_report!.imageUrls.isNotEmpty) ...[
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
                  itemCount: _report!.imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _report!.imageUrls[index];
                    return GestureDetector(
                      onTap: () {
                        _showImagePreview(_report!.imageUrls, index);
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
            if (_report!.videoUrl != null && _report!.videoUrl!.isNotEmpty) ...[
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
                onTap: () => _showVideoPlayerDialog(_report!),
                child: _buildVideoPlayer(_report!),
              ),
            ],
            
            // Voice Recording
            if (_report!.voiceRecordingUrl != null) ...[
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
              _buildAudioPlayer(_report!),
            ],
            
            // Notes (if assigned)
            if (_report!.notes != null && _report!.notes!.isNotEmpty) ...[
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
                  _report!.notes!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 24.h),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final currentUser = Provider.of<SimpleAuthProvider>(context).currentUser;
    final isOwner = currentUser != null && currentUser.id == _report!.userId;

    return Column(
      children: [
        // Edit Button (only for owner)
        if (isOwner)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/problem-report-stepper?reportId=${_report!.id}');
              },
              icon: Icon(Icons.edit, size: 20.sp),
              label: Text(
                AppLocalizations.of(context)?.translate('edit_report') ?? 'تعديل التقرير',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        
        // Deactivate/Activate Button (only for owner)
        if (isOwner) SizedBox(height: 12.h),
        if (isOwner)
          Consumer<FaultProvider>(
            builder: (context, faultProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: faultProvider.isLoading
                      ? null
                      : () => _toggleFaultActiveStatus(faultProvider),
                  icon: Icon(
                    _report!.isActive ? Icons.block : Icons.check_circle,
                    size: 20.sp,
                  ),
                  label: Text(
                    _report!.isActive 
                        ? (AppLocalizations.of(context)?.translate('deactivate_fault') ?? 'إلغاء تفعيل العطل')
                        : (AppLocalizations.of(context)?.translate('activate_fault') ?? 'تفعيل العطل'),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _report!.isActive ? Colors.orange : Colors.green,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        if (!isOwner && _report!.isActive) SizedBox(height: 12.h),
        if (!isOwner && _report!.isActive)
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startChatWithUser(chatProvider),
                  icon: Icon(Icons.message, size: 20.sp),
                  label: Text(
                    AppLocalizations.of(context)?.translate('message_fault_owner') ?? 'مراسلة صاحب العطل',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Views Count
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.visibility_rounded,
                    color: Colors.blue,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${_report!.viewsCount}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 50.h,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          
          // Declined Count
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: Colors.red,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$_declinedCount',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final url = 'https://www.google.com/maps?q=$latitude,$longitude';
    
    try {
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

    if (!_audioPlayers.containsKey(reportId)) {
      final player = AudioPlayer();
      _audioPlayers[reportId] = player;
      _isPlayingMap[reportId] = false;
      _audioDurationMap[reportId] = Duration.zero;
      _audioPositionMap[reportId] = Duration.zero;

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
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.outline,
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
                  color: Theme.of(context).colorScheme.outline,
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

    if (!_videoControllers.containsKey(reportId)) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      controller.initialize().then((_) {
        if (mounted) {
          setState(() {});
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

  Future<void> _toggleFaultActiveStatus(FaultProvider faultProvider) async {
    final newStatus = !_report!.isActive;
    
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
      final success = await faultProvider.updateFaultActiveStatus(_report!.id, newStatus);
      
      if (success && mounted) {
        setState(() {
          _report = _report!.copyWith(isActive: newStatus);
        });
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

  Future<void> _startChatWithUser(ChatProvider chatProvider) async {
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
      final room = await chatProvider.createChatRoomAndReturn(_report!.userId);
      
      if (room != null) {
        await chatProvider.openChatRoom(room.id);
        if (mounted) {
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
        return status;
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

  String _formatScheduledDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

