// Input validation functions

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // College email pattern (customize as needed)
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Student UID validation
  static String? validateStudentUID(String? value) {
    if (value == null || value.isEmpty) {
      return 'Student UID is required';
    }

    if (value.length < 6) {
      return 'Student UID must be at least 6 characters';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  // Income validation
  static String? validateIncome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Family income is required';
    }

    final income = double.tryParse(value);
    if (income == null || income < 0) {
      return 'Please enter a valid income amount';
    }

    return null;
  }

  // Year validation
  static String? validateYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Year is required';
    }

    final year = int.tryParse(value);
    if (year == null || year < 1 || year > 6) {
      return 'Please enter a valid year (1-6)';
    }

    return null;
  }

  // Dropdown validation
  static String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }

    return null;
  }

  // Description validation
  static String? validateDescription(String? value, {int minLength = 10}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }

    if (value.length < minLength) {
      return 'Description must be at least $minLength characters';
    }

    return null;
  }
}
