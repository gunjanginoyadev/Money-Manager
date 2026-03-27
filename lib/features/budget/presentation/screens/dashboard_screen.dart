import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/expense_decision.dart';
import '../viewmodels/budget_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_decision_sheet.dart';
import '../widgets/loading_state.dart';
import '../widgets/status_chip.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;

    if (profile == null) return const SizedBox.shrink();

    final safeToSpend = vm.safeToSpendAfterTrackedSpending;
    final decision = vm.lastDecision;
    final isSafeZone = vm.currentAvailable > profile.safetyBuffer;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final content = [
            Text(
              'Smart Budget Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              isSafeZone ? 'You are in safe zone' : 'Be careful with spending',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSafeZone ? Colors.green : Colors.orange.shade700,
                  ),
            ),
            const SizedBox(height: 18),
            SummaryCard(
              title: 'Current Available Money',
              value: CurrencyFormatter.format(vm.currentAvailable),
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'Total Obligations',
              value: CurrencyFormatter.format(profile.totalObligations),
              icon: Icons.payments_rounded,
              color: const Color(0xFF0EA5E9),
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: 'Safe To Spend',
              value: CurrencyFormatter.format(safeToSpend),
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      vm.cloudSyncEnabled ? Icons.cloud_done : Icons.cloud_off,
                      color: vm.cloudSyncEnabled ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vm.cloudSyncEnabled
                            ? 'Firebase connected. Data is saved automatically.'
                            : 'Firebase not connected. Check your .env and auth setup.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Projection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Expected end-of-month balance: ${CurrencyFormatter.format(vm.currentAvailable)}',
                    ),
                    Text(
                      vm.currentAvailable <= profile.safetyBuffer
                          ? 'Next month may get affected. Reduce optional spending.'
                          : 'Current trend looks healthy for next month.',
                    ),
                  ],
                ),
              ),
            ),
            if (decision != null) ...[
              const SizedBox(height: 18),
              _DecisionResultCard(decision: decision),
            ],
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Expenses',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (vm.expenses.isEmpty)
                      const EmptyState(
                        title: 'No expenses yet',
                        subtitle:
                            'Add your first expense to get instant decision feedback.',
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      ...vm.expenses.reversed.take(5).map(
                            (item) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.name),
                              subtitle: Text(
                                item.createdAt.toLocal().toString().split('.').first,
                              ),
                              trailing:
                                  Text(CurrencyFormatter.format(item.amount)),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 90),
          ];

          final splitIndex = math.min(content.length, 12);

          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.isLoading) ...[
                        const LoadingState(lines: 1),
                        const SizedBox(height: 6),
                      ],
                      wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: content.sublist(0, splitIndex),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: content.sublist(splitIndex),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: content,
                            ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const ExpenseDecisionSheet(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          );
        },
      ),
    );
  }
}

class _DecisionResultCard extends StatelessWidget {
  const _DecisionResultCard({required this.decision});

  final ExpenseDecision decision;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(status: decision.status),
                const SizedBox(width: 10),
                Expanded(child: Text(decision.message)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining after expense: ${CurrencyFormatter.format(decision.remainingBalance)}',
            ),
          ],
        ),
      ),
    );
  }
}
