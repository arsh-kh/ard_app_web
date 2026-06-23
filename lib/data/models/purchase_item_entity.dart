import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_item_entity.freezed.dart';
part 'purchase_item_entity.g.dart';

@freezed
class PurchaseItemEntity with _$PurchaseItemEntity {
  const factory PurchaseItemEntity({
    required String id,
    String? businessId,
    required String purchaseId,
    required String productId,
    required double quantity,
    required double unitPrice,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(0.0) double returnedQuantity,
  }) = _PurchaseItemEntity;

  factory PurchaseItemEntity.fromJson(Map<String, dynamic> json) =>
      _$PurchaseItemEntityFromJson(json);
}
