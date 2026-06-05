class AppValidators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? required(String? v, {String field = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    final d = double.tryParse(v);
    if (d == null || d <= 0) return 'Enter a valid price';
    return null;
  }

  static String? margin(String? v) {
    if (v == null || v.trim().isEmpty) return 'Margin is required';
    final d = double.tryParse(v);
    if (d == null || d < 0 || d > 100) return 'Enter a valid margin (0–100)';
    return null;
  }
}
