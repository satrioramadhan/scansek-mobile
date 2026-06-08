import '../constants/app_constants.dart';

/// Form validation utilities
class Validators {
  Validators._(); // Private constructor

  // ============================================
  // EMAIL VALIDATION
  // ============================================

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Emailnya diisi dulu ya';
    }

    // Trim whitespace (common when pasting)
    final trimmedValue = value.trim();
    
    if (trimmedValue.isEmpty) {
      return 'Emailnya diisi dulu ya';
    }

    // Simple email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Format emailnya kurang pas nih';
    }

    return null;
  }

  // ============================================
  // PASSWORD VALIDATION
  // ============================================

  /// Validate password (min 6 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passwordnya jangan kosong dong';
    }

    if (value.length < AppConstants.passwordMinLength) {
      return 'Password minimal ${AppConstants.passwordMinLength} karakter ya';
    }

    return null;
  }

  /// Validate password confirmation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi passwordnya diisi juga ya';
    }

    if (value != password) {
      return 'Passwordnya beda nih, cek lagi ya';
    }

    return null;
  }

  // ============================================
  // NAME VALIDATION
  // ============================================

  /// Validate name (min 2 characters)
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Namanya diisi dulu dong';
    }

    if (value.length < 2) {
      return 'Nama minimal 2 karakter ya';
    }

    return null;
  }

  // ============================================
  // NUMBER VALIDATIONS
  // ============================================

  /// Validate required number field
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bagian ini'} diisi dulu ya';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Isinya'} harus angka ya';
    }

    return null;
  }

  /// Validate weight (30-150 kg)
  static String? weight(String? value) {
    final error = number(value, fieldName: 'Berat badan');
    if (error != null) return error;

    final weight = double.parse(value!);
    if (weight < AppConstants.minWeight) {
      return 'Berat badan minimal ${AppConstants.minWeight.toInt()} kg';
    }
    if (weight > AppConstants.maxWeight) {
      return 'Angka ini butuh pantauan dokter spesialis khusus';
    }

    return null;
  }

  /// Validate height (100-210 cm)
  static String? height(String? value) {
    final error = number(value, fieldName: 'Tinggi badan');
    if (error != null) return error;

    final height = double.parse(value!);
    if (height < AppConstants.minHeight) {
      return 'Tinggi badan minimal ${AppConstants.minHeight.toInt()} cm';
    }
    if (height > AppConstants.maxHeight) {
      return 'Angka ini butuh pantauan dokter spesialis khusus';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final error = number(value, fieldName: fieldName);
    if (error != null) return error;

    final num = double.parse(value!);
    if (num <= 0) {
      return '${fieldName ?? 'Bagian ini'} harus lebih dari 0 ya';
    }

    return null;
  }

  // ============================================
  // DATE VALIDATION
  // ============================================

  /// Validate date of birth (min age 13)
  static String? dateOfBirth(DateTime? date) {
    if (date == null) {
      return 'Tanggal lahirnya diisi dulu ya';
    }

    final now = DateTime.now();
    final age = now.year - date.year;

    if (age < AppConstants.minimumAge) {
      return 'Umur minimal ${AppConstants.minimumAge} tahun ya';
    }

    // Check if haven't reached birthday this year
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      if (age - 1 < AppConstants.minimumAge) {
        return 'Umur minimal ${AppConstants.minimumAge} tahun ya';
      }
    }

    return null;
  }

  // ============================================
  // OTP VALIDATION
  // ============================================

  /// Validate OTP (exactly 6 digits)
  static String? otp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode OTP-nya diisi dulu ya';
    }

    if (value.length != AppConstants.otpLength) {
      return 'Kode OTP harus ${AppConstants.otpLength} digit ya';
    }

    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Kode OTP isinya angka semua ya';
    }

    return null;
  }

  // ============================================
  // FOOD VALIDATION
  // ============================================

  /// Validate food name
  static String? foodName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama makanannya diisi dulu ya';
    }

    if (value.length < 2) {
      return 'Nama makanan minimal 2 karakter ya';
    }

    return null;
  }

  /// Validate food quantity (min 1)
  static String? foodQuantity(String? value) {
    final error = positiveNumber(value, fieldName: 'Jumlah porsi');
    if (error != null) return error;

    final quantity = double.parse(value!);
    if (quantity < 1) {
      return 'Minimal 1 porsi ya';
    }

    return null;
  }

  // ============================================
  // GENERIC VALIDATIONS
  // ============================================

  /// Check if field is required
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bagian ini'} diisi dulu ya';
    }
    return null;
  }

  /// Validate min length
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bagian ini'} diisi dulu ya';
    }

    if (value.length < min) {
      return '${fieldName ?? 'Bagian ini'} minimal $min karakter ya';
    }

    return null;
  }

  /// Validate max length
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'Bagian ini'} maksimal $max karakter ya';
    }

    return null;
  }
}
