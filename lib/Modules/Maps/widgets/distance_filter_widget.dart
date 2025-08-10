import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Utilities/app_constants.dart';
import '../../../core/Language/locales.dart';

class DistanceFilterWidget extends StatefulWidget {
  final double currentDistance;
  final Function(double) onDistanceChanged;

  const DistanceFilterWidget({
    super.key,
    required this.currentDistance,
    required this.onDistanceChanged,
  });

  @override
  State<DistanceFilterWidget> createState() => _DistanceFilterWidgetState();
}

class _DistanceFilterWidgetState extends State<DistanceFilterWidget> {
  late double _currentDistance;

  @override
  void initState() {
    super.initState();
    _currentDistance = widget.currentDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: AppConstants.padding),
          
          // العنوان
          Text(
            'فلترة حسب المسافة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppConstants.smallPadding),
          
          // عرض المسافة الحالية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المسافة القصوى:',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                '${_currentDistance.toStringAsFixed(1)} كم',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.padding),
          
          // شريط التمرير
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              trackHeight: 4.h,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
            ),
            child: Slider(
              value: _currentDistance,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              onChanged: (value) {
                setState(() {
                  _currentDistance = value;
                });
              },
            ),
          ),
          
          // المسافات المحددة مسبقاً
          SizedBox(height: AppConstants.smallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickDistanceButton(5.0),
              _buildQuickDistanceButton(10.0),
              _buildQuickDistanceButton(20.0),
              _buildQuickDistanceButton(50.0),
            ],
          ),
          
          SizedBox(height: AppConstants.padding),
          
          // أزرار الإجراء
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.outline,
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onDistanceChanged(_currentDistance);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: Text(
                    'تطبيق',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDistanceButton(double distance) {
    final isSelected = _currentDistance == distance;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentDistance = distance;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          '${distance.toInt()} كم',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
} 