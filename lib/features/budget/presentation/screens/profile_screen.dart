import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/budget_profile.dart';
import '../viewmodels/budget_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _incomeController;
  late final TextEditingController _emiController;
  late final TextEditingController _paydayController;

  String? _editingField;
  late int _avatarIndex;
  late double _splitNeeds;
  late double _splitWants;
  late double _splitSavings;
  static const double _minNeeds = 0.05; // keep at least 5% for Needs

  @override
  void initState() {
    super.initState();
    final profile = context.read<BudgetViewModel>().profile!;
    _splitNeeds = profile.splitNeeds;
    _splitWants = profile.splitWants;
    _splitSavings = profile.splitSavings;
    _avatarIndex = profile.avatarIndex
        .clamp(0, kProfileAvatarOptions.length - 1);
    _incomeController =
        TextEditingController(text: profile.monthlyIncome.toStringAsFixed(0));
    _emiController = TextEditingController(text: profile.emi.toStringAsFixed(0));
    _paydayController = TextEditingController(
      text: '${profile.salaryDayOfMonth.clamp(1, 31)}',
    );
    _incomeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _emiController.dispose();
    _paydayController.dispose();
    super.dispose();
  }

  double _previewSpendCap(BudgetProfile saved) {
    final parsed = double.tryParse(_incomeController.text.trim());
    final income = parsed ?? saved.monthlyIncome;
    return income > 0 ? income * _splitWants : 0;
  }

  void _applySplitPreset(double n, double w, double s) {
    setState(() {
      _splitNeeds = n;
      _splitWants = w;
      _splitSavings = s;
    });
  }

  void _setCustomSplit({double? wants, double? savings}) {
    // Two-slider UX:
    // - user moves Wants% and Savings%
    // - Needs% is computed as remainder, clamped to [_minNeeds]
    // - if wants+savings exceeds (1 - minNeeds), we clamp the edited value
    final maxOther = 1.0 - _minNeeds;
    var w = wants ?? _splitWants;
    var s = savings ?? _splitSavings;
    w = w.clamp(0.0, maxOther);
    s = s.clamp(0.0, maxOther);

    if (w + s > maxOther) {
      // Clamp the *changed* knob first (so it feels responsive).
      if (wants != null) {
        w = (maxOther - s).clamp(0.0, maxOther);
      } else if (savings != null) {
        s = (maxOther - w).clamp(0.0, maxOther);
      } else {
        // Shouldn't happen, but keep it safe.
        final scale = maxOther / (w + s);
        w *= scale;
        s *= scale;
      }
    }

    // Fix tiny FP drift: keep sum exactly 1 by adjusting Needs.
    final nn = (1.0 - w - s).clamp(_minNeeds, 1.0);

    setState(() {
      _splitWants = w;
      _splitSavings = s;
      _splitNeeds = nn;
    });
  }

  String _splitPresetLabel(double n, double w, double s) {
    final a = (n * 100).round();
    final b = (w * 100).round();
    final c = (s * 100).round();
    return '$a / $b / $c';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();

    final email = vm.userEmail;
    final opt = kProfileAvatarOptions[_avatarIndex
        .clamp(0, kProfileAvatarOptions.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  HomeShellInsets.bottomNavHeight(context) + 4,
                ),
                children: [
              // Avatar & account
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: vm.isLoading
                                    ? null
                                    : () => _pickAvatar(context),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: opt.color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: opt.color.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Icon(
                                    opt.icon,
                                    color: opt.color,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              elevation: 3,
                              shadowColor: Colors.black54,
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(99),
                              child: InkWell(
                                onTap: vm.isLoading
                                    ? null
                                    : () => _pickAvatar(context),
                                borderRadius: BorderRadius.circular(99),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email ?? 'Not signed in with email',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the picture or edit to change it',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: vm.isLoading ? null : () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.debit,
                    side: BorderSide(color: AppColors.debit.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: vm.isLoading ? null : () => _confirmDeleteAccount(context),
                  icon: Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red.shade700),
                  label: Text(
                    'Delete account',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'SPEND LIMIT & REFERENCE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '“Can I spend?” follows Home’s Wants row (your % of the same baseline). Salary and EMI below are for your reference.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'BUDGET SPLIT (NEEDS · WANTS · SAVINGS)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Targets on Home use these shares of income. Pick a preset or keep your saved mix.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(_splitPresetLabel(0.5, 0.3, 0.2)),
                    selected: _splitNeeds == 0.5 &&
                        _splitWants == 0.3 &&
                        _splitSavings == 0.2,
                    onSelected: (_) =>
                        _applySplitPreset(0.5, 0.3, 0.2),
                  ),
                  ChoiceChip(
                    label: Text('${_splitPresetLabel(0.5, 0.25, 0.25)} · tighter wants'),
                    selected: _splitNeeds == 0.5 &&
                        _splitWants == 0.25 &&
                        _splitSavings == 0.25,
                    onSelected: (_) =>
                        _applySplitPreset(0.5, 0.25, 0.25),
                  ),
                  ChoiceChip(
                    label: Text(_splitPresetLabel(0.45, 0.35, 0.2)),
                    selected: _splitNeeds == 0.45 &&
                        _splitWants == 0.35 &&
                        _splitSavings == 0.2,
                    onSelected: (_) =>
                        _applySplitPreset(0.45, 0.35, 0.2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 14),
                child: Text(
                  'Active: ${_splitPresetLabel(_splitNeeds, _splitWants, _splitSavings)}',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fine-tune (total always 100%)',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SplitSlider(
                      label: 'Wants',
                      value: _splitWants,
                      color: AppColors.warn,
                      onChanged: (v) => _setCustomSplit(wants: v),
                    ),
                    const SizedBox(height: 6),
                    _SplitSlider(
                      label: 'Savings',
                      value: _splitSavings,
                      color: AppColors.primary,
                      onChanged: (v) => _setCustomSplit(savings: v),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Needs is computed: ${(100 * _splitNeeds).round()}%',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _ProfileComputedRow(
                        icon: Icons.savings_outlined,
                        iconColor: AppColors.primaryLight,
                        label:
                            'Wants budget from salary (${(_splitWants * 100).round()}%)',
                        amount: _previewSpendCap(vm.profile!),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.attach_money_rounded,
                        iconColor: AppColors.credit,
                        label: 'Monthly salary',
                        controller: _incomeController,
                        isEditing: _editingField == 'income',
                        onTap: () => setState(() => _editingField = 'income'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.account_balance_rounded,
                        iconColor: AppColors.debit,
                        label: 'EMI / loans / debts',
                        controller: _emiController,
                        isEditing: _editingField == 'emi',
                        onTap: () => setState(() => _editingField = 'emi'),
                        isLast: false,
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileRow(
                        icon: Icons.event_rounded,
                        iconColor: AppColors.primaryLight,
                        label: 'Salary day (1–31)',
                        controller: _paydayController,
                        isEditing: _editingField == 'payday',
                        onTap: () => setState(() => _editingField = 'payday'),
                        isLast: true,
                        isSalaryDay: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Budget periods start on this day each month (default 1st). Change anytime.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
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
                    : FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save Changes'),
                      ),
              ),
            ],
          ),
        ),
    ],
  ),
),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<BudgetViewModel>();
    final prev = vm.profile!;
    setState(() => _editingField = null);
    final pay =
        int.tryParse(_paydayController.text.trim())?.clamp(1, 31) ?? 1;
    await vm.saveProfile(
      BudgetProfile(
        monthlyIncome: double.tryParse(_incomeController.text) ?? 0,
        emi: double.tryParse(_emiController.text) ?? 0,
        rent: prev.rent,
        fixedBills: prev.fixedBills,
        basicExpenses: prev.basicExpenses,
        safetyBuffer: prev.safetyBuffer,
        monthlySpendPool: prev.monthlySpendPool,
        avatarIndex: _avatarIndex,
        remainingOutingsCount: prev.remainingOutingsCount,
        salaryDayOfMonth: pay,
        splitNeeds: _splitNeeds,
        splitWants: _splitWants,
        splitSavings: _splitSavings,
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final vm = context.read<BudgetViewModel>();
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose profile picture'),
        content: SizedBox(
          width: 320,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: kProfileAvatarOptions.length,
            itemBuilder: (context, i) {
              final o = kProfileAvatarOptions[i];
              final sel = i == _avatarIndex;
              return InkWell(
                onTap: () => Navigator.pop(ctx, i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: o.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? o.color : Colors.transparent,
                      width: sel ? 2 : 0,
                    ),
                  ),
                  child: Icon(o.icon, color: o.color, size: 28),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _avatarIndex = picked);
    final prev = vm.profile!;
    final pay =
        int.tryParse(_paydayController.text.trim())?.clamp(1, 31) ?? 1;
    await vm.saveProfile(
      BudgetProfile(
        monthlyIncome: double.tryParse(_incomeController.text) ?? 0,
        emi: double.tryParse(_emiController.text) ?? 0,
        rent: prev.rent,
        fixedBills: prev.fixedBills,
        basicExpenses: prev.basicExpenses,
        safetyBuffer: prev.safetyBuffer,
        monthlySpendPool: prev.monthlySpendPool,
        avatarIndex: picked,
        remainingOutingsCount: prev.remainingOutingsCount,
        salaryDayOfMonth: pay,
        splitNeeds: _splitNeeds,
        splitWants: _splitWants,
        splitSavings: _splitSavings,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final vm = context.read<BudgetViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will return to the sign-in screen. Local data stays on this device unless you use cloud sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    await vm.signOut();
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final vm = context.read<BudgetViewModel>();
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteAccountDialog(),
    );
    if (!mounted || password == null) return;
    await vm.deleteAccount(password: password);
  }
}

class _SplitSlider extends StatelessWidget {
  const _SplitSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.surface2,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.12),
            trackHeight: 4.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 0.8,
            divisions: 80,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Firebase requires re-authenticating with the account password before [User.delete].
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String? _inlineError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final p = _controller.text.trim();
    if (p.isEmpty) {
      setState(() => _inlineError = 'Enter your account password.');
      return;
    }
    Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This permanently removes your cloud data (profile, expenses, transactions) '
              'and deletes your sign-in account. All data on this device will be cleared. '
              'This cannot be undone.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              onChanged: (_) => setState(() => _inlineError = null),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Account password',
                errorText: _inlineError,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Required by Firebase so only you can delete this account.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Delete permanently'),
        ),
      ],
    );
  }
}

class _ProfileComputedRow extends StatelessWidget {
  const _ProfileComputedRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.onTap,
    this.isLast = false,
    this.isSalaryDay = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onTap;
  final bool isLast;
  final bool isSalaryDay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          12,
          14,
          isLast ? 12 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isEditing)
              SizedBox(
                width: isSalaryDay ? 56 : 100,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: isSalaryDay
                      ? TextInputType.number
                      : const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    prefixText: isSalaryDay ? null : 'Rs ',
                    prefixStyle: isSalaryDay
                        ? null
                        : const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                  ),
                  validator: (v) {
                    if (isSalaryDay) {
                      final i = int.tryParse(v?.trim() ?? '');
                      if (i == null || i < 1 || i > 31) return '';
                      return null;
                    }
                    final parsed = double.tryParse(v?.trim() ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              )
            else
              Text(
                isSalaryDay ? controller.text : 'Rs ${controller.text}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
