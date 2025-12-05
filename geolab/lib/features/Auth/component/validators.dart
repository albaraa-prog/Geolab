String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Please enter your email';
  }
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Please enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value?.trim() ?? '';
  if (password.isEmpty) {
    return 'Please enter your password';
  }
  // SECURITY FIX: Stronger password validation
  if (password.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Password must contain at least one lowercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password must contain at least one number';
  }
  // Optional: Add special character requirement
  // if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
  //   return 'Password must contain at least one special character';
  // }
  return null;
}

String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) {
    return 'Please enter your name';
  }
  if (name.length < 2) {
    return 'Name must be at least 2 characters';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  final confirmPassword = value?.trim() ?? '';
  if (confirmPassword.isEmpty) {
    return 'Please confirm your password';
  }
  if (confirmPassword != password) {
    return 'Passwords do not match';
  }
  return null;
}
