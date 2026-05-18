import 'package:clinical_application/core/utils/app_colors.dart';
import 'package:clinical_application/features/finance/presentation/cubits/debts_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/invoices_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/purchases_cubit.dart';
import 'package:clinical_application/features/finance/presentation/cubits/treasury_cubit.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/debts_tab_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/invoices_tab_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/purchases_tab_widget.dart';
import 'package:clinical_application/features/finance/presentation/views/widgets/treasury_tab_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _FinanceTabBar(),
          const Expanded(
            child: TabBarView(
              children: [
                _PurchasesTab(),
                _InvoicesTab(),
                _DebtsTab(),
                _TreasuryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(text: 'المشتريات'),
          Tab(text: 'الفواتير'),
          Tab(text: 'الديون'),
          Tab(text: 'الخزنة'),
        ],
      ),
    );
  }
}

class _PurchasesTab extends StatefulWidget {
  const _PurchasesTab();

  @override
  State<_PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends State<_PurchasesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => PurchasesCubit()..load(),
      child: const PurchasesTabWidget(),
    );
  }
}

class _InvoicesTab extends StatefulWidget {
  const _InvoicesTab();

  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => InvoicesCubit()..load(),
      child: const InvoicesTabWidget(),
    );
  }
}

class _DebtsTab extends StatefulWidget {
  const _DebtsTab();

  @override
  State<_DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<_DebtsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => DebtsCubit()..load(),
      child: const DebtsTabWidget(),
    );
  }
}

class _TreasuryTab extends StatefulWidget {
  const _TreasuryTab();

  @override
  State<_TreasuryTab> createState() => _TreasuryTabState();
}

class _TreasuryTabState extends State<_TreasuryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => TreasuryCubit()..load(),
      child: const TreasuryTabWidget(),
    );
  }
}
