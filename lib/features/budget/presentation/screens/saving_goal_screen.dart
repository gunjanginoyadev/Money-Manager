import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/saving_entry.dart';
import '../../domain/models/saving_goal.dart';
import '../viewmodels/budget_view_model.dart';

class SavingGoalScreen extends StatelessWidget {
  const SavingGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final goal = vm.savingGoal;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Goal'),
      ),
      body: goal == null
          ? const _CreateGoalEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _GoalCard(goal: goal),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: vm.isLoading
                            ? null
                            : () => _showAddSaving(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add saving'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Entries',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                if (vm.savingEntries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'No savings added yet. Add your first entry to start tracking progress.',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSoft,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < vm.savingEntries.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          _EntryRow(
                            entry: vm.savingEntries[i],
                            enabled: !vm.isLoading,
                            onEdit: () => _showEditSaving(
                              context,
                              vm.savingEntries[i],
                            ),
                            onDelete: () => _confirmDeleteSaving(
                              context,
                              vm.savingEntries[i],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  static Future<void> _showAddSaving(BuildContext context) async {
    final vm = context.read<BudgetViewModel>();
    final c = TextEditingController();
    final note = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddSavingSheet(amountController: c, noteController: note),
      ),
    );
    if (ok != true) return;
    final amt = double.tryParse(c.text.trim()) ?? 0;
    if (amt <= 0) return;
    await vm.addSavingEntry(amount: amt, note: note.text.trim());
  }

  static Future<void> _showEditSaving(
    BuildContext context,
    SavingEntry entry,
  ) async {
    final vm = context.read<BudgetViewModel>();
    final c = TextEditingController(text: entry.amount.toString());
    final note = TextEditingController(text: entry.note ?? '');
    var picked = entry.date;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _EditSavingSheet(
            amountController: c,
            noteController: note,
            selectedDate: picked,
            onPickDate: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                context: ctx,
                initialDate: picked,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
              );
              if (d != null) setState(() => picked = d);
            },
          ),
        ),
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final amt = double.tryParse(c.text.trim()) ?? 0;
    if (amt <= 0) return;
    await vm.updateSavingEntry(
      entryId: entry.id,
      amount: amt,
      note: note.text.trim(),
      date: picked,
    );
  }

  static Future<void> _confirmDeleteSaving(
    BuildContext context,
    SavingEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove entry?'),
        content: Text(
          'This removes the saving from your goal and deletes the linked '
          'transaction from your activity.',
          style: GoogleFonts.sora(fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<BudgetViewModel>().deleteSavingEntry(entry.id);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final pct = (g.progressPct * 100).round();
    final remaining = g.remaining;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  g.title,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              _TypeBadge(type: g.type),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${CurrencyFormatter.formatRupee(g.savedAmount)} / ${CurrencyFormatter.formatRupee(g.targetAmount)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: g.progressPct,
              minHeight: 8,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(
                g.isCompleted ? AppColors.safe : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            g.isCompleted
                ? 'Completed 🎉'
                : 'Remaining: ${CurrencyFormatter.formatRupee(remaining)} · $pct% complete',
            style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSoft),
          ),
          if (g.targetDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Target date: ${DateFormat('d MMM yyyy').format(g.targetDate!.toLocal())}',
              style:
                  GoogleFonts.sora(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final GoalType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      GoalType.short => ('Short', AppColors.warn),
      GoalType.mid => ('Mid', AppColors.primary),
      GoalType.long => ('Long', AppColors.savings),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingEntry entry;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amount = entry.amount;
    final note = entry.note;
    final d = entry.date.toLocal();
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 2, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.savings_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.formatRupee(amount),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.safe,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note?.isNotEmpty == true
                      ? note!
                      : DateFormat('d MMM').format(d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('d MMM').format(d),
            style: GoogleFonts.sora(fontSize: 11, color: AppColors.textMuted),
          ),
          PopupMenuButton<String>(
            enabled: enabled,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: AppColors.textMuted,
            ),
            padding: EdgeInsets.zero,
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined, size: 20),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline, size: 20),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateGoalEmpty extends StatelessWidget {
  const _CreateGoalEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create a saving goal',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One active goal keeps it lightweight. Add savings entries to track progress and keep your budget honest.',
              style: GoogleFonts.sora(
                fontSize: 12,
                height: 1.35,
                color: AppColors.textSoft,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showCreateGoal(context),
              icon: const Icon(Icons.flag_rounded, size: 18),
              label: const Text('Create goal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGoal(BuildContext context) async {
    final title = TextEditingController();
    final target = TextEditingController();
    var type = GoalType.mid;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setState) => _CreateGoalSheet(
            titleController: title,
            targetController: target,
            type: type,
            onTypeChanged: (v) => setState(() => type = v),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final t = title.text.trim();
    final amt = double.tryParse(target.text.trim()) ?? 0;
    if (t.isEmpty || amt <= 0) return;
    if (!context.mounted) return;
    await context.read<BudgetViewModel>().createSavingGoal(
          title: t,
          targetAmount: amt,
          type: type,
        );
  }
}

class _CreateGoalSheet extends StatelessWidget {
  const _CreateGoalSheet({
    required this.titleController,
    required this.targetController,
    required this.type,
    required this.onTypeChanged,
  });

  final TextEditingController titleController;
  final TextEditingController targetController;
  final GoalType type;
  final ValueChanged<GoalType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'New goal',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Buy bike',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Short'),
                  selected: type == GoalType.short,
                  onSelected: (_) => onTypeChanged(GoalType.short),
                ),
                ChoiceChip(
                  label: const Text('Mid'),
                  selected: type == GoalType.mid,
                  onSelected: (_) => onTypeChanged(GoalType.mid),
                ),
                ChoiceChip(
                  label: const Text('Long'),
                  selected: type == GoalType.long,
                  onSelected: (_) => onTypeChanged(GoalType.long),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSavingSheet extends StatelessWidget {
  const _AddSavingSheet({
    required this.amountController,
    required this.noteController,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Add saving',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSavingSheet extends StatelessWidget {
  const _EditSavingSheet({
    required this.amountController,
    required this.noteController,
    required this.selectedDate,
    required this.onPickDate,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;
  final DateTime selectedDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final d = selectedDate.toLocal();
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Edit entry',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined,
                          size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('d MMM yyyy').format(d),
                          style: GoogleFonts.sora(
                            fontSize: 14,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save changes'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

