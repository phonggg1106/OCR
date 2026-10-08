import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/currency_format.dart';
import '../../core/theme.dart';

class WeeklyBarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> dayLabels;
  final double maxValue;
  final double progress; // 0.0 -> 1.0 (AnimationController value)
  final int? selectedIndex;

  WeeklyBarChartPainter({
    required this.values,
    required this.dayLabels,
    required this.maxValue,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final bottomPadding = 28.0;
    final topPadding = 24.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final barCount = values.length;
    final barSpacing = size.width / barCount;
    final barWidth = max(14.0, barSpacing * 0.45);

    // Vẽ 3 đường kẻ gióng mờ ngang (Grid lines)
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int step = 0; step <= 2; step++) {
      final y = topPadding + (chartHeight * (step / 2));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final effectiveMax = maxValue > 0 ? maxValue : 1.0;

    for (int i = 0; i < barCount; i++) {
      final value = values[i];
      final normalized = (value / effectiveMax).clamp(0.0, 1.0);
      final currentBarHeight = chartHeight * normalized * progress;

      final centerX = (i * barSpacing) + (barSpacing / 2);
      final isSelected = selectedIndex == i;
      final isToday = i == barCount - 1;

      // Vẽ thanh xám nền phía sau (Track)
      final trackPaint = Paint()
        ..color = AppTheme.canvasLight
        ..style = PaintingStyle.fill;

      final trackRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, topPadding + chartHeight / 2),
          width: barWidth,
          height: chartHeight,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Vẽ thanh dữ liệu chính nếu giá trị > 0
      if (currentBarHeight > 0) {
        final barRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(
            centerX - (barWidth / 2),
            topPadding + chartHeight - currentBarHeight,
            barWidth,
            currentBarHeight,
          ),
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        );

        final barPaint = Paint()
          ..color = isSelected
              ? AppTheme.accentBlue
              : (isToday ? AppTheme.primaryNavy : AppTheme.primaryNavy.withValues(alpha: 0.55))
          ..style = PaintingStyle.fill;

        canvas.drawRRect(barRect, barPaint);
      }

      // Vẽ nhãn ngày ở phía dưới trục
      final textSpan = TextSpan(
        text: dayLabels[i],
        style: TextStyle(
          color: isToday
              ? AppTheme.primaryNavy
              : (isSelected ? AppTheme.accentBlue : AppTheme.textSecondary),
          fontSize: 11,
          fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), size.height - bottomPadding + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.values != values ||
        oldDelegate.maxValue != maxValue;
  }
}

/// Widget hoàn chỉnh hiển thị biểu đồ chi tiêu 7 ngày qua
class AnimatedWeeklyBarChart extends StatefulWidget {
  final Map<DateTime, double> weeklyData;

  const AnimatedWeeklyBarChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<AnimatedWeeklyBarChart> createState() => _AnimatedWeeklyBarChartState();
}

class _AnimatedWeeklyBarChartState extends State<AnimatedWeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedWeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.weeklyData.entries.toList();
    final values = entries.map((e) => e.value).toList();
    final dayLabels = entries.map((e) => CurrencyFormat.formatShortDay(e.key).split(',')[0]).toList();
    final maxVal = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);

    final totalWeek = values.fold(0.0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiêu 7 ngày qua',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tổng: ${CurrencyFormat.formatVND(totalWeek)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
              if (_selectedIndex != null && _selectedIndex! < entries.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    CurrencyFormat.formatVND(entries[_selectedIndex!].value),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: GestureDetector(
              onTapUp: (details) {
                final width = context.size?.width ?? 300;
                final barCount = values.length;
                if (barCount > 0) {
                  final tappedIndex = (details.localPosition.dx / (width / barCount)).floor();
                  if (tappedIndex >= 0 && tappedIndex < barCount) {
                    setState(() {
                      _selectedIndex = _selectedIndex == tappedIndex ? null : tappedIndex;
                    });
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: WeeklyBarChartPainter(
                    values: values,
                    dayLabels: dayLabels,
                    maxValue: maxVal > 0 ? maxVal : 100000,
                    progress: _animation.value,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
