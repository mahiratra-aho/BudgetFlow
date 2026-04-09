import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Affichage d'un montant avec couleur automatique (revenu/dépense)
class AmountDisplay extends StatelessWidget {
  final double amount;
  final bool isExpense;
  final TextStyle? style;
  final bool showSign;

  const AmountDisplay({
    super.key,
    required this.amount,
    required this.isExpense,
    this.style,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = showSign ? (isExpense ? '−' : '+') : '';
    final formatted = _formatAmount(amount);

    return Text(
      '$sign$formatted Ar',
      style: (style ?? theme.textTheme.titleMedium)?.copyWith(color: color),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final formatted = value.toStringAsFixed(0);
      final buffer = StringBuffer();
      int count = 0;
      for (int i = formatted.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write(' ');
        buffer.write(formatted[i]);
        count++;
      }
      return buffer.toString().split('').reversed.join();
    }
    return value.toStringAsFixed(0);
  }
}

/// Badge de montant
class AmountBadge extends StatelessWidget {
  final double amount;
  final bool isExpense;

  const AmountBadge({super.key, required this.amount, required this.isExpense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '−' : '+';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$sign${_formatAmount(amount)} Ar',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) {
      final s = value.toStringAsFixed(0);
      final buf = StringBuffer();
      int c = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        if (c > 0 && c % 3 == 0) buf.write(' ');
        buf.write(s[i]);
        c++;
      }
      return buf.toString().split('').reversed.join();
    }
    return value.toStringAsFixed(0);
  }
}

/// Progression visuelle (barre animée)
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 à 1.0
  final Color? color;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: AppColors.surface,
        color: progress >= 1.0 ? AppColors.income : barColor,
        minHeight: height,
      ),
    );
  }
}
