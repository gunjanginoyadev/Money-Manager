import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/expense_decision.dart';
import '../viewmodels/budget_view_model.dart';
import 'status_chip.dart';

class ExpenseDecisionSheet extends StatefulWidget {
  const ExpenseDecisionSheet({super.key});

  @override
  State<ExpenseDecisionSheet> createState() => _ExpenseDecisionSheetState();
}

class _ExpenseDecisionSheetState extends State<ExpenseDecisionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  ExpenseDecision? _preview;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Expense', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Expense Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs ',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                onChanged: (value) {
                  final amount = double.tryParse(value.trim());
                  if (amount == null) {
                    setState(() => _preview = null);
                    return;
                  }
                  setState(() => _preview = vm.previewExpense(amount));
                },
              ),
              const SizedBox(height: 14),
              if (_preview != null) ...[
                Row(
                  children: [
                    StatusChip(status: _preview!.status),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_preview!.message)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Remaining balance: ${CurrencyFormatter.format(_preview!.remainingBalance)}',
                ),
                const SizedBox(height: 4),
                Text(
                  'End of month projection: ${CurrencyFormatter.format(_preview!.endOfMonthProjection)}',
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: vm.isLoading ? null : _submit,
                  child: vm.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<BudgetViewModel>();
    await vm.addExpense(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
