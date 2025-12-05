# Router Deep Link Testing Guide

## Overview

This document explains how the reset password deep link routing works and how to test it.

## Route Configuration

The `/reset-password` route is configured in `lib/config/router.dart` to:

1. **Extract query parameters**: Reads `code` and `email` from the URL query string
2. **Validate code**: If `code` is missing or empty, redirects to `/sign-in` with an error snackbar
3. **Handle hash fragments**: Ignores hash fragments (like `#/sign-in`) when on the reset-password page
4. **Pass parameters**: Provides `code` and `email` to `ResetPasswordPage`

## Testing in Browser

### Test URL Format

```
http://localhost:55212/reset-password?code=3bbd6f68-2047-475b-87bd-c8e19bdb768c#/sign-in
```

### Test Scenarios

#### 1. Valid Reset Code
**URL**: `http://localhost:55212/reset-password?code=3bbd6f68-2047-475b-87bd-c8e19bdb768c`

**Expected Behavior**:
- ✅ Opens `ResetPasswordPage`
- ✅ Code is passed to the page
- ✅ Hash fragment `#/sign-in` is ignored
- ✅ Page processes the code and shows password input form

#### 2. Valid Reset Code with Email
**URL**: `http://localhost:55212/reset-password?code=3bbd6f68-2047-475b-87bd-c8e19bdb768c&email=user@example.com`

**Expected Behavior**:
- ✅ Opens `ResetPasswordPage`
- ✅ Both `code` and `email` are passed to the page
- ✅ Page can use email for display or validation

#### 3. Missing Code
**URL**: `http://localhost:55212/reset-password`

**Expected Behavior**:
- ✅ Redirects to `/sign-in`
- ✅ Shows error snackbar: "Invalid or missing reset code. Please request a new password reset link."
- ✅ Error snackbar has red background and displays for 4 seconds

#### 4. Empty Code
**URL**: `http://localhost:55212/reset-password?code=`

**Expected Behavior**:
- ✅ Redirects to `/sign-in`
- ✅ Shows error snackbar

#### 5. Hash Fragment Handling
**URL**: `http://localhost:55212/reset-password?code=3bbd6f68-2047-475b-87bd-c8e19bdb768c#/sign-in`

**Expected Behavior**:
- ✅ Opens `ResetPasswordPage` (hash fragment is ignored)
- ✅ URL is cleaned to remove hash fragment automatically
- ✅ Does NOT redirect to `/sign-in`

## Running Unit Tests

### Router Tests

```bash
flutter test test/router_test.dart
```

Tests verify:
- ResetPasswordPage opens with code query parameter
- Hash fragments are handled correctly
- Missing code redirects to SignIn page with error
- Email parameter is passed correctly

### Widget Tests

```bash
flutter test test/reset_password_page_test.dart
```

Tests verify:
- Password input fields are displayed
- Loading indicator shows while processing code
- Code validation works
- Email parameter is received

## Implementation Details

### Router Redirect Logic

The router's `redirect` function:
1. Always allows access to `/reset-password` path (returns `null`)
2. Ignores hash fragments when on `/reset-password` page
3. Prevents auth-based redirects when processing reset codes

### ResetPasswordPage Validation

The page validates:
1. Code is non-null and non-empty (in `initState`)
2. If code is invalid, shows error and redirects to sign-in
3. Processes code via `exchangeCodeForSession()` to create a valid session
4. Only allows password update after code is successfully processed

### URL Cleaning

On web, the page automatically cleans hash fragments from the URL using:
- `url_cleaner_web.dart` (web implementation)
- `url_cleaner_stub.dart` (non-web stub)

This ensures the URL stays clean: `/reset-password?code=...` without unwanted hash fragments.

## Troubleshooting

### Issue: Redirects to sign-in even with valid code

**Possible Causes**:
1. Router redirect logic is interfering
2. Code validation is too strict
3. Hash fragment is being processed incorrectly

**Solution**: Check that the router's redirect function returns `null` for `/reset-password` path.

### Issue: Code not being processed

**Possible Causes**:
1. `exchangeCodeForSession()` is failing
2. Supabase client is not initialized
3. Code is expired or invalid

**Solution**: Check browser console for errors and verify Supabase configuration.

### Issue: Hash fragment causes redirect

**Solution**: Ensure the router ignores hash fragments when `currentPath == '/reset-password'`.

## Example Test URLs

Replace `localhost:55212` with your actual development server port:

```
# Valid reset code
http://localhost:55212/reset-password?code=test-code-123

# With email
http://localhost:55212/reset-password?code=test-code-123&email=user@example.com

# With hash fragment (should be ignored)
http://localhost:55212/reset-password?code=test-code-123#/sign-in

# Missing code (should redirect)
http://localhost:55212/reset-password
```

