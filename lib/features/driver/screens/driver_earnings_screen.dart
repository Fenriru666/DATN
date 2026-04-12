import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:datn/features/driver/services/driver_service.dart';
import 'package:intl/intl.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final DriverService _driverService = DriverService();
  bool _isLoading = true;

  Map<DateTime, double> _earningsByDate = {};
  double _totalEarnings = 0.0;
  int _totalRides = 0;
  int _touchedIndex = -1;

  String _selectedFilter = 'Tuần này';
  late DateTime _startDate;
  late DateTime _endDate;
  final List<DateTime> _chartDates = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  @override
  void initState() {
    super.initState();
    _setDatesForFilter('Tuần này');
    _loadEarningsData();
  }

  void _setDatesForFilter(String filter) {
    final now = DateTime.now();
    _endDate = now;
    if (filter == 'Tuần này') {
      _startDate = now.subtract(const Duration(days: 6));
    } else if (filter == 'Tháng này') {
      _startDate = DateTime(now.year, now.month, 1);
    } else if (filter == 'Tháng trước') {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0); // Last day of previous month
    }
    _selectedFilter = filter;
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFE724C), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = 'Tùy chọn';
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadEarningsData();
    }
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
      _touchedIndex = -1;
    });

    try {
      final summary = await _driverService.getEarningsSummary(
        _startDate,
        _endDate,
      );
      double total = 0.0;
      final earningsMap = summary['earningsByDate'] as Map<DateTime, double>;

      earningsMap.forEach((key, value) {
        total += value;
      });

      // Generate date list for chart (X axis)
      _chartDates.clear();
      DateTime current = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      );
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      while (!current.isAfter(end)) {
        _chartDates.add(current);
        current = current.add(const Duration(days: 1));
      }

      if (mounted) {
        setState(() {
          _earningsByDate = earningsMap;
          _totalEarnings = total;
          _totalRides = summary['totalRides'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải dữ liệu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Thu Nhập Của Tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE724C)),
            )
          : RefreshIndicator(
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFE724C), Color(0xFFFF9A7A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFE724C,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thu nhập ${_selectedFilter.toLowerCase()}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(_totalEarnings),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.task_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$_totalRides Chuyến xe",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Hiệu suất Tốt",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Header & Filter Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Biểu đồ Doanh thu",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              dropdownColor: Theme.of(context).cardColor,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFFE724C),
                              ),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (String? newValue) {
                                if (newValue == 'Tùy chọn') {
                                  _selectCustomDateRange();
                                } else if (newValue != null) {
                                  setState(() {
                                    _setDatesForFilter(newValue);
                                  });
                                  _loadEarningsData();
                                }
                              },
                              items:
                                  <String>[
                                    'Tuần này',
                                    'Tháng này',
                                    'Tháng trước',
                                    'Tùy chọn',
                                  ].map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.only(
                        top: 24,
                        right: 16,
                        left: 8,
                        bottom: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Colors.black87,
                              tooltipPadding: const EdgeInsets.all(8),
                              tooltipMargin: 8,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      _currencyFormat.format(rod.toY),
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                            ),
                            touchCallback:
                                (FlTouchEvent event, barTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        barTouchResponse == null ||
                                        barTouchResponse.spot == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = barTouchResponse
                                        .spot!
                                        .touchedBarGroupIndex;
                                  });
                                },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= _chartDates.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final date = _chartDates[index];

                                  // Skip some labels if there are too many days
                                  if (_chartDates.length > 15) {
                                    if (date.day % 5 != 0 &&
                                        date.day != 1 &&
                                        index != _chartDates.length - 1) {
                                      return const SizedBox.shrink();
                                    }
                                  } else if (_chartDates.length > 7) {
                                    if (index % 2 != 0 &&
                                        index != _chartDates.length - 1) {
                                      return const SizedBox.shrink();
                                    }
                                  }

                                  final label = _chartDates.length <= 7
                                      ? _getWeekdayName(date.weekday)
                                      : '${date.day}/${date.month}';

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: _touchedIndex == index
                                            ? const Color(0xFFFE724C)
                                            : Colors.grey[600],
                                        fontWeight: _touchedIndex == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ), // Hide Y axis numbers to stay clean
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _getMaxY() / 4 > 0
                                ? _getMaxY() / 4
                                : 100000,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[200],
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _createBarGroups(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  double _getMaxY() {
    if (_earningsByDate.isEmpty) return 100000; // default 100k
    double max = 0;
    _earningsByDate.forEach((key, value) {
      if (value > max) max = value;
    });
    // Add 20% headroom
    return max == 0 ? 100000 : max * 1.2;
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  List<BarChartGroupData> _createBarGroups() {
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < _chartDates.length; i++) {
      final date = _chartDates[i];
      final value = _earningsByDate[date] ?? 0.0;
      final isTouched = _touchedIndex == i;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: isTouched ? const Color(0xFFFE724C) : Colors.blue[300],
              width: _chartDates.length > 15
                  ? 8
                  : (_chartDates.length > 7 ? 14 : 22),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getMaxY(),
                color: Colors.grey[100],
              ),
            ),
          ],
          showingTooltipIndicators: isTouched && value > 0 ? [0] : [],
        ),
      );
    }
    return groups;
  }
}
