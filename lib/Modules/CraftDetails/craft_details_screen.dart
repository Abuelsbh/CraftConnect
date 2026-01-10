import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../generated/assets.dart';
import '../../providers/simple_auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/review_service.dart';


class CraftDetailsScreen extends StatefulWidget {
  final String craftId;

  const CraftDetailsScreen({super.key, required this.craftId});

  @override
  State<CraftDetailsScreen> createState() => _CraftDetailsScreenState();
}

enum SortType {
  none,
  rating,
  distance,
}

class _CraftDetailsScreenState extends State<CraftDetailsScreen> {
  bool _isLoading = true;
  bool _isSearching = false;
  List<ArtisanModel> _artisans = [];
  List<ArtisanModel> _filteredArtisans = [];
  String _craftName = '';
  String _searchQuery = '';
  SortType _sortType = SortType.distance; // افتراضياً حسب المسافة
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // تأجيل تحميل البيانات حتى بعد بناء الـ widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCraftDetails();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadCraftDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // التأكد من الحصول على موقع المستخدم
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.currentPosition == null) {
        await appProvider.loadInitialData();
      }
      // تحميل الحرفيين من Firebase حسب نوع الحرفة (المتاحين فقط)
      final querySnapshot = await _firestore
          .collection('artisans')
          .where('craftType', isEqualTo: widget.craftId)
          .where('isAvailable', isEqualTo: true)
          .get();

      final List<ArtisanModel> artisans = [];
      final reviewService = ReviewService();

      // تحميل بيانات الحرفيين مع حساب rating و reviewCount من التقييمات الفعلية
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final artisan = ArtisanModel.fromJson(data);
        
        // حساب rating و reviewCount من التقييمات الفعلية
        try {
          final actualRating = await reviewService.getAverageRating(artisan.id);
          final actualReviewCount = await reviewService.getReviewCount(artisan.id);
          
          // تحديث بيانات الحرفي بالقيم الفعلية
          artisans.add(artisan.copyWith(
            rating: actualRating,
            reviewCount: actualReviewCount,
          ));
        } catch (e) {
          // في حالة الخطأ، نستخدم القيم المخزنة
          print('تحذير: فشل في حساب rating للحرفي ${artisan.id}: $e');
          artisans.add(artisan);
        }
      }

      setState(() {
        _craftName = _getCraftName(widget.craftId);
        _artisans = artisans;
        _filteredArtisans = List.from(artisans);
        _isLoading = false;
      });
      
      // تطبيق البحث والترتيب بعد التحميل
      _applyFilters();

      print('✅ تم تحميل ${artisans.length} حرفي من نوع ${widget.craftId}');
    } catch (e) {
      print('❌ خطأ في تحميل الحرفيين: $e');
      setState(() {
        _craftName = _getCraftName(widget.craftId);
        _artisans = [];
        _filteredArtisans = [];
        _isLoading = false;
      });
    }
  }

  String _getCraftName(String craftId) {
    return AppLocalizations.of(context)?.translate(craftId) ?? craftId;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: _isSearching
          ? IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
                _applyFilters();
                _searchFocusNode.unfocus();
              },
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن حرفي...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            )
          : Text(
              _craftName,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
      actions: [
        if (!_isSearching)
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
              // تفعيل focus بعد بناء الـ widget
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchFocusNode.requestFocus();
              });
            },
            icon: Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        if (_isSearching && _searchQuery.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              _applyFilters();
            },
            icon: Icon(
              Icons.clear_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        PopupMenuButton<SortType>(
          icon: Icon(
            Icons.sort_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onSelected: (SortType sortType) {
            setState(() {
              _sortType = sortType;
            });
            _applyFilters();
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<SortType>(
              value: SortType.none,
              child: Row(
                children: [
                  Icon(
                    _sortType == SortType.none ? Icons.check : Icons.close,
                    size: 20.w,
                    color: _sortType == SortType.none
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  SizedBox(width: 8.w),
                  Text(AppLocalizations.of(context)?.translate('no_sort_option') ?? 'بدون ترتيب'),
                ],
              ),
            ),
            PopupMenuItem<SortType>(
              value: SortType.rating,
              child: Row(
                children: [
                  Icon(
                    _sortType == SortType.rating ? Icons.check : Icons.star,
                    size: 20.w,
                    color: _sortType == SortType.rating
                        ? Theme.of(context).colorScheme.primary
                        : Colors.amber,
                  ),
                  SizedBox(width: 8.w),
                  Text(AppLocalizations.of(context)?.translate('sort_by_rating_option') ?? 'حسب التقييم'),
                ],
              ),
            ),
            PopupMenuItem<SortType>(
              value: SortType.distance,
              child: Row(
                children: [
                  Icon(
                    _sortType == SortType.distance ? Icons.check : Icons.location_on,
                    size: 20.w,
                    color: _sortType == SortType.distance
                        ? Theme.of(context).colorScheme.primary
                        : Colors.red,
                  ),
                  SizedBox(width: 8.w),
                  Text(AppLocalizations.of(context)?.translate('sort_by_distance_option') ?? 'حسب المسافة'),
                ],
              ),
            ),
          ],
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
        // عرض نوع الترتيب إذا كان محدداً
        // if (_sortType != SortType.none)
        //   Container(
        //     padding: EdgeInsets.symmetric(horizontal: AppConstants.padding, vertical: 8.h),
        //     color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        //     child: Row(
        //       children: [
        //         Icon(
        //           _sortType == SortType.rating ? Icons.star : Icons.location_on,
        //           size: 16.w,
        //           color: Theme.of(context).colorScheme.secondary,
        //         ),
        //         SizedBox(width: 8.w),
        //         Text(
        //           _getSortText(),
        //           style: TextStyle(
        //             fontSize: 12.sp,
        //             color: Theme.of(context).colorScheme.secondary,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
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
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            Assets.iconsLogo,
            width: 60.w,
            height: 60.w,
            fit: BoxFit.cover,
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
                  '${_filteredArtisans.length} ${AppLocalizations.of(context)?.translate('artisans')} • ${_getSortText()}',
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
    if (_filteredArtisans.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: EdgeInsets.all(AppConstants.padding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 أعمدة في كل صف
          crossAxisSpacing: 12.w, // زيادة المسافة الأفقية
          mainAxisSpacing: 16.h, // زيادة المسافة العمودية
          childAspectRatio: 0.75, // نسبة العرض إلى الارتفاع
        ),
        itemCount: _filteredArtisans.length,
        itemBuilder: (context, index) {
          // حساب التأخير بناءً على موضع العنصر في الشبكة
          final row = index ~/ 3;
          final col = index % 3;
          final delay = (row * 3 + col) * 50;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            delay: Duration(milliseconds: delay),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildArtisanCard(_filteredArtisans[index], index),
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

  // حساب المسافة بين موقع المستخدم وموقع الحرفي
  double _calculateDistance(double userLat, double userLon, double artisanLat, double artisanLon) {
    return Geolocator.distanceBetween(
      userLat,
      userLon,
      artisanLat,
      artisanLon,
    ) / 1000; // تحويل من متر إلى كيلومتر
  }

  // الحصول على المسافة إلى حرفي
  double? _getDistanceToArtisan(ArtisanModel artisan) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    if (appProvider.currentPosition == null) return null;
    
    return _calculateDistance(
      appProvider.currentPosition!.latitude,
      appProvider.currentPosition!.longitude,
      artisan.latitude,
      artisan.longitude,
    );
  }

  // دالة للحصول على الأحرف الأولى من الاسم
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    final firstInitial = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final lastInitial = parts[parts.length - 1].isNotEmpty 
        ? parts[parts.length - 1][0].toUpperCase() 
        : '';
    return '$firstInitial $lastInitial';
  }

  // دالة للحصول على الاسم بصيغة "First Last" (الحرف الأول + اللقب)
  String _getFormattedName(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return name;
    if (parts.length == 1) return name;
    final firstName = parts[0];
    final lastName = parts[parts.length - 1];
    if (lastName.isNotEmpty) {
      return '$firstName ${lastName[0]}.';
    }
    return firstName;
  }

  Widget _buildArtisanCard(ArtisanModel artisan, int index) {
    final distance = _getDistanceToArtisan(artisan);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            context.push('/artisan-profile/${artisan.id}');
          },
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // صورة الحرفي (دائرية في الأعلى)
                _buildArtisanAvatar(artisan),
                SizedBox(height: 6.h),
                // اسم الحرفي مع الأيقونة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _getFormattedName(artisan.name),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ],
                ),
                SizedBox(height: 4.h),
                // التقييم مع النجوم
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < artisan.rating.floor()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 12.w,
                        color: Colors.amber,
                      );
                    }),
                    SizedBox(width: 4.w),
                    Text(
                      artisan.rating > 0 ? artisan.rating.toStringAsFixed(1) : '0.0',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                // المسافة (إذا كانت متاحة)
                if (distance != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 10.w,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${distance.toStringAsFixed(1)} كم',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanAvatar(ArtisanModel artisan) {
    final profileImage = artisan.profileImageUrl;
    
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: profileImage != null && profileImage.isNotEmpty
          ? (_isBase64Image(profileImage)
              ? _buildBase64Image(profileImage)
              : _buildNetworkImage(profileImage))
          : Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  _getInitials(artisan.name),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBase64Image(String imageData) {
    try {
      final imageBytes = base64Decode(imageData);
      return ClipOval(
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: 50.w,
          height: 50.w,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 25.w,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.person_rounded,
          size: 25.w,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildNetworkImage(String imageUrl) {
    return ClipOval(
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 50.w,
        height: 50.w,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 25.w,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
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

  // دالة مساعدة للتحقق من نوع الصورة (base64 أم URL)
  bool _isBase64Image(String? imageData) {
    if (imageData == null || imageData.isEmpty) return false;
    // التحقق من أن الصورة ليست URL
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return false;
    }
    // محاولة فك تشفير base64
    try {
      base64Decode(imageData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // تطبيق البحث والترتيب
  void _applyFilters() {
    List<ArtisanModel> filtered = List.from(_artisans);

    // البحث بالاسم
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((artisan) {
        return artisan.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // الترتيب
    if (_sortType == SortType.rating) {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortType == SortType.distance) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.currentPosition != null) {
        filtered.sort((a, b) {
          final distanceA = _calculateDistance(
            appProvider.currentPosition!.latitude,
            appProvider.currentPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          final distanceB = _calculateDistance(
            appProvider.currentPosition!.latitude,
            appProvider.currentPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }
    }

    setState(() {
      _filteredArtisans = filtered;
    });
  }

  // الحصول على نص نوع الترتيب
  String _getSortText() {
    switch (_sortType) {
      case SortType.rating:
        return AppLocalizations.of(context)?.translate('sort_by_rating') ?? 'مرتب حسب التقييم';
      case SortType.distance:
        return AppLocalizations.of(context)?.translate('sort_by_distance') ?? 'مرتب حسب المسافة';
      case SortType.none:
        return AppLocalizations.of(context)?.translate('no_sort') ?? 'بدون ترتيب';
    }
  }


} 