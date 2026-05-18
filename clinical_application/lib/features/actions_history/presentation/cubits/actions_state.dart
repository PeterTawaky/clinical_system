import 'package:clinical_application/features/actions_history/data/models/action_model.dart';

sealed class ActionsState {}

class ActionsInitial extends ActionsState {}

class ActionsLoading extends ActionsState {}

class ActionsLoaded extends ActionsState {
  final List<ActionModel> actions;
  final bool showingMineOnly;
  ActionsLoaded(this.actions, {this.showingMineOnly = false});
}

class ActionsError extends ActionsState {
  final String message;
  ActionsError(this.message);
}
