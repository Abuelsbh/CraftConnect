import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../Models/artisan_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/simple_auth_provider.dart';
import '../../services/artisan_service.dart';
import '../ArtisanProfile/ArtisanProfileScreen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ArtisanService _artisanService = ArtisanService();
  List<ArtisanModel> _favoriteArtisans = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavoriteArtisans();
  }

  Future<void> _loadFavoriteArtisans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يجب تسجيل الدخول لعرض المفضلة';
        });
        return;
      }

      // تهيئة المفضلة للمستخدم
      await favoriteProvider.initForUser(currentUser.id);

      // جلب معرفات الحرفيين المفضلة
      final favoriteIds = favoriteProvider.favoriteArtisanIds.toList();

      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteArtisans = [];
          _isLoading = false;
        });
        return;
      }

      // جلب بيانات الحرفيين من Firestore
      final List<ArtisanModel> artisans = [];
      for (final artisanId in favoriteIds) {
        try {
          final artisan = await _artisanService.getArtisanById(artisanId);
          if (artisan != null) {
            artisans.add(artisan);
          }
        } catch (e) {
          print('خطأ في جلب بيانات الحرفي $artisanId: $e');
        }
      }

      setState(() {
        _favoriteArtisans = artisans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في تحميل المفضلة: $e';
      });
    }
  }

  String _getCraftNameArabic(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return 'نجار';
      case 'electrician':
        return 'كهربائي';
      case 'plumber':
        return 'سباك';
      case 'painter':
        return 'صباغ';
      case 'mechanic':
        return 'ميكانيكي';
      case 'hvac':
        return 'تكييف';
      case 'satellite':
        return 'ستالايت';
      case 'internet':
        return 'إنترنت';
      case 'tiler':
        return 'بلاط';
      case 'locksmith':
        return 'أقفال';
      default:
        return craftType;
    }
  }

  Color _getCraftColor(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return const Color(0xFFFF6D00);
      case 'electrician':
        return const Color(0xFFFFC107);
      case 'plumber':
        return const Color(0xFF1976D2);
      case 'painter':
        return const Color(0xFF2E7D32);
      case 'mechanic':
        return const Color(0xFFD32F2F);
      case 'hvac':
        return const Color(0xFF00BCD4);
      case 'satellite':
        return const Color(0xFF9C27B0);
      case 'internet':
        return const Color(0xFF03A9F4);
      case 'tiler':
        return const Color(0xFFE91E63);
      case 'locksmith':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFF7B1FA2);
    }
  }

  IconData _getCraftIcon(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return Icons.handyman;
      case 'electrician':
        return Icons.electrical_services;
      case 'plumber':
        return Icons.plumbing;
      case 'painter':
        return Icons.brush;
      case 'mechanic':
        return Icons.build_circle;
      case 'hvac':
        return Icons.ac_unit;
      case 'satellite':
        return Icons.satellite;
      case 'internet':
        return Icons.wifi;
      case 'tiler':
        return Icons.square_foot;
      case 'locksmith':
        return Icons.lock;
      default:
        return Icons.construction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
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
          'المفضلة',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadFavoriteArtisans,
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    
    // التحقق من تسجيل الدخول
    if (!authProvider.isLoggedIn) {
      return _buildNotLoggedInView();
    }

    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_favoriteArtisans.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteArtisans,
      child: ListView.builder(
        padding: EdgeInsets.all(AppConstants.padding),
        itemCount: _favoriteArtisans.length,
        itemBuilder: (context, index) {
          return _buildArtisanCard(_favoriteArtisans[index]);
        },
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80.w,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppConstants.padding),
            Text(
              'يجب تسجيل الدخول لعرض المفضلة',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              'سجل الدخول لحفظ الحرفيين المفضلين لديك',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.padding * 2),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/login');
              },
              icon: Icon(Icons.login_rounded, size: 20.w),
              label: Text('تسجيل الدخول'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'جارٍ تحميل المفضلة...',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.w,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            SizedBox(height: AppConstants.padding),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.padding),
            ElevatedButton.icon(
              onPressed: _loadFavoriteArtisans,
              icon: Icon(Icons.refresh_rounded, size: 20.w),
              label: Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80.w,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppConstants.padding),
            Text(
              'لا توجد مفضلة بعد',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              'أضف الحرفيين المفضلين لديك من صفحاتهم الشخصية',
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

  Widget _buildArtisanCard(ArtisanModel artisan) {
    final craftColor = _getCraftColor(artisan.craftType);
    
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          context.push('/artisan-profile/${artisan.id}');
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.padding),
          child: Row(
            children: [
              // أيقونة الحرفة
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: craftColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: craftColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getCraftIcon(artisan.craftType),
                  size: 30.w,
                  color: craftColor,
                ),
              ),
              SizedBox(width: AppConstants.padding),
              
              // معلومات الحرفي
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الحرفي
                    Text(
                      artisan.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    
                    // نوع الحرفة
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: craftColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getCraftNameArabic(artisan.craftType),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: craftColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // التقييم والخبرة
                    Row(
                      children: [
                        // التقييم
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
                            Text(
                              ' (${artisan.reviewCount})',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        
                        // سنوات الخبرة
                        Row(
                          children: [
                            Icon(
                              Icons.work_history_rounded,
                              size: 14.w,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${artisan.yearsOfExperience} سنوات',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // زر المفضلة
              Consumer<FavoriteProvider>(
                builder: (context, favoriteProvider, _) {
                  final isFavorite = favoriteProvider.isFavorite(artisan.id);
                  return IconButton(
                    onPressed: () async {
                      try {
                        final nowFav = await favoriteProvider.toggleFavorite(artisan.id);
                        if (!mounted) return;
                        
                        // إزالة من القائمة المحلية إذا تم إزالتها من المفضلة
                        if (!nowFav) {
                          setState(() {
                            _favoriteArtisans.removeWhere((a) => a.id == artisan.id);
                          });
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nowFav
                                  ? 'تمت إضافة الحرفي إلى المفضلة'
                                  : 'تمت إزالة الحرفي من المفضلة',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل في تحديث المفضلة: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.red : Theme.of(context).colorScheme.outline,
                    ),
                    tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}













