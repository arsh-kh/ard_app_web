import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_item_entity.freezed.dart';
part 'order_item_entity.g.dart';

@freezed
class OrderItemEntity with _$OrderItemEntity {
  const factory OrderItemEntity({
    required String id,
    String? businessId,
    required String orderId,
    required String productId,
    required double quantity,
    @Default(0.0) double returnedQuantity,
    required double unitPrice,
    @Default(0.0) double buyPrice,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OrderItemEntity;

  factory OrderItemEntity.fromJson(Map<String, dynamic> json) =>
      _$OrderItemEntityFromJson(json);
}
