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

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      BlocProvider.of<AuthBloc>(context).add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => RTLWrapper(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            context.t('auth.resetPassword.title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t('auth.resetPassword.description'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: context.t('auth.email'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.t('auth.resetPassword.cancel'),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement password reset
                Navigator.pop(context);
                AppAlerts.showSnackbar(
                  context,
                  context.t('auth.resetPassword.success'),
                  color: AppTheme.primary,
                );
              },
              child: Text(
                context.t('auth.resetPassword.sendLink'),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            context.t('auth.signIn'),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.rocket_launch,
                      size: 100,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 40),
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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: () => _submitForm(),
                      label: context.t('auth.password'),
                      icon: HugeIcons.strokeRoundedLock,
                    ),
                    Align(
                      alignment: RTLUtils.endAlignment(context),
                      child: TextButton(
                        onPressed: _showResetPasswordDialog,
                        child: Text(
                          context.t('auth.forgotPassword'),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return CustomButton(
                          onPressed: _submitForm,
                          isLoading: state is AuthLoading,
                          text: context.t('auth.signIn'),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context.go('/sign-up'),
                      child: Text(
                        context.t('auth.noAccount'),
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
    );
  }
}
