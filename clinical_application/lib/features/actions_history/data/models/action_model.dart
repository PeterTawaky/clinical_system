class ActionModel {
  final int actionId;
  final String username;
  final String description;
  final String? actionDate;

  const ActionModel({
    required this.actionId,
    required this.username,
    required this.description,
    this.actionDate,
  });

  factory ActionModel.fromJson(Map<String, dynamic> json) {
    return ActionModel(
      actionId: json['action_id'] as int,
      username: json['username'] as String,
      description: json['action_description'] as String,
      actionDate: json['action_date']?.toString(),
    );
  }
}
