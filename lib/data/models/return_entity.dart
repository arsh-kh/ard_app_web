import 'package:freezed_annotation/freezed_annotation.dart';

part 'return_entity.freezed.dart';
part 'return_entity.g.dart';

@freezed
class ReturnEntity with _$ReturnEntity {
  const factory ReturnEntity({
    required String id,
    String? businessId,
    required String orderId,
    required String customerId,
    required DateTime returnDate,
    required double totalRefund,
    String? notes,
    String? createdBy,
  }) = _ReturnEntity;

  factory ReturnEntity.fromJson(Map<String, dynamic> json) =>
      _$ReturnEntityFromJson(json);
}
