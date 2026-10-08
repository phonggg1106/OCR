import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/currency_format.dart';
import '../../core/theme.dart';

class DonutChartPainter extends CustomPainter {
  final List<double> percentages; // Ví dụ: [0.4, 0.35, 0.25]
  final List<Color> colors;
  final double progress; // 0.0 -> 1.0 (AnimationController value)
  final int? selectedIndex;

  DonutChartPainter({
    required this.percentages,
    required this.colors,
    required this.progress,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (percentages.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = min(size.width, size.height) * 0.38;
    const defaultStroke = 26.0;

    // Vẽ bóng viền nhẹ phía dưới vòng tròn
    final bgPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = defaultStroke;
    canvas.drawCircle(center, baseRadius, bgPaint);

    double startAngle = -pi / 2;

    for (int i = 0; i < percentages.length; i++) {
      final percentage = percentages[i];
      if (percentage <= 0) continue;

      final isSelected = selectedIndex == i;
      final strokeWidth = isSelected ? 32.0 : defaultStroke;
      final radius = isSelected ? baseRadius + 3.0 : baseRadius;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Tính góc quét theo tiến trình hoạt ảnh
      final sweepAngle = (2 * pi * percentage) * progress;

      // Khoảng cách góc nhỏ giữa các phần để tạo sự phân tách tinh tế
      const gapAngle = 0.03;
      final actualSweep = max(0.0, sweepAngle - gapAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        actualSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  void _paintEmptyState(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.38;
    final paint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.percentages != percentages ||
        oldDelegate.colors != colors;
  }
}

/// Widget hoàn chỉnh hiển thị biểu đồ Donut kèm Animation và Chú thích danh mục
class AnimatedCategoryDonutChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const AnimatedCategoryDonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<AnimatedCategoryDonutChart> createState() => _AnimatedCategoryDonutChartState();
}

class _AnimatedCategoryDonutChartState extends State<AnimatedCategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryTotals != widget.categoryTotals) {
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
    if (widget.totalAmount <= 0 || widget.categoryTotals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text(
                'Chưa có dữ liệu chi tiêu',
                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final entries = widget.categoryTotals.entries.toList();
    // Tính phần trăm từng danh mục
    final percentages = entries.map((e) => e.value / widget.totalAmount).toList();
    final colors = entries.map((e) {
      final cat = CategoryHelper.fromString(e.key);
      return CategoryHelper.getColor(cat);
    }).toList();

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
              const Text(
                'Cơ cấu chi tiêu',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.canvasLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  '${entries.length} danh mục',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => CustomPaint(
                      size: const Size(220, 220),
                      painter: DonutChartPainter(
                        percentages: percentages,
                        colors: colors,
                        progress: _animation.value,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                  ),
                  // Phần văn bản ở tâm vòng tròn
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedIndex != null
                            ? entries[_selectedIndex!].key
                            : 'Tổng chi tiêu',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedIndex != null
                            ? CurrencyFormat.formatVND(entries[_selectedIndex!].value)
                            : CurrencyFormat.formatVND(widget.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedIndex != null)
                        Text(
                          '${(percentages[_selectedIndex!] * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors[_selectedIndex! % colors.length],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Danh sách chú thích các danh mục có thể bấm chọn
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              final cat = CategoryHelper.fromString(entry.key);
              final color = CategoryHelper.getColor(cat);
              final percent = (percentages[index] * 100).toStringAsFixed(0);
              final isSelected = _selectedIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = isSelected ? null : index;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.canvasLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.borderColor,
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? color : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
