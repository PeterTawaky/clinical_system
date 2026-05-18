import 'package:clinical_application/core/services/action_logger.dart';
import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/core/utils/helper_functions.dart';
import 'package:clinical_application/features/examinations/data/models/patient_model.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/add_exam_cubit.dart';
import 'package:clinical_application/features/examinations/presentation/cubits/add_exam_state.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Maps Arabic day names to Dart's DateTime.weekday values (Mon=1 … Sun=7).
const _arabicDayToWeekday = {
  'الاثنين': 1,
  'الثلاثاء': 2,
  'الأربعاء': 3,
  'الخميس': 4,
  'الجمعة': 5,
  'السبت': 6,
  'الأحد': 7,
};

class AddExamDialogWidget extends StatelessWidget {
  const AddExamDialogWidget({
    super.key,
    required this.doctor,
    required this.schedule,
  });

  final Doctor doctor;
  final DoctorSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddExamCubit(),
      child: _AddExamDialogContent(doctor: doctor, schedule: schedule),
    );
  }
}

class _AddExamDialogContent extends StatefulWidget {
  const _AddExamDialogContent({required this.doctor, required this.schedule});

  final Doctor doctor;
  final DoctorSchedule schedule;

  @override
  State<_AddExamDialogContent> createState() => _AddExamDialogContentState();
}

class _AddExamDialogContentState extends State<_AddExamDialogContent> {
  final _formKey = GlobalKey<FormState>();

  // Patient fields
  final _patientNameCtrl = TextEditingController();
  final _patientPhoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  PatientModel? _selectedPatient;
  bool _addingNewPatient = false;

  // Exam fields
  DoctorService? _selectedService;
  final _examDateCtrl = TextEditingController();
  DateTime? _pickedExamDate;

  String get _rawExamDateValue {
    if (_pickedExamDate == null) return '';
    String p(int n) => n.toString().padLeft(2, '0');
    return '${_pickedExamDate!.year}-${p(_pickedExamDate!.month)}-${p(_pickedExamDate!.day)} 00:00:00';
  }

  void _onExamDatePicked(DateTime dt) {
    setState(() => _pickedExamDate = dt);
    String p(int n) => n.toString().padLeft(2, '0');
    _examDateCtrl.text =
        '${dt.year}-${p(dt.month)}-${p(dt.day)}  (${widget.schedule.dayOfWeek})';
  }

  void _onBirthDatePicked(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    _birthDateCtrl.text = '${dt.year}-${p(dt.month)}-${p(dt.day)}';
  }

  String _autoExamNumber() => DateTime.now().millisecondsSinceEpoch.toString();

  // Patient search
  List<PatientModel> _matchingPatients = [];

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _examDateCtrl.dispose();
    super.dispose();
  }

  void _onPatientNameChanged(String value, List<PatientModel> patients) {
    final q = value.trim().toLowerCase();
    setState(() {
      _selectedPatient = null;
      if (q.length >= 2) {
        _matchingPatients = patients
            .where((p) => p.patientName.toLowerCase().contains(q))
            .take(6)
            .toList();
        // No matches → treat as new patient automatically.
        _addingNewPatient = _matchingPatients.isEmpty;
      } else {
        _matchingPatients = [];
        _addingNewPatient = false;
      }
    });
  }

  void _selectPatient(PatientModel p) {
    String formattedBirth = '';
    if (p.birthDate != null && p.birthDate!.isNotEmpty) {
      final bd = DateTime.tryParse(p.birthDate!.split('T').first);
      if (bd != null) {
        formattedBirth =
            '${bd.year}-${bd.month.toString().padLeft(2, '0')}-${bd.day.toString().padLeft(2, '0')}';
      }
    }
    setState(() {
      _selectedPatient = p;
      _patientNameCtrl.text = p.patientName;
      _patientPhoneCtrl.text = p.phone;
      _birthDateCtrl.text = formattedBirth;
      _matchingPatients = [];
      _addingNewPatient = false;
    });
  }

  void _addNewPatient() {
    setState(() {
      _selectedPatient = null;
      _patientPhoneCtrl.clear();
      _birthDateCtrl.clear();
      _matchingPatients = [];
      _addingNewPatient = true;
    });
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) return;
    // Must have either selected an existing patient or chosen to add a new one.
    if (_selectedPatient == null && !_addingNewPatient) return;

    context.read<AddExamCubit>().submit(
      doctorId: widget.doctor.doctorId,
      patientName: _patientNameCtrl.text.trim(),
      phone: _patientPhoneCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim().isNotEmpty
          ? _birthDateCtrl.text.trim()
          : null,
      serviceId: _selectedService!.serviceId!,
      branchId: widget.schedule.branchId!,
      examDate: _rawExamDateValue,
      examNumber: _autoExamNumber(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddExamCubit, AddExamState>(
      listener: (context, state) {
        if (state is AddExamSuccess) {
          final patientName = _patientNameCtrl.text.trim();
          final doctorName = widget.doctor.doctorName;
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حجز الكشف بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          ActionLogger.log(
            'حجز كشف جديد للطبيب: $doctorName - المريض: $patientName',
          );
        } else if (state is AddExamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final patients = state is AddExamReady
            ? state.patients
            : <PatientModel>[];
        final isLoading = state is AddExamSubmitting;
        final isLoadingPatients = state is AddExamLoadingPatients;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DialogHeader(doctorName: widget.doctor.doctorName),
                    const SizedBox(height: 10),
                    _ScheduleInfoBar(schedule: widget.schedule),
                    const SizedBox(height: 20),
                    _SectionTitle('بيانات المريض'),
                    const SizedBox(height: 10),
                    _PatientSearchField(
                      controller: _patientNameCtrl,
                      isLoadingPatients: isLoadingPatients,
                      matchingPatients: _matchingPatients,
                      onChanged: (v) => _onPatientNameChanged(v, patients),
                      onSelect: _selectPatient,
                      onAddNew: _addNewPatient,
                    ),
                    if (_selectedPatient != null || _addingNewPatient) ...[
                      const SizedBox(height: 10),
                      _PhoneField(
                        controller: _patientPhoneCtrl,
                        readOnly: _selectedPatient != null,
                      ),
                      const SizedBox(height: 10),
                      _BirthDatePickerField(
                        controller: _birthDateCtrl,
                        readOnly: _selectedPatient != null,
                        onPicked: _onBirthDatePicked,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _SectionTitle('بيانات الكشف'),
                    const SizedBox(height: 10),
                    _ServiceDropdown(
                      services: widget.doctor.services,
                      selected: _selectedService,
                      onChanged: (s) => setState(() => _selectedService = s),
                    ),
                    const SizedBox(height: 10),
                    _ExamDateField(
                      controller: _examDateCtrl,
                      allowedWeekday:
                          _arabicDayToWeekday[widget.schedule.dayOfWeek],
                      onPicked: _onExamDatePicked,
                    ),
                    const SizedBox(height: 24),
                    _DialogActions(
                      isLoading: isLoading,
                      onCancel: () => Navigator.of(context).pop(),
                      onSubmit: _onSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.doctorName});

  final String doctorName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.assignment_add, color: AppColors.primary, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'حجز كشف — $doctorName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the schedule details (day, time range, branch) as a read-only info bar.
class _ScheduleInfoBar extends StatelessWidget {
  const _ScheduleInfoBar({required this.schedule});

  final DoctorSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${schedule.dayOfWeek}  •  '
              '${HelperFunctions.formatTimeArabic(schedule.startTime)} – '
              '${HelperFunctions.formatTimeArabic(schedule.endTime)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (schedule.branchName != null)
            Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.branchName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _PatientSearchField extends StatelessWidget {
  const _PatientSearchField({
    required this.controller,
    required this.isLoadingPatients,
    required this.matchingPatients,
    required this.onChanged,
    required this.onSelect,
    required this.onAddNew,
  });

  final TextEditingController controller;
  final bool isLoadingPatients;
  final List<PatientModel> matchingPatients;
  final ValueChanged<String> onChanged;
  final ValueChanged<PatientModel> onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          textDirection: TextDirection.rtl,
          onChanged: onChanged,
          decoration: _inputDeco(
            'اسم المريض',
            Icons.person_search_rounded,
            suffix: isLoadingPatients
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
        ),
        if (matchingPatients.isNotEmpty)
          _PatientSuggestions(
            patients: matchingPatients,
            onSelect: onSelect,
            onAddNew: onAddNew,
          ),
      ],
    );
  }
}

class _PatientSuggestions extends StatelessWidget {
  const _PatientSuggestions({
    required this.patients,
    required this.onSelect,
    required this.onAddNew,
  });

  final List<PatientModel> patients;
  final ValueChanged<PatientModel> onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowSoft, blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          ...patients.map(
            (p) => InkWell(
              onTap: () => onSelect(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.patientName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      p.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          InkWell(
            onTap: onAddNew,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'إضافة مريض جديد',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.readOnly});

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      textDirection: TextDirection.rtl,
      keyboardType: TextInputType.phone,
      decoration: _inputDeco('رقم الهاتف (اختياري)', Icons.phone_rounded),
    );
  }
}

class _BirthDatePickerField extends StatefulWidget {
  const _BirthDatePickerField({
    required this.controller,
    required this.readOnly,
    required this.onPicked,
  });

  final TextEditingController controller;
  final bool readOnly;
  final ValueChanged<DateTime> onPicked;

  @override
  State<_BirthDatePickerField> createState() => _BirthDatePickerFieldState();
}

class _BirthDatePickerFieldState extends State<_BirthDatePickerField> {
  Future<void> _pick() async {
    if (widget.readOnly) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    widget.onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      textDirection: TextDirection.rtl,
      onTap: _pick,
      decoration: _inputDeco('تاريخ الميلاد (اختياري)', Icons.cake_rounded),
    );
  }
}

class _ServiceDropdown extends StatelessWidget {
  const _ServiceDropdown({
    required this.services,
    required this.selected,
    required this.onChanged,
  });

  final List<DoctorService> services;
  final DoctorService? selected;
  final ValueChanged<DoctorService?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DoctorService>(
      value: selected,
      isExpanded: true,
      decoration: _inputDeco('الخدمة', Icons.medical_services_rounded),
      items: services
          .where((s) => s.serviceId != null)
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                '${s.serviceName} — ${s.price.toStringAsFixed(0)} ج.م',
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'اختر الخدمة' : null,
    );
  }
}

/// Date-only picker that restricts selectable dates to [allowedWeekday].
/// [allowedWeekday] follows Dart's DateTime.weekday: Mon=1 … Sun=7.
class _ExamDateField extends StatefulWidget {
  const _ExamDateField({
    required this.controller,
    required this.onPicked,
    this.allowedWeekday,
  });

  final TextEditingController controller;
  final ValueChanged<DateTime> onPicked;
  final int? allowedWeekday;

  @override
  State<_ExamDateField> createState() => _ExamDateFieldState();
}

class _ExamDateFieldState extends State<_ExamDateField> {
  Future<void> _pickDate() async {
    final today = DateTime.now();

    // Find the next occurrence of allowedWeekday as the initial date.
    DateTime initialDate = today;
    if (widget.allowedWeekday != null) {
      int daysAhead = (widget.allowedWeekday! - today.weekday + 7) % 7;
      if (daysAhead == 0) daysAhead = 0; // today if it matches
      initialDate = today.add(Duration(days: daysAhead));
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      selectableDayPredicate: widget.allowedWeekday == null
          ? null
          : (day) => day.weekday == widget.allowedWeekday,
    );
    if (date == null) return;
    widget.onPicked(date);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true,
      textDirection: TextDirection.rtl,
      onTap: _pickDate,
      decoration: _inputDeco('تاريخ الكشف', Icons.event_rounded),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isLoading ? null : onCancel,
          child: const Text(
            'إلغاء',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(
                  'حفظ الكشف',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}

InputDecoration _inputDeco(String label, IconData icon, {Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.neutral100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
