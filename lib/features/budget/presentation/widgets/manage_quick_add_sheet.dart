import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/quick_add_preset.dart';
import '../../domain/models/spending_kind.dart';
import '../viewmodels/budget_view_model.dart';

Future<void> showManageQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ManageQuickAddSheet(),
  );
}

class _ManageQuickAddSheet extends StatelessWidget {
  const _ManageQuickAddSheet();

  static const int _max = 12;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final vm = context.watch<BudgetViewModel>();
    final list = vm.quickAddPresets;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Quick add shortcuts',
                  style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'One tap logs an expense with these amounts and categories. '
                  'Stored on this device only.',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSoft,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No shortcuts yet. Add one below.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
                        itemBuilder: (ctx, i) {
                          final p = list[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            title: Text(
                              p.title,
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            subtitle: Text(
                              '${p.spendingKind.label} · ${p.subCategory}',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${p.amount == p.amount.roundToDouble() ? p.amount.round() : p.amount}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.textMuted,
                                    size: 22,
                                  ),
                                  onPressed: vm.isLoading
                                      ? null
                                      : () async {
                                          final next = [...vm.quickAddPresets]
                                            ..removeAt(i);
                                          await vm.setQuickAddPresets(next);
                                        },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: vm.isLoading || list.length >= _max
                          ? null
                          : () => _showAddDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        list.length >= _max
                            ? 'Maximum $_max shortcuts'
                            : 'Add shortcut',
                      ),
                    ),
                    TextButton(
                      onPressed: vm.isLoading
                          ? null
                          : () async {
                              await vm.setQuickAddPresets(
                                List<QuickAddPreset>.from(
                                  kDefaultQuickAddPresets,
                                ),
                              );
                            },
                      child: Text(
                        'Reset to defaults',
                        style: GoogleFonts.sora(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final preset = await showDialog<QuickAddPreset>(
      context: context,
      builder: (ctx) => const _AddQuickPresetDialog(),
    );
    if (preset == null || !context.mounted) return;
    final vm = context.read<BudgetViewModel>();
    if (vm.quickAddPresets.length >= _max) return;
    await vm.setQuickAddPresets([...vm.quickAddPresets, preset]);
  }
}

class _AddQuickPresetDialog extends StatefulWidget {
  const _AddQuickPresetDialog();

  @override
  State<_AddQuickPresetDialog> createState() => _AddQuickPresetDialogState();
}

class _AddQuickPresetDialogState extends State<_AddQuickPresetDialog> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  SpendingKind _kind = SpendingKind.want;
  late String _sub;

  @override
  void initState() {
    super.initState();
    _sub = spendingSubcategoriesByKind[_kind]!.first;
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  List<String> get _subs =>
      spendingSubcategoriesByKind[_kind] ?? const ['Other'];

  static final _fieldStyle = GoogleFonts.sora(color: AppColors.text);
  static final _dropdownItemStyle =
      GoogleFonts.sora(color: AppColors.text, fontSize: 15);

  @override
  Widget build(BuildContext context) {
    final menuTheme = Theme.of(context).copyWith(
      canvasColor: AppColors.surface2,
      colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: AppColors.surface2,
            onSurface: AppColors.text,
            primary: AppColors.primary,
          ),
    );

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'New shortcut',
        style: GoogleFonts.sora(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
      content: Theme(
        data: menuTheme,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _amount,
                style: _fieldStyle,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  labelStyle: GoogleFonts.sora(color: AppColors.textSoft),
                  prefixStyle: _fieldStyle,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _title,
                style: _fieldStyle,
                decoration: InputDecoration(
                  labelText: 'Label',
                  hintText: 'Chai',
                  labelStyle: GoogleFonts.sora(color: AppColors.textSoft),
                  hintStyle: GoogleFonts.sora(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Category',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: SpendingKind.values.map((k) {
                  final sel = _kind == k;
                  return ChoiceChip(
                    label: Text(
                      k.label,
                      style: GoogleFonts.sora(
                        color: sel ? AppColors.onAccent : AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface2,
                    side: BorderSide(
                      color: sel ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _kind = k;
                        final list = spendingSubcategoriesByKind[k]!;
                        _sub = list.contains(_sub) ? _sub : list.first;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Subcategory',
                  labelStyle: GoogleFonts.sora(color: AppColors.textSoft),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: AppColors.surface2,
                    iconEnabledColor: AppColors.textMuted,
                    style: _dropdownItemStyle,
                    value: _subs.contains(_sub) ? _sub : _subs.first,
                    items: _subs
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(
                              s,
                              style: _dropdownItemStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _sub = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.textSoft),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onAccent,
          ),
          onPressed: () {
            final amt = double.tryParse(_amount.text.trim());
            final t = _title.text.trim();
            if (amt == null || amt <= 0 || t.isEmpty) return;
            Navigator.of(context).pop(
              QuickAddPreset(
                amount: amt,
                title: t,
                spendingKind: _kind,
                subCategory: _sub,
              ),
            );
          },
          child: Text('Add', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
