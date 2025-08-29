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
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
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
