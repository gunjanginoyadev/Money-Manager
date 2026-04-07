import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Full-screen message when the device has no network connection.
class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 44,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'You\'re offline',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kharcha needs an internet connection to load and sync your budget. '
                'Connect to Wi‑Fi or mobile data, then try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    'Try again',
                    style: GoogleFonts.sora(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
