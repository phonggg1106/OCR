import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/currency_format.dart';
import '../core/theme.dart';
import '../models/parsed_receipt.dart';
import '../state/expense_notifier.dart';
import '../widgets/charts/bar_chart.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/expense_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedChartTab = 0; // 0: Donut chart, 1: Bar chart
  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final grandTotal = ref.watch(grandTotalProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final weeklyTotals = ref.watch(weeklyTotalsProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryNavy, size: 24),
            SizedBox(width: 10),
            Text('Sổ Chi Tiêu & OCR'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(expenseProvider.notifier).refresh(),
          ),
          IconButton(
            tooltip: 'Thêm thủ công',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {
              context.push(
                '/review',
                extra: {
                  'parsed': ParsedReceipt(
                    rawText: '',
                    merchantName: '',
                    totalAmount: null,
                    date: DateTime.now(),
                  ),
                  'imagePath': null,
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          // Lọc danh sách theo danh mục và từ khóa tìm kiếm
          final filteredExpenses = expenses.where((item) {
            final matchesCat =
                _selectedCategory == 'Tất cả' || item.category == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty ||
                item.title.toLowerCase().contains(_searchQuery) ||
                item.category.toLowerCase().contains(_searchQuery);
            return matchesCat && matchesSearch;
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(expenseProvider.notifier).refresh(),
            color: AppTheme.primaryNavy,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Thẻ tổng quan số dư chi tiêu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildSummaryCard(grandTotal, expenses.length),
                  ),
                ),

                // 2. Chuyển đổi và hiển thị Custom Canvas Charts
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildChartSelector(),
                        const SizedBox(height: 12),
                        _selectedChartTab == 0
                            ? AnimatedCategoryDonutChart(
                                categoryTotals: categoryTotals,
                                totalAmount: grandTotal,
                              )
                            : AnimatedWeeklyBarChart(
                                weeklyData: weeklyTotals,
                              ),
                      ],
                    ),
                  ),
                ),

                // 3. Thanh tìm kiếm và bộ lọc danh mục
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildCategoryFilterChips(),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lịch sử chi tiêu (${filteredExpenses.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (filteredExpenses.isNotEmpty)
                              const Text(
                                'Vuốt trái để xóa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Danh sách hóa đơn ảo hóa với ListView.builder
                if (filteredExpenses.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredExpenses[index];
                          return ExpenseSummaryCard(
                            key: ValueKey(item.id),
                            item: item,
                            onTap: () {
                              context.push('/expense/${item.id}');
                            },
                            onDelete: () {
                              ref.read(expenseProvider.notifier).deleteExpense(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã xóa "${item.title}"'),
                                  action: SnackBarAction(
                                    label: 'Hoàn tác',
                                    textColor: Colors.amber,
                                    onPressed: () {
                                      ref.read(expenseProvider.notifier).addExpense(item);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: filteredExpenses.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNavy),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.roseDanger),
              const SizedBox(height: 12),
              Text(
                'Lỗi nạp dữ liệu: $err',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(expenseProvider.notifier).refresh(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        onPressed: () => context.go('/scanner'),
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: const Text(
          'Quét hóa đơn',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                'TỔNG CHI TIÊU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count hóa đơn',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormat.formatVND(total),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tự động ghi chép và phân tích trên thiết bị',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedChartTab == 0 ? AppTheme.pureWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedChartTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Cơ cấu danh mục (Donut)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedChartTab == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedChartTab == 0
                          ? AppTheme.primaryNavy
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedChartTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedChartTab == 1 ? AppTheme.pureWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _selectedChartTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Chi tiêu 7 ngày (Cột)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedChartTab == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedChartTab == 1
                          ? AppTheme.primaryNavy
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm cửa hàng, danh mục...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () => _searchController.clear(),
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    final categories = ['Tất cả', ...CategoryHelper.vietnameseNames.values];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat);
                }
              },
              selectedColor: AppTheme.primaryNavy,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              backgroundColor: AppTheme.pureWhite,
              side: BorderSide(
                color: isSelected ? AppTheme.primaryNavy : AppTheme.borderColor,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 60, color: AppTheme.textMuted),
            const SizedBox(height: 14),
            const Text(
              'Chưa tìm thấy hóa đơn nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy quét hóa đơn đầu tiên bằng máy ảnh hoặc thêm thủ công',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/scanner'),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Quét hóa đơn ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
