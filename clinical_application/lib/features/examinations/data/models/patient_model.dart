class PatientModel {
  final int patientId;
  final String patientName;
  final String phone;
  final String? branch;
  final String? birthDate;

  const PatientModel({
    required this.patientId,
    required this.patientName,
    required this.phone,
    this.branch,
    this.birthDate,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patient_id'] as int,
      patientName: json['patient_name'] as String,
      phone: json['phone'] as String,
      branch: json['branch'] as String?,
      birthDate: json['birth_date']?.toString(),
    );
  }
}
