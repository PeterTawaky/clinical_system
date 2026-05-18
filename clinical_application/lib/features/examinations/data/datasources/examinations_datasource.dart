import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/examinations/data/models/examination_model.dart';
import 'package:clinical_application/features/examinations/data/models/patient_model.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';
import 'package:clinical_application/features/settings/data/models/doctor_model.dart';

class ExaminationsDatasource {
  ExaminationsDatasource() : _dio = DioConsumer();

  final DioConsumer _dio;

  Future<List<Doctor>> getDoctors() async {
    final response = await _dio.get('/all_doctors');
    return (response as List<dynamic>)
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Branch>> getBranches() async {
    final response = await _dio.get('/branches');
    return (response as List<dynamic>)
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getSpecialties() async {
    final response = await _dio.get('/specialties');
    final data = response as Map<String, dynamic>;
    return (data['specialties'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
  }

  Future<List<PatientModel>> getPatients() async {
    final response = await _dio.get('/patients');
    return (response as List<dynamic>)
        .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> generateExamination({
    required int doctorId,
    required String patientName,
    required String phone,
    String? birthDate,
    required int serviceId,
    required int branchId,
    required String examDate,
    required String examNumber,
  }) async {
    final body = {
      'doctor_id': doctorId,
      'patient': {
        'patient_name': patientName,
        'phone': phone,
        if (birthDate != null && birthDate.isNotEmpty) 'birth_date': birthDate,
      },
      'service_id': serviceId,
      'branch_id': branchId,
      'exam_date': examDate,
      'exam_number': examNumber,
      'status': 'مؤقت',
    };
    final response = await _dio.post('/generate_examination', data: body);
    return response as Map<String, dynamic>;
  }

  Future<List<ExaminationModel>> getExaminations({
    String? status,
    String? date,
    String? doctorName,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date;
    if (doctorName != null && doctorName.isNotEmpty) {
      queryParams['doctor_name'] = doctorName;
    }
    final response = await _dio.get('/examinations', queryParameters: queryParams);
    return (response as List<dynamic>)
        .map((e) => ExaminationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmExam(int examId, String username) async {
    await _dio.put(
      '/exam_confirm/$examId',
      queryParameters: {'username': username},
    );
  }

  Future<void> cancelExam(int examId) async {
    await _dio.put('/exam_cancel/$examId');
  }
}
