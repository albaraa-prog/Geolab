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
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return RTLWrapper(
      child: Container(
        width: double.infinity,
        height: double.infinity,
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
                  context.t('auth.signUp.subtitle'),
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
                // Sign Up Form
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
                          context.t('auth.signUp.title'),
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
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 24,
                                tablet: 28,
                                desktop: 32)),
                        TextInputField(
                          controller: _nameController,
                          validator: validateName,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          label: context.t('auth.name'),
                          icon: HugeIcons.strokeRoundedUser,
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 16,
                                tablet: 20,
                                desktop: 24)),
                        TextInputField(
                          controller: _emailController,
                          validator: validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          label: context.t('auth.email'),
                          icon: HugeIcons.strokeRoundedMail01,
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 16,
                                tablet: 20,
                                desktop: 24)),
                        TextInputField(
                          controller: _passwordController,
                          validator: validatePassword,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          label: context.t('auth.password'),
                          icon: HugeIcons.strokeRoundedLock,
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 16,
                                tablet: 20,
                                desktop: 24)),
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
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 24,
                                tablet: 28,
                                desktop: 32)),
                        BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthError) {
                              AppAlerts.showAlert(
                                  context, 'Error', state.message);
                            } else if (state is AuthAuthenticated) {
                              context.go('/');
                            }
                          },
                          builder: (context, state) {
                            _isLoading = state is AuthLoading;
                            return CustomButton(
                              onPressed: _isLoading ? null : _submitForm,
                              text: _isLoading
                                  ? context.t('common.loading')
                                  : context.t('auth.signUp.button'),
                              isLoading: _isLoading,
                            );
                          },
                        ),
                        SizedBox(
                            height: ResponsiveLayout.getResponsiveSpacing(
                                context,
                                mobile: 24,
                                tablet: 28,
                                desktop: 32)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.t('auth.hasAccount'),
                              style: TextStyle(
                                fontSize:
                                    ResponsiveLayout.getResponsiveFontSize(
                                        context,
                                        mobile: 14,
                                        tablet: 16,
                                        desktop: 18),
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/sign-in'),
                              child: Text(
                                context.t('auth.signIn.button'),
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
      ),
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout(); // Use mobile layout for tablet for now
  }

  Widget _buildDesktopLayout() {
    return RTLWrapper(
      child: Row(
        children: [
          // Left side - Branding
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              height: double.infinity,
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
                      context.t('auth.signUp.subtitle'),
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
          // Right side - Sign Up Form
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
                          context.t('auth.signUp.title'),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                          textAlign: TextAlign.center,
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
                        const SizedBox(height: 24),
                        TextInputField(
                          controller: _emailController,
                          validator: validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          label: context.t('auth.email'),
                          icon: HugeIcons.strokeRoundedMail01,
                        ),
                        const SizedBox(height: 24),
                        TextInputField(
                          controller: _passwordController,
                          validator: validatePassword,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          label: context.t('auth.password'),
                          icon: HugeIcons.strokeRoundedLock,
                        ),
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 32),
                        BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state is AuthError) {
                              AppAlerts.showAlert(
                                  context, 'Error', state.message);
                            } else if (state is AuthAuthenticated) {
                              context.go('/');
                            }
                          },
                          builder: (context, state) {
                            _isLoading = state is AuthLoading;
                            return CustomButton(
                              onPressed: _isLoading ? null : _submitForm,
                              text: _isLoading
                                  ? context.t('common.loading')
                                  : context.t('auth.signUp.button'),
                              isLoading: _isLoading,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.t('auth.hasAccount'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/sign-in'),
                              child: Text(
                                context.t('auth.signIn.button'),
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
      ),
    );
  }
}
