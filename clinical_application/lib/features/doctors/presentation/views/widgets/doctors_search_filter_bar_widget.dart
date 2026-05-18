import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class DoctorsSearchFilterBarWidget extends StatefulWidget {
  const DoctorsSearchFilterBarWidget({
    super.key,
    required this.nameFilter,
    required this.branchFilter,
    required this.specialtyFilter,
    required this.branches,
    required this.specialties,
  });

  final ValueNotifier<String> nameFilter;
  final ValueNotifier<String?> branchFilter;
  final ValueNotifier<String?> specialtyFilter;
  final List<String> branches;
  final List<String> specialties;

  @override
  State<DoctorsSearchFilterBarWidget> createState() =>
      _DoctorsSearchFilterBarWidgetState();
}

class _DoctorsSearchFilterBarWidgetState
    extends State<DoctorsSearchFilterBarWidget> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.nameFilter.value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAll() {
    _searchController.clear();
    widget.nameFilter.value = '';
    widget.branchFilter.value = null;
    widget.specialtyFilter.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: (v) => widget.nameFilter.value = v,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BranchDropdown(
                branchFilter: widget.branchFilter,
                branches: widget.branches,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SpecialtyDropdown(
                specialtyFilter: widget.specialtyFilter,
                specialties: widget.specialties,
              ),
            ),
            const SizedBox(width: 8),
            _ClearButton(onClear: _clearAll),
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
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _BranchDropdown extends StatelessWidget {
  const _BranchDropdown({
    required this.branchFilter,
    required this.branches,
  });

  final ValueNotifier<String?> branchFilter;
  final List<String> branches;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: branchFilter,
      builder: (context, value, _) {
        return DropdownButtonFormField<String?>(
          value: value,
          isExpanded: true,
          decoration: _dropdownDecoration('الفرع', Icons.location_city_rounded),
          onChanged: (v) => branchFilter.value = v,
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الفروع')),
            ...branches.map(
              (b) => DropdownMenuItem(value: b, child: Text(b)),
            ),
          ],
        );
      },
    );
  }
}

class _SpecialtyDropdown extends StatelessWidget {
  const _SpecialtyDropdown({
    required this.specialtyFilter,
    required this.specialties,
  });

  final ValueNotifier<String?> specialtyFilter;
  final List<String> specialties;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: specialtyFilter,
      builder: (context, value, _) {
        return DropdownButtonFormField<String?>(
          value: value,
          isExpanded: true,
          decoration: _dropdownDecoration(
              'التخصص', Icons.medical_information_rounded),
          onChanged: (v) => specialtyFilter.value = v,
          items: [
            const DropdownMenuItem(value: null, child: Text('كل التخصصات')),
            ...specialties.map(
              (s) => DropdownMenuItem(value: s, child: Text(s)),
            ),
          ],
        );
      },
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onClear});

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

InputDecoration _dropdownDecoration(String hint, IconData icon) {
  return InputDecoration(
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
}
