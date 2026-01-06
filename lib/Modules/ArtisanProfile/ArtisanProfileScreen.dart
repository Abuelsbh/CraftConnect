import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../Models/review_model.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/artisan_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/review_service.dart';

class ArtisanProfileScreen extends StatefulWidget {
  final String artisanId;

  const ArtisanProfileScreen({super.key, required this.artisanId});

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  bool _isLoading = true;
  ArtisanModel? _artisan;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArtisanProfile();
    });
  }

  Future<void> _loadArtisanProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final artisanDoc = await _firestore.collection('artisans').doc(widget.artisanId).get();
      
      if (artisanDoc.exists) {
        final artisanData = artisanDoc.data()!;
        final artisan = ArtisanModel.fromJson(artisanData);
        
        final reviewService = ReviewService();
        final actualRating = await reviewService.getAverageRating(widget.artisanId);
        final actualReviewCount = await reviewService.getReviewCount(widget.artisanId);
        
        final updatedArtisan = artisan.copyWith(
          rating: actualRating,
          reviewCount: actualReviewCount,
        );
        
        setState(() {
          _artisan = updatedArtisan;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('لم يتم العثور على بيانات الحرفي');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('فشل في تحميل بيانات الحرفي: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

  double? _calculateDistance() {
    if (_artisan == null) return null;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.currentPosition == null) return null;
    
    return Geolocator.distanceBetween(
      appProvider.currentPosition!.latitude,
      appProvider.currentPosition!.longitude,
      _artisan!.latitude,
      _artisan!.longitude,
    ) / 1000; // convert to km
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
    if (_artisan == null) {
      return Center(
        child: Text(AppLocalizations.of(context)?.translate('no_data') ?? 'لا توجد بيانات'),
      );
    }

    return Column(
      children: [
        _buildPurpleHeader(),
        Expanded(
          child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _buildStatsSection(),
                _buildServiceInfo(),
                _buildPortfolioGallery(),
                SizedBox(height: 100.h), // Space for bottom buttons
            ],
          ),
        ),
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildPurpleHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 10.h,
        bottom: 20.h,
        left: 16.w,
        right: 16.w,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20.w),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 0.w),
                // Favorite button
                // Builder(
                //   builder: (context) {
                //     final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
                //     final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
                //     final currentUser = authProvider.currentUser;
                //
                //     if (currentUser != null) {
                //       favoriteProvider.initForUser(currentUser.id);
                //     }
                //
                //     final bool isOwner = currentUser != null &&
                //         currentUser.artisanId != null &&
                //         currentUser.artisanId == _artisan!.id;
                //
                //     if (isOwner) {
                //       return IconButton(
                //         onPressed: () async {
                //           if (_artisan != null) {
                //             final result = await context.push('/edit-artisan-profile/${_artisan!.id}');
                //             if (result == true) {
                //               _loadArtisanProfile();
                //             }
                //           }
                //         },
                //         icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 20.w),
                //         padding: EdgeInsets.zero,
                //         constraints: BoxConstraints(),
                //       );
                //     }
                //
                //     if (authProvider.isLoggedIn && _artisan != null) {
                //       return Consumer<FavoriteProvider>(
                //         builder: (context, favProvider, _) {
                //           final isFav = favProvider.isFavorite(_artisan!.id);
                //           return IconButton(
                //             onPressed: () async {
                //               try {
                //                 await favProvider.toggleFavorite(_artisan!.id);
                //               } catch (e) {
                //                 if (!mounted) return;
                //                 _showErrorSnackBar('فشل في تحديث المفضلة: $e');
                //               }
                //             },
                //             icon: Icon(
                //               isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                //               color: Theme.of(context).colorScheme.onPrimary,
                //               size: 20.w,
                //             ),
                //             padding: EdgeInsets.zero,
                //             constraints: BoxConstraints(),
                //           );
                //         },
                //       );
                //     }
                //
                //     return SizedBox.shrink();
                //   },
                // ),
                Container(
                  width: 70.w,
                  height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.onPrimary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildProfileImage(),
                    ),
                  ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  _artisan!.name,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context)?.translate(_artisan!.craftType) ?? _getCraftNameArabic(_artisan!.craftType),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final distance = _calculateDistance();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Rating Section
              Expanded(
            child: _buildStatSection(
                  icon: Icons.star_rounded,
              iconColor: Theme.of(context).colorScheme.tertiary,
              title: '${_artisan!.rating.toStringAsFixed(1)}',
              subtitle: '(${_artisan!.reviewCount}) ${AppLocalizations.of(context)?.translate('rating_reviews') ?? 'تقييم'}',
              onTap: () {
                context.push('/reviews/${widget.artisanId}?name=${Uri.encodeComponent(_artisan!.name)}');
              },
            ),
          ),
          SizedBox(width: 8.w),
          // Location Section
              Expanded(
            child: _buildStatSection(
              icon: Icons.location_on_rounded,
              iconColor: Theme.of(context).colorScheme.error,
              title: distance != null ? '${distance.toStringAsFixed(1)} ${AppLocalizations.of(context)?.translate('km') ?? 'كم'}' : (AppLocalizations.of(context)?.translate('not_available') ?? 'غير متوفر'),
              subtitle: AppLocalizations.of(context)?.translate('distance') ?? 'المسافة',
              onTap: _openLocation,
            ),
          ),
          SizedBox(width: 8.w),
          // Experience Section
              Expanded(
            child: _buildStatSection(
              icon: Icons.build_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: '+${_artisan!.yearsOfExperience} ${AppLocalizations.of(context)?.translate('years_experience') ?? 'سنوات'}',
              subtitle: AppLocalizations.of(context)?.translate('experience') ?? 'خبرة',
              onTap: null, // No action for experience
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
                        ),
                      ),
                            child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
                              children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.w),
          ),
          SizedBox(height: 8.h),
                                Text(
            title,
                                  style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
            textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4.h),
                                Text(
            subtitle,
                                  style: TextStyle(
              fontSize: 11.sp,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
            textAlign: TextAlign.center,
                                ),
                              ],
                            ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
                            borderRadius: BorderRadius.circular(12.r),
        child: content,
      );
    }

    return content;
  }
              
  Widget _buildServiceInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child:  Center(
        child: Text(
          _artisan!.description,
            style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioGallery() {
    if (_artisan!.galleryImages.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('portfolio_gallery') ?? 'معرض الأعمال',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 1.0,
            ),
            itemCount: _artisan!.galleryImages.length > 6 ? 6 : _artisan!.galleryImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageGallery(index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
                    child: Stack(
                      fit: StackFit.expand,
          children: [
                        _buildImageFromData(
                          _artisan!.galleryImages[index],
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool isOwner = currentUser != null && 
                        currentUser.artisanId != null && 
                        currentUser.artisanId == _artisan!.id;

    if (isOwner) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
      child: Row(
        children: [
            // Call Button (Purple)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _makePhoneCall();
              },
              icon: Icon(Icons.phone_rounded, size: 20.w),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
                label: Text(
                  AppLocalizations.of(context)?.translate('call') ?? 'اتصال',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
            // Message Button (Grey)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (authProvider.isLoggedIn) {
                    _startChatWithArtisan();
                } else {
                  _showLoginDialog();
                }
              },
                icon: Icon(Icons.message_rounded, size: 20.w),
              label: Text(
                  AppLocalizations.of(context)?.translate('message') ?? 'الرسائل',
            style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
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
                imageProvider: _buildImageProvider(_artisan!.galleryImages[index]),
                initialScale: PhotoViewComputedScale.contained * 0.8,
                minScale: PhotoViewComputedScale.contained * 0.5,
                maxScale: PhotoViewComputedScale.covered * 2,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white,
                      size: 64.w,
                    ),
                  );
                },
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

  void _startChatWithArtisan() async {
    if (_artisan == null) return;

    try {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // التأكد من أن ChatProvider مهيأ
      if (authProvider.currentUser != null) {
        if (chatProvider.currentUser == null || 
            chatProvider.currentUser!.id != authProvider.currentUser!.id) {
          chatProvider.initialize(authProvider.currentUser!);
          // انتظر قليلاً للتأكد من التهيئة
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      final room = await chatProvider.createChatRoomAndReturn(_artisan!.id);

      if (room != null) {
        await chatProvider.openChatRoom(room.id);
        if (mounted) {
          context.push('/chat-room');
        }
      } else {
        if (mounted) {
          final errorMsg = chatProvider.errorMessage ?? 'فشل في إنشاء المحادثة';
          _showErrorSnackBar(errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('فشل في إنشاء المحادثة: $e');
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

  Future<void> _makePhoneCall() async {
    if (_artisan == null || _artisan!.phone.isEmpty) {
      if (!mounted) return;
      _showErrorSnackBar('رقم الهاتف غير متوفر');
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: _artisan!.phone);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!mounted) return;
        _showErrorSnackBar('لا يمكن فتح تطبيق الاتصال');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('فشل في الاتصال: ${e.toString()}');
    }
  }

  Future<void> _openLocation() async {
    if (_artisan == null) return;

    final double lat = _artisan!.latitude;
    final double lng = _artisan!.longitude;
    
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showErrorSnackBar('لا يمكن فتح تطبيق الخريطة');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('فشل في فتح الخريطة: ${e.toString()}');
    }
  }

  bool _isBase64Image(String? imageData) {
    if (imageData == null || imageData.isEmpty) return false;
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return false;
    }
    try {
      base64Decode(imageData);
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildImageFromData(String? imageData, {BoxFit fit = BoxFit.cover}) {
    if (imageData == null || imageData.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.image_rounded,
          size: 40.w,
          color: Colors.grey[400],
        ),
      );
    }

    if (_isBase64Image(imageData)) {
      try {
        final imageBytes = base64Decode(imageData);
        return Image.memory(
          imageBytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.broken_image_rounded,
                size: 40.w,
                color: Colors.grey[400],
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.broken_image_rounded,
            size: 40.w,
            color: Colors.grey[400],
          ),
        );
      }
    } else {
      return Image.network(
        imageData,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image_rounded,
              size: 40.w,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }
  }

  Widget _buildProfileImage() {
    if (_artisan == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Icon(
          Icons.person_rounded,
          size: 50.w,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final profileImage = _artisan!.profileImageUrl;
    if (profileImage == null || profileImage.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Icon(
          Icons.person_rounded,
          size: 50.w,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return _buildImageFromData(profileImage);
  }

  ImageProvider _buildImageProvider(String imageData) {
    if (_isBase64Image(imageData)) {
      try {
        final imageBytes = base64Decode(imageData);
        return MemoryImage(imageBytes);
      } catch (e) {
        return MemoryImage(Uint8List(0));
      }
    } else {
      return NetworkImage(imageData);
    }
  }
}
