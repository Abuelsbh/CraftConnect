import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../models/artisan_model.dart';
import '../../providers/simple_auth_provider.dart';

class DemoMapsPage extends StatefulWidget {
  const DemoMapsPage({super.key});

  @override
  State<DemoMapsPage> createState() => _DemoMapsPageState();
}

class _DemoMapsPageState extends State<DemoMapsPage> {
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
    // محاكاة تحميل البيانات
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
          description: 'نجار محترف متخصص في الأثاث المنزلي',
          latitude: 24.7136,
          longitude: 46.6753,
          address: 'حي الملز، الرياض',
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
          description: 'كهربائي محترف - تمديدات وصيانة',
          latitude: 24.7200,
          longitude: 46.6800,
          address: 'حي العليا، الرياض',
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
          description: 'سباك ماهر - تسليك وتمديدات',
          latitude: 24.7100,
          longitude: 46.6700,
          address: 'حي السليمانية، الرياض',
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
          address: 'حي الربوة، الرياض',
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
          description: 'ميكانيكي سيارات متخصص',
          latitude: 24.7250,
          longitude: 46.6600,
          address: 'حي الشفا، الرياض',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)?.translate('maps') ?? 'الخرائط',
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
                _buildNoticeCard(),
                _buildFilterChips(),
                Expanded(child: _buildArtisansList()),
              ],
            ),
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      margin: EdgeInsets.all(AppConstants.padding),
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 24.w,
          ),
          SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗺️ وضع الخرائط التجريبي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'يمكنك عرض قائمة الحرفيين مرتبة حسب المسافة. لتفعيل الخرائط الكاملة، تحتاج لإضافة Google Maps API Key.',
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
                craftType == 'all' 
                    ? AppLocalizations.of(context)?.translate('all_crafts') ?? 'الكل'
                    : AppLocalizations.of(context)?.translate(craftType) ?? craftType,
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
                // صورة الحرفي
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Icon(
                    _getCraftIcon(artisan.craftType),
                    size: 30.w,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: AppConstants.padding),
                
                // معلومات الحرفي
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
                        AppLocalizations.of(context)?.translate(artisan.craftType) ?? artisan.craftType,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.primary,
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
                            Icons.location_on_rounded,
                            size: 14.w,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '2.5 كم',
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
            
            // الوصف
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
            
            SizedBox(height: AppConstants.padding),
            
            // الأزرار
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
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showArtisanDetails(artisan);
                    },
                    icon: Icon(Icons.person_rounded, size: 18.w),
                    label: Text(
                      'التفاصيل',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
              leading: Icon(Icons.phone_rounded, color: Theme.of(context).colorScheme.primary),
              title: Text('مكالمة هاتفية'),
              subtitle: Text(artisan.phone),
              onTap: () {
                Navigator.pop(context);
                // TODO: تنفيذ المكالمة
              },
            ),
            ListTile(
              leading: Icon(Icons.chat_rounded, color: Theme.of(context).colorScheme.primary),
              title: Text('إرسال رسالة'),
              subtitle: Text('بدء محادثة واتساب'),
              onTap: () {
                Navigator.pop(context);
                // TODO: فتح واتساب
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showArtisanDetails(ArtisanModel artisan) {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تسجيل الدخول مطلوب'),
          content: const Text('يجب تسجيل الدخول لعرض تفاصيل الحرفيين'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: التوجه لصفحة تسجيل الدخول
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
      return;
    }

    // TODO: التوجه لصفحة تفاصيل الحرفي
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('عرض تفاصيل ${artisan.name}')),
    );
  }
} 