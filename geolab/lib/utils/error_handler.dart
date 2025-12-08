import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolab/features/Settings/components/localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  /// Converts any error object into a user-friendly string message.
  /// Avoids showing technical codes, stack traces, or raw exception names.
  static String getFriendlyErrorMessage(dynamic error) {
    // 1. Handle Dio Network Errors
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "The connection timed out. Please check your internet and try again.";
        case DioExceptionType.connectionError:
          return "Unable to connect to the server. Please check your internet connection.";
        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);
        case DioExceptionType.cancel:
          return "The request was cancelled.";
        default:
          return "We encountered a network issue. Please try again.";
      }
    } 
    
    // 2. Handle Socket/Network Errors
    if (error is SocketException) {
      return "No internet connection available.";
    }

    // 3. Handle Supabase Auth Errors
    if (error is AuthException) {
      return _handleAuthError(error);
    }

    // 4. Handle String-based errors (fallback logic)
    final message = error.toString().toLowerCase();

    // Check for common technical phrases to sanitize
    if (message.contains("socketexception") || 
        message.contains("connection refused") || 
        message.contains("network is unreachable")) {
      return "No internet connection available.";
    }
    
    if (message.contains("timeout")) {
      return "The operation timed out. Please try again.";
    }
    
    if (message.contains("404")) {
      return "We couldn't find what you were looking for.";
    }
    
    if (message.contains("500") || message.contains("internal server error")) {
      return "Something went wrong on our end. Please try again later.";
    }

    // If it's just a clean string message (not an exception dump), return it
    // Otherwise return generic fallback
    if (error is String && !message.contains("exception") && !message.contains("stacktrace")) {
       return error;
    }

    return "Something unexpected went wrong. Please try again.";
  }

  static String _handleBadResponse(Response? response) {
    if (response == null) return "Server error occurred.";
    
    final statusCode = response.statusCode;
    
    // Check if the backend sent a specific friendly "error" or "message" field
    try {
      if (response.data is Map) {
        final data = response.data as Map;
        if (data.containsKey('error') && data['error'] is String) {
           return data['error'].toString(); 
        }
        if (data.containsKey('message') && data['message'] is String) {
           return data['message'].toString();
        }
      }
    } catch (_) {
      // ignore parsing errors
    }

    if (statusCode == 400) return "Invalid request. Please check your input.";
    if (statusCode == 401) return "Your session has expired. Please log in again.";
    if (statusCode == 403) return "You don't have permission to perform this action.";
    if (statusCode == 404) return "The requested resource was not found.";
    if (statusCode == 429) return "You're doing that too often. Please wait a moment.";
    if (statusCode != null && statusCode >= 500) return "Our servers are having trouble right now. We're working on it.";
    
    return "Something unexpected happened.";
  }

  static String _handleAuthError(AuthException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains("invalid login credentials")) return "Incorrect email or password.";
    if (msg.contains("email not confirmed")) return "Please verify your email address before logging in.";
    if (msg.contains("user already registered")) return "An account with this email already exists.";
    if (msg.contains("rate limit")) return "Too many attempts. Please try again later.";
    
    return error.message; // Supabase messages are usually readable, but we caught the technical ones above
  }
}
