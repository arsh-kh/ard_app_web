import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_entity.freezed.dart';
part 'customer_entity.g.dart';

@freezed
class CustomerEntity with _$CustomerEntity {
  const factory CustomerEntity({
    required String id,
    String? businessId,
    String? userId,
    required String businessName,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    required double debtBalance,
    String? imageUrl,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CustomerEntity;

  factory CustomerEntity.fromJson(Map<String, dynamic> json) =>
      _$CustomerEntityFromJson(json);
}
