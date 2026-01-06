import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/artisan_provider.dart' show ArtisanProvider, SortType;
import '../../providers/app_provider.dart';
import '../../Models/artisan_model.dart';

class ArtisanListScreen extends StatefulWidget {
  final String craftType;
  final String craftName;
  
  const ArtisanListScreen({
    super.key,
    required this.craftType,
    required this.craftName,
  });

  @override
  State<ArtisanListScreen> createState() => _ArtisanListScreenState();
}

class _ArtisanListScreenState extends State<ArtisanListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // تعيين موقع المستخدم للترتيب حسب المسافة
      artisanProvider.setUserPosition(appProvider.currentPosition);
      
      artisanProvider.loadArtisansByCraftType(widget.craftType).then((_) {
        // تحديث الموقع مرة أخرى بعد تحميل الحرفيين
        artisanProvider.setUserPosition(appProvider.currentPosition);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[300],
      appBar: AppBar(
        title: Text(widget.craftName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              print('Search button pressed');
              _showSearchDialog();
            },
          ),
          Consumer<ArtisanProvider>(
            builder: (context, artisanProvider, child) {
              return PopupMenuButton<SortType>(
                icon: Icon(Icons.sort),
                onSelected: (SortType sortType) {
                  print('Sort type selected: $sortType');
                  artisanProvider.setSortType(sortType);
                },
                itemBuilder: (BuildContext menuContext) {
                  final currentSortType = artisanProvider.sortType;
                  return [
                    PopupMenuItem<SortType>(
                      value: SortType.none,
                      child: Row(
                        children: [
                          Icon(
                            currentSortType == SortType.none
                                ? Icons.check
                                : Icons.close,
                            size: 20.w,
                            color: currentSortType == SortType.none
                                ? Theme.of(menuContext).colorScheme.primary
                                : null,
                          ),
                          SizedBox(width: 8.w),
                          Text(AppLocalizations.of(context)?.translate('no_sort') ?? 'بدون ترتيب'),
                        ],
                      ),
                    ),
                    PopupMenuItem<SortType>(
                      value: SortType.rating,
                      child: Row(
                        children: [
                          Icon(
                            currentSortType == SortType.rating
                                ? Icons.check
                                : Icons.star,
                            size: 20.w,
                            color: currentSortType == SortType.rating
                                ? Theme.of(menuContext).colorScheme.primary
                                : Theme.of(menuContext).colorScheme.tertiary,
                          ),
                          SizedBox(width: 8.w),
                          Text(AppLocalizations.of(context)?.translate('sort_by_rating') ?? 'حسب التقييم'),
                        ],
                      ),
                    ),
                    PopupMenuItem<SortType>(
                      value: SortType.distance,
                      child: Row(
                        children: [
                          Icon(
                            currentSortType == SortType.distance
                                ? Icons.check
                                : Icons.location_on,
                            size: 20.w,
                            color: currentSortType == SortType.distance
                                ? Theme.of(menuContext).colorScheme.primary
                                : Theme.of(menuContext).colorScheme.error,
                          ),
                          SizedBox(width: 8.w),
                          Text(AppLocalizations.of(context)?.translate('sort_by_distance') ?? 'حسب المسافة'),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ArtisanProvider>(
        builder: (context, artisanProvider, child) {
          if (artisanProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          if (artisanProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.w,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    artisanProvider.errorMessage!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      artisanProvider.loadArtisansByCraftType(widget.craftType);
                    },
                    child: Text(
                      AppLocalizations.of(context)?.translate('try_again') ?? 'حاول مرة أخرى',
                    ),
                  ),
                ],
              ),
            );
          }

          final artisans = artisanProvider.filteredArtisans;

          if (artisans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64.w,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context)?.translate('no_artisans_found') ?? 'لم يتم العثور على حرفيين',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    AppLocalizations.of(context)?.translate('no_artisans_in_category') ?? 'لا يوجد حرفيين متاحين في هذه الفئة حالياً',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // عرض استعلام البحث إذا كان موجوداً
              if (artisanProvider.searchQuery.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppConstants.padding, vertical: 8.h),
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16.w, color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context)?.translate('search') ?? 'البحث'}: ${artisanProvider.searchQuery}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18.w),
                        onPressed: () {
                          _searchController.clear();
                          artisanProvider.setSearchQuery('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              // عرض نوع الترتيب إذا كان محدداً
              if (artisanProvider.sortType != SortType.none)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppConstants.padding, vertical: 8.h),
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Icon(
                        artisanProvider.sortType == SortType.rating ? Icons.star : Icons.location_on,
                        size: 16.w,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        artisanProvider.sortType == SortType.rating
                            ? (AppLocalizations.of(context)?.translate('sorted_by_rating') ?? 'مرتب حسب التقييم')
                            : (AppLocalizations.of(context)?.translate('sorted_by_distance') ?? 'مرتب حسب المسافة'),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildFilterChips(artisanProvider),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(AppConstants.padding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 أعمدة مثل الصورة
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.7, // نسبة العرض إلى الارتفاع
                  ),
                  itemCount: artisans.length,
                  itemBuilder: (context, index) {
                    final artisan = artisans[index];
                    return _buildArtisanCard(artisan);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ArtisanProvider artisanProvider) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            'all',
            AppLocalizations.of(context)?.translate('all') ?? 'الكل',
            artisanProvider.selectedCraftType == 'all',
            artisanProvider.artisans.length,
            () => artisanProvider.selectCraftType('all'),
          ),
          _buildFilterChip(
            'available',
            AppLocalizations.of(context)?.translate('available') ?? 'متاح',
            artisanProvider.selectedCraftType == 'available',
            artisanProvider.availableArtisans.length,
            () => artisanProvider.selectCraftType('available'),
          ),
          _buildFilterChip(
            'high_rating',
            AppLocalizations.of(context)?.translate('high_rating') ?? 'تقييم عالي',
            artisanProvider.selectedCraftType == 'high_rating',
            artisanProvider.getArtisansByRating(4.0).length,
            () => artisanProvider.selectCraftType('high_rating'),
          ),
          _buildFilterChip(
            'experienced',
            AppLocalizations.of(context)?.translate('experienced') ?? 'خبرة عالية',
            artisanProvider.selectedCraftType == 'experienced',
            artisanProvider.getArtisansByExperience(5).length,
            () => artisanProvider.selectCraftType('experienced'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, bool isSelected, int count, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: (isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedColor: Theme.of(context).colorScheme.primary,
        checkmarkColor: Theme.of(context).colorScheme.onPrimary,
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
        elevation: isSelected ? 4 : 2,
      ),
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final distance = _calculateDistance(artisan, appProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
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
                // صورة الحرفي (دائرية)
                _buildArtisanAvatar(artisan),
                SizedBox(height: 6.h),
                // اسم الحرفي
                _buildArtisanName(artisan),
                SizedBox(height: 3.h),
                // المسافة
                if (distance != null) _buildDistance(distance),
                SizedBox(height: 3.h),
                // التقييم
                _buildArtisanRating(artisan),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanAvatar(ArtisanModel artisan) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
      ),
      child: artisan.profileImageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                artisan.profileImageUrl,
                fit: BoxFit.cover,
                width: 50.w,
                height: 50.w,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 25.w,
                      color: _getCraftColor(artisan.craftType),
                    ),
                  );
                },
              ),
            )
          : Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 25.w,
                color: _getCraftColor(artisan.craftType),
              ),
            ),
    );
  }

  Widget _buildArtisanName(ArtisanModel artisan) {
    return Text(
      artisan.name,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDistance(double distance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 12.w,
          color: Theme.of(context).colorScheme.outline,
        ),
        SizedBox(width: 2.w),
        Text(
          '${distance.toStringAsFixed(1)} ${AppLocalizations.of(context)?.translate('km') ?? 'كم'}',
          style: TextStyle(
            fontSize: 10.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  double? _calculateDistance(ArtisanModel artisan, AppProvider appProvider) {
    if (appProvider.currentPosition == null) return null;
    
    return Geolocator.distanceBetween(
      appProvider.currentPosition!.latitude,
      appProvider.currentPosition!.longitude,
      artisan.latitude,
      artisan.longitude,
    ) / 1000; // تحويل من متر إلى كيلومتر
  }

  Widget _buildArtisanRating(ArtisanModel artisan) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          size: 14.w,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        SizedBox(width: 2.w),
        Text(
          '${artisan.rating.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
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
        return Icons.build;
      default:
        return Icons.work;
    }
  }

  void _showSearchDialog() {
    print('_showSearchDialog called');
    final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
    _searchController.text = artisanProvider.searchQuery;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.translate('search_artisans') ?? 'البحث عن حرفي'),
          content: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.translate('enter_artisan_name') ?? 'أدخل اسم الحرفي',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            autofocus: true,
            onSubmitted: (value) {
              final provider = Provider.of<ArtisanProvider>(context, listen: false);
              provider.setSearchQuery(value);
              Navigator.of(dialogContext).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _searchController.clear();
                final provider = Provider.of<ArtisanProvider>(context, listen: false);
                provider.setSearchQuery('');
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context)?.translate('clear') ?? 'مسح'),
            ),
            TextButton(
              onPressed: () {
                final provider = Provider.of<ArtisanProvider>(context, listen: false);
                provider.setSearchQuery(_searchController.text);
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context)?.translate('search') ?? 'بحث'),
            ),
          ],
        );
      },
    );
  }
} 