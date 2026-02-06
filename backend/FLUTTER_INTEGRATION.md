# Calories Guard API Integration Guide for Flutter

This guide helps Flutter developers integrate with the Calories Guard backend API.

## 📱 Integration Checklist

- [ ] Setup HTTP client in Flutter
- [ ] Implement authentication flow
- [ ] Create API service wrapper
- [ ] Setup token storage (secure storage)
- [ ] Implement token refresh logic
- [ ] Create models from API responses
- [ ] Build service classes for each feature
- [ ] Implement error handling
- [ ] Add logging for debugging
- [ ] Test all endpoints

## 🔧 Setup Instructions

### 1. Add Dependencies to pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  dio: ^5.3.0
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
  connectivity_plus: ^5.0.0
  jwt_decoder: ^2.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 2. Create API Configuration

**lib/config/api_config.dart**
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api';
  // or for production:
  // static const String baseUrl = 'https://api.calories-guard.com/api';
  
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String mealsEndpoint = '/meals';
  static const String foodsEndpoint = '/foods';
  static const String notificationsEndpoint = '/notifications';
  static const String gamificationEndpoint = '/gamification';
  static const String contentEndpoint = '/content';
  
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}
```

### 3. Create Secure Token Storage

**lib/services/token_service.dart**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  
  final _secureStorage = const FlutterSecureStorage();
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
  }
  
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }
  
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }
  
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null) return false;
    
    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }
  
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }
}
```

### 4. Create API Service Base

**lib/services/api_service.dart**
```dart
import 'package:dio/dio.dart';
import 'package:calories_guard/config/api_config.dart';
import 'package:calories_guard/services/token_service.dart';

class ApiService {
  late Dio _dio;
  final TokenService _tokenService = TokenService();
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.connectionTimeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
      ),
    );
    
    // Add interceptor for token management
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              return handler.resolve(await _retryRequest(error.requestOptions));
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        await _tokenService.saveTokens(
          response.data['access_token'],
          response.data['refresh_token'] ?? refreshToken,
        );
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }
  
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    return _dio.request(
      requestOptions.path,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }
  
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return fromJson?.call(response.data) ?? response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<T> post<T>(
    String path, {
    required dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return fromJson?.call(response.data) ?? response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<T> put<T>(
    String path, {
    required dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return fromJson?.call(response.data) ?? response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        _tokenService.clearTokens();
        // Emit logout event or navigate to login
      }
    }
    print('API Error: $error');
  }
}
```

### 5. Authentication Service

**lib/services/auth_service.dart**
```dart
import 'package:calories_guard/services/api_service.dart';
import 'package:calories_guard/services/token_service.dart';
import 'package:calories_guard/models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();
  
  Future<User> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _apiService.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'username': username,
      },
    );
    
    await _tokenService.saveTokens(
      response['access_token'],
      response['refresh_token'],
    );
    
    return User.fromJson(response);
  }
  
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    
    await _tokenService.saveTokens(
      response['access_token'],
      response['refresh_token'],
    );
    
    return User.fromJson(response);
  }
  
  Future<User> getCurrentUser() async {
    final response = await _apiService.get('/auth/me');
    return User.fromJson(response);
  }
  
  Future<void> logout() async {
    await _tokenService.clearTokens();
  }
  
  Future<bool> isLoggedIn() async {
    return await _tokenService.hasValidToken();
  }
}
```

### 6. User Service

**lib/services/user_service.dart**
```dart
import 'package:calories_guard/services/api_service.dart';
import 'package:calories_guard/models/user.dart';

class UserService {
  final ApiService _apiService = ApiService();
  
  Future<User> getProfile() async {
    final response = await _apiService.get('/users/profile');
    return User.fromJson(response);
  }
  
  Future<User> updateProfile({
    required Map<String, dynamic> updates,
  }) async {
    final response = await _apiService.put(
      '/users/profile',
      data: updates,
    );
    return User.fromJson(response);
  }
  
  Future<Map<String, dynamic>> getStats() async {
    return await _apiService.get('/users/stats');
  }
  
  Future<Map<String, dynamic>> updateStats({
    required Map<String, dynamic> stats,
  }) async {
    return await _apiService.post(
      '/users/stats',
      data: stats,
    );
  }
}
```

### 7. Meal Service

**lib/services/meal_service.dart**
```dart
import 'package:calories_guard/services/api_service.dart';

class MealService {
  final ApiService _apiService = ApiService();
  
  Future<Map<String, dynamic>> logMeal({
    required String mealType,
    required List<Map<String, dynamic>> items,
  }) async {
    return await _apiService.post(
      '/meals/log',
      data: {
        'meal_type': mealType,
        'items': items,
      },
    );
  }
  
  Future<List<dynamic>> getMealsByDate(String dateStr) async {
    return await _apiService.get(
      '/meals/by-date',
      queryParameters: {'date_str': dateStr},
    );
  }
  
  Future<Map<String, dynamic>> getDailySummary(String dateStr) async {
    return await _apiService.get('/meals/summary/$dateStr');
  }
  
  Future<void> deleteMeal(int mealId) async {
    await _apiService.delete('/meals/$mealId');
  }
  
  Future<Map<String, dynamic>> logWeight(double weight) async {
    return await _apiService.post(
      '/meals/weight',
      data: {'weight_kg': weight},
    );
  }
  
  Future<List<dynamic>> getWeightHistory({int limit = 30}) async {
    return await _apiService.get(
      '/meals/weight/history/$limit',
    );
  }
}
```

### 8. Food Service

**lib/services/food_service.dart**
```dart
import 'package:calories_guard/services/api_service.dart';

class FoodService {
  final ApiService _apiService = ApiService();
  
  Future<List<dynamic>> getAllFoods({int skip = 0, int limit = 100}) async {
    return await _apiService.get(
      '/foods/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
  }
  
  Future<List<dynamic>> searchFoods({
    required String query,
    int limit = 20,
  }) async {
    return await _apiService.get(
      '/foods/search',
      queryParameters: {'q': query, 'limit': limit},
    );
  }
  
  Future<Map<String, dynamic>> getFood(int foodId) async {
    return await _apiService.get('/foods/$foodId');
  }
  
  Future<List<dynamic>> getFavorites() async {
    return await _apiService.get('/foods/favorites/list');
  }
  
  Future<void> addToFavorites(int foodId) async {
    await _apiService.post(
      '/foods/favorites/$foodId',
      data: {},
    );
  }
  
  Future<void> removeFromFavorites(int foodId) async {
    await _apiService.delete('/foods/favorites/$foodId');
  }
  
  Future<List<dynamic>> getAllergyFlags() async {
    return await _apiService.get('/foods/allergies/flags');
  }
  
  Future<void> addAllergyPreference({
    required int flagId,
    required String preferenceType,
  }) async {
    await _apiService.post(
      '/foods/allergies/preference',
      data: {
        'flag_id': flagId,
        'preference_type': preferenceType,
      },
    );
  }
}
```

## 📋 Data Models

### User Model

**lib/models/user.dart**
```dart
class User {
  final int userId;
  final String email;
  final String username;
  final String? gender;
  final int? currentStreak;
  
  User({
    required this.userId,
    required this.email,
    required this.username,
    this.gender,
    this.currentStreak,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      email: json['email'],
      username: json['username'],
      gender: json['gender'],
      currentStreak: json['current_streak'],
    );
  }
}
```

## 🔄 Example Usage in Flutter

### Login Screen
```dart
final authService = AuthService();

try {
  final user = await authService.login(
    email: emailController.text,
    password: passwordController.text,
  );
  // Navigate to home
} catch (e) {
  // Show error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Login failed: $e')),
  );
}
```

### Log Meal
```dart
final mealService = MealService();

try {
  await mealService.logMeal(
    mealType: 'breakfast',
    items: [
      {
        'food_id': 1,
        'amount': 100,
        'note': '1 bowl',
      },
    ],
  );
  // Show success message
} catch (e) {
  // Show error
}
```

### View Daily Summary
```dart
final mealService = MealService();

final summary = await mealService.getDailySummary(
  DateTime.now().toString().split(' ')[0],
);

print('Calories: ${summary['total_calories_intake']}');
print('Goal Met: ${summary['is_goal_met']}');
```

## 🛡️ Error Handling

```dart
try {
  // API call
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Unauthorized - refresh token or logout
  } else if (e.response?.statusCode == 400) {
    // Bad request - show validation errors
  } else if (e.response?.statusCode == 500) {
    // Server error
  } else {
    // Network error
  }
}
```

## 📡 Recommended Architecture

```
lib/
├── models/              # Data models
├── services/            # API services
├── providers/           # State management (Provider, Riverpod)
├── screens/             # UI screens
├── widgets/             # Reusable widgets
├── config/              # Configuration
└── main.dart
```

## 🚀 Performance Tips

1. **Cache responses** using local database
2. **Implement pagination** for large lists
3. **Use lazy loading** for images
4. **Minimize API calls** with thoughtful data fetching
5. **Implement offline support** with local storage

## 🔐 Security Best Practices

1. **Never store sensitive data** in SharedPreferences
2. **Use FlutterSecureStorage** for tokens
3. **Validate SSL certificates** in production
4. **Implement certificate pinning** for extra security
5. **Never log tokens** in console output
6. **Use HTTPS only** in production

---

For detailed API documentation, visit `http://localhost:8000/docs`
