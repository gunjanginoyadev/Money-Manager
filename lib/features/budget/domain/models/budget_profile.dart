import 'package:flutter/material.dart';

class BudgetProfile {
  const BudgetProfile({
    required this.monthlyIncome,
    required this.emi,
    required this.rent,
    required this.fixedBills,
    required this.basicExpenses,
    required this.safetyBuffer,
    this.monthlySpendPool = 0,
    this.avatarIndex = 0,
    this.remainingOutingsCount = 0,
  });

  final double monthlyIncome;
  final double emi;
  final double rent;
  final double fixedBills;
  final double basicExpenses;
  final double safetyBuffer;

  /// Legacy stored field; not used for “Can I spend?” (that uses Home’s Wants / 30% logic).
  final double monthlySpendPool;

  /// Index into [kProfileAvatarOptions] for the profile picture.
  final int avatarIndex;

  /// Planned **wants** outings/events left this month (**N** in R÷N). Edited on the Spend tab.
  final int remainingOutingsCount;

  /// **20% of [monthlyIncome]** — used only for the optional 50-30-20 “Spend pool” baseline on Home.
  double get spendBudgetFromIncome =>
      monthlyIncome > 0 ? monthlyIncome * 0.2 : 0;

  double get totalObligations => emi + rent + fixedBills + basicExpenses;

  /// EMI + rent + bills only (matches reference “Fixed Deductions”, excludes essentials).
  double get fixedObligationsOnly => emi + rent + fixedBills;

  double get safeToSpend => monthlyIncome - totalObligations - safetyBuffer;

  Map<String, dynamic> toJson() => {
        'monthlyIncome': monthlyIncome,
        'emi': emi,
        'rent': rent,
        'fixedBills': fixedBills,
        'basicExpenses': basicExpenses,
        'safetyBuffer': safetyBuffer,
        'monthlySpendPool': monthlySpendPool,
        'avatarIndex': avatarIndex,
        'remainingOutingsCount': remainingOutingsCount,
      };

  factory BudgetProfile.fromJson(Map<String, dynamic> json) {
    return BudgetProfile(
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      emi: (json['emi'] as num?)?.toDouble() ?? 0,
      rent: (json['rent'] as num?)?.toDouble() ?? 0,
      fixedBills: (json['fixedBills'] as num?)?.toDouble() ?? 0,
      basicExpenses: (json['basicExpenses'] as num?)?.toDouble() ?? 0,
      safetyBuffer: (json['safetyBuffer'] as num?)?.toDouble() ?? 0,
      monthlySpendPool: (json['monthlySpendPool'] as num?)?.toDouble() ?? 0,
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
      remainingOutingsCount:
          (json['remainingOutingsCount'] as num?)?.toInt() ?? 0,
    );
  }

  BudgetProfile copyWith({
    double? monthlyIncome,
    double? emi,
    double? rent,
    double? fixedBills,
    double? basicExpenses,
    double? safetyBuffer,
    double? monthlySpendPool,
    int? avatarIndex,
    int? remainingOutingsCount,
  }) {
    return BudgetProfile(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      emi: emi ?? this.emi,
      rent: rent ?? this.rent,
      fixedBills: fixedBills ?? this.fixedBills,
      basicExpenses: basicExpenses ?? this.basicExpenses,
      safetyBuffer: safetyBuffer ?? this.safetyBuffer,
      monthlySpendPool: monthlySpendPool ?? this.monthlySpendPool,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      remainingOutingsCount:
          remainingOutingsCount ?? this.remainingOutingsCount,
    );
  }
}

/// Predefined avatar styles (icon + accent). No assets required.
class ProfileAvatarOption {
  const ProfileAvatarOption({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

const List<ProfileAvatarOption> kProfileAvatarOptions = [
  ProfileAvatarOption(icon: Icons.person_rounded, color: Color(0xFF6366F1)),
  ProfileAvatarOption(icon: Icons.face_rounded, color: Color(0xFF22C55E)),
  ProfileAvatarOption(icon: Icons.face_3_rounded, color: Color(0xFFF59E0B)),
  ProfileAvatarOption(icon: Icons.pets_rounded, color: Color(0xFFEC4899)),
  ProfileAvatarOption(icon: Icons.sports_esports_rounded, color: Color(0xFF8B5CF6)),
  ProfileAvatarOption(icon: Icons.restaurant_rounded, color: Color(0xFF0EA5E9)),
  ProfileAvatarOption(icon: Icons.flight_takeoff_rounded, color: Color(0xFF14B8A6)),
  ProfileAvatarOption(icon: Icons.music_note_rounded, color: Color(0xFFEF4444)),
];
