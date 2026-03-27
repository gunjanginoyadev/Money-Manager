import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../viewmodels/budget_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final items = vm.expenses.reversed.toList();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense History',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Track your spending patterns and remove incorrect entries.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: vm.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: LoadingState(lines: 8),
                          )
                        : items.isEmpty
                        ? const EmptyState(
                            title: 'No expense records',
                            subtitle:
                                'Your added expenses will appear here for review and cleanup.',
                            icon: Icons.history_toggle_off,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                title: Text(item.name),
                                subtitle: Text(
                                  item.createdAt
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(CurrencyFormatter.format(item.amount)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Delete expense',
                                      onPressed: vm.isLoading
                                          ? null
                                          : () async {
                                              final shouldDelete =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                    'Delete expense?',
                                                  ),
                                                  content: Text(
                                                    'Remove "${item.name}" from history?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (shouldDelete ?? false) {
                                                await vm.deleteExpense(item.id);
                                              }
                                            },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemCount: items.length,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
