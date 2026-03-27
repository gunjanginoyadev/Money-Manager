import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/budget_profile.dart';
import '../viewmodels/budget_view_model.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Row(
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
                    ),
                    const SizedBox(height: 22),
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
                      controller: _incomeController,
                      label: 'Monthly Salary',
                      icon: Icons.attach_money_rounded,
                      iconColor: AppColors.credit,
                    ),

                    const SizedBox(height: 18),
                    const _SectionLabel('FIXED MONTHLY COSTS'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _emiController,
                      label: 'EMI / Loan',
                      icon: Icons.account_balance_rounded,
                      iconColor: AppColors.debit,
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      controller: _rentController,
                      label: 'Rent',
                      icon: Icons.home_rounded,
                      iconColor: AppColors.warn,
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      controller: _billsController,
                      label: 'Other Fixed Bills',
                      icon: Icons.receipt_outlined,
                      iconColor: AppColors.debit,
                    ),

                    const SizedBox(height: 18),
                    const _SectionLabel('SPENDING LIMITS'),
                    const SizedBox(height: 8),
                    _Field(
                      controller: _basicExpenseController,
                      label: 'Monthly Essentials (food/travel)',
                      icon: Icons.shopping_cart_outlined,
                      iconColor: AppColors.warn,
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      controller: _bufferController,
                      label: 'Safety Buffer',
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.primary,
                    ),

                    const SizedBox(height: 22),
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
                              onPressed: _save,
                              child: Text(
                                'Set Up My Budget →',
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
