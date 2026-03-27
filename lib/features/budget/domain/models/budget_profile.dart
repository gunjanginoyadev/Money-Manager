import 'package:flutter/material.dart';

class BudgetProfile {
  const BudgetProfile({
    required this.monthlyIncome,
    required this.emi,
    required this.rent,
    required this.fixedBills,
    required this.basicExpenses,
    required this.safetyBuffer,
    this.avatarIndex = 0,
  });

  final double monthlyIncome;
  final double emi;
  final double rent;
  final double fixedBills;
  final double basicExpenses;
  final double safetyBuffer;

  /// Index into [kProfileAvatarOptions] for the profile picture.
  final int avatarIndex;

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
        'avatarIndex': avatarIndex,
      };

  factory BudgetProfile.fromJson(Map<String, dynamic> json) {
    return BudgetProfile(
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      emi: (json['emi'] as num?)?.toDouble() ?? 0,
      rent: (json['rent'] as num?)?.toDouble() ?? 0,
      fixedBills: (json['fixedBills'] as num?)?.toDouble() ?? 0,
      basicExpenses: (json['basicExpenses'] as num?)?.toDouble() ?? 0,
      safetyBuffer: (json['safetyBuffer'] as num?)?.toDouble() ?? 0,
      avatarIndex: (json['avatarIndex'] as num?)?.toInt() ?? 0,
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
