import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/users_management/data/models/system_user_model.dart';
import 'package:clinical_application/features/users_management/presentation/cubits/users_cubit.dart';
import 'package:clinical_application/features/users_management/presentation/views/widgets/role_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditUserDialogWidget extends StatefulWidget {
  const EditUserDialogWidget({super.key, required this.user});

  final SystemUser user;

  @override
  State<EditUserDialogWidget> createState() => _EditUserDialogWidgetState();
}

class _EditUserDialogWidgetState extends State<EditUserDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passwordController;
  late final ValueNotifier<UserRole> _roleNotifier;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.user.password);
    _roleNotifier = ValueNotifier(widget.user.role);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _roleNotifier.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<UsersCubit>().editUser(
          id: widget.user.id,
          username: widget.user.username,
          password: _passwordController.text,
          role: _roleNotifier.value,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _EditDialogHeader(),
              const SizedBox(height: 20),
              _UsernameDisplay(username: widget.user.username),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _passwordController,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<UserRole>(
                valueListenable: _roleNotifier,
                builder: (context, role, _) => RoleDropdownWidget(
                  value: role,
                  onChanged: (v) => _roleNotifier.value = v,
                ),
              ),
              const SizedBox(height: 20),
              _EditDialogActions(onSave: _save),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _buildInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    suffixIcon: suffix,
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
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderError)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _UsernameDisplay extends StatelessWidget {
  const _UsernameDisplay({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              color: AppColors.neutral400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.lock_rounded, color: AppColors.neutral300, size: 16),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: _buildInputDecoration(
        label: 'كلمة المرور',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.neutral400,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة المرور' : null,
    );
  }
}

class _EditDialogHeader extends StatelessWidget {
  const _EditDialogHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const Text(
          'تعديل بيانات المستخدم',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EditDialogActions extends StatelessWidget {
  const _EditDialogActions({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ التغييرات'),
          ),
        ),
      ],
    );
  }
}
