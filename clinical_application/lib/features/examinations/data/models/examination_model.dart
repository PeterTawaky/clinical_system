class ExaminationModel {
  final int examId;
  final String examNumber;
  final String examDate;
  final String status;
  final int serviceId;
  final String serviceName;
  final double price;
  final String doctorName;
  final String specialty;
  final String patientName;
  final String phone;
  final int branchId;
  final String branchName;

  const ExaminationModel({
    required this.examId,
    required this.examNumber,
    required this.examDate,
    required this.status,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.doctorName,
    required this.specialty,
    required this.patientName,
    required this.phone,
    required this.branchId,
    required this.branchName,
  });

  factory ExaminationModel.fromJson(Map<String, dynamic> json) {
    return ExaminationModel(
      examId: json['exam_id'] as int,
      examNumber: json['exam_number']?.toString() ?? '',
      examDate: json['exam_date']?.toString() ?? '',
      status: json['status'] as String,
      serviceId: json['service_id'] as int,
      serviceName: json['service_name'] as String,
      price: (json['price'] as num).toDouble(),
      doctorName: json['doctor_name'] as String,
      specialty: json['specialty'] as String,
      patientName: json['patient_name'] as String,
      phone: json['phone'] as String,
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
    );
  }
}
