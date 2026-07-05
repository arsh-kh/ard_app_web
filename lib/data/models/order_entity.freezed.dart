// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrderEntity _$OrderEntityFromJson(Map<String, dynamic> json) {
  return _OrderEntity.fromJson(json);
}

/// @nodoc
mixin _$OrderEntity {
  String get id => throw _privateConstructorUsedError;
  String? get businessId => throw _privateConstructorUsedError;
  int? get orderNumber => throw _privateConstructorUsedError;
  String get customerId => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError;
  double get totalCogs => throw _privateConstructorUsedError;
  bool get hasReturn => throw _privateConstructorUsedError;
  double get totalReturnedAmount => throw _privateConstructorUsedError;
  DateTime get orderDate => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OrderEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderEntityCopyWith<OrderEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderEntityCopyWith<$Res> {
  factory $OrderEntityCopyWith(
    OrderEntity value,
    $Res Function(OrderEntity) then,
  ) = _$OrderEntityCopyWithImpl<$Res, OrderEntity>;
  @useResult
  $Res call({
    String id,
    String? businessId,
    int? orderNumber,
    String customerId,
    double totalAmount,
    double discount,
    double totalCogs,
    bool hasReturn,
    double totalReturnedAmount,
    DateTime orderDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$OrderEntityCopyWithImpl<$Res, $Val extends OrderEntity>
    implements $OrderEntityCopyWith<$Res> {
  _$OrderEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? orderNumber = freezed,
    Object? customerId = null,
    Object? totalAmount = null,
    Object? discount = null,
    Object? totalCogs = null,
    Object? hasReturn = null,
    Object? totalReturnedAmount = null,
    Object? orderDate = null,
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
            orderNumber: freezed == orderNumber
                ? _value.orderNumber
                : orderNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            customerId: null == customerId
                ? _value.customerId
                : customerId // ignore: cast_nullable_to_non_nullable
                      as String,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            discount: null == discount
                ? _value.discount
                : discount // ignore: cast_nullable_to_non_nullable
                      as double,
            totalCogs: null == totalCogs
                ? _value.totalCogs
                : totalCogs // ignore: cast_nullable_to_non_nullable
                      as double,
            hasReturn: null == hasReturn
                ? _value.hasReturn
                : hasReturn // ignore: cast_nullable_to_non_nullable
                      as bool,
            totalReturnedAmount: null == totalReturnedAmount
                ? _value.totalReturnedAmount
                : totalReturnedAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            orderDate: null == orderDate
                ? _value.orderDate
                : orderDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
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
abstract class _$$OrderEntityImplCopyWith<$Res>
    implements $OrderEntityCopyWith<$Res> {
  factory _$$OrderEntityImplCopyWith(
    _$OrderEntityImpl value,
    $Res Function(_$OrderEntityImpl) then,
  ) = __$$OrderEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? businessId,
    int? orderNumber,
    String customerId,
    double totalAmount,
    double discount,
    double totalCogs,
    bool hasReturn,
    double totalReturnedAmount,
    DateTime orderDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$OrderEntityImplCopyWithImpl<$Res>
    extends _$OrderEntityCopyWithImpl<$Res, _$OrderEntityImpl>
    implements _$$OrderEntityImplCopyWith<$Res> {
  __$$OrderEntityImplCopyWithImpl(
    _$OrderEntityImpl _value,
    $Res Function(_$OrderEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? orderNumber = freezed,
    Object? customerId = null,
    Object? totalAmount = null,
    Object? discount = null,
    Object? totalCogs = null,
    Object? hasReturn = null,
    Object? totalReturnedAmount = null,
    Object? orderDate = null,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$OrderEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: freezed == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String?,
        orderNumber: freezed == orderNumber
            ? _value.orderNumber
            : orderNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        customerId: null == customerId
            ? _value.customerId
            : customerId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        discount: null == discount
            ? _value.discount
            : discount // ignore: cast_nullable_to_non_nullable
                  as double,
        totalCogs: null == totalCogs
            ? _value.totalCogs
            : totalCogs // ignore: cast_nullable_to_non_nullable
                  as double,
        hasReturn: null == hasReturn
            ? _value.hasReturn
            : hasReturn // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalReturnedAmount: null == totalReturnedAmount
            ? _value.totalReturnedAmount
            : totalReturnedAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        orderDate: null == orderDate
            ? _value.orderDate
            : orderDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
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
class _$OrderEntityImpl implements _OrderEntity {
  const _$OrderEntityImpl({
    required this.id,
    this.businessId,
    this.orderNumber,
    required this.customerId,
    required this.totalAmount,
    this.discount = 0.0,
    this.totalCogs = 0.0,
    this.hasReturn = false,
    this.totalReturnedAmount = 0.0,
    required this.orderDate,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory _$OrderEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String? businessId;
  @override
  final int? orderNumber;
  @override
  final String customerId;
  @override
  final double totalAmount;
  @override
  @JsonKey()
  final double discount;
  @override
  @JsonKey()
  final double totalCogs;
  @override
  @JsonKey()
  final bool hasReturn;
  @override
  @JsonKey()
  final double totalReturnedAmount;
  @override
  final DateTime orderDate;
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
    return 'OrderEntity(id: $id, businessId: $businessId, orderNumber: $orderNumber, customerId: $customerId, totalAmount: $totalAmount, discount: $discount, totalCogs: $totalCogs, hasReturn: $hasReturn, totalReturnedAmount: $totalReturnedAmount, orderDate: $orderDate, createdBy: $createdBy, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.orderNumber, orderNumber) ||
                other.orderNumber == orderNumber) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.totalCogs, totalCogs) ||
                other.totalCogs == totalCogs) &&
            (identical(other.hasReturn, hasReturn) ||
                other.hasReturn == hasReturn) &&
            (identical(other.totalReturnedAmount, totalReturnedAmount) ||
                other.totalReturnedAmount == totalReturnedAmount) &&
            (identical(other.orderDate, orderDate) ||
                other.orderDate == orderDate) &&
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
    orderNumber,
    customerId,
    totalAmount,
    discount,
    totalCogs,
    hasReturn,
    totalReturnedAmount,
    orderDate,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderEntityImplCopyWith<_$OrderEntityImpl> get copyWith =>
      __$$OrderEntityImplCopyWithImpl<_$OrderEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderEntityImplToJson(this);
  }
}

abstract class _OrderEntity implements OrderEntity {
  const factory _OrderEntity({
    required final String id,
    final String? businessId,
    final int? orderNumber,
    required final String customerId,
    required final double totalAmount,
    final double discount,
    final double totalCogs,
    final bool hasReturn,
    final double totalReturnedAmount,
    required final DateTime orderDate,
    final String? createdBy,
    final String? updatedBy,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$OrderEntityImpl;

  factory _OrderEntity.fromJson(Map<String, dynamic> json) =
      _$OrderEntityImpl.fromJson;

  @override
  String get id;
  @override
  String? get businessId;
  @override
  int? get orderNumber;
  @override
  String get customerId;
  @override
  double get totalAmount;
  @override
  double get discount;
  @override
  double get totalCogs;
  @override
  bool get hasReturn;
  @override
  double get totalReturnedAmount;
  @override
  DateTime get orderDate;
  @override
  String? get createdBy;
  @override
  String? get updatedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of OrderEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderEntityImplCopyWith<_$OrderEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
