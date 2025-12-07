import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolab/features/Auth/Bloc/auth_bloc.dart';
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
import 'package:geolab/Service/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// Conditional import for web
import 'url_cleaner_stub.dart'
    if (dart.library.html) 'url_cleaner_web.dart' as url_cleaner;
import 'package:geolab/main.dart' show setRecoveryMode;

// Conditional import for web HTML access - handled via helper function

class ResetPasswordPage extends StatefulWidget {
  final String? code;
  final String? email;

  const ResetPasswordPage({
    super.key,
    this.code,
    this.email,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordReset = false;
  bool _codeProcessed = false;
  bool _obscurePassword = true; // Password visibility toggle
  bool _obscureConfirmPassword = true; // Confirm password visibility toggle
  
  // Timer for continuous URL cleaning on web
  Timer? _urlCleanTimer;

  @override
  void initState() {
    super.initState();
    // Clean URL hash fragment immediately if present (Supabase sometimes adds unwanted fragments like #/sign-in)
    // Do this synchronously in initState to prevent router from processing the hash fragment
    if (kIsWeb) {
      // Clean immediately, not in postFrameCallback
      url_cleaner.cleanResetPasswordUrl();
      
      // Clean multiple times to catch any async additions
      // After first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        url_cleaner.cleanResetPasswordUrl();
      });
      
      // After a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          url_cleaner.cleanResetPasswordUrl();
        }
      });
      
      // After another delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          url_cleaner.cleanResetPasswordUrl();
        }
      });
      
      // Set up continuous monitoring to clean hash if it gets re-added
      // Check every 100ms for the first 2 seconds
      _urlCleanTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        url_cleaner.cleanResetPasswordUrl();
        // Stop after 2 seconds
        if (timer.tick >= 20) {
          timer.cancel();
        }
      });
    }
    
    // Wait for Supabase to process the redirect and extract code from URL if needed
    // On web, Supabase might add the code to the URL after redirect
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // Check if code is in URL (might be added by Supabase after redirect)
      String? code = widget.code;
      if (kIsWeb && (code == null || code.isEmpty)) {
        // Try to extract code from current URL using url_cleaner helper
        code = _getCodeFromUrl();
      }
      
      // If no code, check if we have a valid session from PASSWORD_RECOVERY event
      // Supabase creates a recovery session when processing the reset link
      if (code == null || code.isEmpty) {
        
        final client = SupabaseService.client;
        final session = client?.auth.currentSession;
        
        if (session != null) {
          // User has a valid session (from PASSWORD_RECOVERY), allow password reset
          setState(() {
            _codeProcessed = true;
            _isLoading = false;
          });
          return;
        }
        
        // Wait a bit more in case Supabase is still processing
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check session again
        final sessionRetry = client?.auth.currentSession;
        if (sessionRetry != null) {
          setState(() {
            _codeProcessed = true;
            _isLoading = false;
          });
          return;
        }
        
        // Check URL again after delay
        if (kIsWeb) {
          code = _getCodeFromUrl();
        }
        
        // If still no code AND no session, show error
        if ((code == null || code.isEmpty)) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _codeProcessed = false;
            });
            AppAlerts.showSnackbar(
              context,
              'Invalid or missing reset code. Please request a new password reset link.',
              color: AppTheme.errorColor,
            );
          }
          return;
        }
      }
      
      // Process the code if we have one
      if (mounted && code != null && code.isNotEmpty) {
        _processResetCodeWithCode(code);
      }
    });
  }

  // Helper function to get code from URL (web only)
  // Uses url_cleaner's getCurrentUrlHref function which has web access
  String? _getCodeFromUrl() {
    if (!kIsWeb) return null;
    try {
      final currentHref = url_cleaner.getCurrentUrlHref();
      if (currentHref.isEmpty) return null;
      final currentUrl = Uri.parse(currentHref);
      return currentUrl.queryParameters['code'];
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // Cancel URL cleaning timer
    _urlCleanTimer?.cancel();
    // Cancel any pending navigation timers
    // Note: Future.delayed doesn't return a cancellable timer, but we check mounted
    // before executing, so this is safe
    super.dispose();
  }

  Future<void> _processResetCode() async {
    if (_codeProcessed) return;
    final code = widget.code;
    if (code == null || code.isEmpty) return;
    await _processResetCodeWithCode(code);
  }
  
  Future<void> _processResetCodeWithCode(String resetCode) async {
    if (_codeProcessed) return;
    
    setState(() => _isLoading = true);
    
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase client is not available');
      }

      // For password reset, we need to explicitly exchange the code for a session
      // Supabase doesn't auto-process password reset codes like magic links
      // We must use exchangeCodeForSession to convert the code into a valid session
      
      Session? session;
      
      if (kIsWeb) {
        // On web, Supabase may auto-process the code from the URL in some cases
        // Wait a moment for it to process
        await Future.delayed(const Duration(milliseconds: 500));
        session = client.auth.currentSession;
      }
      
      // If no session yet, explicitly exchange the code for a session
      if (session == null && resetCode.isNotEmpty) {
        try {
          // Exchange the code for a session - this is required for password reset
          final response = await client.auth.exchangeCodeForSession(resetCode);
          session = response.session;
        } catch (e) {
          // If exchangeCodeForSession fails, the code might be invalid or expired
          throw Exception('Invalid or expired reset code. Please request a new password reset link.');
        }
      }
      
      if (session == null) {
        throw Exception('Invalid or expired reset code. Please request a new password reset link.');
      }

      setState(() {
        _codeProcessed = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = e.toString();
        // Make error message more user-friendly
        if (errorMessage.contains('AuthSessionMissingException') || 
            errorMessage.contains('session missing') ||
            errorMessage.contains('Invalid') ||
            errorMessage.contains('expired')) {
          errorMessage = 'Invalid or expired reset code. Please request a new password reset link.';
        }
        AppAlerts.showAlert(
          context,
          context.t('common.error'),
          errorMessage,
        );
        // Navigate back to sign-in if code is invalid
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setRecoveryMode(false);
            context.go('/sign-in');
          }
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final password = _passwordController.text.trim();
      
      // Update password via Supabase
      _updatePassword(password);
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    setState(() => _isLoading = true);
    
    try {
      final client = SupabaseService.client;
      if (client == null) {
        throw Exception('Supabase client is not available');
      }

      // Update password using Supabase
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      setState(() {
        _passwordReset = true;
        _isLoading = false;
      });

      AppAlerts.showSnackbar(
        context,
        context.t('auth.resetPassword.passwordUpdated'),
        color: AppTheme.successColor,
      );

      // Navigate to sign-in after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setRecoveryMode(false);
          context.go('/sign-in');
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      AppAlerts.showAlert(
        context,
        context.t('common.error'),
        e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _passwordReset, // Only allow back navigation after password is reset
      onPopInvoked: (didPop) {
        if (!didPop && !_passwordReset) {
          // If trying to go back before resetting password, go to sign-in instead
          setRecoveryMode(false);
          context.go('/sign-in');
        }
      },
      child: Scaffold(
        body: ResponsiveBuilder(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
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
                    const SizedBox(height: 40),
                    Icon(
                      HugeIcons.strokeRoundedLock,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.t('auth.resetPassword.title'),
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getResponsiveFontSize(
                          context,
                          mobile: 28,
                          tablet: 32,
                          desktop: 36,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t('auth.resetPassword.setNewPassword'),
                      style: TextStyle(
                        fontSize: ResponsiveLayout.getResponsiveFontSize(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
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
                      child: _passwordReset ? _buildSuccessMessage() : _buildResetForm(),
                    ),
                    const SizedBox(height: 24),
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
    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                  Icon(
                    HugeIcons.strokeRoundedLock,
                    size: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.t('auth.resetPassword.title'),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t('auth.resetPassword.setNewPassword'),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _passwordReset ? _buildSuccessMessage() : _buildResetForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    // Show loading if processing code
    if (_isLoading && !_codeProcessed) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            context.t('auth.resetPassword.verifying'),
            style: TextStyle(
              fontSize: ResponsiveLayout.getResponsiveFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              color: AppTheme.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          TextInputField(
            controller: _confirmPasswordController,
            label: context.t('auth.confirmPassword'),
            obscureText: _obscureConfirmPassword,
            validator: (value) => validateConfirmPassword(
              value,
              _passwordController.text,
            ),
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
              context,
              mobile: 32,
              tablet: 36,
              desktop: 40,
            ),
          ),
          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                AppAlerts.showAlert(
                  context,
                  context.t('common.error'),
                  state.message,
                );
              }
            },
            builder: (context, state) {
              _isLoading = state is AuthLoading;
              return CustomButton(
                onPressed: _isLoading ? null : _submitForm,
                text: _isLoading
                    ? context.t('common.loading')
                    : context.t('auth.resetPassword.updatePassword'),
                isLoading: _isLoading,
              );
            },
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setRecoveryMode(false);
              context.go('/sign-in');
            },
            child: Text(
              context.t('auth.resetPassword.backToSignIn'),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: ResponsiveLayout.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: AppTheme.successColor,
        ),
        const SizedBox(height: 24),
        Text(
          context.t('auth.resetPassword.passwordUpdated'),
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
            ),
            fontWeight: FontWeight.bold,
            color: AppTheme.successColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          context.t('auth.resetPassword.redirecting'),
          style: TextStyle(
            fontSize: ResponsiveLayout.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            color: AppTheme.neutral600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

