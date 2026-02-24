import 'package:flutter/material.dart';
import '../models/models.dart';

class RiskBadge extends StatelessWidget {
  final RiskScore riskScore;

  const RiskBadge({super.key, required this.riskScore});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String label;

    switch (riskScore) {
      case RiskScore.low:
        backgroundColor = Colors.green;
        label = 'Low';
        break;
      case RiskScore.medium:
        backgroundColor = Colors.orange;
        label = 'Medium';
        break;
      case RiskScore.high:
        backgroundColor = Colors.red;
        label = 'High';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
