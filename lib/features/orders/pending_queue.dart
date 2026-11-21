import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_controller.dart';
import 'orders_repository.dart';

enum PendingStatus { pending, needsAttention }

class PendingOrder {
  PendingOrder({
    required this.uuid,
    required this.payload,
    required this.createdAt,
    this.status = PendingStatus.pending,
    this.error,
  });

  final String uuid;
  final Map<String, dynamic> payload; // body POST /orders lengkap dengan `pay`
  final DateTime createdAt;
  final PendingStatus status;
  final String? error;

  String get methodCode => ((payload['pay'] as Map?)?['method'] as String?) ?? '-';
  int get itemCount =>
      ((payload['items'] as List?) ?? const []).fold<int>(0, (s, i) => s + ((i as Map)['qty'] as int));

  PendingOrder copyWith({PendingStatus? status, String? error}) => PendingOrder(
        uuid: uuid,
        payload: payload,
        createdAt: createdAt,
        status: status ?? this.status,
        error: error ?? this.error,
      );

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'error': error,
      };

  factory PendingOrder.fromJson(Map<String, dynamic> j) => PendingOrder(
        uuid: j['uuid'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['created_at'] as String),
        status: PendingStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => PendingStatus.pending),
        error: j['error'] as String?,
      );
}

/// Antrean order offline. Disimpan di perangkat; dikirim ulang otomatis
/// (tiap 30 detik, saat login, dan lewat tombol manual).
class PendingQueue extends Notifier<List<PendingOrder>> {
  static const _key = 'pending_orders_v1';
  Future<void>? _ready;
  bool _flushing = false;

  @override
  List<PendingOrder> build() {
    _ready = _load();
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_signedIn && state.any((p) => p.status == PendingStatus.pending)) flush();
    });
    ref.onDispose(timer.cancel);
    ref.listen(authControllerProvider, (_, next) {
      if (next.status == AuthStatus.signedIn) flush();
    });
    return const [];
  }

  bool get _signedIn => ref.read(authControllerProvider).status == AuthStatus.signedIn;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return;
    state = (jsonDecode(raw) as List).map((e) => PendingOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _set(List<PendingOrder> list) async {
    state = list;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> load() => _ready ??= _load();

  Future<void> enqueue(Map<String, dynamic> payload, {bool autoFlush = true}) async {
    await _ready;
    final uuid = payload['uuid'] as String;
    if (state.any((p) => p.uuid == uuid)) return;
    await _set([...state, PendingOrder(uuid: uuid, payload: payload, createdAt: DateTime.now())]);
    if (autoFlush) flush();
  }

  Future<void> discard(String uuid) async => _set(state.where((p) => p.uuid != uuid).toList());

  Future<void> flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      await _ready;
      final repo = ref.read(ordersRepositoryProvider);
      for (final p in List.of(state)) {
        if (p.status != PendingStatus.pending) continue;
        try {
          await repo.submitFull(p.payload);
          await _set(state.where((e) => e.uuid != p.uuid).toList());
        } on ApiException catch (e) {
          if (e.isUnauthorized || e.isPasswordChangeRequired || e.retryable) return; // coba lagi nanti
          // Ditolak server (mis. uang kurang): jangan diulang otomatis, butuh keputusan manusia.
          await _set([for (final x in state) x.uuid == p.uuid ? x.copyWith(status: PendingStatus.needsAttention, error: e.message) : x]);
        }
      }
    } finally {
      _flushing = false;
    }
  }
}

final pendingQueueProvider = NotifierProvider<PendingQueue, List<PendingOrder>>(PendingQueue.new);
