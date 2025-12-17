import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de garantia local
class LocalCollateral {
  final String tierId;
  final String tierName;
  final int requiredSats;
  final int lockedSats;
  final int activeOrders;
  final double maxOrderBrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalCollateral({
    required this.tierId,
    required this.tierName,
    required this.requiredSats,
    required this.lockedSats,
    required this.activeOrders,
    required this.maxOrderBrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocalCollateral.fromJson(Map<String, dynamic> json) {
    return LocalCollateral(
      tierId: json['tier_id'] ?? '',
      tierName: json['tier_name'] ?? '',
      requiredSats: json['required_sats'] ?? 0,
      lockedSats: json['locked_sats'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      maxOrderBrl: (json['max_order_brl'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier_id': tierId,
      'tier_name': tierName,
      'required_sats': requiredSats,
      'locked_sats': lockedSats,
      'active_orders': activeOrders,
      'max_order_brl': maxOrderBrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LocalCollateral copyWith({
    String? tierId,
    String? tierName,
    int? requiredSats,
    int? lockedSats,
    int? activeOrders,
    double? maxOrderBrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalCollateral(
      tierId: tierId ?? this.tierId,
      tierName: tierName ?? this.tierName,
      requiredSats: requiredSats ?? this.requiredSats,
      lockedSats: lockedSats ?? this.lockedSats,
      activeOrders: activeOrders ?? this.activeOrders,
      maxOrderBrl: maxOrderBrl ?? this.maxOrderBrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Serviço para gerenciar garantia LOCAL do provedor
/// A garantia é uma "reserva contábil" - o provedor precisa manter esse saldo
/// na carteira para poder aceitar ordens.
/// 
/// Fluxo:
/// 1. Provedor escolhe um tier e "deposita" (reserva sats da própria carteira)
/// 2. Enquanto tiver a garantia reservada, pode aceitar ordens até o limite do tier
/// 3. Quando aceita uma ordem, parte da garantia fica "travada" para aquela ordem
/// 4. Se a ordem for concluída com sucesso, a garantia é liberada
/// 5. Se houver disputa e o provedor perder, a garantia é confiscada
/// 6. Provedor pode "sacar" (remover reserva) se não tiver ordens em aberto
class LocalCollateralService {
  static const String _collateralKey = 'local_collateral';

  /// Configurar garantia para um tier
  Future<LocalCollateral> setCollateral({
    required String tierId,
    required String tierName,
    required int requiredSats,
    required double maxOrderBrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final collateral = LocalCollateral(
      tierId: tierId,
      tierName: tierName,
      requiredSats: requiredSats,
      lockedSats: requiredSats, // Trava o valor requerido
      activeOrders: 0,
      maxOrderBrl: maxOrderBrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await prefs.setString(_collateralKey, json.encode(collateral.toJson()));
    debugPrint('✅ Garantia local configurada: $tierName ($requiredSats sats)');
    
    return collateral;
  }

  /// Obter garantia atual
  Future<LocalCollateral?> getCollateral() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_collateralKey);
      
      if (dataStr == null) return null;
      
      return LocalCollateral.fromJson(json.decode(dataStr));
    } catch (e) {
      debugPrint('❌ Erro ao carregar garantia local: $e');
      return null;
    }
  }

  /// Verificar se tem garantia configurada
  Future<bool> hasCollateral() async {
    final collateral = await getCollateral();
    return collateral != null;
  }

  /// Verificar se pode aceitar uma ordem de determinado valor
  bool canAcceptOrder(LocalCollateral collateral, double orderValueBrl, int walletBalanceSats) {
    // Verificar se carteira tem saldo suficiente para a garantia
    if (walletBalanceSats < collateral.lockedSats) {
      debugPrint('❌ canAcceptOrder: Saldo insuficiente ($walletBalanceSats < ${collateral.lockedSats})');
      return false;
    }
    
    // Verificar se valor da ordem está dentro do limite do tier
    if (orderValueBrl > collateral.maxOrderBrl) {
      debugPrint('❌ canAcceptOrder: Ordem R\$ $orderValueBrl > limite R\$ ${collateral.maxOrderBrl}');
      return false;
    }
    
    debugPrint('✅ canAcceptOrder: OK');
    return true;
  }

  /// Travar garantia para uma ordem
  Future<LocalCollateral> lockForOrder(LocalCollateral collateral, String orderId) async {
    final updated = collateral.copyWith(
      activeOrders: collateral.activeOrders + 1,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collateralKey, json.encode(updated.toJson()));
    
    debugPrint('🔒 Ordem $orderId travada. Total ordens: ${updated.activeOrders}');
    return updated;
  }

  /// Destravar garantia de uma ordem
  Future<LocalCollateral> unlockOrder(LocalCollateral collateral, String orderId) async {
    final newActiveOrders = collateral.activeOrders > 0 ? collateral.activeOrders - 1 : 0;
    
    final updated = collateral.copyWith(
      activeOrders: newActiveOrders,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collateralKey, json.encode(updated.toJson()));
    
    debugPrint('🔓 Ordem $orderId liberada. Total ordens: ${updated.activeOrders}');
    return updated;
  }

  /// Obter saldo disponível (carteira - travado)
  int getAvailableBalance(LocalCollateral collateral, int walletBalanceSats) {
    final available = walletBalanceSats - collateral.lockedSats;
    return available > 0 ? available : 0;
  }

  /// Verificar se pode sacar (remover garantia)
  bool canWithdraw(LocalCollateral collateral) {
    return collateral.activeOrders == 0;
  }

  /// Remover garantia completamente
  Future<void> withdrawAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collateralKey);
    debugPrint('✅ Garantia local removida');
  }
}
