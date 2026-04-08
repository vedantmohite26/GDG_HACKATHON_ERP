class Certificate {
  final String certificateId;
  final String studentUid;
  final String studentName;
  final String studentId;
  final String course;
  final String semester;
  final double cgpa;
  final double sgpa;
  final DateTime issuedDate;
  final String certificateHash;
  final Map<String, dynamic>? metadata;

  Certificate({
    required this.certificateId,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
    required this.course,
    required this.semester,
    required this.cgpa,
    required this.sgpa,
    required this.issuedDate,
    required this.certificateHash,
    this.metadata,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      certificateId: json['certificate_id'] as String,
      studentUid: json['student_uid'] as String? ?? '',
      studentName: json['student_name'] as String,
      studentId: json['student_id'] as String,
      course: json['course'] as String,
      semester: json['semester'] as String,
      cgpa: (json['cgpa'] as num).toDouble(),
      sgpa: (json['sgpa'] as num).toDouble(),
      issuedDate: DateTime.parse(json['issued_date'] as String),
      certificateHash: json['certificate_hash'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'certificate_id': certificateId,
      'student_uid': studentUid,
      'student_name': studentName,
      'student_id': studentId,
      'course': course,
      'semester': semester,
      'cgpa': cgpa,
      'sgpa': sgpa,
      'issued_date': issuedDate.toIso8601String(),
      'certificate_hash': certificateHash,
      if (metadata != null) 'metadata': metadata,
    };
  }

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${issuedDate.day} ${months[issuedDate.month - 1]} ${issuedDate.year}';
  }
}

class CertificateVerificationResult {
  final bool valid;
  final Certificate? certificate;
  final String? error;
  final Map<String, dynamic>? verification;

  CertificateVerificationResult({
    required this.valid,
    this.certificate,
    this.error,
    this.verification,
  });

  factory CertificateVerificationResult.fromJson(Map<String, dynamic> json) {
    return CertificateVerificationResult(
      valid: json['valid'] as bool,
      certificate: json['certificate'] != null
          ? Certificate.fromJson(json['certificate'])
          : null,
      error: json['error'] as String?,
      verification: json['verification'] as Map<String, dynamic>?,
    );
  }

  bool get isHashValid => verification?['hash_valid'] == true;
  bool get isSignatureValid => verification?['signature_valid'] == true;
}
