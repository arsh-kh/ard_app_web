import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_return_item_entity.freezed.dart';
part 'purchase_return_item_entity.g.dart';

@freezed
class PurchaseReturnItemEntity with _$PurchaseReturnItemEntity {
  const factory PurchaseReturnItemEntity({
    required String id,
    String? businessId,
    required String returnId,
    required String productId,
    required String productName,
    required String unitType,
    required double unitPrice,
    required double returnedQty,
  }) = _PurchaseReturnItemEntity;

  factory PurchaseReturnItemEntity.fromJson(Map<String, dynamic> json) =>
      _$PurchaseReturnItemEntityFromJson(json);
}
