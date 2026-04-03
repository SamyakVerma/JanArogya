class PatientInfo {
  final String name;
  final String age;
  final String gender;  // 'Male' | 'Female' | 'Other'
  final String phone;
  final bool   isSelf;

  const PatientInfo({
    required this.name,
    required this.age,
    required this.gender,
    this.phone  = '',
    this.isSelf = false,
  });

  String get phoneMasked {
    if (phone.isEmpty) return 'XXXXXXXXXX';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return 'XXXXXXXXXX';
    return '${'X' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }
}
