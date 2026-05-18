import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:flutter/material.dart';

class PasswordFieldWidget extends StatelessWidget {
  const PasswordFieldWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.buttonFocusNode,
    required this.isObscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode buttonFocusNode;
  final bool isObscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'كلمة المرور',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isObscure,
          textInputAction: TextInputAction.done,
          onEditingComplete: () => buttonFocusNode.requestFocus(),
          onFieldSubmitted: (_) => onSubmit(),
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'يرجى إدخال كلمة المرور'
              : null,
          decoration: InputDecoration(
            hintText: 'أدخل كلمة المرور',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.lock_outline_rounded,
                  color: AppColors.neutral400, size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.neutral400,
                size: 22,
              ),
              onPressed: onToggleObscure,
              splashRadius: 20,
            ),
            filled: true,
            fillColor: AppColors.neutral100,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
