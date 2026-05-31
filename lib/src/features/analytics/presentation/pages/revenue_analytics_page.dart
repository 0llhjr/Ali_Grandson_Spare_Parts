// ============================================================
// revenue_analytics_page.dart — Admin Revenue Analytics Screen
// ============================================================
// Shows the admin a visual overview of delivered-order revenue.
//
// Features:
//   • Filter chips to select the time period:
//       Week | Month | Quarter | Year | Last Year | Custom range
//   • Summary card showing total revenue and order count.
//   • Line chart (fl_chart) with one data point per day, grouped
//     and summed from the raw order rows.
//   • Transaction list showing the last 10 orders.
//   • Export to CSV — writes a timestamped file to the temp
//     directory, then offers "Open" or "Share" via the OS.
//
// CSV columns: Order ID, Date, Customer, Amount, Payment Mode,
//              Status, Address, Phone.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Defines the selectable time periods for filtering revenue data.
enum RevenueFilter { thisWeek, thisMonth, thisQuarter, thisYear, lastYear, custom }

class RevenueAnalyticsPage extends StatefulWidget {
  const RevenueAnalyticsPage({super.key});

  @override
  State<RevenueAnalyticsPage> createState() => _RevenueAnalyticsPageState();
}

class _RevenueAnalyticsPageState extends State<RevenueAnalyticsPage> {
  RevenueFilter _selectedFilter = RevenueFilter.thisMonth;
  DateTimeRange? _customRange;
  List<Map<String, dynamic>> _revenueData = [];
  List<Map<String, dynamic>> _detailedOrders = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Calculates the start and end dates based on the selected filter and fetches data from DB
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_selectedFilter) {
      case RevenueFilter.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case RevenueFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case RevenueFilter.thisQuarter:
        int quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(now.year, quarterMonth, 1);
        break;
      case RevenueFilter.thisYear:
        start = DateTime(now.year, 1, 1);
        break;
      case RevenueFilter.lastYear:
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      case RevenueFilter.custom:
        start = _customRange?.start ?? DateTime(now.year, now.month, 1);
        end = _customRange?.end ?? now;
        break;
    }

    final db = DatabaseHelper.instance;
    final data = await db.getRevenueData(start, end);
    final detailed = await db.getDetailedOrdersForRevenue(start, end);

    if (mounted) {
      setState(() {
        _revenueData = data;
        _detailedOrders = detailed;
        _isLoading = false;
      });
    }
  }

  // Opens a date picker for custom range selection
  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kSecondaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedFilter = RevenueFilter.custom;
      });
      _fetchData();
    }
  }

  // Generates a CSV file and prompts the user to either open or share it
  Future<void> _exportToCSV() async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);
    
    try {
      // Allow UI to update to show loading state
      await Future.delayed(const Duration(milliseconds: 500));

      List<List<dynamic>> rows = [];
      // Professional Table Headers
      rows.add(["Order ID", "Date", "Customer", "Amount (OMR)", "Payment Mode", "Status", "Address", "Phone"]);

      for (var order in _detailedOrders) {
        rows.add([
          order['id'],
          order['order_date'],
          order['user_username'],
          order['total_price'],
          order['payment_mode'],
          order['status'],
          order['address'],
          order['phone']
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      
      // Use temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = "Ali_Grandsons_Revenue_$timestamp.csv";
      final File file = File("${directory.path}/$fileName");
      
      await file.writeAsString(csvData);

      if (mounted) {
        setState(() => _isExporting = false);
        _showSharingOptions(file.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showErrorSnackBar("Export failed: Unable to create file.");
      }
    }
  }

  // Presents sharing and opening choices to the user
  void _showSharingOptions(String filePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: kGreyLight, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.check_circle_outline_rounded, size: 54, color: kSuccessColor),
            const SizedBox(height: 16),
            const Text(
              'Report Ready',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kSecondaryColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'The revenue report has been generated successfully. How would you like to proceed?',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openFile(filePath);
                    },
                    icon: const Icon(Icons.launch_rounded),
                    label: const Text('OPEN'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: kPrimaryColor),
                      foregroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareFile(filePath);
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('SHARE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Opens the file with the device's default CSV viewer
  Future<void> _openFile(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        String msg = "Could not open file.";
        if (result.type == ResultType.noAppToOpen) {
          msg = "No compatible app found. Please install a Spreadsheet viewer like Excel.";
        }
        _showErrorSnackBar(msg);
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred while opening the file.");
    }
  }

  // Shares the file using the native share sheet
  Future<void> _shareFile(String path) async {
    try {
      final ShareResult result = await Share.shareXFiles(
        [XFile(path, mimeType: 'text/csv')],
        subject: 'Revenue Report - Ali Grandsons',
      );

      // Status check for fallback logic
      if (result.status == ShareResultStatus.unavailable && mounted) {
        _openFile(path);
      }
    } catch (e) {
      if (mounted) {
        _openFile(path);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kErrorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('REVENUE ANALYTICS'),
        elevation: 0,
        actions: [
          _isExporting 
            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor))))
            : IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: _detailedOrders.isEmpty ? null : _exportToCSV,
                tooltip: 'Export & Share',
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSummaryHeader(),
                        const SizedBox(height: 24),
                        _buildChartCard(),
                        const SizedBox(height: 24),
                        _buildTransactionList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: kSurfaceColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _filterChip('WEEK', RevenueFilter.thisWeek),
          _filterChip('MONTH', RevenueFilter.thisMonth),
          _filterChip('QUARTER', RevenueFilter.thisQuarter),
          _filterChip('YEAR', RevenueFilter.thisYear),
          _filterChip('LAST YEAR', RevenueFilter.lastYear),
          _customFilterChip(),
        ],
      ),
    );
  }

  Widget _filterChip(String label, RevenueFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kTextSecondary)),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() => _selectedFilter = filter);
            _fetchData();
          }
        },
        selectedColor: kPrimaryColor,
        backgroundColor: kGreyLight,
      ),
    );
  }

  Widget _customFilterChip() {
    bool isSelected = _selectedFilter == RevenueFilter.custom;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          _customRange == null ? 'CUSTOM' : '${DateFormat('MMM d').format(_customRange!.start)} - ${DateFormat('MMM d').format(_customRange!.end)}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kTextSecondary),
        ),
        onPressed: _selectCustomRange,
        backgroundColor: isSelected ? kPrimaryColor : kGreyLight,
      ),
    );
  }

  Widget _buildSummaryHeader() {
    double total = _detailedOrders.fold(0.0, (sum, item) => sum + item['total_price']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSecondaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Revenue in Period', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'OMR ${total.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${_detailedOrders.length} Completed Orders', style: const TextStyle(color: kAccentColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: kGreyLight)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue Trend', style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: _revenueData.isEmpty 
                ? const Center(child: Text('No data for this period'))
                : LineChart(_getChartData()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _getChartData() {
    List<FlSpot> spots = [];
    
    // Group and sum by date for the chart
    Map<String, double> grouped = {};
    for (var row in _revenueData) {
      String date = row['order_date'].split(' ')[0];
      grouped[date] = (grouped[date] ?? 0.0) + row['total_price'];
    }

    var sortedKeys = grouped.keys.toList()..sort();
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), grouped[sortedKeys[i]]!));
    }

    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (sortedKeys.length / 5).clamp(1, double.infinity),
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < sortedKeys.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM d').format(DateTime.parse(sortedKeys[index])),
                    style: const TextStyle(color: kTextSecondary, fontSize: 9),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: kPrimaryColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: kPrimaryColor.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: kSecondaryColor,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                'OMR ${spot.y.toStringAsFixed(2)}\n${sortedKeys[spot.x.toInt()]}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
        const SizedBox(height: 12),
        ..._detailedOrders.take(10).map((order) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kGreyLight)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: kPrimaryColor.withOpacity(0.1),
              child: const Icon(Icons.receipt_long, color: kPrimaryColor, size: 20),
            ),
            title: Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(order['order_date'].split(' ')[0], style: const TextStyle(fontSize: 12)),
            trailing: Text(
              'OMR ${order['total_price'].toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: kSecondaryColor),
            ),
          ),
        )),
      ],
    );
  }
}
