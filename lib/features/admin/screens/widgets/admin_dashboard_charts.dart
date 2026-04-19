import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueLineChart extends StatelessWidget {
  final List<double> weeklyRevenue;
  final double maxRevenue;

  const RevenueLineChart({
    super.key,
    required this.weeklyRevenue,
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
          const Text(
            'Biểu đồ danh thu (7 Ngày qua)',
            style: TextStyle(
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
                      interval: 1,
                      getTitlesWidget: bottomTitleWidgets,
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
                maxX: 6,
                minY: 0,
                maxY: maxRevenue == 0 ? 100000 : maxRevenue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (index) {
                      return FlSpot(index.toDouble(), weeklyRevenue[index]);
                    }),
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
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

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Colors.grey,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('T2', style: style);
        break;
      case 1:
        text = const Text('T3', style: style);
        break;
      case 2:
        text = const Text('T4', style: style);
        break;
      case 3:
        text = const Text('T5', style: style);
        break;
      case 4:
        text = const Text('T6', style: style);
        break;
      case 5:
        text = const Text('T7', style: style);
        break;
      case 6:
        text = const Text('CN', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
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
