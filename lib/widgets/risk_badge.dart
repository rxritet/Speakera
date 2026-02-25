import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/models.dart';

/// Colored pill badge showing risk level (Low / Medium / High).
///
/// Uses semantic risk colors from [AppColors].
class RiskBadge extends StatelessWidget {
  final RiskScore riskScore;
  final bool dense;

  const RiskBadge({super.key, required this.riskScore, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (riskScore) {
      RiskLevel.low => (
        AppColors.riskLow.withValues(alpha: 0.15),
        AppColors.riskLow,
        'Low',
      ),
      RiskLevel.medium => (
        AppColors.riskMedium.withValues(alpha: 0.15),
        AppColors.riskMedium,
        'Medium',
      ),
      RiskLevel.high => (
        AppColors.riskHigh.withValues(alpha: 0.15),
        AppColors.riskHigh,
        'High',
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
