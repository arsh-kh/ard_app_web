// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PurchaseEntity _$PurchaseEntityFromJson(Map<String, dynamic> json) {
  return _PurchaseEntity.fromJson(json);
}

/// @nodoc
mixin _$PurchaseEntity {
  String get id => throw _privateConstructorUsedError;
  String? get businessId => throw _privateConstructorUsedError;
  int? get purchaseNumber => throw _privateConstructorUsedError;
  String? get supplierId => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'received', 'cancelled'
  double get totalAmount => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError;
  double get deliveryFee => throw _privateConstructorUsedError;
  DateTime get purchaseDate => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  String? get updatedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  bool get hasReturn => throw _privateConstructorUsedError;
  double get totalReturnedAmount => throw _privateConstructorUsedError;

  /// Serializes this PurchaseEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PurchaseEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PurchaseEntityCopyWith<PurchaseEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseEntityCopyWith<$Res> {
  factory $PurchaseEntityCopyWith(
    PurchaseEntity value,
    $Res Function(PurchaseEntity) then,
  ) = _$PurchaseEntityCopyWithImpl<$Res, PurchaseEntity>;
  @useResult
  $Res call({
    String id,
    String? businessId,
    int? purchaseNumber,
    String? supplierId,
    String status,
    double totalAmount,
    double discount,
    double deliveryFee,
    DateTime purchaseDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool hasReturn,
    double totalReturnedAmount,
  });
}

/// @nodoc
class _$PurchaseEntityCopyWithImpl<$Res, $Val extends PurchaseEntity>
    implements $PurchaseEntityCopyWith<$Res> {
  _$PurchaseEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PurchaseEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? purchaseNumber = freezed,
    Object? supplierId = freezed,
    Object? status = null,
    Object? totalAmount = null,
    Object? discount = null,
    Object? deliveryFee = null,
    Object? purchaseDate = null,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? hasReturn = null,
    Object? totalReturnedAmount = null,
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
            purchaseNumber: freezed == purchaseNumber
                ? _value.purchaseNumber
                : purchaseNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            supplierId: freezed == supplierId
                ? _value.supplierId
                : supplierId // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            discount: null == discount
                ? _value.discount
                : discount // ignore: cast_nullable_to_non_nullable
                      as double,
            deliveryFee: null == deliveryFee
                ? _value.deliveryFee
                : deliveryFee // ignore: cast_nullable_to_non_nullable
                      as double,
            purchaseDate: null == purchaseDate
                ? _value.purchaseDate
                : purchaseDate // ignore: cast_nullable_to_non_nullable
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
            hasReturn: null == hasReturn
                ? _value.hasReturn
                : hasReturn // ignore: cast_nullable_to_non_nullable
                      as bool,
            totalReturnedAmount: null == totalReturnedAmount
                ? _value.totalReturnedAmount
                : totalReturnedAmount // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PurchaseEntityImplCopyWith<$Res>
    implements $PurchaseEntityCopyWith<$Res> {
  factory _$$PurchaseEntityImplCopyWith(
    _$PurchaseEntityImpl value,
    $Res Function(_$PurchaseEntityImpl) then,
  ) = __$$PurchaseEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? businessId,
    int? purchaseNumber,
    String? supplierId,
    String status,
    double totalAmount,
    double discount,
    double deliveryFee,
    DateTime purchaseDate,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool hasReturn,
    double totalReturnedAmount,
  });
}

/// @nodoc
class __$$PurchaseEntityImplCopyWithImpl<$Res>
    extends _$PurchaseEntityCopyWithImpl<$Res, _$PurchaseEntityImpl>
    implements _$$PurchaseEntityImplCopyWith<$Res> {
  __$$PurchaseEntityImplCopyWithImpl(
    _$PurchaseEntityImpl _value,
    $Res Function(_$PurchaseEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PurchaseEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? purchaseNumber = freezed,
    Object? supplierId = freezed,
    Object? status = null,
    Object? totalAmount = null,
    Object? discount = null,
    Object? deliveryFee = null,
    Object? purchaseDate = null,
    Object? createdBy = freezed,
    Object? updatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? hasReturn = null,
    Object? totalReturnedAmount = null,
  }) {
    return _then(
      _$PurchaseEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: freezed == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String?,
        purchaseNumber: freezed == purchaseNumber
            ? _value.purchaseNumber
            : purchaseNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        supplierId: freezed == supplierId
            ? _value.supplierId
            : supplierId // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        discount: null == discount
            ? _value.discount
            : discount // ignore: cast_nullable_to_non_nullable
                  as double,
        deliveryFee: null == deliveryFee
            ? _value.deliveryFee
            : deliveryFee // ignore: cast_nullable_to_non_nullable
                  as double,
        purchaseDate: null == purchaseDate
            ? _value.purchaseDate
            : purchaseDate // ignore: cast_nullable_to_non_nullable
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
        hasReturn: null == hasReturn
            ? _value.hasReturn
            : hasReturn // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalReturnedAmount: null == totalReturnedAmount
            ? _value.totalReturnedAmount
            : totalReturnedAmount // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseEntityImpl implements _PurchaseEntity {
  const _$PurchaseEntityImpl({
    required this.id,
    this.businessId,
    this.purchaseNumber,
    this.supplierId,
    required this.status,
    required this.totalAmount,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
    required this.purchaseDate,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.hasReturn = false,
    this.totalReturnedAmount = 0.0,
  });

  factory _$PurchaseEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String? businessId;
  @override
  final int? purchaseNumber;
  @override
  final String? supplierId;
  @override
  final String status;
  // 'pending', 'received', 'cancelled'
  @override
  final double totalAmount;
  @override
  @JsonKey()
  final double discount;
  @override
  @JsonKey()
  final double deliveryFee;
  @override
  final DateTime purchaseDate;
  @override
  final String? createdBy;
  @override
  final String? updatedBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final bool hasReturn;
  @override
  @JsonKey()
  final double totalReturnedAmount;

  @override
  String toString() {
    return 'PurchaseEntity(id: $id, businessId: $businessId, purchaseNumber: $purchaseNumber, supplierId: $supplierId, status: $status, totalAmount: $totalAmount, discount: $discount, deliveryFee: $deliveryFee, purchaseDate: $purchaseDate, createdBy: $createdBy, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt, hasReturn: $hasReturn, totalReturnedAmount: $totalReturnedAmount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.purchaseNumber, purchaseNumber) ||
                other.purchaseNumber == purchaseNumber) &&
            (identical(other.supplierId, supplierId) ||
                other.supplierId == supplierId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.deliveryFee, deliveryFee) ||
                other.deliveryFee == deliveryFee) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.hasReturn, hasReturn) ||
                other.hasReturn == hasReturn) &&
            (identical(other.totalReturnedAmount, totalReturnedAmount) ||
                other.totalReturnedAmount == totalReturnedAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    businessId,
    purchaseNumber,
    supplierId,
    status,
    totalAmount,
    discount,
    deliveryFee,
    purchaseDate,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
    hasReturn,
    totalReturnedAmount,
  );

  /// Create a copy of PurchaseEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseEntityImplCopyWith<_$PurchaseEntityImpl> get copyWith =>
      __$$PurchaseEntityImplCopyWithImpl<_$PurchaseEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseEntityImplToJson(this);
  }
}

abstract class _PurchaseEntity implements PurchaseEntity {
  const factory _PurchaseEntity({
    required final String id,
    final String? businessId,
    final int? purchaseNumber,
    final String? supplierId,
    required final String status,
    required final double totalAmount,
    final double discount,
    final double deliveryFee,
    required final DateTime purchaseDate,
    final String? createdBy,
    final String? updatedBy,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final bool hasReturn,
    final double totalReturnedAmount,
  }) = _$PurchaseEntityImpl;

  factory _PurchaseEntity.fromJson(Map<String, dynamic> json) =
      _$PurchaseEntityImpl.fromJson;

  @override
  String get id;
  @override
  String? get businessId;
  @override
  int? get purchaseNumber;
  @override
  String? get supplierId;
  @override
  String get status; // 'pending', 'received', 'cancelled'
  @override
  double get totalAmount;
  @override
  double get discount;
  @override
  double get deliveryFee;
  @override
  DateTime get purchaseDate;
  @override
  String? get createdBy;
  @override
  String? get updatedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  bool get hasReturn;
  @override
  double get totalReturnedAmount;

  /// Create a copy of PurchaseEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseEntityImplCopyWith<_$PurchaseEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
