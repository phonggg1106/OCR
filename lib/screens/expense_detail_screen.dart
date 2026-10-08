import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../core/theme.dart';
import '../models/expense_item.dart';
import '../models/parsed_receipt.dart';
import '../state/expense_notifier.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String id;

  const ExpenseDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Chi Tiết Hóa Đơn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.roseDanger),
            tooltip: 'Xóa giao dịch',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final item = expenses.cast<ExpenseItem?>().firstWhere(
                (e) => e?.id == id,
                orElse: () => null,
              );

          if (item == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text('Không tìm thấy hóa đơn này'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            );
          }

          final catEnum = item.categoryEnum;
          final catColor = CategoryHelper.getColor(catEnum);
          final catIcon = CategoryHelper.getIcon(catEnum);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Thẻ trung tâm số tiền và tên nhà bán lẻ
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(20),
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
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(catIcon, color: catColor, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.formattedAmount,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.canvasLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: catColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Thẻ thông tin ngày giờ
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Ngày giao dịch',
                        value: CurrencyFormat.formatDate(item.date),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Thời điểm tạo',
                        value: CurrencyFormat.formatDateTime(item.createdAt),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Mã định danh',
                        value: item.id.substring(0, item.id.length > 8 ? 8 : item.id.length),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Ảnh hóa đơn (nếu có lưu)
                if (item.imagePath != null &&
                    item.imagePath!.isNotEmpty &&
                    (kIsWeb || (!kIsWeb && File(item.imagePath!).existsSync()))) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.image_outlined, size: 20, color: AppTheme.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              'Ảnh chụp hóa đơn',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  item.imagePath!,
                                  fit: BoxFit.contain,
                                  height: 240,
                                  width: double.infinity,
                                  errorBuilder: (_, _, _) => const Icon(Icons.receipt_long, size: 60),
                                )
                              : Image.file(
                                  File(item.imagePath!),
                                  fit: BoxFit.contain,
                                  height: 240,
                                  width: double.infinity,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Nhật ký văn bản OCR thô (nếu có)
                if (item.rawOcrText != null && item.rawOcrText!.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: ExpansionTile(
                      leading: const Icon(Icons.code_rounded, color: AppTheme.textSecondary),
                      title: const Text(
                        'Văn bản OCR nhận diện được',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.canvasLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              item.rawOcrText!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Nút chỉnh sửa lại hóa đơn
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    context.push(
                      '/review',
                      extra: {
                        'parsed': ParsedReceipt(
                          rawText: item.rawOcrText ?? '',
                          merchantName: item.title,
                          totalAmount: item.amount,
                          date: item.date,
                          detectedCategory: item.category,
                        ),
                        'imagePath': item.imagePath,
                      },
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: const Text('Chỉnh sửa hóa đơn này'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc chắn muốn xóa vĩnh viễn hóa đơn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.roseDanger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(expenseProvider.notifier).deleteExpense(id);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa hóa đơn thành công')),
        );
      }
    }
  }
}
