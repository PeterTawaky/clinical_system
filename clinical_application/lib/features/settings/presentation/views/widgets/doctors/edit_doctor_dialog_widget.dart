import 'dart:ui';

import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:clinical_application/features/settings/presentation/cubits/doctors_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const List<String> _weekDays = [
  'السبت',
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
];

class EditDoctorDialogWidget extends StatefulWidget {
  const EditDoctorDialogWidget({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<EditDoctorDialogWidget> createState() => _EditDoctorDialogWidgetState();
}

class _EditDoctorDialogWidgetState extends State<EditDoctorDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _specialtyCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _balanceCtrl;

  List<Branch> _branches = [];
  late Set<int> _selectedBranchIds;
  late List<_ScheduleEntry> _schedules;
  late List<_ServiceEntry> _services;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _nameCtrl = TextEditingController(text: d.doctorName);
    _specialtyCtrl = TextEditingController(text: d.specialty);
    _phoneCtrl = TextEditingController(text: d.doctorPhoneNumber);
    _balanceCtrl =
        TextEditingController(text: d.doctorBalance.toStringAsFixed(0));

    _schedules = d.schedules.map((s) {
      final entry = _ScheduleEntry();
      entry.day =
          _weekDays.contains(s.dayOfWeek) ? s.dayOfWeek : _weekDays.first;
      entry.startTime = _parseTime(s.startTime);
      entry.endTime = _parseTime(s.endTime);
      entry.branchId = s.branchId;
      return entry;
    }).toList();

    _services = d.services.map((s) {
      final entry = _ServiceEntry();
      entry.nameCtrl.text = s.serviceName;
      entry.priceCtrl.text = s.price.toStringAsFixed(0);
      return entry;
    }).toList();

    _selectedBranchIds = {};
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final dio = DioConsumer();
      final response = await dio.get('/branches');
      final list = response as List<dynamic>;
      _branches =
          list.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();

      // Match existing branch names to IDs
      for (final name in widget.doctor.branches) {
        final match = _branches.firstWhere(
          (b) => b.branchName == name,
          orElse: () => const Branch(branchId: -1, branchName: '', doctorCount: 0),
        );
        if (match.branchId != -1) _selectedBranchIds.add(match.branchId);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _phoneCtrl.dispose();
    _balanceCtrl.dispose();
    for (final s in _schedules) s.dispose();
    for (final s in _services) s.dispose();
    super.dispose();
  }

  void _addSchedule() => setState(() => _schedules.add(_ScheduleEntry()));

  void _removeSchedule(int i) {
    _schedules[i].dispose();
    setState(() => _schedules.removeAt(i));
  }

  void _addService() => setState(() => _services.add(_ServiceEntry()));

  void _removeService(int i) {
    _services[i].dispose();
    setState(() => _services.removeAt(i));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر فرعاً واحداً على الأقل')),
      );
      return;
    }

    final schedules = _schedules.map((s) {
      return DoctorSchedule(
        dayOfWeek: s.day,
        startTime: _fmt(s.startTime),
        endTime: _fmt(s.endTime),
        branchId: s.branchId,
        isActive: true,
      );
    }).toList();

    final services = _services.map((s) {
      return DoctorService(
        serviceName: s.nameCtrl.text.trim(),
        price: double.tryParse(s.priceCtrl.text.trim()) ?? 0,
      );
    }).toList();

    context.read<DoctorsCubit>().editDoctor(
          doctorId: widget.doctor.doctorId,
          doctorName: _nameCtrl.text.trim(),
          specialty: _specialtyCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          balance: double.tryParse(_balanceCtrl.text.trim()) ?? 0,
          branchIds: _selectedBranchIds.toList(),
          schedules: schedules,
          services: services,
        );
    ActionLogger.log('تعديل طبيب: ${_nameCtrl.text.trim()}');
    Navigator.of(context).pop();
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: 520,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 20,
                      offset: Offset(0, 8)),
                ],
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    )
                  : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تعديل بيانات الطبيب',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildField(_nameCtrl, 'اسم الطبيب', Icons.person_rounded),
            const SizedBox(height: 12),
            _buildField(_specialtyCtrl, 'التخصص', Icons.medical_information_rounded),
            const SizedBox(height: 12),
            _buildField(_phoneCtrl, 'رقم الهاتف', Icons.phone_rounded,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField(_balanceCtrl, 'الرصيد',
                Icons.account_balance_wallet_rounded,
                keyboard: TextInputType.number, required: false),

            // Branches
            const SizedBox(height: 16),
            const _SectionLabel(
                icon: Icons.location_city_rounded, label: 'الفروع'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _branches.map((b) {
                final selected = _selectedBranchIds.contains(b.branchId);
                return FilterChip(
                  label: Text(b.branchName),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedBranchIds.add(b.branchId);
                    } else {
                      _selectedBranchIds.remove(b.branchId);
                    }
                  }),
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),

            // Schedules
            const SizedBox(height: 16),
            Row(
              children: [
                const _SectionLabel(
                    icon: Icons.schedule_rounded, label: 'مواعيد العمل'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSchedule,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(_schedules.length, (i) {
              return _ScheduleRow(
                entry: _schedules[i],
                branches: _branches,
                onRemove: () => _removeSchedule(i),
                onChanged: () => setState(() {}),
              );
            }),

            // Services
            const SizedBox(height: 16),
            Row(
              children: [
                const _SectionLabel(
                    icon: Icons.medical_services_outlined, label: 'الخدمات'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addService,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.success,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(_services.length, (i) {
              return _ServiceRow(
                entry: _services[i],
                onRemove: () => _removeService(i),
              );
            }),

            // Actions
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('حفظ التغييرات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.neutral100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.borderFocus, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderError)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ScheduleEntry {
  String day = _weekDays.first;
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 14, minute: 0);
  int? branchId;
  void dispose() {}
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.entry,
    required this.branches,
    required this.onRemove,
    required this.onChanged,
  });

  final _ScheduleEntry entry;
  final List<Branch> branches;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? entry.startTime : entry.endTime,
      builder: (ctx, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked != null) {
      if (isStart) {
        entry.startTime = picked;
      } else {
        entry.endTime = picked;
      }
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: entry.day,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'اليوم',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
              items: _weekDays
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  entry.day = v;
                  onChanged();
                }
              },
            ),
          ),
          _TimeButton(
            label: 'من ${_fmt(entry.startTime)}',
            onTap: () => _pickTime(context, true),
          ),
          _TimeButton(
            label: 'إلى ${_fmt(entry.endTime)}',
            onTap: () => _pickTime(context, false),
          ),
          SizedBox(
            width: 130,
            child: DropdownButtonFormField<int>(
              value: entry.branchId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'الفرع',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
              items: branches
                  .map((b) => DropdownMenuItem(
                      value: b.branchId, child: Text(b.branchName)))
                  .toList(),
              onChanged: (v) {
                entry.branchId = v;
                onChanged();
              },
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_rounded, size: 22),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ServiceEntry {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.entry, required this.onRemove});
  final _ServiceEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: entry.nameCtrl,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'اسم الخدمة',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.priceCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'السعر',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_rounded, size: 22),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}
