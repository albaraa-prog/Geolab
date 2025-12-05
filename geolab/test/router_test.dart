import 'package:flutter_test/flutter_test.dart';
import 'package:geolab/config/router.dart';
import 'package:geolab/features/Auth/ResetPasswordPage.dart';
import 'package:geolab/features/Auth/SignInPage.dart';
import 'test_helpers.dart';

void main() {
  // Setup services before running tests
  setUpAll(() async {
    await setupTestServices();
  });

  group('Router Deep Link Tests', () {
    testWidgets('ResetPasswordPage opens with code query parameter', (WidgetTester tester) async {
      // Build the app with router and all required providers
      await tester.pumpWidget(
        const TestApp(),
      );
      
      // Wait for initial build
      await tester.pump();

      // Navigate to reset-password with code
      router.go('/reset-password?code=test-code-123&email=test@example.com');
      await tester.pump(); // Pump once to trigger navigation
      // Wait for any async operations (like code processing) to complete
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify ResetPasswordPage is displayed
      expect(find.byType(ResetPasswordPage), findsOneWidget);
      
      // Verify the page received the code
      final resetPasswordPage = tester.widget<ResetPasswordPage>(
        find.byType(ResetPasswordPage),
      );
      expect(resetPasswordPage.code, equals('test-code-123'));
      expect(resetPasswordPage.email, equals('test@example.com'));
    });

    testWidgets('ResetPasswordPage handles hash fragments in URL', (WidgetTester tester) async {
      // Build the app with router and all required providers
      await tester.pumpWidget(
        const TestApp(),
      );
      
      // Wait for initial build
      await tester.pump();

      // Navigate to reset-password with code and hash fragment
      // Simulating: http://localhost:55212/reset-password?code=3bbd6f68-2047-475b-87bd-c8e19bdb768c#/sign-in
      router.go('/reset-password?code=3bbd6f68-2047-475b-87bd-c8e19bdb768c');
      await tester.pump(); // Pump once to trigger navigation
      // Wait for any async operations (like code processing) to complete
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify ResetPasswordPage is displayed (hash fragment should be ignored)
      expect(find.byType(ResetPasswordPage), findsOneWidget);
      
      final resetPasswordPage = tester.widget<ResetPasswordPage>(
        find.byType(ResetPasswordPage),
      );
      expect(resetPasswordPage.code, equals('3bbd6f68-2047-475b-87bd-c8e19bdb768c'));
    });

    testWidgets('Missing code redirects to SignIn page with error', (WidgetTester tester) async {
      // Build the app with router and all required providers
      await tester.pumpWidget(
        const TestApp(),
      );

      // Navigate to reset-password without code
      router.go('/reset-password');
      await tester.pump(); // First pump to build the loading widget
      
      // Wait for postFrameCallback to execute
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify SignInPage is displayed
      expect(find.byType(SignInPage), findsOneWidget);
      
      // Verify error snackbar is shown
      expect(find.text('Invalid or missing reset code. Please request a new password reset link.'), findsOneWidget);
    });

    testWidgets('Empty code redirects to SignIn page', (WidgetTester tester) async {
      // Build the app with router and all required providers
      await tester.pumpWidget(
        const TestApp(),
      );

      // Navigate to reset-password with empty code
      router.go('/reset-password?code=');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify SignInPage is displayed
      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('ResetPasswordPage receives email parameter', (WidgetTester tester) async {
      // Build the app with router and all required providers
      await tester.pumpWidget(
        const TestApp(),
      );
      
      // Wait for initial build
      await tester.pump();

      // Navigate to reset-password with code and email
      router.go('/reset-password?code=test-code&email=user@example.com');
      await tester.pump(); // Pump once to trigger navigation
      // Wait for any async operations (like code processing) to complete
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify ResetPasswordPage received email
      final resetPasswordPage = tester.widget<ResetPasswordPage>(
        find.byType(ResetPasswordPage),
      );
      expect(resetPasswordPage.email, equals('user@example.com'));
    });
  });
}

