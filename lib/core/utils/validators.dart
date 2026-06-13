class Validators {
  static String? required(String? v, String label) => v == null || v.trim().isEmpty ? '$label is required' : null;
  static String? email(String? v) {
    final r = required(v, 'Email');
    if (r != null) return r;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim()) ? null : 'Enter a valid email';
  }
  static String? password(String? v) {
    final r = required(v, 'Password');
    if (r != null) return r;
    return v!.length < 6 ? 'Password must be at least 6 characters' : null;
  }
  static String? mobile(String? v) {
    final r = required(v, 'Mobile number');
    if (r != null) return r;
    final digits = v!.replaceAll(RegExp(r'\D'), '');
    return digits.length < 10 ? 'Enter a valid mobile number' : null;
  }
  static String maskMobile(String? mobile) {
    if (mobile == null || mobile.isEmpty) return '';
    final d = mobile.replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return '****';
    return '${d.substring(0, 2)}******${d.substring(d.length - 2)}';
  }
}
