import 'package:flutter_test/flutter_test.dart';
import 'package:sapore_kasir/features/catalog/catalog_item.dart';
import 'package:sapore_kasir/features/auth/auth_models.dart';

void main() {
  test('CatalogItem mem-parse harga string desimal dan membuat key unik', () {
    final it = CatalogItem.fromJson({
      'type': 'package', 'id': 3, 'code': 'PK-1', 'name': 'Paket Family A',
      'category': 'Paket', 'price': '125000.00', 'is_active': true,
    });
    expect(it.price, 125000);
    expect(it.key, 'package-3');
  });

  test('AuthUser: hanya owner/manager boleh retur', () {
    AuthUser u(String role) => AuthUser(id: 1, name: 'x', role: role, branchId: 1, branch: 'A', mustChangePassword: false);
    expect(u('owner').canRefund, isTrue);
    expect(u('manager').canRefund, isTrue);
    expect(u('cashier').canRefund, isFalse);
  });
}
