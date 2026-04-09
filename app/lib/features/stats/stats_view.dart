import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/category.dart';
import 'stats_viewmodel.dart';

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  List<Widget> _buildCategoryRows(
    Map<String, double> expenseByCategory,
    Map<String, CategorieModele> catMap,
  ) {
    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = expenseByCategory.values.fold(0.0, (s, v) => s + v);
    return entries.map((e) {
      final cat = catMap[e.key];
      final pct = total > 0 ? e.value / total * 100 : 0;
      return _CategoryStatRow(
        category: cat,
        amount: e.value,
        percentage: pct.toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (data) {
          final catMap = {for (final c in data.categories) c.id: c};
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(statsViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MonthNavigator(
                  month: data.month,
                  year: data.year,
                  onChanged: (m, y) => ref
                      .read(statsViewModelProvider.notifier)
                      .changeMonth(m, y),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Revenus',
                        amount: data.totalIncome,
                        color: AppColors.income,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'Dépenses',
                        amount: data.totalExpense,
                        color: AppColors.expense,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Camembert dépenses
                if (data.expenseByCategory.isNotEmpty) ...[
                  Text(
                    'Répartition des dépenses',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: _PieChartWidget(
                      dataMap: data.expenseByCategory,
                      catMap: catMap,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Tendances
                if (data.trends.isNotEmpty) ...[
                  Text(
                    'Tendances (6 mois)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: _TrendChart(trends: data.trends),
                  ),
                  const SizedBox(height: 20),
                ],

                // Légende catégories
                if (data.expenseByCategory.isNotEmpty) ...[
                  Text(
                    'Détail par catégorie',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._buildCategoryRows(
                    data.expenseByCategory,
                    catMap,
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(amount)} Ar',
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      int c = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        if (c > 0 && c % 3 == 0) buf.write(' ');
        buf.write(s[i]);
        c++;
      }
      return buf.toString().split('').reversed.join();
    }
    return v.toStringAsFixed(0);
  }
}

class _PieChartWidget extends StatefulWidget {
  final Map<String, double> dataMap;
  final Map<String, CategorieModele> catMap;

  const _PieChartWidget({required this.dataMap, required this.catMap});

  @override
  State<_PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<_PieChartWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.dataMap.values.fold(0.0, (s, v) => s + v);
    final entries = widget.dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().map((i, e) {
      final cat = widget.catMap[e.key];
      final color = cat != null ? Color(cat.colorValue) : _defaultColor(i);
      final pct = total > 0 ? e.value / total * 100 : 0;
      final isTouched = i == _touchedIndex;

      return MapEntry(
        i,
        PieChartSectionData(
          value: e.value,
          color: color,
          radius: isTouched ? 80 : 65,
          title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections.values.toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  _touchedIndex = -1;
                } else {
                  _touchedIndex = response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
        ),
      ),
    );
  }

  Color _defaultColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Color(0xFF80CBC4),
      Color(0xFFFFB347),
      Color(0xFF81C784),
    ];
    return colors[index % colors.length];
  }
}

class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;

  const _TrendChart({required this.trends});

  @override
  Widget build(BuildContext context) {
    final maxY = trends.fold<double>(
      0,
      (m, t) => [m, t['income'] as double, t['expense'] as double]
          .reduce((a, b) => a > b ? a : b),
    );

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < trends.length) {
                    return Text(
                      AppDateUtils.monthName(trends[i]['month'] as int)
                          .substring(0, 3),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.disabled,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 20,
              ),
            ),
          ),
          barGroups: trends.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            return BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: (t['income'] as double),
                  color: AppColors.income,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: (t['expense'] as double),
                  color: AppColors.expense,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _CategoryStatRow extends StatelessWidget {
  final CategorieModele? category;
  final double amount;
  final double percentage;

  const _CategoryStatRow({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        category != null ? Color(category!.colorValue) : AppColors.disabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category?.name ?? 'Autre',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_fmt(amount)} Ar',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      int c = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        if (c > 0 && c % 3 == 0) buf.write(' ');
        buf.write(s[i]);
        c++;
      }
      return buf.toString().split('').reversed.join();
    }
    return v.toStringAsFixed(0);
  }
}

class _MonthNavigator extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int, int) onChanged;

  const _MonthNavigator({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () {
            final dt = DateTime(year, month - 1);
            onChanged(dt.month, dt.year);
          },
        ),
        Text(
          '${AppDateUtils.monthName(month).toUpperCase()} $year',
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: month == now.month && year == now.year
              ? null
              : () {
                  final dt = DateTime(year, month + 1);
                  onChanged(dt.month, dt.year);
                },
        ),
      ],
    );
  }
}
