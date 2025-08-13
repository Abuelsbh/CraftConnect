import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    // تأجيل تحميل البيانات حتى بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCraftDetails();
    });
  }

  void _loadCraftDetails() {
    // محاكاة تحميل البيانات
    setState(() {
      _craftName = _getCraftName(widget.craftId);
      _artisans = _generateSampleArtisans();
      _isLoading = false;
    });
  }

  String _getCraftName(String craftId) {
    return AppLocalizations.of(context)?.translate(craftId) ?? craftId;
  }

  List<ArtisanModel> _generateSampleArtisans() {
    // بيانات تجريبية - في التطبيق الحقيقي ستأتي من Firebase
    return [
      ArtisanModel(
        id: '1',
        name: 'محمد أحمد',
        email: 'mohamed@example.com',
        phone: '+966501234567',
        profileImageUrl: 'https://via.placeholder.com/150',
        craftType: widget.craftId,
        yearsOfExperience: 8,
        description: 'خبرة طويلة في مجال ${_getCraftName(widget.craftId)} مع أعمال عالية الجودة',
        latitude: 24.7136,
        longitude: 46.6753,
        address: 'الرياض، المملكة العربية السعودية',
        rating: 4.8,
        reviewCount: 156,
        galleryImages: [
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      ArtisanModel(
        id: '2',
        name: 'سعد محمد',
        email: 'saad@example.com',
        phone: '+966509876543',
        profileImageUrl: 'https://via.placeholder.com/150',
        craftType: widget.craftId,
        yearsOfExperience: 12,
        description: 'متخصص محترف في ${_getCraftName(widget.craftId)} مع ضمان جودة العمل',
        latitude: 24.7236,
        longitude: 46.6653,
        address: 'الرياض، المملكة العربية السعودية',
        rating: 4.9,
        reviewCount: 203,
        galleryImages: [
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
        updatedAt: DateTime.now(),
      ),
      ArtisanModel(
        id: '3',
        name: 'عبدالله سالم',
        email: 'abdullah@example.com',
        phone: '+966555123456',
        profileImageUrl: 'https://via.placeholder.com/150',
        craftType: widget.craftId,
        yearsOfExperience: 6,
        description: 'حرفي ماهر في ${_getCraftName(widget.craftId)} بأسعار منافسة',
        latitude: 24.7036,
        longitude: 46.6853,
        address: 'الرياض، المملكة العربية السعودية',
        rating: 4.6,
        reviewCount: 89,
        galleryImages: [
          'https://via.placeholder.com/300x200',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
    ];
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