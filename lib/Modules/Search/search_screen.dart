import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../Utilities/app_constants.dart';
import '../../core/Language/locales.dart';
import '../../Models/artisan_model.dart';
import '../../Models/craft_model.dart';
import '../../providers/app_provider.dart';
import '../../services/craft_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCraftType = 'all';
  double _selectedRadius = 10.0;
  double _minRating = 0.0;
  bool _showFilters = false;
  List<CraftModel> _availableCrafts = [];

  @override
  void initState() {
    super.initState();
    // تحميل البيانات الأولية إذا لم تكن محملة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.artisans.isEmpty) {
        appProvider.loadInitialData();
      }
      // تحميل الحرف من Firebase
      _loadCrafts();
    });
  }

  Future<void> _loadCrafts() async {
    try {
      final craftService = CraftService();
      final crafts = await craftService.getAllCrafts(activeOnly: true);
      if (mounted) {
        setState(() {
          _availableCrafts = crafts;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل الحرف في صفحة البحث: $e');
      if (mounted) {
        setState(() {
          _availableCrafts = [];
        });
      }
    }
  }

  String _getCraftDisplayName(String craftType) {
    // البحث عن الحرفة في القائمة المحملة من Firebase
    final craft = _availableCrafts.firstWhere(
      (c) => c.value == craftType,
      orElse: () => CraftModel(
        id: craftType,
        value: craftType,
        translations: {},
        order: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    final languageCode = Localizations.localeOf(context).languageCode;
    final displayName = craft.getDisplayName(languageCode);
    
    // إذا لم تكن هناك ترجمة، استخدم AppLocalizations كبديل
    if (displayName == craftType && craft.translations.isEmpty) {
      return AppLocalizations.of(context)?.translate(craftType) ?? craftType;
    }
    
    return displayName;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appProvider.errorMessage != null) {
            return _buildErrorState(appProvider.errorMessage!);
          }

          return Column(
            children: [
              _buildSearchBar(appProvider),
              if (_showFilters) 
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: _buildFilters(appProvider),
                  ),
                ),
              Expanded(
                child: _buildSearchResults(appProvider),
              ),
            ],
          );
        },
      ),
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
        AppLocalizations.of(context)?.translate('search') ?? 'البحث',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
          icon: Icon(
            _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppProvider appProvider) {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          appProvider.updateSearchQuery(value);
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.translate('search_artisans') ?? 'البحث عن حرفيين...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.outline,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    appProvider.updateSearchQuery('');
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildFilters(AppProvider appProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفلاتر',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          
          // فلتر نوع الحرفة
          _buildCraftTypeFilter(appProvider),
          SizedBox(height: AppConstants.smallPadding),
          
          // فلتر المسافة
          _buildRadiusFilter(appProvider),
          SizedBox(height: AppConstants.smallPadding),
          
          // فلتر التقييم
          _buildRatingFilter(),
          SizedBox(height: AppConstants.padding),
          
          // أزرار إعادة تعيين وتطبيق
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCraftType = 'all';
                      _selectedRadius = 10.0;
                      _minRating = 0.0;
                      _searchController.clear();
                    });
                    appProvider.resetFilters();
                  },
                  child: Text(AppLocalizations.of(context)?.translate('reset_search') ?? 'إعادة تعيين'),
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    appProvider.updateSelectedCraftType(_selectedCraftType);
                    appProvider.updateSearchRadius(_selectedRadius);
                    setState(() {
                      _showFilters = false;
                    });
                  },
                  child: Text(AppLocalizations.of(context)?.translate('apply') ?? 'تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCraftTypeFilter(AppProvider appProvider) {
    // استخدام الحرف المحملة من Firebase
    final languageCode = Localizations.localeOf(context).languageCode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الحرفة',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            // خيار "الكل"
            FilterChip(
              label: Text(
                'الكل',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _selectedCraftType == 'all' ? Colors.white : Theme.of(context).colorScheme.primary,
                ),
              ),
              selected: _selectedCraftType == 'all',
              onSelected: (selected) {
                setState(() {
                  _selectedCraftType = 'all';
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
            ),
            // الحرف من Firebase
            ..._availableCrafts.map((craft) {
              final isSelected = _selectedCraftType == craft.value;
              return FilterChip(
                label: Text(
                  craft.getDisplayName(languageCode),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCraftType = craft.value;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildRadiusFilter(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المسافة القصوى',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${_selectedRadius.toStringAsFixed(0)} كم',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            thumbColor: Theme.of(context).colorScheme.primary,
          ),
          child: Slider(
            value: _selectedRadius,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            onChanged: (value) {
              setState(() {
                _selectedRadius = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'التقييم الأدنى',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    size: 16.w,
                    color: index < _minRating ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
                  );
                }),
                SizedBox(width: 8.w),
                Text(
                  '${_minRating.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.amber,
            inactiveTrackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            thumbColor: Colors.amber,
          ),
          child: Slider(
            value: _minRating,
            min: 0.0,
            max: 5.0,
            divisions: 50,
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(AppProvider appProvider) {
    final results = appProvider.searchArtisans(
      query: appProvider.searchQuery,
      craftType: _selectedCraftType,
      minRating: _minRating,
      maxDistance: _selectedRadius.toInt(),
    );

    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(AppConstants.padding),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppConstants.padding),
                  child: _buildArtisanCard(results[index], appProvider),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtisanCard(ArtisanModel artisan, AppProvider appProvider) {
    final distance = appProvider.getDistanceToArtisan(artisan);
    
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الحرفي
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 40.w,
                  color: Theme.of(context).colorScheme.primary,
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
                        if (distance != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${distance.toStringAsFixed(1)} كم',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Text(
                      _getCraftDisplayName(artisan.craftType),
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
                        SizedBox(width: 4.w),
                        Text(
                          '(${artisan.reviewCount})',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${artisan.yearsOfExperience} سنوات خبرة',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Text(
                      artisan.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          SizedBox(height: AppConstants.padding),
          Text(
            AppLocalizations.of(context)?.translate('no_artisans_found') ?? 'لم يتم العثور على حرفيين',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            AppLocalizations.of(context)?.translate('try_changing_search') ?? 'جرب تغيير معايير البحث أو الفلاتر',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.padding),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedCraftType = 'all';
                _selectedRadius = 10.0;
                _minRating = 0.0;
                _searchController.clear();
              });
              Provider.of<AppProvider>(context, listen: false).resetFilters();
            },
            child: Text(AppLocalizations.of(context)?.translate('reset_search_button') ?? 'إعادة تعيين البحث'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80.w,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppConstants.padding),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          Text(
            error,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.padding),
          ElevatedButton(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).loadInitialData();
            },
            child: Text(AppLocalizations.of(context)?.translate('try_again') ?? 'حاول مرة أخرى'),
          ),
        ],
      ),
    );
  }
} 