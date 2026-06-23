import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_entity.freezed.dart';
part 'payment_entity.g.dart';

@freezed
class PaymentEntity with _$PaymentEntity {
  const factory PaymentEntity({
    required String id,
    String? businessId,
    required String customerId,
    required double amount,
    required DateTime paymentDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PaymentEntity;

  factory PaymentEntity.fromJson(Map<String, dynamic> json) =>
      _$PaymentEntityFromJson(json);
}
