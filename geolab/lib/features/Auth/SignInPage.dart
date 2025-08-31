import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/component/CustomButton.dart';
import 'package:geolab/features/Auth/component/TextInputField.dart';
import 'package:geolab/features/Auth/component/validators.dart';
import 'package:geolab/utils/alerts.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
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
              },
              child: Text(
                context.t('auth.resetPassword.send'),
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
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveLayout.getResponsivePadding(context),
          child: Column(
            children: [
              SizedBox(
                  height: ResponsiveLayout.getResponsiveSpacing(context,
                      mobile: 40, tablet: 60, desktop: 80)),
              // Logo or App Title
              Icon(
                HugeIcons.strokeRoundedGem,
                size: ResponsiveLayout.getResponsiveIconSize(context,
                    mobile: 80, tablet: 100, desktop: 120),
                color: Colors.white,
              ),
              SizedBox(
                  height: ResponsiveLayout.getResponsiveSpacing(context,
                      mobile: 16, tablet: 20, desktop: 24)),
              Text(
                'Geolab',
                style: TextStyle(
                  fontSize: ResponsiveLayout.getResponsiveFontSize(context,
                      mobile: 32, tablet: 36, desktop: 40),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                  height: ResponsiveLayout.getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16)),
              Text(
                context.t('auth.signIn.subtitle'),
                style: TextStyle(
                  fontSize: ResponsiveLayout.getResponsiveFontSize(context,
                      mobile: 16, tablet: 18, desktop: 20),
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                  height: ResponsiveLayout.getResponsiveSpacing(context,
                      mobile: 40, tablet: 60, desktop: 80)),
              // Sign In Form
              Container(
                padding: ResponsiveLayout.getResponsivePadding(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.t('auth.signIn.title'),
                        style: TextStyle(
                          fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 24,
                              tablet: 26,
                              desktop: 28),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: ResponsiveLayout.getResponsiveSpacing(context,
                              mobile: 24, tablet: 28, desktop: 32)),
                      TextInputField(
                        controller: _emailController,
                        label: context.t('auth.email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: validateEmail,
                        icon: HugeIcons.strokeRoundedMail01,
                      ),
                      SizedBox(
                          height: ResponsiveLayout.getResponsiveSpacing(context,
                              mobile: 16, tablet: 20, desktop: 24)),
                      TextInputField(
                        controller: _passwordController,
                        label: context.t('auth.password'),
                        obscureText: true,
                        validator: validatePassword,
                        icon: HugeIcons.strokeRoundedLock,
                      ),
                      SizedBox(
                          height: ResponsiveLayout.getResponsiveSpacing(context,
                              mobile: 8, tablet: 12, desktop: 16)),
                      Align(
                        alignment: RTLUtils.endAlignment(context),
                        child: TextButton(
                          onPressed: _showResetPasswordDialog,
                          child: Text(
                            context.t('auth.forgotPassword'),
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: ResponsiveLayout.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: ResponsiveLayout.getResponsiveSpacing(context,
                              mobile: 24, tablet: 28, desktop: 32)),
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthError) {
                            AppAlerts.showAlert(
                                context, 'Error', state.message);
                          } else if (state is AuthAuthenticated) {
                            context.go('/home');
                          }
                        },
                        builder: (context, state) {
                          _isLoading = state is AuthLoading;
                          return CustomButton(
                            onPressed: _isLoading ? null : _submitForm,
                            text: _isLoading
                                ? context.t('common.loading')
                                : context.t('auth.signIn.button'),
                            isLoading: _isLoading,
                          );
                        },
                      ),
                      SizedBox(
                          height: ResponsiveLayout.getResponsiveSpacing(context,
                              mobile: 24, tablet: 28, desktop: 32)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.t('auth.noAccount'),
                            style: TextStyle(
                              fontSize: ResponsiveLayout.getResponsiveFontSize(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18),
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: Text(
                              context.t('auth.signUp.button'),
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    ResponsiveLayout.getResponsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                  height: ResponsiveLayout.getResponsiveSpacing(context,
                      mobile: 40, tablet: 60, desktop: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout(); // Use mobile layout for tablet for now
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    HugeIcons.strokeRoundedGem,
                    size: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Geolab',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t('auth.signIn.subtitle'),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side - Sign In Form
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.t('auth.signIn.title'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextInputField(
                        controller: _emailController,
                        label: context.t('auth.email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: validateEmail,
                        icon: HugeIcons.strokeRoundedMail01,
                      ),
                      const SizedBox(height: 24),
                      TextInputField(
                        controller: _passwordController,
                        label: context.t('auth.password'),
                        obscureText: true,
                        validator: validatePassword,
                        icon: HugeIcons.strokeRoundedLock,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: RTLUtils.endAlignment(context),
                        child: TextButton(
                          onPressed: _showResetPasswordDialog,
                          child: Text(
                            context.t('auth.forgotPassword'),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthError) {
                            AppAlerts.showAlert(
                                context, 'Error', state.message);
                          } else if (state is AuthAuthenticated) {
                            context.go('/home');
                          }
                        },
                        builder: (context, state) {
                          _isLoading = state is AuthLoading;
                          return CustomButton(
                            onPressed: _isLoading ? null : _submitForm,
                            text: _isLoading
                                ? context.t('common.loading')
                                : context.t('auth.signIn.button'),
                            isLoading: _isLoading,
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.t('auth.noAccount'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: Text(
                              context.t('auth.signUp.button'),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
