import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_entity.freezed.dart';
part 'purchase_entity.g.dart';

@freezed
class PurchaseEntity with _$PurchaseEntity {
  const factory PurchaseEntity({
    required String id,
    String? businessId,
    int? purchaseNumber,
    String? supplierId,
    required double totalAmount,
    @Default(0.0) double discount,
    @Default(0.0) double deliveryFee,
    required DateTime purchaseDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool hasReturn,
    @Default(0.0) double totalReturnedAmount,
  }) = _PurchaseEntity;

  factory PurchaseEntity.fromJson(Map<String, dynamic> json) =>
      _$PurchaseEntityFromJson(json);
}
