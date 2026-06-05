import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_entity.freezed.dart';
part 'purchase_entity.g.dart';

@freezed
class PurchaseEntity with _$PurchaseEntity {
  const factory PurchaseEntity({
    required String id,
    required String productId,
    required double quantity,
    required double totalCost,
    required DateTime purchaseDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PurchaseEntity;

  factory PurchaseEntity.fromJson(Map<String, dynamic> json) => _$PurchaseEntityFromJson(json);
}
