import 'package:freezed_annotation/freezed_annotation.dart';

part 'return_item_entity.freezed.dart';
part 'return_item_entity.g.dart';

@freezed
class ReturnItemEntity with _$ReturnItemEntity {
  const ReturnItemEntity._();

  const factory ReturnItemEntity({
    required String id,
    String? businessId,
    required String returnId,
    required String productId,
    required String productName,
    required String unitType,
    required double unitPrice,
    required double returnedQty,
  }) = _ReturnItemEntity;

  double get lineRefund => unitPrice * returnedQty;

  factory ReturnItemEntity.fromJson(Map<String, dynamic> json) =>
      _$ReturnItemEntityFromJson(json);
}
