class DoctorSchedule {
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int? branchId;
  final String? branchName;
  final bool isActive;

  const DoctorSchedule({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.branchId,
    this.branchName,
    this.isActive = true,
  });

  factory DoctorSchedule.fromJson(Map<String, dynamic> json) {
    return DoctorSchedule(
      dayOfWeek: json['day_of_week'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'branch_id': branchId,
        'is_active': isActive,
      };
}

class DoctorService {
  final int? serviceId;
  final String serviceName;
  final double price;

  const DoctorService({
    this.serviceId,
    required this.serviceName,
    required this.price,
  });

  factory DoctorService.fromJson(Map<String, dynamic> json) {
    return DoctorService(
      serviceId: json['service_id'] as int?,
      serviceName: json['service_name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'service_name': serviceName,
        'price': price,
      };
}

class Doctor {
  final int doctorId;
  final String doctorName;
  final String specialty;
  final String doctorPhoneNumber;
  final double doctorBalance;
  final List<String> branches;
  final List<DoctorSchedule> schedules;
  final List<DoctorService> services;

  const Doctor({
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.doctorPhoneNumber,
    required this.doctorBalance,
    required this.branches,
    required this.schedules,
    required this.services,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctor_id'] as int,
      doctorName: json['doctor_name'] as String,
      specialty: json['specialty'] as String,
      doctorPhoneNumber: json['doctor_phone_number'] as String,
      doctorBalance: (json['doctor_balance'] as num?)?.toDouble() ?? 0.0,
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((e) => DoctorSchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => DoctorService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
