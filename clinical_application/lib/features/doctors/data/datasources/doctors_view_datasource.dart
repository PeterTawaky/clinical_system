import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';

class DoctorsViewDataSource {
  final DioConsumer _dio;

  DoctorsViewDataSource() : _dio = DioConsumer();

  Future<List<Doctor>> getDoctors() async {
    final response = await _dio.get('/all_doctors');
    return (response as List<dynamic>)
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getBranches() async {
    final response = await _dio.get('/branches');
    return (response as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['branch_name'] as String)
        .toList();
  }

  Future<List<String>> getSpecialties() async {
    final response = await _dio.get('/specialties');
    final data = response as Map<String, dynamic>;
    return (data['specialties'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }
}
