import 'package:clinical_application/features/auth/presentation/cubits/login_cubit.dart';
import 'package:clinical_application/features/auth/presentation/views/widgets/login_button_widget.dart';
import 'package:clinical_application/features/auth/presentation/views/widgets/password_field_widget.dart';
import 'package:clinical_application/features/auth/presentation/views/widgets/username_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({super.key});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _loginButtonFocus = FocusNode();
  final _isObscure = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _loginButtonFocus.dispose();
    _isObscure.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().login(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UsernameFieldWidget(
            controller: _usernameController,
            focusNode: _usernameFocus,
            nextFocusNode: _passwordFocus,
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<bool>(
            valueListenable: _isObscure,
            builder: (_, obscure, __) => PasswordFieldWidget(
              controller: _passwordController,
              focusNode: _passwordFocus,
              buttonFocusNode: _loginButtonFocus,
              isObscure: obscure,
              onToggleObscure: () => _isObscure.value = !_isObscure.value,
              onSubmit: _submit,
            ),
          ),
          const SizedBox(height: 32),
          BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) => LoginButtonWidget(
              focusNode: _loginButtonFocus,
              isLoading: state is LoginLoading,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}
