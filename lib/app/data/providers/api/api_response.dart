/// Standard API response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  /// From JSON factory
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
    };
  }

  /// Check if response is successful
  bool get isSuccess => success;

  /// Check if response has error
  bool get hasError => !success;

  /// Get error message
  String get errorMessage {
    if (message != null) return message!;
    if (errors != null && errors!.isNotEmpty) {
      // Return first error message from errors map
      final firstKey = errors!.keys.first;
      final firstError = errors![firstKey];
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }
    return 'Unknown error occurred';
  }
}
