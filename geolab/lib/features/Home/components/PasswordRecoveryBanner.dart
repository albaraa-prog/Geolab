import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolab/Service/supabase_service.dart';
import 'package:geolab/config/theme.dart';
import 'package:geolab/utils/app_localizations.dart';
import 'package:geolab/utils/responsive_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class PasswordRecoveryBanner extends StatefulWidget {
  const PasswordRecoveryBanner({super.key});

  @override
  State<PasswordRecoveryBanner> createState() => _PasswordRecoveryBannerState();
}

class _PasswordRecoveryBannerState extends State<PasswordRecoveryBanner> {
  bool _isPasswordRecovery = false;
  bool _isDismissed = false;
  String? _recoveryCode;

  @override
  void initState() {
    super.initState();
    _checkPasswordRecoveryState();
  }

  Future<void> _checkPasswordRecoveryState() async {
    try {
      // Check URL for recovery code/token
      final uri = Uri.base;
      
      // Don't show banner if already on reset-password page
      if (uri.path == '/reset-password') {
        return;
      }
      
      // Support both legacy 'code' and new PKCE 'token' parameters
      final code = uri.queryParameters['code'];
      final token = uri.queryParameters['token'];
      final isRecovery = uri.queryParameters['type'] == 'recovery';
      
      // If we have code, token, or type=recovery, this is a password reset flow
      if (code != null || token != null || isRecovery) {
        setState(() {
          _isPasswordRecovery = true;
          _recoveryCode = code ?? token; // Use token if code is null (PKCE flow)
        });
        
        // Show dialog on mobile, banner stays on web
        if (!kIsWeb && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showMobileDialog();
          });
        }
      }
    } catch (e) {
      print('Error checking password recovery state: $e');
    }
  }

  void _showMobileDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.neutral100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                HugeIcons.strokeRoundedLockPassword,
                color: AppTheme.warningColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.t('auth.resetPasswordRequired') != 'auth.resetPasswordRequired'
                    ? context.t('auth.resetPasswordRequired')
                    : 'Reset Your Password',
                style: TextStyle(
                  color: AppTheme.neutral900,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('auth.resetPasswordMessage') != 'auth.resetPasswordMessage'
                  ? context.t('auth.resetPasswordMessage')
                  : 'You\'ve requested to reset your password. Click continue to set a new password for your account.',
              style: TextStyle(
                color: AppTheme.neutral800.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    HugeIcons.strokeRoundedInformationCircle,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This link will expire in 1 hour',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isDismissed = true);
            },
            child: Text(
              context.t('common.cancel') != 'common.cancel'
                  ? context.t('common.cancel')
                  : 'Later',
              style: TextStyle(color: AppTheme.neutral700.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToResetPassword();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.t('common.continue') != 'common.continue'
                  ? context.t('common.continue')
                  : 'Continue',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _dismiss() {
    setState(() {
      _isDismissed = true;
    });
  }

  void _navigateToResetPassword() {
    
    // If we're already on reset-password page, don't navigate
    if (Uri.base.path == '/reset-password') {
      return;
    }
    
    // Navigate with the code parameter preserved
    if (_recoveryCode != null) {
      context.go('/reset-password?code=$_recoveryCode');
    } else {
      context.go('/reset-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show banner on web, mobile uses dialog
    if (!_isPasswordRecovery || _isDismissed || !kIsWeb) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 4,
      color: AppTheme.warningColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ResponsiveBuilder(
            mobile: _buildCompactBanner(),
            tablet: _buildFullBanner(),
            desktop: _buildFullBanner(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBanner() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            HugeIcons.strokeRoundedLockPassword,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reset Your Password',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to continue',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _navigateToResetPassword,
          icon: const Icon(
            HugeIcons.strokeRoundedArrowRight01,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: _dismiss,
          icon: Icon(
            HugeIcons.strokeRoundedCancel01,
            color: Colors.white.withOpacity(0.7),
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildFullBanner() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            HugeIcons.strokeRoundedLockPassword,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reset Your Password',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You\'ve requested to reset your password. Click continue to set a new password.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _navigateToResetPassword,
          icon: const Icon(HugeIcons.strokeRoundedArrowRight01, size: 18),
          label: const Text(
            'Continue',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.warningColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _dismiss,
          icon: Icon(
            HugeIcons.strokeRoundedCancel01,
            color: Colors.white.withOpacity(0.8),
            size: 22,
          ),
        ),
      ],
    );
  }
}
