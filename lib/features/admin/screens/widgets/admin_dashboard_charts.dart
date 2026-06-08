import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RevenueLineChart extends StatelessWidget {
  final List<double> dailyRevenue;
  final double maxRevenue;

  const RevenueLineChart({
    super.key,
    required this.dailyRevenue,
    required this.maxRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dailyRevenue.length <= 7
                ? 'Biểu đồ doanh thu (7 Ngày qua)'
                : 'Biểu đồ doanh thu (${dailyRevenue.length} Ngày qua)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRevenue == 0 ? 25000 : (maxRevenue / 4),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200], strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: dailyRevenue.length <= 7
                          ? 1
                          : dailyRevenue.length <= 30
                              ? 5
                              : 15,
                      getTitlesWidget: (val, meta) => bottomTitleWidgets(val, meta, dailyRevenue.length),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxRevenue == 0 ? 25000 : (maxRevenue / 4),
                      getTitlesWidget: leftTitleWidgets,
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (dailyRevenue.length - 1).toDouble(),
                minY: 0,
                maxY: maxRevenue == 0 ? 100000 : maxRevenue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(dailyRevenue.length, (index) {
                      return FlSpot(index.toDouble(), dailyRevenue[index]);
                    }),
                    isCurved: dailyRevenue.length <= 30,
                    color: Colors.indigo,
                    barWidth: dailyRevenue.length > 30 ? 2.5 : 4.0,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: dailyRevenue.length <= 7),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.indigo.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta, int totalDays) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Colors.grey,
    );
    final index = value.toInt();
    if (index < 0 || index >= totalDays) return const SizedBox.shrink();

    final date = DateTime.now().subtract(Duration(days: (totalDays - 1) - index));
    Widget text;
    if (totalDays <= 7) {
      String dayStr = '';
      switch (date.weekday) {
        case 1: dayStr = 'T2'; break;
        case 2: dayStr = 'T3'; break;
        case 3: dayStr = 'T4'; break;
        case 4: dayStr = 'T5'; break;
        case 5: dayStr = 'T6'; break;
        case 6: dayStr = 'T7'; break;
        case 7: dayStr = 'CN'; break;
      }
      text = Text(dayStr, style: style);
    } else {
      text = Text(DateFormat('dd/MM').format(date), style: style);
    }

    return SideTitleWidget(meta: meta, child: text);
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 10,
      color: Colors.grey,
    );
    if (value == 0) return const Text('0', style: style);

    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      text = value.toStringAsFixed(0);
    }

    return Text(text, style: style, textAlign: TextAlign.left, maxLines: 1);
  }
}

class UserDemographicsPieChart extends StatelessWidget {
  final Map<String, dynamic> demographics;
  final int totalUsers;

  const UserDemographicsPieChart({
    super.key,
    required this.demographics,
    required this.totalUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tỉ trọng người dùng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    sections: _getSections(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalUsers',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Total Users',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(
                Colors.blue,
                'Khách hàng',
                _getPercentage('customer'),
              ),
              const SizedBox(width: 16),
              _buildLegend(Colors.orange, 'Tài xế', _getPercentage('driver')),
              const SizedBox(width: 16),
              _buildLegend(Colors.green, 'Quán ăn', _getPercentage('merchant')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text, String percentage) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '$text ($percentage)',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  String _getPercentage(String key) {
    if (totalUsers == 0) return '0%';
    final count = demographics[key] ?? 0;
    return '${((count / totalUsers) * 100).toStringAsFixed(1)}%';
  }

  List<PieChartSectionData> _getSections() {
    if (totalUsers == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 100,
          title: '',
          radius: 20,
        ),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: ((demographics['customer'] ?? 0) as int).toDouble(),
        title: '',
        radius: 20,
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: ((demographics['driver'] ?? 0) as int).toDouble(),
        title: '',
        radius: 20,
      ),
      PieChartSectionData(
        color: Colors.green,
        value: ((demographics['merchant'] ?? 0) as int).toDouble(),
        title: '',
        radius: 20,
      ),
    ];
  }
}
