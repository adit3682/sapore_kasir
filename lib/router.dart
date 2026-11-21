import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/change_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/orders/order_detail_page.dart';
import 'features/orders/orders_history_page.dart';
import 'features/orders/pay_order_page.dart';
import 'features/orders/pending_orders_page.dart';
import 'features/orders/receipt_page.dart';
import 'features/orders/return_page.dart';
import 'features/pos/checkout_page.dart';
import 'features/printing/printer_settings_page.dart';
import 'features/pos/pos_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Router ikut dievaluasi ulang setiap status auth berubah.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      switch (status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.signedOut:
          return loc == '/login' ? null : '/login';
        case AuthStatus.mustChangePassword:
          return loc == '/change-password' ? null : '/change-password';
        case AuthStatus.signedIn:
          return (loc == '/splash' || loc == '/login' || loc == '/change-password') ? '/pos' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordPage()),
      GoRoute(path: '/pos', builder: (_, __) => const PosPage()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingOrdersPage()),
      GoRoute(path: '/printer', builder: (_, __) => const PrinterSettingsPage()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersHistoryPage()),
      GoRoute(path: '/orders/:uuid', builder: (_, st) => OrderDetailPage(uuid: st.pathParameters['uuid']!)),
      GoRoute(path: '/orders/:uuid/return', builder: (_, st) => ReturnPage(uuid: st.pathParameters['uuid']!)),
      GoRoute(path: '/orders/:uuid/pay', builder: (_, st) => PayOrderPage(uuid: st.pathParameters['uuid']!)),
      GoRoute(
        path: '/orders/:uuid/returns/:returnUuid/receipt',
        builder: (_, st) => ReceiptPage(uuid: st.pathParameters['uuid']!, returnUuid: st.pathParameters['returnUuid']),
      ),
      GoRoute(path: '/orders/:uuid/receipt', builder: (_, st) => ReceiptPage(uuid: st.pathParameters['uuid']!)),
    ],
  );
});
