import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../models/artisan_model.dart';

class FallbackMapsPage extends StatefulWidget {
  const FallbackMapsPage({super.key});

  @override
  State<FallbackMapsPage> createState() => _FallbackMapsPageState();
}

class _FallbackMapsPageState extends State<FallbackMapsPage> {
  String _selectedCraftType = 'all';
  List<ArtisanModel> _artisans = [];
  bool _isLoading = true;

  final List<String> _craftTypes = [
    'all',
    'carpenter',
    'electrician',
    'plumber',
    'painter',
    'mechanic',
  ];

  @override
  void initState() {
    super.initState();
    _loadArtisans();
  }

  Future<void> _loadArtisans() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _artisans = [
        ArtisanModel(
          id: '1',
          name: 'محمد أحمد',
          email: 'mohamed@example.com',
          phone: '+966501234567',
          profileImageUrl: '',
          craftType: 'carpenter',
          yearsOfExperience: 8,
          description: 'نجار محترف متخصص في الأثاث المنزلي والمكتبي',
          latitude: 24.7136,
          longitude: 46.6753,
          address: 'حي الملز، الرياض - 2.5 كم من موقعك',
          rating: 4.8,
          reviewCount: 156,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '2',
          name: 'سعد محمد',
          email: 'saad@example.com',
          phone: '+966509876543',
          profileImageUrl: '',
          craftType: 'electrician',
          yearsOfExperience: 12,
          description: 'كهربائي محترف - تمديدات وصيانة كهربائية',
          latitude: 24.7200,
          longitude: 46.6800,
          address: 'حي العليا، الرياض - 3.2 كم من موقعك',
          rating: 4.9,
          reviewCount: 203,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '3',
          name: 'عبدالله سالم',
          email: 'abdullah@example.com',
          phone: '+966555123456',
          profileImageUrl: '',
          craftType: 'plumber',
          yearsOfExperience: 6,
          description: 'سباك ماهر - تسليك وتمديدات صحية',
          latitude: 24.7100,
          longitude: 46.6700,
          address: 'حي السليمانية، الرياض - 1.8 كم من موقعك',
          rating: 4.6,
          reviewCount: 89,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '4',
          name: 'خالد العتيبي',
          email: 'khalid@example.com',
          phone: '+966556789012',
          profileImageUrl: '',
          craftType: 'painter',
          yearsOfExperience: 10,
          description: 'صباغ محترف - دهانات داخلية وخارجية',
          latitude: 24.7080,
          longitude: 46.6850,
          address: 'حي الربوة، الرياض - 4.1 كم من موقعك',
          rating: 4.7,
          reviewCount: 134,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ArtisanModel(
          id: '5',
          name: 'أحمد القحطاني',
          email: 'ahmed@example.com',
          phone: '+966554321098',
          profileImageUrl: '',
          craftType: 'mechanic',
          yearsOfExperience: 15,
          description: 'ميكانيكي سيارات متخصص في جميع الأنواع',
          latitude: 24.7250,
          longitude: 46.6600,
          address: 'حي الشفا، الرياض - 5.7 كم من موقعك',
          rating: 4.9,
          reviewCount: 298,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      _isLoading = false;
    });
  }

  List<ArtisanModel> _getFilteredArtisans() {
    if (_selectedCraftType == 'all') {
      return _artisans;
    }
    return _artisans.where((artisan) => artisan.craftType == _selectedCraftType).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'الخرائط',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMapNotAvailableCard(),
                _buildFilterChips(),
                Expanded(child: _buildArtisansList()),
              ],
            ),
    );
  }

  Widget _buildMapNotAvailableCard() {
    return Container(
      margin: EdgeInsets.all(AppConstants.padding),
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 24.w,
          ),
          SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗺️ الخرائط غير متاحة حالياً',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'يمكنك عرض قائمة الحرفيين مرتبة حسب المسافة التقريبية من موقعك.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: AppConstants.padding),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _craftTypes.length,
        itemBuilder: (context, index) {
          final craftType = _craftTypes[index];
          final isSelected = _selectedCraftType == craftType;
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(
                craftType == 'all' ? 'الكل' : _getCraftNameArabic(craftType),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCraftType = craftType;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtisansList() {
    final filteredArtisans = _getFilteredArtisans();
    
    if (filteredArtisans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64.w,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: AppConstants.padding),
            Text(
              'لا توجد حرفيين في هذه الفئة',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.padding),
      itemCount: filteredArtisans.length,
      itemBuilder: (context, index) {
        final artisan = filteredArtisans[index];
        return _buildArtisanCard(artisan);
      },
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan) {
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.padding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: _getCraftColor(artisan.craftType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Icon(
                    _getCraftIcon(artisan.craftType),
                    size: 30.w,
                    color: _getCraftColor(artisan.craftType),
                  ),
                ),
                SizedBox(width: AppConstants.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _getCraftNameArabic(artisan.craftType),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _getCraftColor(artisan.craftType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
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
                          const Spacer(),
                          Icon(
                            Icons.work_history_rounded,
                            size: 14.w,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          SizedBox(width: 2.w),
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
                ),
              ],
            ),
            
            SizedBox(height: AppConstants.padding),
            
            Text(
              artisan.description,
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: AppConstants.smallPadding),
            
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 14.w,
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
              ],
            ),
            
            SizedBox(height: AppConstants.padding),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showContactOptions(artisan);
                    },
                    icon: Icon(Icons.phone_rounded, size: 18.w),
                    label: Text(
                      'اتصال',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getCraftColor(artisan.craftType),
                      side: BorderSide(color: _getCraftColor(artisan.craftType)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/artisan-profile/${artisan.id}');
                    },
                    icon: Icon(Icons.person_rounded, size: 18.w),
                    label: Text(
                      'الملف الشخصي',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getCraftColor(artisan.craftType),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCraftIcon(String craftType) {
    switch (craftType) {
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
      default:
        return Icons.handyman_rounded;
    }
  }

  Color _getCraftColor(String craftType) {
    switch (craftType) {
      case 'carpenter':
        return Colors.orange;
      case 'electrician':
        return Colors.amber[700]!;
      case 'plumber':
        return Colors.blue;
      case 'painter':
        return Colors.green;
      case 'mechanic':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  void _showContactOptions(ArtisanModel artisan) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'التواصل مع ${artisan.name}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppConstants.padding),
            ListTile(
              leading: Icon(Icons.phone_rounded, color: _getCraftColor(artisan.craftType)),
              title: Text('مكالمة هاتفية'),
              subtitle: Text(artisan.phone),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('اتصال بـ ${artisan.name}')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat_rounded, color: _getCraftColor(artisan.craftType)),
              title: Text('إرسال رسالة'),
              subtitle: Text('بدء محادثة'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('مراسلة ${artisan.name}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 