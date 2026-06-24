/// Input Validators
///
/// Collection of validation functions for user inputs
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$');

    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (!RegExp(r"^[a-zA-Z\s'-]*$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validate employee ID
  static String? validateEmployeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }

    if (value.length < 3) {
      return 'Employee ID must be at least 3 characters long';
    }

    return null;
  }

  /// Validate text field (generic)
  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? Function(String?) validateMinLength(int length) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'This field is required';
      }
      if (value.length < length) {
        return 'Must be at least $length characters long';
      }
      return null;
    };
  }

  /// Validate maximum length
  static String? Function(String?) validateMaxLength(int length) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      if (value.length > length) {
        return 'Cannot exceed $length characters';
      }
      return null;
    };
  }

  /// Validate numeric input
  static String? validateNumeric(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    if (!RegExp(r'^[0-9]*\.?[0-9]*$').hasMatch(value)) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  /// Validate date
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Validate invite code
  static String? validateInviteCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Invite code is required';
    }

    if (value.length < 6) {
      return 'Invite code must be at least 6 characters long';
    }

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'Invite code can only contain uppercase letters and numbers';
    }

    return null;
  }

  /// Password confirmation validator
  static String? Function(String?) validatePasswordMatch(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }

      if (value != password) {
        return 'Passwords do not match';
      }

      return null;
    };
  }
}
