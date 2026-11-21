import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/sapore_theme.dart';
import 'features/orders/pending_queue.dart';
import 'router.dart';

class SaporeKasirApp extends ConsumerWidget {
  const SaporeKasirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingQueueProvider); // aktifkan antrean offline sejak app dibuka
    return MaterialApp.router(
      title: 'SAPORÉ Kasir',
      debugShowCheckedModeBanner: false,
      theme: saporeTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
