import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/component/CustomButton.dart';
import 'package:geolab/features/Auth/component/TextInputField.dart';
import 'package:geolab/features/Auth/component/validators.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/alerts.dart';
import 'package:geolab/utils/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppAlerts.showSnackbar(
          context,
          context.t('auth.error.passwordsDoNotMatch'),
          color: Colors.red,
        );
        return;
      }

      BlocProvider.of<AuthBloc>(context).add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          subscriptionTier: 'free',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RTLWrapper(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.onPrimary,
          title: Text(
            context.t('auth.signUp'),
            style: const TextStyle(
              color: AppTheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/');
            } else if (state is AuthError) {
              setState(() => _isLoading = false);
              AppAlerts.showSnackbar(context, state.message, color: Colors.red);
            } else if (state is AuthLoading) {
              setState(() => _isLoading = true);
            }
          },
          child: Container(
            color: AppTheme.scaffoldBackground,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.rocket_launch,
                        size: 100,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 40),
                      TextInputField(
                        controller: _nameController,
                        validator: validateName,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        label: context.t('auth.name'),
                        icon: HugeIcons.strokeRoundedUser,
                      ),
                      const SizedBox(height: 20),
                      TextInputField(
                        controller: _emailController,
                        validator: validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        label: context.t('auth.email'),
                        icon: HugeIcons.strokeRoundedMail01,
                      ),
                      const SizedBox(height: 20),
                      TextInputField(
                        controller: _passwordController,
                        validator: validatePassword,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        label: context.t('auth.password'),
                        icon: HugeIcons.strokeRoundedLock,
                      ),
                      const SizedBox(height: 20),
                      TextInputField(
                        controller: _confirmPasswordController,
                        validator: (value) => validateConfirmPassword(
                            value, _passwordController.text),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: () => _submitForm(),
                        label: context.t('auth.confirmPassword'),
                        icon: HugeIcons.strokeRoundedLock,
                      ),
                      const SizedBox(height: 30),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return CustomButton(
                            onPressed: _submitForm,
                            isLoading: state is AuthLoading,
                            text: context.t('auth.signUp'),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => context.go('/sign-in'),
                        child: Text(
                          context.t('auth.hasAccount'),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
