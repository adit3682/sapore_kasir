class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.role,
    required this.branchId,
    required this.branch,
    required this.mustChangePassword,
  });

  final int id;
  final String name;
  final String role; // owner, manager, chef, inventory, cashier
  final int? branchId;
  final String? branch;
  final bool mustChangePassword;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as int,
        name: j['name'] as String,
        role: j['role'] as String,
        branchId: j['branch_id'] as int?,
        branch: j['branch'] as String?,
        mustChangePassword: j['must_change_password'] as bool? ?? false,
      );

  /// Hanya Owner/Manager yang boleh retur (lihat OrderReturnService di backend).
  bool get canRefund => role == 'owner' || role == 'manager';
}
