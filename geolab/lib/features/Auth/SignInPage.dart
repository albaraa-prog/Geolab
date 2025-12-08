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
import 'package:geolab/utils/error_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  bool _usePassword = true; // Toggle between password and magic link
  bool _obscurePassword = true; // Password visibility toggle
  int _resendTimer = 0;
  String _pendingEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      _pendingEmail = _emailController.text.trim();
      
      if (_usePassword) {
        // Password-based login
        BlocProvider.of<AuthBloc>(context).add(
          AuthLoginRequested(
            email: _pendingEmail,
            password: _passwordController.text.trim(),
          ),
        );
      } else {
        // Magic link login
        BlocProvider.of<AuthBloc>(context).add(
          AuthSendEmailVerificationRequested(
            email: _pendingEmail,
            name: '',
            password: '',
          ),
        );
      }
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

  void _showResetPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
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
                  color: AppTheme.primaryColor,
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
                        BorderSide(color: AppTheme.primaryColor, width: 2),
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
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (emailController.text.trim().isNotEmpty) {
                  BlocProvider.of<AuthBloc>(context).add(
                    AuthPasswordResetRequested(
                      email: emailController.text.trim(),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(
                context.t('auth.resetPassword.send'),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Form(
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
              color: AppTheme.primaryColor,
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
            controller: _emailController,
            label: context.t('auth.email'),
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            icon: HugeIcons.strokeRoundedMail01,
          ),
          if (_usePassword) ...[
            SizedBox(
                height: ResponsiveLayout.getResponsiveSpacing(
                    context,
                    mobile: 16,
                    tablet: 20,
                    desktop: 24)),
            TextInputField(
              controller: _passwordController,
              label: context.t('auth.password'),
              obscureText: _obscurePassword,
              validator: validatePassword,
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
                    context,
                    mobile: 8,
                    tablet: 12,
                    desktop: 16)),
            // Forgot password and magic link options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _usePassword = !_usePassword;
                      _passwordController.clear();
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _usePassword 
                            ? HugeIcons.strokeRoundedMail01 
                            : HugeIcons.strokeRoundedLock,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _usePassword
                            ? context.t('auth.signIn.useMagicLink')
                            : context.t('auth.signIn.usePassword'),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: ResponsiveLayout.getResponsiveFontSize(
                              context,
                              mobile: 14,
                              tablet: 16,
                              desktop: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showResetPasswordDialog,
                  child: Text(
                    context.t('auth.forgotPassword'),
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
            ),
          ],
          SizedBox(
              height: ResponsiveLayout.getResponsiveSpacing(
                  context,
                  mobile: 8,
                  tablet: 12,
                  desktop: 16)),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                AppAlerts.showAlert(
                    context, 
                    context.t('common.error'), 
                    ErrorHandler.getFriendlyErrorMessage(state.message)
                );
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
              } else if (state is PasswordResetSent) {
                AppAlerts.showSnackbar(
                  context,
                  context.t('auth.resetPassword.success'),
                  color: AppTheme.successColor,
                );
              } else if (state is AuthAuthenticated) {
                // Don't navigate away if we're on reset-password page
                final currentPath = Uri.base.path;
                if (currentPath != '/reset-password') {
                  print('🔍 SignInPage: Authenticated, navigating to home');
                  context.go('/');
                } else {
                  print('🔍 SignInPage: Authenticated but on reset-password, staying put');
                }
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
              height: ResponsiveLayout.getResponsiveSpacing(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.t('auth.noAccount'),
                style: TextStyle(
                  fontSize:
                      ResponsiveLayout.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 16,
                          desktop: 18),
                  color: AppTheme.neutral600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/sign-up'),
                child: Text(
                  context.t('auth.signUp.button'),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
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
    );
  }

  Widget _buildDesktopSignInForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t('auth.signIn.title'),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
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
          if (_usePassword) ...[
            const SizedBox(height: 24),
            TextInputField(
              controller: _passwordController,
              label: context.t('auth.password'),
              obscureText: _obscurePassword,
              validator: validatePassword,
              icon: HugeIcons.strokeRoundedLock,
              showPasswordToggle: true,
              onToggleObscureText: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            const SizedBox(height: 16),
            // Forgot password and magic link options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _usePassword = !_usePassword;
                      _passwordController.clear();
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _usePassword 
                            ? HugeIcons.strokeRoundedMail01 
                            : HugeIcons.strokeRoundedLock,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _usePassword
                            ? context.t('auth.signIn.useMagicLink')
                            : context.t('auth.signIn.usePassword'),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showResetPasswordDialog,
                  child: Text(
                    context.t('auth.forgotPassword'),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                AppAlerts.showAlert(
                    context, context.t('common.error'), state.message);
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
              } else if (state is PasswordResetSent) {
                AppAlerts.showSnackbar(
                  context,
                  context.t('auth.resetPassword.success'),
                  color: AppTheme.successColor,
                );
              } else if (state is AuthAuthenticated) {
                // Don't navigate away if we're on reset-password page
                final currentPath = Uri.base.path;
                if (currentPath != '/reset-password') {
                  print('🔍 SignInPage (magic link): Authenticated, navigating to home');
                  context.go('/');
                } else {
                  print('🔍 SignInPage (magic link): Authenticated but on reset-password, staying put');
                }
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
                  color: AppTheme.neutral600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/sign-up'),
                child: Text(
                  context.t('auth.signUp.button'),
                  style: const TextStyle(
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
        // Back button - more prominent
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          icon: Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          label: Text(
            context.t('common.back'),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: ResponsiveLayout.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
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
                Image.asset(
                  'assets/images/rock_logo.png',
                  width: ResponsiveLayout.getResponsiveIconSize(context,
                      mobile: 200, tablet: 250, desktop: 300),
                  height: ResponsiveLayout.getResponsiveIconSize(context,
                      mobile: 200, tablet: 250, desktop: 300),
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
                      : context.t('auth.signIn.subtitle'),
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
                  child: _emailSent ? _buildEmailVerificationMessage() : _buildSignInForm(),
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
                    Image.asset(
                      'assets/images/rock_logo.png',
                      width: 350,
                      height: 350,
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
                          : context.t('auth.signIn.subtitle'),
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _emailSent ? _buildEmailVerificationMessage() : _buildDesktopSignInForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
