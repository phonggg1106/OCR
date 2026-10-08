import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../core/theme.dart';
import '../models/expense_item.dart';
import '../models/parsed_receipt.dart';
import '../state/expense_notifier.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final ParsedReceipt initialData;
  final String? imagePath;

  const ReviewScreen({
    super.key,
    required this.initialData,
    this.imagePath,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;

  late final FocusNode _merchantFocus;
  late final FocusNode _amountFocus;
  late final FocusNode _dateFocus;

  late DateTime _selectedDate;
  late String _selectedCategory;
  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();

    // Khởi tạo các giá trị từ OCR trích xuất được
    _merchantController = TextEditingController(
      text: widget.initialData.merchantName ?? '',
    );

    final initialAmount = widget.initialData.totalAmount;
    _amountController = TextEditingController(
      text: initialAmount != null ? initialAmount.toStringAsFixed(0) : '',
    );

    _selectedDate = widget.initialData.date ?? DateTime.now();
    _dateController = TextEditingController(
      text: CurrencyFormat.formatDate(_selectedDate),
    );

    _selectedCategory = widget.initialData.detectedCategory ??
        CategoryHelper.getName(ExpenseCategory.food);

    _merchantFocus = FocusNode();
    _amountFocus = FocusNode();
    _dateFocus = FocusNode();

    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // ⚠ LUÔN giải phóng controllers và focus nodes để tránh rò rỉ bộ nhớ (Memory Leaks)!
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();

    _merchantFocus.dispose();
    _amountFocus.dispose();
    _dateFocus.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = CurrencyFormat.formatDate(picked);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final merchant = _merchantController.text.trim();
      final cleanAmountStr = _amountController.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll(' ', '');
      final amount = double.parse(cleanAmountStr);

      final newExpense = ExpenseItem(
        id: const Uuid().v4(),
        title: merchant,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        imagePath: widget.imagePath,
        rawOcrText: widget.initialData.rawText,
        createdAt: DateTime.now(),
      );

      // Lưu trữ trạng thái qua Riverpod 2 Notifier
      ref.read(expenseProvider.notifier).addExpense(newExpense);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Đã lưu hóa đơn vào cơ sở dữ liệu thành công!'),
            ],
          ),
          backgroundColor: AppTheme.emeraldSuccess,
        ),
      );

      // Quay lại màn hình chính
      context.go('/dash');
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedPreviewAmount = CurrencyFormat.parseAmount(_amountController.text);

    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      appBar: AppBar(
        title: const Text('Xác Thực & Chỉnh Sửa Hóa Đơn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Thẻ thông báo trạng thái OCR
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryNavy, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dữ liệu được trích xuất bằng On-Device AI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.initialData.matchedKeyword != null
                                ? 'Tìm thấy từ khóa: "${widget.initialData.matchedKeyword}". Vui lòng kiểm tra lại trước khi lưu.'
                                : 'Vui lòng kiểm tra và chỉnh sửa lại các trường nếu cần thiết.',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Ảnh hóa đơn (nếu có)
              if (widget.imagePath != null &&
                  widget.imagePath!.isNotEmpty &&
                  (kIsWeb || (!kIsWeb && File(widget.imagePath!).existsSync()))) ...[
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? Image.network(
                                widget.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.receipt_long, size: 50),
                              )
                            : Image.file(
                                File(widget.imagePath!),
                                fit: BoxFit.cover,
                              ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_camera_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Ảnh hóa đơn gốc',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Trường Tên cửa hàng / Đơn vị
              TextFormField(
                controller: _merchantController,
                focusNode: _merchantFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_amountFocus),
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng / Đơn vị',
                  hintText: 'VD: Highlands Coffee, Co.opmart...',
                  prefixIcon: Icon(Icons.storefront_rounded, color: AppTheme.textSecondary),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên cửa hàng' : null,
              ),

              const SizedBox(height: 16),

              // 4. Trường Tổng số tiền (VNĐ)
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Tổng tiền (VNĐ)',
                  hintText: 'VD: 65000',
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.textSecondary),
                  suffixText: '₫',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  helperText: parsedPreviewAmount > 0
                      ? 'Định dạng: ${CurrencyFormat.formatVND(parsedPreviewAmount)}'
                      : null,
                ),
                validator: (v) {
                  final clean = v?.replaceAll('.', '').replaceAll(',', '').trim();
                  final n = double.tryParse(clean ?? '');
                  return (n == null || n <= 0)
                      ? 'Vui lòng nhập số tiền hợp lệ lớn hơn 0'
                      : null;
                },
              ),

              const SizedBox(height: 16),

              // 5. Trường Ngày giao dịch
              TextFormField(
                controller: _dateController,
                focusNode: _dateFocus,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Ngày giao dịch',
                  prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary),
                  suffixIcon: Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryNavy),
                ),
              ),

              const SizedBox(height: 20),

              // 6. Chọn Danh mục chi tiêu
              const Text(
                'Danh mục chi tiêu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryHelper.vietnameseNames.values.map((catName) {
                  final isSelected = _selectedCategory == catName;
                  final catEnum = CategoryHelper.fromString(catName);
                  final catColor = CategoryHelper.getColor(catEnum);
                  final catIcon = CategoryHelper.getIcon(catEnum);

                  return ChoiceChip(
                    avatar: Icon(
                      catIcon,
                      size: 16,
                      color: isSelected ? Colors.white : catColor,
                    ),
                    label: Text(catName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = catName);
                      }
                    },
                    selectedColor: AppTheme.primaryNavy,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                    backgroundColor: AppTheme.pureWhite,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryNavy : AppTheme.borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 7. Văn bản OCR thô (Tùy chọn xem kiểm tra)
              if (widget.initialData.rawText.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: _showRawOcr,
                    onExpansionChanged: (v) => setState(() => _showRawOcr = v),
                    leading: const Icon(Icons.notes_rounded, color: AppTheme.textSecondary),
                    title: const Text(
                      'Xem toàn bộ văn bản OCR nhận diện được',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                            widget.initialData.rawText,
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
                const SizedBox(height: 24),
              ],

              // 8. Nút Lưu Hóa Đơn & Nút Hủy
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submitForm,
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text(
                  'Lưu Hóa Đơn Vào Sổ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Hủy bỏ'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
