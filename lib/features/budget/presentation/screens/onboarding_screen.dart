import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/budget_profile.dart';
import '../viewmodels/budget_view_model.dart';

/// Wide layouts show a fixed left rail; narrow is full-width scroll.
const double _kWideBreakpoint = 900;
const double _kSidebarWidth = 260;
const double _kContentMaxWidth = 520;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _emiController = TextEditingController(text: '0');
  final _rentController = TextEditingController(text: '0');
  final _billsController = TextEditingController(text: '0');
  final _basicExpenseController = TextEditingController(text: '0');
  final _bufferController = TextEditingController(text: '5000');

  @override
  void dispose() {
    _incomeController.dispose();
    _emiController.dispose();
    _rentController.dispose();
    _billsController.dispose();
    _basicExpenseController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BudgetViewModel>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kWideBreakpoint;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _kSidebarWidth,
                      child: ColoredBox(
                        color: AppColors.surface.withValues(alpha: 0.65),
                        child: _OnboardingSidebar(
                          padding: const EdgeInsets.fromLTRB(20, 28, 16, 24),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.border),
                    Expanded(
                      child: _ScrollableOnboardingForm(
                        showBrandInHeader: false,
                        vm: vm,
                        formKey: _formKey,
                        incomeController: _incomeController,
                        emiController: _emiController,
                        rentController: _rentController,
                        billsController: _billsController,
                        basicExpenseController: _basicExpenseController,
                        bufferController: _bufferController,
                        onSave: _save,
                      ),
                    ),
                  ],
                )
              : _ScrollableOnboardingForm(
                  showBrandInHeader: true,
                  vm: vm,
                  formKey: _formKey,
                  incomeController: _incomeController,
                  emiController: _emiController,
                  rentController: _rentController,
                  billsController: _billsController,
                  basicExpenseController: _basicExpenseController,
                  bufferController: _bufferController,
                  onSave: _save,
                ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<BudgetViewModel>();
    await vm.saveProfile(
      BudgetProfile(
        monthlyIncome: double.tryParse(_incomeController.text) ?? 0,
        emi: double.tryParse(_emiController.text) ?? 0,
        rent: double.tryParse(_rentController.text) ?? 0,
        fixedBills: double.tryParse(_billsController.text) ?? 0,
        basicExpenses: double.tryParse(_basicExpenseController.text) ?? 0,
        safetyBuffer: double.tryParse(_bufferController.text) ?? 0,
        avatarIndex: 0,
      ),
    );
  }
}

class _OnboardingSidebar extends StatelessWidget {
  const _OnboardingSidebar({required this.padding});

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          const SizedBox(height: 28),
          Text(
            'Get started',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryGlow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_calendar_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Monthly budget setup',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Amounts in Indian Rupees (INR)',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('💰', style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Kharcha',
          style: GoogleFonts.sora(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ScrollableOnboardingForm extends StatelessWidget {
  const _ScrollableOnboardingForm({
    required this.showBrandInHeader,
    required this.vm,
    required this.formKey,
    required this.incomeController,
    required this.emiController,
    required this.rentController,
    required this.billsController,
    required this.basicExpenseController,
    required this.bufferController,
    required this.onSave,
  });

  final bool showBrandInHeader;
  final BudgetViewModel vm;
  final GlobalKey<FormState> formKey;
  final TextEditingController incomeController;
  final TextEditingController emiController;
  final TextEditingController rentController;
  final TextEditingController billsController;
  final TextEditingController basicExpenseController;
  final TextEditingController bufferController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width >= _kWideBreakpoint
        ? 40.0
        : 24.0;

    Widget form = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBrandInHeader) ...[
            const _BrandMark(),
            const SizedBox(height: 22),
          ] else
            const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: GoogleFonts.sora(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -1,
                color: AppColors.textPrimary,
              ),
              children: const [
                TextSpan(text: 'Smart spending\n'),
                TextSpan(
                  text: 'decisions',
                  style: TextStyle(color: AppColors.primary),
                ),
                TextSpan(text: ' — fast.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Set up your monthly finances once. We\'ll tell you instantly if any expense is safe to make.',
            style: GoogleFonts.sora(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 28),
          const _SectionLabel('INCOME'),
          const SizedBox(height: 8),
          _Field(
            controller: incomeController,
            label: 'Monthly Salary',
            icon: Icons.currency_rupee_rounded,
            iconColor: AppColors.credit,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('FIXED MONTHLY COSTS'),
          const SizedBox(height: 8),
          _Field(
            controller: emiController,
            label: 'EMI / Loan',
            icon: Icons.account_balance_rounded,
            iconColor: AppColors.debit,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: rentController,
            label: 'Rent',
            icon: Icons.home_rounded,
            iconColor: AppColors.warn,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: billsController,
            label: 'Other Fixed Bills',
            icon: Icons.receipt_outlined,
            iconColor: AppColors.debit,
          ),
          const SizedBox(height: 18),
          const _SectionLabel('SPENDING LIMITS'),
          const SizedBox(height: 8),
          _Field(
            controller: basicExpenseController,
            label: 'Monthly Essentials (food/travel)',
            icon: Icons.shopping_cart_outlined,
            iconColor: AppColors.warn,
          ),
          const SizedBox(height: 10),
          _Field(
            controller: bufferController,
            label: 'Safety Buffer',
            icon: Icons.shield_outlined,
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 28),
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
                : FilledButton(
                    onPressed: onSave,
                    child: Text(
                      'Set Up My Budget →',
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    form = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
        child: form,
      ),
    );

    return SafeArea(
      child: Scrollbar(
        thumbVisibility: MediaQuery.sizeOf(context).width >= _kWideBreakpoint,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
          child: form,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        prefixIcon: Icon(icon, color: iconColor, size: 18),
      ),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed < 0) return 'Enter a valid amount';
        return null;
      },
    );
  }
}
