// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'return_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReturnEntity _$ReturnEntityFromJson(Map<String, dynamic> json) {
  return _ReturnEntity.fromJson(json);
}

/// @nodoc
mixin _$ReturnEntity {
  String get id => throw _privateConstructorUsedError;
  String? get businessId => throw _privateConstructorUsedError;
  String get orderId => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  DateTime get returnDate => throw _privateConstructorUsedError;
  double get totalRefund => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this ReturnEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReturnEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReturnEntityCopyWith<ReturnEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReturnEntityCopyWith<$Res> {
  factory $ReturnEntityCopyWith(
    ReturnEntity value,
    $Res Function(ReturnEntity) then,
  ) = _$ReturnEntityCopyWithImpl<$Res, ReturnEntity>;
  @useResult
  $Res call({
    String id,
    String? businessId,
    String orderId,
    String customerId,
    DateTime returnDate,
    double totalRefund,
    String? notes,
    String? createdBy,
  });
}

/// @nodoc
class _$ReturnEntityCopyWithImpl<$Res, $Val extends ReturnEntity>
    implements $ReturnEntityCopyWith<$Res> {
  _$ReturnEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReturnEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? orderId = null,
    Object? customerId = null,
    Object? returnDate = null,
    Object? totalRefund = null,
    Object? notes = freezed,
    Object? createdBy = freezed,
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
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            returnDate: null == returnDate
                ? _value.returnDate
                : returnDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            totalRefund: null == totalRefund
                ? _value.totalRefund
                : totalRefund // ignore: cast_nullable_to_non_nullable
                      as double,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReturnEntityImplCopyWith<$Res>
    implements $ReturnEntityCopyWith<$Res> {
  factory _$$ReturnEntityImplCopyWith(
    _$ReturnEntityImpl value,
    $Res Function(_$ReturnEntityImpl) then,
  ) = __$$ReturnEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? businessId,
    String orderId,
    String customerId,
    DateTime returnDate,
    double totalRefund,
    String? notes,
    String? createdBy,
  });
}

/// @nodoc
class __$$ReturnEntityImplCopyWithImpl<$Res>
    extends _$ReturnEntityCopyWithImpl<$Res, _$ReturnEntityImpl>
    implements _$$ReturnEntityImplCopyWith<$Res> {
  __$$ReturnEntityImplCopyWithImpl(
    _$ReturnEntityImpl _value,
    $Res Function(_$ReturnEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReturnEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? orderId = null,
    Object? customerId = null,
    Object? returnDate = null,
    Object? totalRefund = null,
    Object? notes = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(
      _$ReturnEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: freezed == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String?,
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        returnDate: null == returnDate
            ? _value.returnDate
            : returnDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        totalRefund: null == totalRefund
            ? _value.totalRefund
            : totalRefund // ignore: cast_nullable_to_non_nullable
                  as double,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReturnEntityImpl implements _ReturnEntity {
  const _$ReturnEntityImpl({
    required this.id,
    this.businessId,
    required this.orderId,
    required this.customerId,
    required this.returnDate,
    required this.totalRefund,
    this.notes,
    this.createdBy,
  });

  factory _$ReturnEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReturnEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String? businessId;
  @override
  final String orderId;
  @override
  final String customerId;
  @override
  final DateTime returnDate;
  @override
  final double totalRefund;
  @override
  final String? notes;
  @override
  final String? createdBy;

  @override
  String toString() {
    return 'ReturnEntity(id: $id, businessId: $businessId, orderId: $orderId, customerId: $customerId, returnDate: $returnDate, totalRefund: $totalRefund, notes: $notes, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReturnEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.returnDate, returnDate) ||
                other.returnDate == returnDate) &&
            (identical(other.totalRefund, totalRefund) ||
                other.totalRefund == totalRefund) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    businessId,
    orderId,
    customerId,
    returnDate,
    totalRefund,
    notes,
    createdBy,
  );

  /// Create a copy of ReturnEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReturnEntityImplCopyWith<_$ReturnEntityImpl> get copyWith =>
      __$$ReturnEntityImplCopyWithImpl<_$ReturnEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReturnEntityImplToJson(this);
  }
}

abstract class _ReturnEntity implements ReturnEntity {
  const factory _ReturnEntity({
    required final String id,
    final String? businessId,
    required final String orderId,
    required final String customerId,
    required final DateTime returnDate,
    required final double totalRefund,
    final String? notes,
    final String? createdBy,
  }) = _$ReturnEntityImpl;

  factory _ReturnEntity.fromJson(Map<String, dynamic> json) =
      _$ReturnEntityImpl.fromJson;

  @override
  String get id;
  @override
  String? get businessId;
  @override
  String get orderId;
  @override
  String get customerId;
  @override
  DateTime get returnDate;
  @override
  double get totalRefund;
  @override
  String? get notes;
  @override
  String? get createdBy;

  /// Create a copy of ReturnEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReturnEntityImplCopyWith<_$ReturnEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
