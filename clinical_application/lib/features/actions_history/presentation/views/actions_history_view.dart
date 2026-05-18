import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/actions_history/data/models/action_model.dart';
import 'package:clinical_application/features/actions_history/presentation/cubits/actions_cubit.dart';
import 'package:clinical_application/features/actions_history/presentation/cubits/actions_state.dart';
import 'package:clinical_application/features/actions_history/presentation/views/widgets/action_card_widget.dart';
import 'package:clinical_application/features/actions_history/presentation/views/widgets/actions_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActionsHistoryView extends StatelessWidget {
  const ActionsHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ActionsCubit(),
      child: const _ActionsHistoryBody(),
    );
  }
}

class _ActionsHistoryBody extends StatelessWidget {
  const _ActionsHistoryBody();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<ActionsCubit, ActionsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<ActionsCubit>().loadAll(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ActionsPageHeader(),
                        const SizedBox(height: 16),
                        ActionsFilterWidget(
                          showingMineOnly: state is ActionsLoaded
                              ? state.showingMineOnly
                              : false,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                switch (state) {
                  ActionsLoading() => const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                  ActionsLoaded s when s.actions.isEmpty =>
                    const SliverFillRemaining(child: _EmptyState()),
                  ActionsLoaded s => _ActionsList(actions: s.actions),
                  ActionsError s => SliverFillRemaining(
                      child: _ErrorState(message: s.message),
                    ),
                  _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionsList extends StatelessWidget {
  const _ActionsList({required this.actions});

  final List<ActionModel> actions;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: actions.length,
        itemBuilder: (context, index) =>
            ActionCardWidget(action: actions[index]),
      ),
    );
  }
}

class _ActionsPageHeader extends StatelessWidget {
  const _ActionsPageHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.onPrimary, size: 32),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سجل الإجراءات',
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'كل الإجراءات التي تمّت على النظام',
                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off_rounded,
            size: 56, color: AppColors.neutral300),
        SizedBox(height: 12),
        Text('لا توجد إجراءات مسجّلة بعد',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded,
            size: 56, color: AppColors.neutral300),
        const SizedBox(height: 12),
        Text(message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => context.read<ActionsCubit>().loadAll(),
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          label: const Text('إعادة المحاولة',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
