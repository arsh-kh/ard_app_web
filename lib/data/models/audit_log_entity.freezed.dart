// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuditLogEntity _$AuditLogEntityFromJson(Map<String, dynamic> json) {
  return _AuditLogEntity.fromJson(json);
}

/// @nodoc
mixin _$AuditLogEntity {
  String get id => throw _privateConstructorUsedError;
  String? get businessId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get entityType => throw _privateConstructorUsedError;
  String get entityId => throw _privateConstructorUsedError;
  String? get details => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this AuditLogEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuditLogEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuditLogEntityCopyWith<AuditLogEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuditLogEntityCopyWith<$Res> {
  factory $AuditLogEntityCopyWith(
    AuditLogEntity value,
    $Res Function(AuditLogEntity) then,
  ) = _$AuditLogEntityCopyWithImpl<$Res, AuditLogEntity>;
  @useResult
  $Res call({
    String id,
    String? businessId,
    String userId,
    String userName,
    String action,
    String entityType,
    String entityId,
    String? details,
    Map<String, dynamic>? metadata,
    DateTime timestamp,
  });
}

/// @nodoc
class _$AuditLogEntityCopyWithImpl<$Res, $Val extends AuditLogEntity>
    implements $AuditLogEntityCopyWith<$Res> {
  _$AuditLogEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuditLogEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? userId = null,
    Object? userName = null,
    Object? action = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? details = freezed,
    Object? metadata = freezed,
    Object? timestamp = null,
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
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            entityType: null == entityType
                ? _value.entityType
                : entityType // ignore: cast_nullable_to_non_nullable
                      as String,
            entityId: null == entityId
                ? _value.entityId
                : entityId // ignore: cast_nullable_to_non_nullable
                      as String,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as String?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuditLogEntityImplCopyWith<$Res>
    implements $AuditLogEntityCopyWith<$Res> {
  factory _$$AuditLogEntityImplCopyWith(
    _$AuditLogEntityImpl value,
    $Res Function(_$AuditLogEntityImpl) then,
  ) = __$$AuditLogEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? businessId,
    String userId,
    String userName,
    String action,
    String entityType,
    String entityId,
    String? details,
    Map<String, dynamic>? metadata,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$AuditLogEntityImplCopyWithImpl<$Res>
    extends _$AuditLogEntityCopyWithImpl<$Res, _$AuditLogEntityImpl>
    implements _$$AuditLogEntityImplCopyWith<$Res> {
  __$$AuditLogEntityImplCopyWithImpl(
    _$AuditLogEntityImpl _value,
    $Res Function(_$AuditLogEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuditLogEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = freezed,
    Object? userId = null,
    Object? userName = null,
    Object? action = null,
    Object? entityType = null,
    Object? entityId = null,
    Object? details = freezed,
    Object? metadata = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _$AuditLogEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        businessId: freezed == businessId
            ? _value.businessId
            : businessId // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        entityType: null == entityType
            ? _value.entityType
            : entityType // ignore: cast_nullable_to_non_nullable
                  as String,
        entityId: null == entityId
            ? _value.entityId
            : entityId // ignore: cast_nullable_to_non_nullable
                  as String,
        details: freezed == details
            ? _value.details
            : details // ignore: cast_nullable_to_non_nullable
                  as String?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuditLogEntityImpl implements _AuditLogEntity {
  const _$AuditLogEntityImpl({
    required this.id,
    this.businessId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    final Map<String, dynamic>? metadata,
    required this.timestamp,
  }) : _metadata = metadata;

  factory _$AuditLogEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuditLogEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String? businessId;
  @override
  final String userId;
  @override
  final String userName;
  @override
  final String action;
  @override
  final String entityType;
  @override
  final String entityId;
  @override
  final String? details;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'AuditLogEntity(id: $id, businessId: $businessId, userId: $userId, userName: $userName, action: $action, entityType: $entityType, entityId: $entityId, details: $details, metadata: $metadata, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuditLogEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.entityType, entityType) ||
                other.entityType == entityType) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.details, details) || other.details == details) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    businessId,
    userId,
    userName,
    action,
    entityType,
    entityId,
    details,
    const DeepCollectionEquality().hash(_metadata),
    timestamp,
  );

  /// Create a copy of AuditLogEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuditLogEntityImplCopyWith<_$AuditLogEntityImpl> get copyWith =>
      __$$AuditLogEntityImplCopyWithImpl<_$AuditLogEntityImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuditLogEntityImplToJson(this);
  }
}

abstract class _AuditLogEntity implements AuditLogEntity {
  const factory _AuditLogEntity({
    required final String id,
    final String? businessId,
    required final String userId,
    required final String userName,
    required final String action,
    required final String entityType,
    required final String entityId,
    final String? details,
    final Map<String, dynamic>? metadata,
    required final DateTime timestamp,
  }) = _$AuditLogEntityImpl;

  factory _AuditLogEntity.fromJson(Map<String, dynamic> json) =
      _$AuditLogEntityImpl.fromJson;

  @override
  String get id;
  @override
  String? get businessId;
  @override
  String get userId;
  @override
  String get userName;
  @override
  String get action;
  @override
  String get entityType;
  @override
  String get entityId;
  @override
  String? get details;
  @override
  Map<String, dynamic>? get metadata;
  @override
  DateTime get timestamp;

  /// Create a copy of AuditLogEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuditLogEntityImplCopyWith<_$AuditLogEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
