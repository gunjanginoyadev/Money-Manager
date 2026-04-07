import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/payment_method.dart';
import '../../domain/models/spending_kind.dart';
import '../../domain/models/transaction_entry.dart';
import '../viewmodels/budget_view_model.dart';

/// Full-screen add income / expense (replaces the old modal bottom sheet).
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.transactionToEdit});

  /// When set, the screen pre-fills fields and updates this row on save.
  final TransactionEntry? transactionToEdit;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.debit;

  DateTime _transactionDate = DateTime.now();

  SpendingKind _spendingKind = SpendingKind.need;
  String _subCategory = spendingSubcategoriesByKind[SpendingKind.need]!.first;
  String _incomeCategory = incomeCategories.first;

  // ignore: prefer_final_fields — updated in setState via Online/Cash toggles
  PaymentMethod _paymentMethod = PaymentMethod.online;

  @override
  void initState() {
    super.initState();
    final e = widget.transactionToEdit;
    if (e == null) return;

    _type = e.type;

    final raw = e.transactionDate ?? e.createdAt;
    final local = raw.toLocal();
    _transactionDate = DateTime(local.year, local.month, local.day);

    _titleController.text = e.title;
    _amountController.text = _formatAmountForField(e.amount);
    _noteController.text = e.note ?? '';

    _paymentMethod = e.paymentMethod ?? PaymentMethod.online;

    if (e.isCredit) {
      final rawCat = e.incomeCategory ?? e.category;
      _incomeCategory = (rawCat != null && incomeCategories.contains(rawCat))
          ? rawCat
          : incomeCategories.first;
    } else {
      _spendingKind = e.spendingKind ?? SpendingKind.other;
      final list =
          spendingSubcategoriesByKind[_spendingKind] ?? const ['Other'];
      final sub = e.subCategory;
      _subCategory =
          (sub != null && list.contains(sub)) ? sub : list.first;
    }
  }

  String _formatAmountForField(double amount) {
    if (amount <= 0) return '';
    if (amount == amount.roundToDouble()) {
      return amount.round().toString();
    }
    return amount.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _subsForKind =>
      spendingSubcategoriesByKind[_spendingKind] ?? const ['Other'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final isDebit = _type == TransactionType.debit;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.transactionToEdit == null
              ? 'Add transaction'
              : 'Edit transaction',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDebit
                    ? 'Classify expenses as Need, Want, Saving, or Other — then pick a subcategory.'
                    : 'Record income for this month (salary, freelance, etc.).',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeBtn(
                        label: 'Expense',
                        icon: Icons.arrow_upward_rounded,
                        active: isDebit,
                        activeColor: AppColors.debit,
                        onTap: () =>
                            setState(() => _type = TransactionType.debit),
                      ),
                    ),
                    Expanded(
                      child: _TypeBtn(
                        label: 'Income',
                        icon: Icons.arrow_downward_rounded,
                        active: !isDebit,
                        activeColor: AppColors.credit,
                        onTap: () =>
                            setState(() => _type = TransactionType.credit),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.event_rounded,
                  color: isDebit ? AppColors.debit : AppColors.credit,
                ),
                title: const Text('Date'),
                subtitle: Text(
                  '${_transactionDate.day}/${_transactionDate.month}/${_transactionDate.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _transactionDate,
                    firstDate: DateTime(DateTime.now().year - 5),
                    lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                  );
                  if (picked != null) {
                    setState(() => _transactionDate = picked);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    color: isDebit ? AppColors.debit : AppColors.credit,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: '0',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 14),
              const Text(
                'Payment',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeBtn(
                        label: 'Online',
                        icon: Icons.account_balance_rounded,
                        active: _paymentMethod == PaymentMethod.online,
                        activeColor: AppColors.primary,
                        onTap: () => setState(
                          () => _paymentMethod = PaymentMethod.online,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _TypeBtn(
                        label: 'Cash',
                        icon: Icons.payments_outlined,
                        active: _paymentMethod == PaymentMethod.cash,
                        activeColor: AppColors.primary,
                        onTap: () =>
                            setState(() => _paymentMethod = PaymentMethod.cash),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (isDebit) ...[
                const Text(
                  'Category',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SpendingKind.values.map((k) {
                    final selected = _spendingKind == k;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _spendingKind = k;
                          final list = spendingSubcategoriesByKind[k]!;
                          _subCategory = list.contains(_subCategory)
                              ? _subCategory
                              : list.first;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryGlow
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          k.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      value: _subsForKind.contains(_subCategory)
                          ? _subCategory
                          : _subsForKind.first,
                      items: _subsForKind
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _subCategory = v);
                      },
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Income type',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: incomeCategories.map((c) {
                    final selected = _incomeCategory == c;
                    return GestureDetector(
                      onTap: () => setState(() => _incomeCategory = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryGlow
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: vm.isLoading
                      ? Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : FilledButton(
                          onPressed: _submit,
                          child: Text(
                            widget.transactionToEdit == null
                                ? 'Save transaction'
                                : 'Save changes',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) return;

    final vm = context.read<BudgetViewModel>();
    final edit = widget.transactionToEdit;
    if (edit != null) {
      if (_type == TransactionType.debit) {
        await vm.updateTransaction(
          id: edit.id,
          title: title,
          amount: amount,
          type: TransactionType.debit,
          spendingKind: _spendingKind,
          subCategory: _subCategory,
          category: '${_spendingKind.label} · $_subCategory',
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          transactionDate: _transactionDate,
          paymentMethod: _paymentMethod,
        );
      } else {
        await vm.updateTransaction(
          id: edit.id,
          title: title,
          amount: amount,
          type: TransactionType.credit,
          incomeCategory: _incomeCategory,
          category: _incomeCategory,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          transactionDate: _transactionDate,
          paymentMethod: _paymentMethod,
        );
      }
    } else if (_type == TransactionType.debit) {
      await vm.addTransaction(
        title: title,
        amount: amount,
        type: TransactionType.debit,
        spendingKind: _spendingKind,
        subCategory: _subCategory,
        category: '${_spendingKind.label} · $_subCategory',
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        transactionDate: _transactionDate,
        paymentMethod: _paymentMethod,
      );
    } else {
      await vm.addTransaction(
        title: title,
        amount: amount,
        type: TransactionType.credit,
        incomeCategory: _incomeCategory,
        category: _incomeCategory,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        transactionDate: _transactionDate,
        paymentMethod: _paymentMethod,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _TypeBtn extends StatelessWidget {
  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
