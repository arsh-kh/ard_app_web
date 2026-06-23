// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomerEntity _$CustomerEntityFromJson(Map<String, dynamic> json) {
  return _CustomerEntity.fromJson(json);
}

/// @nodoc
mixin _$CustomerEntity {
  String get id => throw _privateConstructorUsedError;
  String? get businessId => throw _privateConstructorUsedError;
  String? get userId => throw _privateConstructorUsedError;
  String get businessName => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  double get debtBalance => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CustomerEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomerEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomerEntityCopyWith<CustomerEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomerEntityCopyWith<$Res> {
  factory $CustomerEntityCopyWith(
    CustomerEntity value,
    $Res Function(CustomerEntity) then,
  ) = _$CustomerEntityCopyWithImpl<$Res, CustomerEntity>;
  @useResult
  $Res call({
    String id,
    String? businessId,
    String? userId,
    String businessName,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    double debtBalance,
    String? imageUrl,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$CustomerEntityCopyWithImpl<$Res, $Val extends CustomerEntity>
    implements $CustomerEntityCopyWith<$Res> {
  _$CustomerEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomerEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? userId = freezed,
    Object? businessName = null,
    Object? phone = freezed,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? debtBalance = null,
    Object? imageUrl = freezed,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            businessId: freezed == businessId
                ? _value.businessId
                : businessId // ignore: cast_nullable_to_non_nullable
                      as String?,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            businessName: null == businessName
                ? _value.businessName
                : businessName // ignore: cast_nullable_to_non_nullable
                      as String,
            phone: freezed == phone
                ? _value.phone
                : phone // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            debtBalance: null == debtBalance
                ? _value.debtBalance
                : debtBalance // ignore: cast_nullable_to_non_nullable
                      as double,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedBy: freezed == updatedBy
                ? _value.updatedBy
                : updatedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomerEntityImplCopyWith<$Res>
    implements $CustomerEntityCopyWith<$Res> {
  factory _$$CustomerEntityImplCopyWith(
    _$CustomerEntityImpl value,
    $Res Function(_$CustomerEntityImpl) then,
  ) = __$$CustomerEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? businessId,
    String? userId,
    String businessName,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    double debtBalance,
    String? imageUrl,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$CustomerEntityImplCopyWithImpl<$Res>
    extends _$CustomerEntityCopyWithImpl<$Res, _$CustomerEntityImpl>
    implements _$$CustomerEntityImplCopyWith<$Res> {
  __$$CustomerEntityImplCopyWithImpl(
    _$CustomerEntityImpl _value,
    $Res Function(_$CustomerEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomerEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? userId = freezed,
    Object? businessName = null,
    Object? phone = freezed,
    Object? address = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? debtBalance = null,
    Object? imageUrl = freezed,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$CustomerEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: freezed == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        businessName: null == businessName
            ? _value.businessName
            : businessName // ignore: cast_nullable_to_non_nullable
                  as String,
        phone: freezed == phone
            ? _value.phone
            : phone // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        debtBalance: null == debtBalance
            ? _value.debtBalance
            : debtBalance // ignore: cast_nullable_to_non_nullable
                  as double,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedBy: freezed == updatedBy
            ? _value.updatedBy
            : updatedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomerEntityImpl implements _CustomerEntity {
  const _$CustomerEntityImpl({
    required this.id,
    this.businessId,
    this.userId,
    required this.businessName,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    required this.debtBalance,
    this.imageUrl,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory _$CustomerEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomerEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String? businessId;
  @override
  final String? userId;
  @override
  final String businessName;
  @override
  final String? phone;
  @override
  final String? address;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final double debtBalance;
  @override
  final String? imageUrl;
  @override
  final String? createdBy;
  @override
  final String? updatedBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CustomerEntity(id: $id, businessId: $businessId, userId: $userId, businessName: $businessName, phone: $phone, address: $address, latitude: $latitude, longitude: $longitude, debtBalance: $debtBalance, imageUrl: $imageUrl, createdBy: $createdBy, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomerEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.debtBalance, debtBalance) ||
                other.debtBalance == debtBalance) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    businessId,
    userId,
    businessName,
    phone,
    address,
    latitude,
    longitude,
    debtBalance,
    imageUrl,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of CustomerEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomerEntityImplCopyWith<_$CustomerEntityImpl> get copyWith =>
      __$$CustomerEntityImplCopyWithImpl<_$CustomerEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomerEntityImplToJson(this);
  }
}

abstract class _CustomerEntity implements CustomerEntity {
  const factory _CustomerEntity({
    required final String id,
    final String? businessId,
    final String? userId,
    required final String businessName,
    final String? phone,
    final String? address,
    final double? latitude,
    final double? longitude,
    required final double debtBalance,
    final String? imageUrl,
    final String? createdBy,
    final String? updatedBy,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$CustomerEntityImpl;

  factory _CustomerEntity.fromJson(Map<String, dynamic> json) =
      _$CustomerEntityImpl.fromJson;

  @override
  String get id;
  @override
  String? get businessId;
  @override
  String? get userId;
  @override
  String get businessName;
  @override
  String? get phone;
  @override
  String? get address;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  double get debtBalance;
  @override
  String? get imageUrl;
  @override
  String? get createdBy;
  @override
  String? get updatedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of CustomerEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomerEntityImplCopyWith<_$CustomerEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
