import 'package:flutter/material.dart';
import 'package:acf2/models/trend_data.dart';
import 'package:acf2/providers/health_data_provider.dart';
import 'package:acf2/providers/user_provider.dart';
import 'package:acf2/views/custom_topbar.dart';
import 'package:acf2/views/styles.dart';
import 'package:provider/provider.dart';

class TrendVisualization extends StatefulWidget {
  const TrendVisualization({super.key});

  @override
  State<TrendVisualization> createState() => _TrendVisualizationState();
}

class _TrendVisualizationState extends State<TrendVisualization> {
  String _selectedTimeframe = '30days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrendData());
  }

  Future<void> _loadTrendData() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).activeProfileId;
      if (userId == null) {
        throw Exception('User ID not found. Please select a profile.');
      }
      await Provider.of<HealthDataProvider>(context, listen: false)
          .fetchTrendData(userId, timeframe: _selectedTimeframe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading trend data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildCustomChart(List<TrendData> trendData) {
    if (trendData.isEmpty) {
      return Center(
        child: Text(
          'No trend data available.',
          style: normalTextStyle(context, AppColors.textPrimary),
        ),
      );
    }

    return Container(
      height: 380,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: TrendChartPainter(trendData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(
        title: "Trend Analysis",
        hasDrawer: false,
        hasSettings: false,
        withBack: true,
      ),
      body: Consumer<HealthDataProvider>(
        builder: (context, provider, child) {
          final trendData = provider.trendData;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButton<String>(
                    value: _selectedTimeframe,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTimeframe = newValue!;
                      });
                      _loadTrendData();
                    },
                    items: [
                      DropdownMenuItem(
                        value: '7days',
                        child: Text(
                          'Last 7 days',
                          style: normalTextStyle(context, AppColors.textPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '30days',
                        child: Text(
                          'Last 30 days',
                          style: normalTextStyle(context, AppColors.textPrimary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: '90days',
                        child: Text(
                          'Last 90 days',
                          style: normalTextStyle(context, AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCustomChart(trendData),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TrendChartPainter extends CustomPainter {
  final List<TrendData> trendData;

  TrendChartPainter(this.trendData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    final labelStyle = TextStyle(color: Colors.black, fontSize: 10);

    final double maxY = 100;
    final double maxX = trendData.length.toDouble();

    // Draw axes
    final double padding = 20;
    final double chartWidth = size.width - 2 * padding;
    final double chartHeight = size.height - 2 * padding;

    final double xStart = padding;
    final double yStart = size.height - padding;
    final double xEnd = size.width - padding;
    final double yEnd = padding;

    // Draw vertical axis
    canvas.drawLine(Offset(xStart, yStart), Offset(xStart, yEnd), axisPaint);

    // Draw horizontal axis
    canvas.drawLine(Offset(xStart, yStart), Offset(xEnd, yStart), axisPaint);

    // Draw grid and labels
    final int steps = 5;
    for (int i = 0; i <= steps; i++) {
      final double y = yStart - (chartHeight / steps) * i;
      final double labelValue = (maxY / steps) * i;

      // Draw grid line
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), axisPaint..color = Colors.grey.withOpacity(0.2));

      // Draw label
      final textSpan = TextSpan(text: labelValue.toStringAsFixed(0), style: labelStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(xStart - textPainter.width - 5, y - textPainter.height / 2));
    }

    // Draw data points and connect with lines
    final double xStep = chartWidth / (maxX - 1);
    final points = trendData.asMap().entries.map((entry) {
      final int index = entry.key;
      final TrendData data = entry.value;

      final double x = xStart + xStep * index;
      final double y = yStart - (data.riskLevel / maxY) * chartHeight;
      return Offset(x, y);
    }).toList();

    // Draw lines between points
    if (points.isNotEmpty) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
