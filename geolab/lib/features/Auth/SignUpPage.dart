import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_event.dart';
import 'package:geolab/features/Auth/Bloc/auth_state.dart';
import 'package:geolab/features/Auth/component/CustomButton.dart';
import 'package:geolab/features/Auth/component/OTPInputField.dart';
import 'package:geolab/features/Auth/component/TextInputField.dart';
import 'package:geolab/features/Auth/component/validators.dart';
import 'package:geolab/utils/alerts.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:geolab/utils/rtl_wrapper.dart';
import 'package:geolab/utils/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/foundation.dart';


class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  final GlobalKey<OTPInputFieldState> _otpFieldKey = GlobalKey<OTPInputFieldState>();
String? _otpError;
  
  bool _isLoading = false;
  bool _showOTPStep = false;
  bool _isResendingOTP = false;
  int _resendTimer = 0;
  
  // Store user data for OTP verification step
  String _pendingEmail = '';
  String _pendingName = '';
  String _pendingPassword = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
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
          color: Colors.red,
        );
        return;
      }

      // Store user data and send OTP
      _pendingEmail = _emailController.text.trim();
      _pendingName = _nameController.text.trim();
      _pendingPassword = _passwordController.text.trim();

      // Send OTP request to your backend
      BlocProvider.of<AuthBloc>(context).add(
        AuthSendOTPRequested(email: _pendingEmail),
      );
    }
  }

  void _verifyOTP() {
    if (_otpFormKey.currentState?.validate() ?? false) {
      // Verify OTP and complete registration
      BlocProvider.of<AuthBloc>(context).add(
        AuthVerifyOTPAndRegister(
          email: _pendingEmail,
          name: _pendingName,
          password: _pendingPassword,
          otp: _otpController.text.trim(),
          subscriptionTier: 'free',
        ),
      );
    }
  }

  void _resendOTP() {
    if (_resendTimer == 0) {
      BlocProvider.of<AuthBloc>(context).add(
        AuthResendOTPRequested(email: _pendingEmail),
      );
      _startResendTimer();
    }
  }

  void _goBackToSignUp() {
    setState(() {
      _showOTPStep = false;
      _otpController.clear();
    });
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
                  _showOTPStep 
                      ? context.t('auth.otp.subtitle')
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
                  child: _showOTPStep ? _buildOTPForm() : _buildSignUpForm(),
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
            color: AppTheme.primary,
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
          obscureText: true,
          textInputAction: TextInputAction.next,
          label: context.t('auth.password'),
          icon: HugeIcons.strokeRoundedLock,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context, mobile: 16, tablet: 20, desktop: 24)),
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
                context, mobile: 24, tablet: 28, desktop: 32)),
        BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              AppAlerts.showAlert(context, 'Error', state.message);
            } else if (state is AuthOTPSent) {
              setState(() {
                _showOTPStep = true;
              });
              _startResendTimer();
              AppAlerts.showSnackbar(
                context,
                context.t('auth.otp.sent'),
                color: Colors.green,
              );
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
                  : context.t('auth.signUp.sendOTP'),
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



  Widget _buildOTPForm() {
  return Form(
    key: _otpFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _goBackToSignUp,
            icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          HugeIcons.strokeRoundedMail01,
          size: ResponsiveLayout.getResponsiveIconSize(context,
              mobile: 60, tablet: 70, desktop: 80),
          color: AppTheme.primary,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 16,
                tablet: 20,
                desktop: 24)),
        Text(
          context.t('auth.otp.title'),
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
                mobile: 8,
                tablet: 12,
                desktop: 16)),
        Text(
          context.t('auth.otp.description', {'email': _pendingEmail}),
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 32,
                tablet: 36,
                desktop: 40)),
        // Modern OTP Input Field
        OTPInputField(
          key: _otpFieldKey,
          length: 6,
          errorText: _otpError,
          enabled: !_isLoading,
          onChanged: (otp) {
            // Clear error when user starts typing
            if (_otpError != null) {
              setState(() {
                _otpError = null;
              });
            }
          },
          onCompleted: (otp) {
            _otpController.text = otp;
            // Auto-verify when complete
            _verifyOTP();
          },
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
              setState(() {
                _otpError = state.message;
              });
              _otpFieldKey.currentState?.clearOTP();
              AppAlerts.showAlert(context, 'Error', state.message);
            } else if (state is AuthOTPSent) {
              AppAlerts.showSnackbar(
                context,
                context.t('auth.otp.resent'),
                color: Colors.green,
              );
            } else if (state is AuthAuthenticated) {
              AppAlerts.showSnackbar(
                context,
                context.t('auth.signUp.success'),
                color: Colors.green,
              );
              context.go('/');
            }
          },
          builder: (context, state) {
            _isLoading = state is AuthLoading;
            return CustomButton(
              onPressed: _isLoading ? null : () {
                final otp = _otpFieldKey.otpValue;
                if (otp.length == 6) {
                  _otpController.text = otp;
                  _verifyOTP();
                } else {
                  setState(() {
                    _otpError = context.t('auth.otp.invalid');
                  });
                }
              },
              text: _isLoading
                  ? context.t('common.loading')
                  : context.t('auth.otp.verify'),
              isLoading: _isLoading,
            );
          },
        ),
        SizedBox(
            height: ResponsiveLayout.getResponsiveSpacing(
                context,
                mobile: 20,
                tablet: 24,
                desktop: 28)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.t('auth.otp.didntReceive'),
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
              onPressed: _resendTimer > 0 ? null : _resendOTP,
              child: Text(
                _resendTimer > 0 
                    ? '${context.t('auth.otp.resend')} (${_resendTimer}s)'
                    : context.t('auth.otp.resend'),
                style: TextStyle(
                  color: _resendTimer > 0 ? Colors.grey : AppTheme.primary,
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
      ],
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
                      _showOTPStep 
                          ? context.t('auth.otp.subtitle')
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
                child: SizedBox(
                  width: 400,
                  child: _showOTPStep ? _buildDesktopOTPForm() : _buildDesktopSignUpForm(),
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
                AppAlerts.showAlert(context, 'Error', state.message);
              } else if (state is AuthOTPSent) {
                setState(() {
                  _showOTPStep = true;
                });
                _startResendTimer();
                AppAlerts.showSnackbar(
                  context,
                  context.t('auth.otp.sent'),
                  color: Colors.green,
                );
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
                    : context.t('auth.signUp.sendOTP'),
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
    );
  }

Widget _buildDesktopOTPForm() {
  return Form(
    key: _otpFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: _goBackToSignUp,
            icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Icon(
          HugeIcons.strokeRoundedMail01,
          size: 80,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          context.t('auth.otp.title'),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          context.t('auth.otp.description', {'email': _pendingEmail}),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        // Modern OTP Input Field
        OTPInputField(
          key: _otpFieldKey,
          length: 6,
          errorText: _otpError,
          enabled: !_isLoading,
          onChanged: (otp) {
            // Clear error when user starts typing
            if (_otpError != null) {
              setState(() {
                _otpError = null;
              });
            }
          },
          onCompleted: (otp) {
            _otpController.text = otp;
            // Auto-verify when complete
            _verifyOTP();
          },
        ),
        const SizedBox(height: 32),
        BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              setState(() {
                _otpError = state.message;
              });
              _otpFieldKey.currentState?.clearOTP();
              AppAlerts.showAlert(context, 'Error', state.message);
            } else if (state is AuthOTPSent) {
              AppAlerts.showSnackbar(
                context,
                context.t('auth.otp.resent'),
                color: Colors.green,
              );
            } else if (state is AuthAuthenticated) {
              AppAlerts.showSnackbar(
                context,
                context.t('auth.signUp.success'),
                color: Colors.green,
              );
              context.go('/');
            }
          },
          builder: (context, state) {
            _isLoading = state is AuthLoading;
            return CustomButton(
              onPressed: _isLoading ? null : () {
                final otp = _otpFieldKey.otpValue;
                if (otp.length == 6) {
                  _otpController.text = otp;
                  _verifyOTP();
                } else {
                  setState(() {
                    _otpError = context.t('auth.otp.invalid');
                  });
                }
              },
              text: _isLoading
                  ? context.t('common.loading')
                  : context.t('auth.otp.verify'),
              isLoading: _isLoading,
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.t('auth.otp.didntReceive'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            TextButton(
              onPressed: _resendTimer > 0 ? null : _resendOTP,
              child: Text(
                _resendTimer > 0 
                    ? '${context.t('auth.otp.resend')} (${_resendTimer}s)'
                    : context.t('auth.otp.resend'),
                style: TextStyle(
                  color: _resendTimer > 0 ? Colors.grey : AppTheme.primary,
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

