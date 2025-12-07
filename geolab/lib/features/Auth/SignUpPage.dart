import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/features/Auth/component/CustomButton.dart';
import 'package:geolab/features/Auth/component/TextInputField.dart';
import 'package:geolab/features/Auth/component/validators.dart';
import 'package:geolab/utils/alerts.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/config/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


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
  bool _emailSent = false;
  bool _obscurePassword = true; // Password visibility toggle
  bool _obscureConfirmPassword = true; // Confirm password visibility toggle
  int _resendTimer = 0;
  String _pendingEmail = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60; // 60 seconds countdown
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppAlerts.showSnackbar(
          context,
          context.t('auth.error.passwordsDoNotMatch'),
          color: AppTheme.errorColor,
        );
        return;
      }

      // Store email and send verification email
      _pendingEmail = _emailController.text.trim();
      final name = _nameController.text.trim();
      final password = _passwordController.text.trim();

      // Send email verification request
      BlocProvider.of<AuthBloc>(context).add(
        AuthSendEmailVerificationRequested(
          email: _pendingEmail,
          name: name,
          password: password,
        ),
      );
    }
  }

  void _resendEmail() {
    if (_resendTimer == 0) {
      BlocProvider.of<AuthBloc>(context).add(
        AuthResendEmailVerificationRequested(email: _pendingEmail),
      );
      _startResendTimer();
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
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: ResponsiveLayout.getResponsivePadding(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: kIsWeb ? 500 : double.infinity,
                ),
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
                  _emailSent 
                      ? context.t('auth.emailVerification.subtitle')
                      : context.t('auth.signUp.subtitle'),
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
                // Form Container
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
                  child: _emailSent ? _buildEmailVerificationMessage() : _buildSignUpForm(),
                ),
                SizedBox(
                    height: ResponsiveLayout.getResponsiveSpacing(context,
                        mobile: 40, tablet: 60, desktop: 80)                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildSignUpForm() {
  return Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t('auth.signUp.title'),
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(
                context, mobile: 24, tablet: 26, desktop: 28),
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context, mobile: 24, tablet: 28, desktop: 32)),
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
                context, mobile: 16, tablet: 20, desktop: 24)),
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
                context, mobile: 16, tablet: 20, desktop: 24)),
        TextInputField(
          controller: _passwordController,
          validator: validatePassword,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          label: context.t('auth.password'),
          icon: HugeIcons.strokeRoundedLock,
          showPasswordToggle: true,
          onToggleObscureText: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context, mobile: 16, tablet: 20, desktop: 24)),
        TextInputField(
          controller: _confirmPasswordController,
          validator: (value) => validateConfirmPassword(
              value, _passwordController.text),
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: () => _submitForm(),
          label: context.t('auth.confirmPassword'),
          icon: HugeIcons.strokeRoundedLock,
          showPasswordToggle: true,
          onToggleObscureText: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context, mobile: 24, tablet: 28, desktop: 32)),
        BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              AppAlerts.showAlert(context, context.t('common.error'), state.message);
            } else if (state is AuthEmailVerificationSent) {
              setState(() {
                _emailSent = true;
              });
              _startResendTimer();
              
              AppAlerts.showSnackbar(
                context,
                context.t('auth.emailVerification.sent'),
                color: AppTheme.successColor,
              );
            } else if (state is AuthAuthenticated) {
              AppAlerts.showSnackbar(
                context,
                context.t('auth.signUp.success'),
                color: AppTheme.successColor,
              );
              context.go('/');
            }
          },
          builder: (context, state) {
            _isLoading = state is AuthLoading;
            return CustomButton(
              onPressed: _isLoading ? null : _submitForm,
              text: _isLoading
                  ? context.t('common.loading')
                  : context.t('auth.signUp.sendVerification'),
              isLoading: _isLoading,
            );
          },
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context, mobile: 24, tablet: 28, desktop: 32)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.t('auth.hasAccount'),
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(
                    context, mobile: 14, tablet: 16, desktop: 18),
                color: AppTheme.neutral600,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: Text(
                context.t('auth.signIn.button'),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveLayout.getResponsiveFontSize(
                      context, mobile: 14, tablet: 16, desktop: 18),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  
  );
}



  Widget _buildEmailVerificationMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          HugeIcons.strokeRoundedMail01,
          size: ResponsiveLayout.getResponsiveIconSize(context,
              mobile: 60, tablet: 70, desktop: 80),
          color: AppTheme.primaryColor,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24)),
        Text(
          context.t('auth.emailVerification.title'),
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(
                context,
                mobile: 24,
                tablet: 26,
                desktop: 28),
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 8,
                tablet: 12,
                desktop: 16)),
        Text(
          context.t('auth.emailVerification.description', {'email': _pendingEmail}),
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18),
            color: AppTheme.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.t('auth.emailVerification.checkSpam'),
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 14,
                        desktop: 16),
                    color: AppTheme.neutral700,
                  ),
                ),
              ),
            ],
          ),
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
              context.t('auth.emailVerification.didntReceive'),
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18),
                color: AppTheme.neutral600,
              ),
            ),
            TextButton(
              onPressed: _resendTimer > 0 ? null : _resendEmail,
              child: Text(
                _resendTimer > 0 
                    ? '${context.t('auth.emailVerification.resend')} (${_resendTimer}s)'
                    : context.t('auth.emailVerification.resend'),
                style: TextStyle(
                  color: _resendTimer > 0 ? AppTheme.neutral500 : AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveLayout.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 16,
                      desktop: 18),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24)),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            context.t('common.back'),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: ResponsiveLayout.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18),
            ),
          ),
        ),
      ],
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
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
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
                      _emailSent 
                          ? context.t('auth.emailVerification.subtitle')
                          : context.t('auth.signUp.subtitle'),
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
          // Right side - Form
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _emailSent ? _buildEmailVerificationMessage() : _buildDesktopSignUpForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('auth.signUp.title'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
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
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            label: context.t('auth.password'),
            icon: HugeIcons.strokeRoundedLock,
            showPasswordToggle: true,
            onToggleObscureText: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          const SizedBox(height: 24),
          TextInputField(
            controller: _confirmPasswordController,
            validator: (value) => validateConfirmPassword(
                value, _passwordController.text),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: () => _submitForm(),
            label: context.t('auth.confirmPassword'),
            icon: HugeIcons.strokeRoundedLock,
            showPasswordToggle: true,
            onToggleObscureText: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 32),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                AppAlerts.showAlert(context, context.t('common.error'), state.message);
              } else if (state is AuthEmailVerificationSent) {
                setState(() {
                  _emailSent = true;
                });
                _startResendTimer();
                AppAlerts.showSnackbar(
                  context,
                  context.t('auth.emailVerification.sent'),
                  color: AppTheme.successColor,
                );
              } else if (state is AuthAuthenticated) {
                AppAlerts.showSnackbar(
                  context,
                  context.t('auth.signUp.success'),
                  color: AppTheme.successColor,
                );
                context.go('/');
              }
            },
            builder: (context, state) {
              _isLoading = state is AuthLoading;
              return CustomButton(
                onPressed: _isLoading ? null : _submitForm,
                text: _isLoading
                    ? context.t('common.loading')
                    : context.t('auth.signUp.sendVerification'),
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
                  color: AppTheme.neutral600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: Text(
                  context.t('auth.signIn.button'),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

