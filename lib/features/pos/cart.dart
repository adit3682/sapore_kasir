import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_item.dart';

class CartLine {
  const CartLine(this.item, this.qty);
  final CatalogItem item;
  final int qty;
  num get total => item.price * qty;
}

class CartState {
  const CartState([this.lines = const []]);
  final List<CartLine> lines;
  num get subtotal => lines.fold<num>(0, (s, l) => s + l.total);
  int get count => lines.fold(0, (s, l) => s + l.qty);
  bool get isEmpty => lines.isEmpty;
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void add(CatalogItem item) {
    final i = state.lines.indexWhere((l) => l.item.key == item.key);
    final lines = [...state.lines];
    if (i < 0) {
      lines.add(CartLine(item, 1));
    } else {
      lines[i] = CartLine(item, lines[i].qty + 1);
    }
    state = CartState(lines);
  }

  void decrement(String key) {
    final lines = <CartLine>[];
    for (final l in state.lines) {
      if (l.item.key != key) {
        lines.add(l);
      } else if (l.qty > 1) {
        lines.add(CartLine(l.item, l.qty - 1));
      }
    }
    state = CartState(lines);
  }

  void remove(String key) =>
      state = CartState(state.lines.where((l) => l.item.key != key).toList());

  void clear() => state = const CartState();
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
