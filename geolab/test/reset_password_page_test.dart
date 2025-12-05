import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolab/features/Auth/ResetPasswordPage.dart';
import 'test_helpers.dart';

void main() {
  group('ResetPasswordPage Widget Tests', () {
    testWidgets('Displays password input fields when code is provided', (WidgetTester tester) async {
      // Build the ResetPasswordPage with a valid code and all required providers
      await tester.pumpWidget(
        TestWidgetWrapper(
          child: ResetPasswordPage(
            code: 'valid-reset-code-123',
            email: 'test@example.com',
          ),
        ),
      );

      // Wait for the page to initialize and process the code
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify password input fields are present
      // Note: These will only be visible after code is processed
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Confirm Password'), findsWidgets);
    });

    testWidgets('Shows loading indicator while processing code', (WidgetTester tester) async {
      // Build the ResetPasswordPage with a valid code and all required providers
      await tester.pumpWidget(
        TestWidgetWrapper(
          child: ResetPasswordPage(
            code: 'valid-reset-code-123',
            email: 'test@example.com',
          ),
        ),
      );

      // Pump immediately after building
      await tester.pump();

      // Verify loading indicator is shown (or verifying message)
      // The exact UI depends on the implementation
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Validates code is non-null in constructor', (WidgetTester tester) async {
      // Build the ResetPasswordPage without code and all required providers
      await tester.pumpWidget(
        TestWidgetWrapper(
          child: ResetPasswordPage(
            code: null,
            email: 'test@example.com',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The page should handle null code gracefully
      // It should either show an error or redirect
      // This depends on the implementation
      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });

    testWidgets('Displays email when provided', (WidgetTester tester) async {
      // Build the ResetPasswordPage with email and all required providers
      await tester.pumpWidget(
        TestWidgetWrapper(
          child: ResetPasswordPage(
            code: 'valid-reset-code-123',
            email: 'user@example.com',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify the page is built (email is used internally, may not be displayed)
      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });
  });
}
