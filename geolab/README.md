# MVC Architecture with BLoC Integration

This directory contains the core MVC architecture components that work seamlessly with your existing BLoC state management.

## 🏗️ Architecture Overview

The MVC pattern is implemented with three main components:

### 📋 Models (`BaseModel`)
- **Purpose**: Data structures and business logic
- **Location**: `lib/core/base_model.dart`
- **Usage**: Extend `BaseModel` for all data models

```dart
class UserModel extends BaseModel {
  final String id;
  final String email;
  
  // Implement required methods
  @override
  Map<String, dynamic> toJson() => {'id': id, 'email': email};
  
  @override
  factory UserModel.fromJson(Map<String, dynamic> json) => 
    UserModel(id: json['id'], email: json['email']);
  
  @override
  UserModel copyWith({String? id, String? email}) => 
    UserModel(id: id ?? this.id, email: email ?? this.email);
}
```

### 🎮 Controllers (`BaseController`)
- **Purpose**: Business logic and state management
- **Location**: `lib/core/base_controller.dart`
- **Usage**: Extend `BaseController` for local state management

```dart
class UserController extends BaseController {
  UserModel? _user;
  
  UserModel? get user => _user;
  
  Future<void> loadUser() async {
    setLoading(true);
    try {
      // API call logic
      _user = await apiService.getUser();
      notifyListeners();
    } catch (e) {
      setError('Failed to load user: $e');
    } finally {
      setLoading(false);
    }
  }
}
```

### 🖼️ Views (`BaseView`, `BaseBlocView`, `BaseHybridView`)
- **Purpose**: UI components and user interactions
- **Location**: `lib/core/base_view.dart`
- **Usage**: Choose the appropriate base view for your needs

#### Option 1: Pure MVC (BaseView)
```dart
class UserView extends BaseView<UserController> {
  @override
  UserController createController() => UserController();
  
  @override
  Widget buildView(BuildContext context) {
    return Scaffold(
      body: controller.isLoading 
        ? const CircularProgressIndicator()
        : Text(controller.user?.email ?? 'No user'),
    );
  }
}
```

#### Option 2: Pure BLoC (BaseBlocView)
```dart
class UserBlocView extends BaseBlocView<UserBloc, UserState> {
  @override
  Widget buildView(BuildContext context, UserState state) {
    if (state is UserLoading) {
      return const CircularProgressIndicator();
    }
    if (state is UserLoaded) {
      return Text(state.user.email);
    }
    return const Text('No user');
  }
}
```

#### Option 3: Hybrid MVC + BLoC (BaseHybridView)
```dart
class UserHybridView extends BaseHybridView<UserController, UserBloc, UserState> {
  @override
  UserController createController() => UserController();
  
  @override
  Widget buildView(BuildContext context, UserState state) {
    // Use both controller and BLoC state
    return Scaffold(
      body: Column(
        children: [
          Text('Controller: ${controller.user?.email}'),
          Text('BLoC: ${state is UserLoaded ? state.user.email : 'Loading...'}'),
        ],
      ),
    );
  }
}
```

## 🎨 Enhanced Features

### 🎬 Lottie Animations
- **Location**: `lib/core/animations/`
- **Usage**: Pre-built animation widgets for common states

```dart
// Loading animation
AnimationWidgets.loading(
  message: 'Loading data...',
  width: 100,
  height: 100,
)

// Success animation
AnimationWidgets.success(
  message: 'Data saved successfully!',
  onCompleted: () => Navigator.pop(context),
)

// Error animation
AnimationWidgets.error(
  message: 'Something went wrong',
)
```

### 🎯 Comprehensive Icon System
- **Location**: `lib/core/icons/app_icons.dart`
- **Usage**: Consistent icon usage across the app

```dart
// Navigation icons
Icon(AppIcons.home)
Icon(AppIcons.settings)
Icon(AppIcons.profile)

// Action icons
Icon(AppIcons.add)
Icon(AppIcons.edit)
Icon(AppIcons.delete)

// Status icons
Icon(AppIcons.success)
Icon(AppIcons.error)
Icon(AppIcons.warning)
```

### 🌍 Localization & Theming
- **Localization**: Enhanced existing system with RTL support
- **Theming**: Advanced theme system with light/dark modes
- **Usage**: Works seamlessly across all pages

## 🚀 Integration with Existing BLoC

Your existing BLoC structure remains unchanged. The MVC components work alongside your BLoC:

```dart
// In your existing BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Your existing implementation
}

// New MVC controller for local state
class AuthController extends BaseController {
  bool _rememberMe = false;
  
  bool get rememberMe => _rememberMe;
  
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }
}

// Hybrid view using both
class AuthView extends BaseHybridView<AuthController, AuthBloc, AuthState> {
  @override
  AuthController createController() => AuthController();
  
  @override
  Widget buildView(BuildContext context, AuthState state) {
    return Column(
      children: [
        // Use BLoC state for authentication
        if (state is AuthLoading) const CircularProgressIndicator(),
        if (state is AuthAuthenticated) Text('Welcome ${state.user.name}'),
        
        // Use controller for local UI state
        CheckboxListTile(
          value: controller.rememberMe,
          onChanged: (_) => controller.toggleRememberMe(),
          title: const Text('Remember me'),
        ),
      ],
    );
  }
}
```

## 📁 File Structure

```
lib/core/
├── base_controller.dart      # Base controller class
├── base_model.dart          # Base model class
├── base_view.dart           # Base view classes
├── animations/              # Lottie animation system
│   ├── lottie_animations.dart
│   └── animation_widgets.dart
├── icons/                   # Comprehensive icon system
│   └── app_icons.dart
├── examples/                # Working examples
│   └── simple_example.dart
└── README.md               # This file
```

## ✅ Benefits

1. **Clean Architecture**: Clear separation of concerns
2. **BLoC Integration**: Works seamlessly with existing BLoC
3. **Flexible**: Choose MVC, BLoC, or hybrid approach
4. **Consistent**: Standardized patterns across the app
5. **Enhanced UX**: Lottie animations and comprehensive icons
6. **Maintainable**: Easy to test and modify
7. **Scalable**: Grows with your app's complexity

## 🎯 Best Practices

1. **Use MVC for local UI state** (form inputs, toggles, etc.)
2. **Use BLoC for global app state** (authentication, data fetching)
3. **Use hybrid approach for complex features** that need both
4. **Keep controllers focused** on single responsibilities
5. **Use the icon system** for consistency
6. **Add animations** for better user experience
7. **Follow the existing patterns** in your codebase

This architecture provides a solid foundation while maintaining compatibility with your existing BLoC implementation!
