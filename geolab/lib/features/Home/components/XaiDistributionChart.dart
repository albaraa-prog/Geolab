import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolab/Service/theme_service.dart';

class XaiDistributionChart extends StatelessWidget {
  final Map<String, double> probabilities;
  final ThemeService themeService;

  const XaiDistributionChart({
    super.key,
    required this.probabilities,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    if (probabilities.isEmpty) {
      return const SizedBox.shrink();
    }

    var sortedEntries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    // Optimize for mobile: Show top 4 + Others if list is too long
    if (sortedEntries.length > 5) {
      final topEntries = sortedEntries.take(4).toList();
      final otherProb = sortedEntries.skip(4).fold(0.0, (sum, entry) => sum + entry.value);
      if (otherProb > 0.01) {
        topEntries.add(MapEntry('Others', otherProb));
      }
      sortedEntries = topEntries;
    }

    // Colors for the chart matching the app's premium aesthetic
    final colors = [
      const Color(0xFFE57373), // Red 300
      const Color(0xFF64B5F6), // Blue 300
      const Color(0xFF81C784), // Green 300
      const Color(0xFFBA68C8), // Purple 300
      const Color(0xFFFFD54F), // Amber 300
    ];

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => themeService.surfaceColor,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 final entry = sortedEntries[group.x];
                return BarTooltipItem(
                  '${entry.key}\n',
                  TextStyle(
                    color: themeService.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${(rod.toY * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= sortedEntries.length) return const SizedBox.shrink();
                  final entry = sortedEntries[value.toInt()];
                  
                  // Allow longer names, split heavily
                  String name = entry.key;
                  // Replace underscores with spaces for better readability
                  name = name == "non_rock" ? "Not a Rock" : name.replaceAll('_', ' ');
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 55, // Reduced from 60 to prevent overlap on narrow screens
                      child: Text(
                        name,
                        style: TextStyle(
                          color: themeService.textColor.withOpacity(0.9),
                          fontSize: 9, 
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3, 
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  );
                },
                reservedSize: 50, // Increased from 40 to accommodate 3 lines comfortably
              ),
              ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    '${(value * 100).toInt()}%',
                    style: TextStyle(
                      color: themeService.textColor.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 30,
                interval: 0.2,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: themeService.onSurfaceColor.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(sortedEntries.length, (index) {
            final entry = sortedEntries[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: colors[index % colors.length],
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 1.0,
                    color: themeService.onSurfaceColor.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
