import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_entity.freezed.dart';
part 'business_entity.g.dart';

@freezed
class BusinessEntity with _$BusinessEntity {
  const factory BusinessEntity({
    required String id,
    required String name,
    required String nameLower,
    required String inviteCode,
    required String ownerId,
    DateTime? createdAt,
  }) = _BusinessEntity;

  factory BusinessEntity.fromJson(Map<String, dynamic> json) =>
      _$BusinessEntityFromJson(json);
}
