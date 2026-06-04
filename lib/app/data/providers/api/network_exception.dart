import 'dart:io';
import 'package:dio/dio.dart';

/// Custom exceptions untuk network errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  NetworkException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// No internet connection exception
class NoInternetException extends NetworkException {
  NoInternetException()
      : super(
          message: 'Hmmm, Coba cek koneksi internet kamu',
        );
}

/// Timeout exception
class TimeoutException extends NetworkException {
  TimeoutException()
      : super(
          message: 'Lama banget loadingnya. Coba lagi ya!',
        );
}

/// Unauthorized exception (401)
class UnauthorizedException extends NetworkException {
  UnauthorizedException({String? message})
      : super(
          message: message ?? 'Sesi kamu udah habis nih. Login lagi yuk!',
          statusCode: 401,
        );
}

/// Forbidden exception (403)
class ForbiddenException extends NetworkException {
  ForbiddenException({String? message})
      : super(
          message: message ?? 'Ups, kamu nggak boleh akses ini.',
          statusCode: 403,
        );
}

/// Not found exception (404)
class NotFoundException extends NetworkException {
  NotFoundException({String? message})
      : super(
          message: message ?? 'Datanya nggak ketemu nih.',
          statusCode: 404,
        );
}

/// Validation exception (400)
class ValidationException extends NetworkException {
  final Map<String, dynamic>? errors;

  ValidationException({
    String? message,
    this.errors,
  }) : super(
          message: message ?? 'Ada data yang kurang pas nih.',
          statusCode: 400,
          data: errors,
        );
}

/// Server error exception (500)
class ServerException extends NetworkException {
  ServerException({String? message})
      : super(
          message: message ?? 'Server lagi pusing. Coba lagi nanti ya!',
          statusCode: 500,
        );
}

/// Helper to convert Dio exceptions to custom exceptions
class ExceptionHandler {
  ExceptionHandler._(); // Private constructor

  static NetworkException handleException(dynamic error) {
    if (error is SocketException) {
      return NoInternetException();
    }

    if (error.toString().contains('SocketException')) {
      return NoInternetException();
    }

    if (error.toString().contains('TimeoutException')) {
      return TimeoutException();
    }

    return NetworkException(
      message: 'Ada masalah nih. Coba lagi ya!',
    );
  }

  static NetworkException handleDioError(dynamic error) {
    try {
      if (error is DioException) {
        // Handle connection errors directly before looking at status codes
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            return TimeoutException();
          case DioExceptionType.connectionError:
            return NoInternetException();
          case DioExceptionType.unknown:
            if (error.error is SocketException) {
              return NoInternetException();
            }
            break;
          default:
            break;
        }
      }

      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      // Extract message from response
      String? message;
      if (data is Map<String, dynamic>) {
        message = data['message'];
      }

      switch (statusCode) {
        case 400:
          return ValidationException(
            message: message,
            errors: data is Map<String, dynamic> ? data['errors'] : null,
          );
        case 401:
          return UnauthorizedException(message: message);
        case 403:
          return ForbiddenException(message: message);
        case 404:
          return NotFoundException(message: message);
        case 500:
        case 502:
        case 503:
          return ServerException(message: message);
        default:
          return NetworkException(
            message: message ?? 'Servernya ngambek nih. Coba lagi ya!',
            statusCode: statusCode,
            data: data,
          );
      }
    } catch (e) {
      return handleException(error);
    }
  }
}
