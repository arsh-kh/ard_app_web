// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BusinessEntity _$BusinessEntityFromJson(Map<String, dynamic> json) {
  return _BusinessEntity.fromJson(json);
}

/// @nodoc
mixin _$BusinessEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get inviteCode => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this BusinessEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BusinessEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusinessEntityCopyWith<BusinessEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusinessEntityCopyWith<$Res> {
  factory $BusinessEntityCopyWith(
    BusinessEntity value,
    $Res Function(BusinessEntity) then,
  ) = _$BusinessEntityCopyWithImpl<$Res, BusinessEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String inviteCode,
    String ownerId,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$BusinessEntityCopyWithImpl<$Res, $Val extends BusinessEntity>
    implements $BusinessEntityCopyWith<$Res> {
  _$BusinessEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusinessEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? inviteCode = null,
    Object? ownerId = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            inviteCode: null == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                      as String,
            ownerId: null == ownerId
                ? _value.ownerId
                : ownerId // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BusinessEntityImplCopyWith<$Res>
    implements $BusinessEntityCopyWith<$Res> {
  factory _$$BusinessEntityImplCopyWith(
    _$BusinessEntityImpl value,
    $Res Function(_$BusinessEntityImpl) then,
  ) = __$$BusinessEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String inviteCode,
    String ownerId,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$BusinessEntityImplCopyWithImpl<$Res>
    extends _$BusinessEntityCopyWithImpl<$Res, _$BusinessEntityImpl>
    implements _$$BusinessEntityImplCopyWith<$Res> {
  __$$BusinessEntityImplCopyWithImpl(
    _$BusinessEntityImpl _value,
    $Res Function(_$BusinessEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusinessEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? inviteCode = null,
    Object? ownerId = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$BusinessEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        inviteCode: null == inviteCode
            ? _value.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerId: null == ownerId
            ? _value.ownerId
            : ownerId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BusinessEntityImpl implements _BusinessEntity {
  const _$BusinessEntityImpl({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    this.createdAt,
  });

  factory _$BusinessEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusinessEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String inviteCode;
  @override
  final String ownerId;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'BusinessEntity(id: $id, name: $name, inviteCode: $inviteCode, ownerId: $ownerId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusinessEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, inviteCode, ownerId, createdAt);

  /// Create a copy of BusinessEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusinessEntityImplCopyWith<_$BusinessEntityImpl> get copyWith =>
      __$$BusinessEntityImplCopyWithImpl<_$BusinessEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BusinessEntityImplToJson(this);
  }
}

abstract class _BusinessEntity implements BusinessEntity {
  const factory _BusinessEntity({
    required final String id,
    required final String name,
    required final String inviteCode,
    required final String ownerId,
    final DateTime? createdAt,
  }) = _$BusinessEntityImpl;

  factory _BusinessEntity.fromJson(Map<String, dynamic> json) =
      _$BusinessEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get inviteCode;
  @override
  String get ownerId;
  @override
  DateTime? get createdAt;

  /// Create a copy of BusinessEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusinessEntityImplCopyWith<_$BusinessEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
