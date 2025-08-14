import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../providers/artisan_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final artisanProvider = Provider.of<ArtisanProvider>(context, listen: false);
      artisanProvider.loadArtisansByCraftType(widget.craftType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.craftName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: إضافة البحث
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
                    'لا يوجد حرفيين متاحين في هذه الفئة حالياً',
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
              _buildFilterChips(artisanProvider),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(AppConstants.padding),
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
            'الكل',
            artisanProvider.selectedCraftType == 'all',
            artisanProvider.artisans.length,
            () => artisanProvider.selectCraftType('all'),
          ),
          _buildFilterChip(
            'available',
            'متاح',
            artisanProvider.selectedCraftType == 'available',
            artisanProvider.availableArtisans.length,
            () => artisanProvider.selectCraftType('available'),
          ),
          _buildFilterChip(
            'high_rating',
            'تقييم عالي',
            artisanProvider.selectedCraftType == 'high_rating',
            artisanProvider.getArtisansByRating(4.0).length,
            () => artisanProvider.selectCraftType('high_rating'),
          ),
          _buildFilterChip(
            'experienced',
            'خبرة عالية',
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
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: (isSelected ? Colors.white : Theme.of(context).colorScheme.primary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
        elevation: isSelected ? 4 : 2,
      ),
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            context.push('/craft-details/${artisan.craftType}');
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildArtisanAvatar(artisan),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildArtisanName(artisan),
                      SizedBox(height: 4.h),
                      _buildArtisanInfo(artisan),
                      SizedBox(height: 8.h),
                      _buildArtisanRating(artisan),
                    ],
                  ),
                ),
                _buildActionButtons(artisan),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanAvatar(ArtisanModel artisan) {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getCraftColor(artisan.craftType).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: artisan.profileImageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(
                artisan.profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getCraftIcon(artisan.craftType),
                    size: 30.w,
                    color: _getCraftColor(artisan.craftType),
                  );
                },
              ),
            )
          : Icon(
              _getCraftIcon(artisan.craftType),
              size: 30.w,
              color: _getCraftColor(artisan.craftType),
            ),
    );
  }

  Widget _buildArtisanName(ArtisanModel artisan) {
    return Text(
      artisan.name,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildArtisanInfo(ArtisanModel artisan) {
    return Text(
      '${_getCraftNameArabic(artisan.craftType)} • ${artisan.yearsOfExperience} ${AppLocalizations.of(context)?.translate('years_experience') ?? 'سنوات خبرة'}',
      style: TextStyle(
        fontSize: 14.sp,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildArtisanRating(ArtisanModel artisan) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 16.w,
          color: Colors.amber,
        ),
        SizedBox(width: 4.w),
        Text(
          '${artisan.rating.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '(${artisan.reviewCount} ${AppLocalizations.of(context)?.translate('reviews') ?? 'تقييم'})',
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        if (!artisan.isAvailable) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'غير متاح',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(ArtisanModel artisan) {
    return Column(
      children: [
        IconButton(
          onPressed: artisan.isAvailable ? () => _callArtisan(artisan) : null,
          icon: Icon(
            Icons.phone,
            color: artisan.isAvailable ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        IconButton(
          onPressed: artisan.isAvailable ? () => _messageArtisan(artisan) : null,
          icon: Icon(
            Icons.message,
            color: artisan.isAvailable ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  void _callArtisan(ArtisanModel artisan) {
    // TODO: تنفيذ الاتصال
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري الاتصال بـ ${artisan.name}...'),
      ),
    );
  }

  void _messageArtisan(ArtisanModel artisan) {
    // TODO: فتح المحادثة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري فتح المحادثة مع ${artisan.name}...'),
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
} 