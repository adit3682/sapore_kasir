/// Menu atau paket di katalog kasir (GET /catalog).
class CatalogItem {
  CatalogItem({
    required this.type,
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.price,
    required this.isActive,
  });

  final String type; // 'menu' | 'package'
  final int id;
  final String code;
  final String name;
  final String? category;
  final num price;
  final bool isActive;

  /// Kunci unik: id menu dan id paket bisa sama.
  String get key => '$type-$id';

  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
        type: j['type'] as String,
        id: j['id'] as int,
        code: j['code'] as String,
        name: j['name'] as String,
        category: j['category'] as String?,
        price: num.parse('${j['price']}'), // server mengirim string desimal
        isActive: j['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'code': code,
        'name': name,
        'category': category,
        'price': price.toString(),
        'is_active': isActive,
      };
}
