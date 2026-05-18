class Branch {
  final int branchId;
  final String branchName;
  final int doctorCount;

  const Branch({
    required this.branchId,
    required this.branchName,
    required this.doctorCount,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      doctorCount: json['doctor_count'] as int? ?? 0,
    );
  }
}
