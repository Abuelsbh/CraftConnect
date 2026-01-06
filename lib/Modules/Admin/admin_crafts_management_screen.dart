import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../Models/craft_model.dart';
import '../../core/Language/locales.dart';
import '../../services/craft_service.dart';
import '../../core/Language/app_languages.dart';
import '../../Utilities/app_constants.dart';

class AdminCraftsManagementScreen extends StatefulWidget {
  const AdminCraftsManagementScreen({super.key});

  @override
  State<AdminCraftsManagementScreen> createState() => _AdminCraftsManagementScreenState();
}

class _AdminCraftsManagementScreenState extends State<AdminCraftsManagementScreen> {
  final CraftService _craftService = CraftService();
  final Uuid _uuid = const Uuid();
  
  List<CraftModel> _crafts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCrafts();
  }

  Future<void> _loadCrafts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final crafts = await _craftService.getAllCrafts(activeOnly: false);
      if (mounted) {
        setState(() {
          _crafts = crafts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في تحميل الحرف: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addCraft() async {
    final result = await showDialog<CraftModel>(
      context: context,
      builder: (context) => _CraftEditDialog(
        craft: null,
        languageCode: Provider.of<AppLanguage>(context, listen: false).appLang.name,
      ),
    );

    if (result != null) {
      try {
        await _craftService.addCraft(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('craft_added_success') ?? 'تم إضافة الحرفة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCrafts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.translate('craft_add_failed') ?? 'خطأ في إضافة الحرفة'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editCraft(CraftModel craft) async {
    final result = await showDialog<CraftModel>(
      context: context,
      builder: (context) => _CraftEditDialog(
        craft: craft,
        languageCode: Provider.of<AppLanguage>(context, listen: false).appLang.name,
      ),
    );

    if (result != null) {
      try {
        await _craftService.updateCraft(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('craft_updated_success') ?? 'تم تحديث الحرفة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCrafts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.translate('craft_update_failed') ?? 'خطأ في تحديث الحرفة'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCraft(CraftModel craft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.translate('confirm_delete') ?? 'تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الحرفة "${craft.getDisplayName('ar')}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)?.translate('delete') ?? 'حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _craftService.deleteCraft(craft.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('craft_deleted_success') ?? 'تم حذف الحرفة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCrafts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.translate('craft_delete_failed') ?? 'خطأ في حذف الحرفة'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Provider.of<AppLanguage>(context, listen: false).appLang.name;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة أنواع الحرف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCrafts,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 16.sp),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadCrafts,
                        child: Text(AppLocalizations.of(context)?.translate('retry') ?? 'إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _crafts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد حرف',
                            style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCrafts,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _crafts.length,
                        itemBuilder: (context, index) {
                          final craft = _crafts[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12.h),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: craft.isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                child: Text(
                                  '${craft.order}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                craft.getDisplayName(languageCode),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  decoration: craft.isActive
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4.h),
                                  Text(
                                    'القيمة: ${craft.value}',
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  Text(
                                    'عربي: ${craft.arabicName} | English: ${craft.englishName}',
                                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                                  ),
                                  if (!craft.isActive)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: Text(
                                        'غير نشط',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue,
                                    onPressed: () => _editCraft(craft),
                                    tooltip: 'تعديل',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteCraft(craft),
                                    tooltip: 'حذف',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCraft,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)?.translate('add_new_craft') ?? 'إضافة حرفة جديدة'),
      ),
    );
  }
}

/// Dialog لإضافة/تعديل حرفة
class _CraftEditDialog extends StatefulWidget {
  final CraftModel? craft;
  final String languageCode;

  const _CraftEditDialog({
    required this.craft,
    required this.languageCode,
  });

  @override
  State<_CraftEditDialog> createState() => _CraftEditDialogState();
}

class _CraftEditDialogState extends State<_CraftEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _arabicController = TextEditingController();
  final _englishController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isActive = true;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.craft != null) {
      _valueController.text = widget.craft!.value;
      _arabicController.text = widget.craft!.translations['ar'] ?? '';
      _englishController.text = widget.craft!.translations['en'] ?? '';
      _orderController.text = widget.craft!.order.toString();
      _isActive = widget.craft!.isActive;
    } else {
      _orderController.text = '1';
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _arabicController.dispose();
    _englishController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final craft = CraftModel(
        id: widget.craft?.id ?? _uuid.v4(),
        value: _valueController.text.trim(),
        translations: {
          'ar': _arabicController.text.trim(),
          'en': _englishController.text.trim(),
        },
        order: int.tryParse(_orderController.text) ?? 0,
        isActive: _isActive,
        createdAt: widget.craft?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(craft);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.craft == null ? 'إضافة حرفة جديدة' : 'تعديل حرفة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // القيمة (Value)
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'القيمة (Value)',
                  hintText: 'مثال: carpenter',
                  prefixIcon: Icon(Icons.code),
                ),
                enabled: widget.craft != null ? false : true, // لا يمكن تعديل القيمة للحرف الموجودة
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'القيمة مطلوبة';
                  }
                  if (value.contains(' ')) {
                    return 'القيمة يجب ألا تحتوي على مسافات';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // الترجمة العربية
              TextFormField(
                controller: _arabicController,
                decoration: InputDecoration(
                  labelText: 'الترجمة العربية',
                  hintText: AppLocalizations.of(context)?.translate('example_craft_name') ?? 'مثال: عطل نجارة',
                  prefixIcon: Icon(Icons.translate),
                ),
                textDirection: TextDirection.rtl,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الترجمة العربية مطلوبة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // الترجمة الإنجليزية
              TextFormField(
                controller: _englishController,
                decoration: const InputDecoration(
                  labelText: 'الترجمة الإنجليزية',
                  hintText: 'مثال: Carpentry Problem',
                  prefixIcon: Icon(Icons.language),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الترجمة الإنجليزية مطلوبة';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // الترتيب
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  hintText: 'مثال: 1',
                  prefixIcon: Icon(Icons.sort),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الترتيب مطلوب';
                  }
                  if (int.tryParse(value) == null) {
                    return 'يجب أن يكون رقم';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              
              // حالة النشاط
              SwitchListTile(
                title: Text(AppLocalizations.of(context)?.translate('active') ?? 'نشط'),
                subtitle: Text(AppLocalizations.of(context)?.translate('craft_will_appear') ?? 'الحرفة ستظهر في التطبيق'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(AppLocalizations.of(context)?.translate('save') ?? 'حفظ'),
        ),
      ],
    );
  }
}

