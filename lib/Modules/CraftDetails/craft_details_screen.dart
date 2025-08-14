import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';


class CraftDetailsScreen extends StatefulWidget {
  final String craftId;

  const CraftDetailsScreen({super.key, required this.craftId});

  @override
  State<CraftDetailsScreen> createState() => _CraftDetailsScreenState();
}

class _CraftDetailsScreenState extends State<CraftDetailsScreen> {
  bool _isLoading = true;
  List<ArtisanModel> _artisans = [];
  String _craftName = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // تأجيل تحميل البيانات حتى بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCraftDetails();
    });
  }

  void _loadCraftDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تحميل الحرفيين من Firebase حسب نوع الحرفة
      final querySnapshot = await _firestore
          .collection('artisans')
          .where('craftType', isEqualTo: widget.craftId)
          .get();

      final List<ArtisanModel> artisans = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        artisans.add(ArtisanModel.fromJson(data));
      }

      setState(() {
        _craftName = _getCraftName(widget.craftId);
        _artisans = artisans;
        _isLoading = false;
      });

      print('✅ تم تحميل ${artisans.length} حرفي من نوع ${widget.craftId}');
    } catch (e) {
      print('❌ خطأ في تحميل الحرفيين: $e');
      setState(() {
        _craftName = _getCraftName(widget.craftId);
        _artisans = [];
        _isLoading = false;
      });
    }
  }

  String _getCraftName(String craftId) {
    return AppLocalizations.of(context)?.translate(craftId) ?? craftId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      title: Text(
        _craftName,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: تنفيذ البحث
          },
          icon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: تنفيذ الفلترة
          },
          icon: Icon(
            Icons.filter_list_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildArtisansList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getCraftIcon(widget.craftId),
            size: 40.w,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: AppConstants.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.translate('nearby_artisans') ?? '',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_artisans.length} ${AppLocalizations.of(context)?.translate('artisans')} • ${AppLocalizations.of(context)?.translate('sort_by_distance')}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisansList() {
    if (_artisans.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(AppConstants.padding),
        itemCount: _artisans.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppConstants.padding),
                  child: _buildArtisanCard(_artisans[index], index),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80.w,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد حرفيين متاحين',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan, int index) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: () {
          context.push('/artisan-profile/${artisan.id}');
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.padding),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة الحرفي
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 40.w,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  SizedBox(width: AppConstants.padding),

                  // معلومات الحرفي
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                artisan.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: artisan.isAvailable
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                artisan.isAvailable ? 'متاح' : 'مشغول',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: artisan.isAvailable ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 4.h),

                        // التقييم والخبرة
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16.w,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${artisan.rating}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '(${artisan.reviewCount})',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Icon(
                              Icons.work_history_rounded,
                              size: 16.w,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${artisan.yearsOfExperience} ${AppLocalizations.of(context)?.translate('years_experience')}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8.h),

                        // العنوان
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16.w,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                artisan.address,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(index + 1) * 1.2} km', // محاكاة المسافة
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppConstants.padding),

              // الوصف
              Text(
                artisan.description,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: AppConstants.padding),

              // أزرار الإجراءات
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _handleMessageButton(artisan);
                      },
                      icon: Icon(
                        Icons.chat_rounded,
                        size: 18.w,
                      ),
                      label: Text(
                        AppLocalizations.of(context)?.translate('message') ?? '',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: AppConstants.smallPadding),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/artisan-profile/${artisan.id}');
                      },
                      icon: Icon(
                        Icons.person_rounded,
                        size: 18.w,
                      ),
                      label: Text(
                        AppLocalizations.of(context)?.translate('view_profile') ?? '',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMessageButton(ArtisanModel artisan) {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      _startChatWithArtisan(chatProvider, artisan);
    } else {
      _showLoginDialog();
    }
  }

  void _startChatWithArtisan(ChatProvider chatProvider, ArtisanModel artisan) async {
    try {
      // إنشاء غرفة دردشة مع الحرفي والحصول عليها مباشرة
      final room = await chatProvider.createChatRoomAndReturn(artisan.id);

      if (room != null) {
        // فتح غرفة الدردشة
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
              content: Text('${AppLocalizations.of(context)?.translate('chat_creation_failed') ?? 'فشل في إنشاء المحادثة'}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('login_required') ?? ''),
        content: Text(AppLocalizations.of(context)?.translate('login_message') ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
            child: Text(AppLocalizations.of(context)?.translate('login') ?? 'Login'),
          ),
        ],
      ),
    );
  }

  IconData _getCraftIcon(String craftId) {
    switch (craftId) {
      case 'carpenter':
        return Icons.carpenter_rounded;
      case 'electrician':
        return Icons.electrical_services_rounded;
      case 'plumber':
        return Icons.plumbing_rounded;
      case 'painter':
        return Icons.format_paint_rounded;
      case 'mechanic':
        return Icons.build_rounded;
      case 'tailor':
        return Icons.content_cut_rounded;
      case 'blacksmith':
        return Icons.hardware_rounded;
      case 'welder':
        return Icons.construction_rounded;
      case 'mason':
        return Icons.foundation_rounded;
      case 'gardener':
        return Icons.local_florist_rounded;
      default:
        return Icons.work_rounded;
    }
  }
} 