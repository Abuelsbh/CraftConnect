import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';

class ArtisanProfileScreen extends StatefulWidget {
  final String artisanId;

  const ArtisanProfileScreen({super.key, required this.artisanId});

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  ArtisanModel? _artisan;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // تأجيل تحميل البيانات حتى بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArtisanProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadArtisanProfile() {
    // محاكاة تحميل البيانات
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _artisan = _generateSampleArtisan();
        _isLoading = false;
      });
    });
  }

  ArtisanModel _generateSampleArtisan() {
    return ArtisanModel(
      id: widget.artisanId,
      name: 'محمد أحمد السعيد',
      email: 'mohamed.ahmed@example.com',
      phone: '+966501234567',
      profileImageUrl: 'https://via.placeholder.com/300',
      craftType: 'carpenter',
      yearsOfExperience: 12,
      description: 'نجار محترف متخصص في صناعة الأثاث المنزلي والمكتبي بأعلى معايير الجودة. أتميز بالدقة في العمل والالتزام بالمواعيد المحددة. لدي خبرة واسعة في جميع أنواع الأخشاب والتشطيبات الحديثة.',
      latitude: 24.7136,
      longitude: 46.6753,
      address: 'حي النرجس، شارع الأمير محمد بن عبدالعزيز، الرياض 12382',
      rating: 4.8,
      reviewCount: 156,
      galleryImages: [
        'https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=مشروع+1',
        'https://via.placeholder.com/400x300/4ECDC4/FFFFFF?text=مشروع+2',
        'https://via.placeholder.com/400x300/45B7D1/FFFFFF?text=مشروع+3',
        'https://via.placeholder.com/400x300/96CEB4/FFFFFF?text=مشروع+4',
        'https://via.placeholder.com/400x300/FFEAA7/000000?text=مشروع+5',
        'https://via.placeholder.com/400x300/DDA0DD/000000?text=مشروع+6',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1095)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildActionButtons(),
              _buildTabSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: مشاركة الملف الشخصي
          },
          icon: const Icon(Icons.share_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            // TODO: إضافة إلى المفضلة
          },
          icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40.h),
                Hero(
                  tag: 'artisan_${_artisan!.id}',
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          size: 50.w,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  _artisan!.name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      child: Column(
        children: [
          // المعلومات الأساسية
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.star_rounded,
                  title: '${_artisan!.rating}',
                  subtitle: 'التقييم',
                  color: Colors.amber,
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.work_history_rounded,
                  title: '${_artisan!.yearsOfExperience}',
                  subtitle: 'سنوات خبرة',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.rate_review_rounded,
                  title: '${_artisan!.reviewCount}',
                  subtitle: 'تقييم',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.padding),
          
          // معلومات الاتصال
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('contact_info') ?? '',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          _buildContactItem(
            icon: Icons.phone_rounded,
            title: AppLocalizations.of(context)?.translate('phone') ?? '',
            value: _artisan!.phone,
            onTap: () {
              // TODO: إجراء مكالمة
            },
          ),
          _buildContactItem(
            icon: Icons.email_rounded,
            title: AppLocalizations.of(context)?.translate('email') ?? '',
            value: _artisan!.email,
            onTap: () {
              // TODO: إرسال إيميل
            },
          ),
          _buildContactItem(
            icon: Icons.location_on_rounded,
            title: AppLocalizations.of(context)?.translate('location') ?? '',
            value: _artisan!.address,
            onTap: () {
              // TODO: فتح الخريطة
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.w,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.w,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (authProvider.isLoggedIn) {
                  _startChatWithArtisan(chatProvider);
                } else {
                  _showLoginDialog();
                }
              },
              icon: Icon(Icons.chat_rounded, size: 20.w),
              label: Text(
                AppLocalizations.of(context)?.translate('send_message') ?? '',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(width: AppConstants.smallPadding),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: إجراء مكالمة
              },
              icon: Icon(
                Icons.phone_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.outline,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(
                text: AppLocalizations.of(context)?.translate('about') ?? '',
                icon: Icon(Icons.info_rounded, size: 20.w),
              ),
              Tab(
                text: AppLocalizations.of(context)?.translate('gallery') ?? '',
                icon: Icon(Icons.photo_library_rounded, size: 20.w),
              ),
              Tab(
                text: AppLocalizations.of(context)?.translate('reviews') ?? '',
                icon: Icon(Icons.star_rounded, size: 20.w),
              ),
            ],
          ),
          SizedBox(
            height: 400.h,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildGalleryTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: EdgeInsets.all(AppConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('about') ?? '',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            _artisan!.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          SizedBox(height: AppConstants.padding),
          _buildSkillChips(),
        ],
      ),
    );
  }

  Widget _buildSkillChips() {
    final skills = ['نجارة', 'تصميم أثاث', 'تركيب', 'صيانة', 'ديكور'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المهارات',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppConstants.smallPadding),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: skills.map((skill) => Chip(
            label: Text(
              skill,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Padding(
      padding: EdgeInsets.all(AppConstants.padding),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.smallPadding,
          mainAxisSpacing: AppConstants.smallPadding,
          childAspectRatio: 1.2,
        ),
        itemCount: _artisan!.galleryImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showImageGallery(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                child: Image.network(
                  _artisan!.galleryImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 40.w,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: EdgeInsets.all(AppConstants.padding),
      child: Column(
        children: [
          // ملخص التقييمات
          Container(
            padding: EdgeInsets.all(AppConstants.padding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      '${_artisan!.rating}',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star_rounded,
                          size: 16.w,
                          color: index < _artisan!.rating.floor()
                              ? Colors.amber
                              : Colors.grey.withValues(alpha: 0.3),
                        );
                      }),
                    ),
                    Text(
                      '${_artisan!.reviewCount} تقييم',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: AppConstants.padding),
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final rating = 5 - index;
                      final percentage = (rating / 5) * 0.8; // محاكاة النسب
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Row(
                          children: [
                            Text(
                              '$rating',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.padding),
          Expanded(
            child: ListView.builder(
              itemCount: 3, // عدد التقييمات المعروضة
              itemBuilder: (context, index) => _buildReviewCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(int index) {
    final reviewers = ['أحمد محمد', 'فاطمة سالم', 'عبدالله يوسف'];
    final ratings = [5.0, 4.0, 5.0];
    final comments = [
      'عمل ممتاز وجودة عالية. أنصح بالتعامل معه.',
      'حرفي ماهر والتزام بالمواعيد.',
      'إبداع في العمل وأسعار مناسبة.',
    ];

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewers[index],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (starIndex) {
                            return Icon(
                              Icons.star_rounded,
                              size: 14.w,
                              color: starIndex < ratings[index]
                                  ? Colors.amber
                                  : Colors.grey.withValues(alpha: 0.3),
                            );
                          }),
                          SizedBox(width: 8.w),
                          Text(
                            'منذ ${index + 1} أسبوع',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              comments[index],
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageGallery(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(_artisan!.galleryImages[index]),
                initialScale: PhotoViewComputedScale.contained * 0.8,
                minScale: PhotoViewComputedScale.contained * 0.5,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            itemCount: _artisan!.galleryImages.length,
            pageController: PageController(initialPage: initialIndex),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _startChatWithArtisan(ChatProvider chatProvider) async {
    if (_artisan == null) return;
    
    try {
      // إنشاء غرفة دردشة مع الحرفي والحصول عليها مباشرة
      final room = await chatProvider.createChatRoomAndReturn(_artisan!.id);
      
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
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/login');
            },
            child: Text(AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
} 