import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

const _weekDays = [
  'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
];

class BookExamFiltersWidget extends StatefulWidget {
  const BookExamFiltersWidget({
    super.key,
    required this.nameFilter,
    required this.specialtyFilter,
    required this.branchFilter,
    required this.dayFilter,
    required this.branches,
    required this.specialties,
    required this.hasBranches,
  });

  final ValueNotifier<String> nameFilter;
  final ValueNotifier<String?> specialtyFilter;
  final ValueNotifier<String?> branchFilter;
  final ValueNotifier<String?> dayFilter;
  final List<String> branches;
  final List<String> specialties;
  final bool hasBranches;

  @override
  State<BookExamFiltersWidget> createState() => _BookExamFiltersWidgetState();
}

class _BookExamFiltersWidgetState extends State<BookExamFiltersWidget> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.nameFilter.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _clearAll() {
    _ctrl.clear();
    widget.nameFilter.value = '';
    widget.specialtyFilter.value = null;
    widget.branchFilter.value = null;
    widget.dayFilter.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(controller: _ctrl, onChanged: (v) => widget.nameFilter.value = v),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _FilterDropdown<String?>(
                notifier: widget.dayFilter,
                hint: 'اليوم',
                icon: Icons.calendar_today_rounded,
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الأيام')),
                  ..._weekDays.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdown<String?>(
                notifier: widget.specialtyFilter,
                hint: 'التخصص',
                icon: Icons.medical_information_rounded,
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل التخصصات')),
                  ...widget.specialties
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: widget.hasBranches
                  ? _FilterDropdown<String?>(
                      notifier: widget.branchFilter,
                      hint: 'الفرع',
                      icon: Icons.location_city_rounded,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('كل الفروع')),
                        ...widget.branches
                            .map((b) => DropdownMenuItem(value: b, child: Text(b))),
                      ],
                    )
                  : const _NoBranchHint(),
            ),
            const SizedBox(width: 8),
            _ClearBtn(onClear: _clearAll),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'بحث باسم الطبيب...',
        hintTextDirection: TextDirection.rtl,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.notifier,
    required this.hint,
    required this.icon,
    required this.items,
  });

  final ValueNotifier<T> notifier;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: _deco(hint, icon),
          onChanged: (v) => notifier.value = v as T,
          items: items,
        );
      },
    );
  }
}

class _NoBranchHint extends StatelessWidget {
  const _NoBranchHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: const Text(
        'لا توجد فروع',
        style: TextStyle(fontSize: 12, color: AppColors.warning),
      ),
    );
  }
}

class _ClearBtn extends StatelessWidget {
  const _ClearBtn({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'مسح الفلاتر',
      child: IconButton(
        onPressed: onClear,
        icon: const Icon(Icons.filter_alt_off_rounded),
        color: AppColors.textMuted,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

InputDecoration _deco(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
