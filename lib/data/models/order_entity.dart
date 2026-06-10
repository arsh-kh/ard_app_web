import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_entity.freezed.dart';
part 'order_entity.g.dart';

@freezed
class OrderEntity with _$OrderEntity {
  const factory OrderEntity({
    required String id,
    int? orderNumber,
    required String customerId,
    required String status,
    required double totalAmount,
    @Default(0.0) double discount,
    @Default(false) bool hasReturn,
    @Default(0.0) double totalReturnedAmount,
    required DateTime orderDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OrderEntity;

  factory OrderEntity.fromJson(Map<String, dynamic> json) => _$OrderEntityFromJson(json);
}
