import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';

class DoctorsRemoteDataSource {
  final DioConsumer _dio;

  DoctorsRemoteDataSource() : _dio = DioConsumer();

  Future<List<Doctor>> getDoctors() async {
    final response = await _dio.get('/all_doctors');
    final list = response as List<dynamic>;
    return list
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getSpecialties() async {
    final response = await _dio.get('/specialties');
    final data = response as Map<String, dynamic>;
    return (data['specialties'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }

  Future<void> createDoctor({
    required String doctorName,
    required String specialty,
    required String phoneNumber,
    required double balance,
    required List<int> branchIds,
    required List<Map<String, dynamic>> schedules,
    required List<Map<String, dynamic>> services,
  }) async {
    await _dio.post(
      '/generate_doctor',
      data: {
        'doctor_name': doctorName,
        'specialty': specialty,
        'doctor_phone_number': phoneNumber,
        'doctor_balance': balance,
        'branches': branchIds,
        'schedules': schedules,
        'services': services,
      },
    );
  }

  Future<void> updateDoctor({
    required int doctorId,
    String? doctorName,
    String? specialty,
    String? phoneNumber,
    double? balance,
    List<int>? branchIds,
    List<Map<String, dynamic>>? schedules,
    List<Map<String, dynamic>>? services,
  }) async {
    final data = <String, dynamic>{};
    if (doctorName != null) data['doctor_name'] = doctorName;
    if (specialty != null) data['specialty'] = specialty;
    if (phoneNumber != null) data['doctor_phone_number'] = phoneNumber;
    if (balance != null) data['doctor_balance'] = balance;
    if (branchIds != null) data['branches'] = branchIds;
    if (schedules != null) data['schedules'] = schedules;
    if (services != null) data['services'] = services;

    await _dio.put('/doctor_edit/$doctorId', data: data);
  }

  Future<void> deleteDoctor(int doctorId) async {
    await _dio.delete('/doctor_delete/$doctorId');
  }
}
