import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/parsed_receipt.dart';
import '../screens/expense_detail_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/review_screen.dart';
import '../screens/scanner_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dash',
  routes: [
    // ShellRoute giữ thanh điều hướng dưới cố định cho các tab Home & Scanner
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/dash',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerScreen(),
        ),
      ],
    ),

    // Tuyến đường xác thực & chỉnh sửa dữ liệu OCR
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/review',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final parsed = extra['parsed'] as ParsedReceipt? ??
            const ParsedReceipt(rawText: '');
        final imagePath = extra['imagePath'] as String?;

        return ReviewScreen(
          initialData: parsed,
          imagePath: imagePath,
        );
      },
    ),

    // Tuyến đường chi tiết hóa đơn theo Dynamic Path Parameter :id
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/expense/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ExpenseDetailScreen(id: id);
      },
    ),
  ],
);
