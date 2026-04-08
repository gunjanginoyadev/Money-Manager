import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/home_shell_insets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/budget_profile.dart';
import '../../domain/models/fifty_thirty_baseline_mode.dart';
import '../viewmodels/budget_view_model.dart';

final _inrFmt = NumberFormat.decimalPattern('en_IN');

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
  late int _wPct;
  late int _sPct;

  late double _splitNeeds;
  late double _splitWants;
  late double _splitSavings;

  @override
  void initState() {
    super.initState();
    final profile = context.read<BudgetViewModel>().profile!;
    _wPct = (profile.splitWants * 100).round().clamp(0, 99);
    _sPct = (profile.splitSavings * 100).round().clamp(0, 99);
    _clampPair();
    _splitWants = _wPct / 100.0;
    _splitSavings = _sPct / 100.0;
    _splitNeeds = (100 - _wPct - _sPct) / 100.0;

    _avatarIndex = profile.avatarIndex.clamp(
      0,
      kProfileAvatarOptions.length - 1,
    );
    _incomeController = TextEditingController(
      text: profile.monthlyIncome.toStringAsFixed(0),
    );
    _emiController = TextEditingController(
      text: profile.emi.toStringAsFixed(0),
    );
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

  /// Monthly salary from Reference — same baseline Home uses in profile-salary mode.
  double get _salaryBaseline {
    final parsed = double.tryParse(_incomeController.text.trim());
    return parsed != null && parsed > 0 ? parsed : 0;
  }

  void _clampPair() {
    _wPct = _wPct.clamp(0, 99);
    _sPct = _sPct.clamp(0, 99 - _wPct);
  }

  void _syncSplitsFromInts() {
    _clampPair();
    _splitWants = _wPct / 100.0;
    _splitSavings = _sPct / 100.0;
    _splitNeeds = (100 - _wPct - _sPct) / 100.0;
  }

  void _applySplitPreset(int w, int s) {
    setState(() {
      _wPct = w.clamp(0, 99);
      _sPct = s.clamp(0, 99 - _wPct);
      _clampPair();
      _syncSplitsFromInts();
    });
  }

  void _stepWants(int delta) {
    setState(() {
      _wPct = (_wPct + delta).clamp(0, 99);
      _clampPair();
      _syncSplitsFromInts();
    });
  }

  void _stepSavings(int delta) {
    setState(() {
      _sPct = (_sPct + delta).clamp(0, 99 - _wPct);
      _clampPair();
      _syncSplitsFromInts();
    });
  }

  String _splitPresetLabel(int n, int w, int s) => '$n / $w / $s';

  bool _presetActive(int n, int w, int s) {
    final nn = 100 - _wPct - _sPct;
    return nn == n && _wPct == w && _sPct == s;
  }

  String _userDisplayName() {
    final u = FirebaseAuth.instance.currentUser;
    final dn = u?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final e = u?.email;
    if (e != null && e.contains('@')) return e.split('@').first;
    return 'You';
  }

  String _formatRupee(double amount) {
    if (amount <= 0) return '₹0';
    return '₹${_inrFmt.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();

    final email = vm.userEmail ?? 'Not signed in';
    final opt =
        kProfileAvatarOptions[_avatarIndex.clamp(
          0,
          kProfileAvatarOptions.length - 1,
        )];
    final sal = _salaryBaseline;
    final needsPct = 100 - _wPct - _sPct;
    final needsAmt = sal > 0 ? (sal * needsPct / 100).round().toDouble() : 0.0;
    final wantsAmtPreview =
        sal > 0 ? (sal * _wPct / 100).round().toDouble() : 0.0;

    final bottomNav = HomeShellInsets.bottomNavHeight(context);
    const saveBarHeight = 108.0;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            bottomNav + saveBarHeight + 8 + keyboardBottom,
          ),
          children: [
            Text(
              'Profile',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 20),

            // Account card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -40,
                    top: -40,
                    child: IgnorePointer(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.07),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: vm.isLoading
                                    ? null
                                    : () => _pickAvatar(context),
                                borderRadius: BorderRadius.circular(99),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1F4A3A),
                                        Color(0xFF2D6E55),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    opt.icon,
                                    color: opt.color,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Material(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                                child: InkWell(
                                  onTap: vm.isLoading
                                      ? null
                                      : () => _pickAvatar(context),
                                  borderRadius: BorderRadius.circular(99),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 10,
                                      color: AppColors.onAccent,
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
                            Text(
                              _userDisplayName(),
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        child: InkWell(
                          onTap: vm.isLoading
                              ? null
                              : () => _pickAvatar(context),
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              'Edit',
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Danger row
            Row(
              children: [
                Expanded(
                  child: _DangerButton(
                    label: 'Log out',
                    isDelete: false,
                    onPressed: vm.isLoading
                        ? null
                        : () => _confirmLogout(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DangerButton(
                    label: 'Delete account',
                    isDelete: true,
                    onPressed: vm.isLoading
                        ? null
                        : () => _confirmDeleteAccount(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Budget split · Needs · Wants · Savings',
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(
                  label: _splitPresetLabel(50, 30, 20),
                  selected: _presetActive(50, 30, 20),
                  onTap: () => _applySplitPreset(30, 20),
                ),
                _PresetChip(
                  label: _splitPresetLabel(50, 25, 25),
                  selected: _presetActive(50, 25, 25),
                  onTap: () => _applySplitPreset(25, 25),
                ),
                _PresetChip(
                  label: _splitPresetLabel(45, 35, 20),
                  selected: _presetActive(45, 35, 20),
                  onTap: () => _applySplitPreset(35, 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Fine-tune
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fine-tune',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Always totals 100%',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FineTuneGroup(
                    label: 'Wants',
                    labelColor: AppColors.textMuted,
                    accent: AppColors.warn,
                    pct: _wPct,
                    maxSlider: 99,
                    onStepDown: () => _stepWants(-1),
                    onStepUp: () => _stepWants(1),
                    onSlider: (v) {
                      setState(() {
                        _wPct = v.round();
                        _clampPair();
                        _syncSplitsFromInts();
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  _FineTuneGroup(
                    label: 'Savings',
                    labelColor: AppColors.textMuted,
                    accent: AppColors.primary,
                    pct: _sPct,
                    maxSlider: (99 - _wPct).toDouble(),
                    onStepDown: () => _stepSavings(-1),
                    onStepUp: () => _stepSavings(1),
                    onSlider: (v) {
                      setState(() {
                        _sPct = v.round().clamp(0, 99 - _wPct);
                        _clampPair();
                        _syncSplitsFromInts();
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Needs (computed)',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatRupee(needsAmt),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$needsPct%',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.savings,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _ThisPeriodHomeTargets(
              localSalary: sal,
              splitNeeds: _splitNeeds,
              splitWants: _splitWants,
              splitSavings: _splitSavings,
              wantsPct: _wPct,
              savingsPct: _sPct,
            ),
            const SizedBox(height: 20),

            Text(
              'Reference & limits',
              style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 10),

            Form(
              key: _formKey,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      emoji: '💸',
                      iconBg: AppColors.primary.withValues(alpha: 0.12),
                      label: 'Wants budget ($_wPct%)',
                      value: _formatRupee(wantsAmtPreview),
                      valueColor: AppColors.primary,
                      isMono: true,
                    ),
                    const Divider(height: 1),
                    _ProfileRow(
                      emoji: '💰',
                      iconBg: const Color(0x1F60A5FA),
                      label: 'Monthly salary',
                      controller: _incomeController,
                      isEditing: _editingField == 'income',
                      onTap: () => setState(() => _editingField = 'income'),
                    ),
                    const Divider(height: 1),
                    _ProfileRow(
                      emoji: '🏦',
                      iconBg: AppColors.danger.withValues(alpha: 0.12),
                      label: 'EMI / Loans / Debts',
                      controller: _emiController,
                      isEditing: _editingField == 'emi',
                      onTap: () => setState(() => _editingField = 'emi'),
                    ),
                    const Divider(height: 1),
                    _ProfileRow(
                      emoji: '📅',
                      iconBg: AppColors.savings.withValues(alpha: 0.12),
                      label: 'Salary day',
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
            const SizedBox(height: 24),
            ClipRect(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.bg, AppColors.bg.withValues(alpha: 0)],
                    stops: const [0.45, 1],
                  ),
                ),
                child: vm.isLoading
                    ? Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Save Changes'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
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
    final pay = int.tryParse(_paydayController.text.trim())?.clamp(1, 31) ?? 1;
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
    final pay = int.tryParse(_paydayController.text.trim())?.clamp(1, 31) ?? 1;
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

/// Preview of Home’s budget targets using draft **Monthly salary** as salary baseline.
class _ThisPeriodHomeTargets extends StatelessWidget {
  const _ThisPeriodHomeTargets({
    required this.localSalary,
    required this.splitNeeds,
    required this.splitWants,
    required this.splitSavings,
    required this.wantsPct,
    required this.savingsPct,
  });

  /// Draft monthly salary (Reference) — Home’s profile-salary baseline when saved.
  final double localSalary;
  final double splitNeeds;
  final double splitWants;
  final double splitSavings;
  final int wantsPct;
  final int savingsPct;

  static String _modeCaption(FiftyThirtyBaselineMode m) {
    switch (m) {
      case FiftyThirtyBaselineMode.profileSalary:
        return 'Uses the same salary baseline as Home (Monthly salary).';
      case FiftyThirtyBaselineMode.monthIncomeEntries:
        return 'Home baseline is income logged this period; targets use your split % with that amount.';
      case FiftyThirtyBaselineMode.spendPool:
        return 'Home baseline is 20% of Monthly salary; targets use your splits of that pool.';
    }
  }

  static String _emptyMessage(FiftyThirtyBaselineMode m) {
    switch (m) {
      case FiftyThirtyBaselineMode.monthIncomeEntries:
        return 'No income logged in this budget period yet. Add an income entry from Home, or open the tune menu on Home’s budget card to switch baseline.';
      case FiftyThirtyBaselineMode.spendPool:
        return 'Set monthly salary in Reference below so the 20% pool can be calculated, or change baseline on Home.';
      case FiftyThirtyBaselineMode.profileSalary:
        return 'Set Monthly salary in Reference (or Fine-tune ₹), then Save.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    final profile = vm.profile;
    if (profile == null) return const SizedBox.shrink();

    final snap = vm.fiftyThirtyTwentyForMonth(vm.currentBudgetPeriodStart);
    final mode = vm.fiftyThirtyBaselineMode;

    final needsPctInt = 100 - wantsPct - savingsPct;

    late final double baselineDisplay;
    late final String baselineSub;
    late final double targetNeeds;
    late final double targetWants;
    late final double targetSavings;
    var empty = false;

    switch (mode) {
      case FiftyThirtyBaselineMode.profileSalary:
        baselineDisplay = localSalary;
        baselineSub = 'What Home uses when baseline = profile salary';
        if (localSalary <= 0) {
          empty = true;
        } else {
          targetNeeds = localSalary * splitNeeds;
          targetWants = localSalary * splitWants;
          targetSavings = localSalary * splitSavings;
        }
      case FiftyThirtyBaselineMode.spendPool:
        final pool = localSalary > 0 ? localSalary * 0.2 : 0.0;
        baselineDisplay = pool;
        baselineSub = '20% of Monthly salary (Home alternate baseline)';
        if (pool <= 0) {
          empty = true;
        } else {
          targetNeeds = pool * splitNeeds;
          targetWants = pool * splitWants;
          targetSavings = pool * splitSavings;
        }
      case FiftyThirtyBaselineMode.monthIncomeEntries:
        baselineDisplay = snap.incomeBaseline;
        baselineSub = 'From credits this budget period (Home’s current baseline)';
        if (snap.incomeBaseline <= 0) {
          empty = true;
        } else {
          final b = snap.incomeBaseline;
          targetNeeds = b * splitNeeds;
          targetWants = b * splitWants;
          targetSavings = b * splitSavings;
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'This period · matches Home',
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _modeCaption(mode),
          style: GoogleFonts.sora(
            fontSize: 11,
            height: 1.35,
            color: AppColors.textSoft,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: empty
              ? Text(
                  _emptyMessage(mode),
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSoft,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeSplitAmountRow(
                      label: 'Salary baseline',
                      sub: baselineSub,
                      amount: CurrencyFormatter.formatRupee(baselineDisplay),
                      amountStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    _HomeSplitAmountRow(
                      label: 'Needs',
                      sub: '$needsPctInt% of baseline',
                      amount: CurrencyFormatter.formatRupee(targetNeeds),
                      amountStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HomeSplitAmountRow(
                      label: 'Wants',
                      sub: '$wantsPct% of baseline',
                      amount: CurrencyFormatter.formatRupee(targetWants),
                      amountStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warn,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HomeSplitAmountRow(
                      label: 'Savings',
                      sub: '$savingsPct% of baseline',
                      amount: CurrencyFormatter.formatRupee(targetSavings),
                      amountStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.savings,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HomeSplitAmountRow extends StatelessWidget {
  const _HomeSplitAmountRow({
    required this.label,
    required this.sub,
    required this.amount,
    required this.amountStyle,
  });

  final String label;
  final String sub;
  final String amount;
  final TextStyle amountStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.sora(
                  fontSize: 11,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(amount, style: amountStyle),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.isDelete,
    required this.onPressed,
  });

  final String label;
  final bool isDelete;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final red = AppColors.danger;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDelete ? red.withValues(alpha: 0.15) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDelete)
                Icon(Icons.delete_outline_rounded, size: 14, color: red)
              else
                const Icon(
                  Icons.logout_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDelete ? red : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _FineTuneGroup extends StatelessWidget {
  const _FineTuneGroup({
    required this.label,
    required this.labelColor,
    required this.accent,
    required this.pct,
    required this.maxSlider,
    required this.onStepDown,
    required this.onStepUp,
    required this.onSlider,
  });

  final String label;
  final Color labelColor;
  final Color accent;
  final int pct;
  final double maxSlider;
  final VoidCallback onStepDown;
  final VoidCallback onStepUp;
  final ValueChanged<double> onSlider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: _ValPill(
              child: Row(
                children: [
                  _StepBtn(
                    onTap: onStepDown,
                    child: Text(
                      '−',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.textMuted,
                        height: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$pct',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          Text(
                            '%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _StepBtn(
                    onTap: onStepUp,
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.textMuted,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final disabled = maxSlider <= 0;
            final trackMax = disabled ? 1.0 : maxSlider;
            final sliderValue = disabled
                ? 0.0
                : math.min(trackMax, math.max(0.0, pct.toDouble()));
            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                inactiveTrackColor: AppColors.surface2,
                thumbColor: accent,
                overlayColor: accent.withValues(alpha: 0.12),
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: trackMax,
                onChanged: disabled ? null : onSlider,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ValPill extends StatelessWidget {
  const _ValPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(width: 24, height: 24, child: Center(child: child)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.emoji,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
    this.isMono = false,
  });

  final String emoji;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          if (isMono)
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
        ],
      ),
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
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Required by Firebase so only you can delete this account.',
              style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted),
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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.emoji,
    required this.iconBg,
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.onTap,
    this.isLast = false,
    this.isSalaryDay = false,
  });

  final String emoji;
  final Color iconBg;
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final VoidCallback onTap;
  final bool isLast;
  final bool isSalaryDay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (isEditing)
                SizedBox(
                  width: isSalaryDay ? 56 : 120,
                  child: TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: isSalaryDay
                        ? TextInputType.number
                        : const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.jetBrainsMono(
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
                      prefixText: isSalaryDay ? null : '₹ ',
                      prefixStyle: GoogleFonts.jetBrainsMono(
                        color: AppColors.textMuted,
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
                  isSalaryDay
                      ? controller.text
                      : '₹ ${_inrFmt.format(double.tryParse(controller.text) ?? 0)}',
                  style: GoogleFonts.jetBrainsMono(
                    color: isSalaryDay
                        ? AppColors.textMuted
                        : AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
