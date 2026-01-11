import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Models/fault_report_model.dart';
import '../../../core/Language/locales.dart';

/// Widget للخطوة الثانية: اختيار نوع العطل
class Step2FaultTypeWidget extends StatelessWidget {
  final List<Map<String, String>> faultTypes;
  final String selectedFaultType;
  final Function(String, String) onFaultTypeSelected;

  const Step2FaultTypeWidget({
    super.key,
    required this.faultTypes,
    required this.selectedFaultType,
    required this.onFaultTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('select_section') ?? 'تحديد القسم',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)?.translate('select_section_description') ?? 'اختر القسم المناسب للمشكلة',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          SizedBox(height: 32.h),
          
          // Craft Types Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 2.5,
            ),
            itemCount: faultTypes.length,
            itemBuilder: (context, index) {
              final faultType = faultTypes[index];
              final isSelected = selectedFaultType == faultType['value'];
              
              return InkWell(
                onTap: () {
                  onFaultTypeSelected(faultType['value']!, faultType['label']!);
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      faultType['label']!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
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
}











