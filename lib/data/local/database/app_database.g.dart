// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserPlaceTableTable extends UserPlaceTable
    with TableInfo<$UserPlaceTableTable, UserPlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPlaceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
    'custom_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<int> radiusM = GeneratedColumn<int>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(150),
  );
  @override
  late final GeneratedColumnWithTypeConverter<UserPlaceSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UserPlaceSource>($UserPlaceTableTable.$convertersource);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    customName,
    lat,
    lng,
    radiusM,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_name'],
      ),
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}radius_m'],
      )!,
      source: $UserPlaceTableTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserPlaceTableTable createAlias(String alias) {
    return $UserPlaceTableTable(attachedDatabase, alias);
  }

  static TypeConverter<UserPlaceSource, String> $convertersource =
      const UserPlaceSourceConverter();
}

class UserPlaceRow extends DataClass implements Insertable<UserPlaceRow> {
  final int id;

  /// `home` / `work` / `school` / `other` / a custom label.
  final String label;
  final String? customName;
  final double? lat;
  final double? lng;

  /// Geofence radius in meters. Unused until geofencing exists (Phase 3+).
  final int radiusM;
  final UserPlaceSource source;
  final DateTime createdAt;
  const UserPlaceRow({
    required this.id,
    required this.label,
    this.customName,
    this.lat,
    this.lng,
    required this.radiusM,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    map['radius_m'] = Variable<int>(radiusM);
    {
      map['source'] = Variable<String>(
        $UserPlaceTableTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserPlaceTableCompanion toCompanion(bool nullToAbsent) {
    return UserPlaceTableCompanion(
      id: Value(id),
      label: Value(label),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      radiusM: Value(radiusM),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory UserPlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPlaceRow(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      customName: serializer.fromJson<String?>(json['customName']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      radiusM: serializer.fromJson<int>(json['radiusM']),
      source: serializer.fromJson<UserPlaceSource>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'customName': serializer.toJson<String?>(customName),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'radiusM': serializer.toJson<int>(radiusM),
      'source': serializer.toJson<UserPlaceSource>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserPlaceRow copyWith({
    int? id,
    String? label,
    Value<String?> customName = const Value.absent(),
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    int? radiusM,
    UserPlaceSource? source,
    DateTime? createdAt,
  }) => UserPlaceRow(
    id: id ?? this.id,
    label: label ?? this.label,
    customName: customName.present ? customName.value : this.customName,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    radiusM: radiusM ?? this.radiusM,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  UserPlaceRow copyWithCompanion(UserPlaceTableCompanion data) {
    return UserPlaceRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPlaceRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('customName: $customName, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('radiusM: $radiusM, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, customName, lat, lng, radiusM, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPlaceRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.customName == this.customName &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.radiusM == this.radiusM &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class UserPlaceTableCompanion extends UpdateCompanion<UserPlaceRow> {
  final Value<int> id;
  final Value<String> label;
  final Value<String?> customName;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<int> radiusM;
  final Value<UserPlaceSource> source;
  final Value<DateTime> createdAt;
  const UserPlaceTableCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.customName = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserPlaceTableCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    this.customName = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.radiusM = const Value.absent(),
    required UserPlaceSource source,
    required DateTime createdAt,
  }) : label = Value(label),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<UserPlaceRow> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<String>? customName,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<int>? radiusM,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (customName != null) 'custom_name': customName,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusM != null) 'radius_m': radiusM,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserPlaceTableCompanion copyWith({
    Value<int>? id,
    Value<String>? label,
    Value<String?>? customName,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<int>? radiusM,
    Value<UserPlaceSource>? source,
    Value<DateTime>? createdAt,
  }) {
    return UserPlaceTableCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      customName: customName ?? this.customName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<int>(radiusM.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $UserPlaceTableTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPlaceTableCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('customName: $customName, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('radiusM: $radiusM, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NoteTableTable extends NoteTable
    with TableInfo<$NoteTableTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskDescriptionMeta = const VerificationMeta(
    'taskDescription',
  );
  @override
  late final GeneratedColumn<String> taskDescription = GeneratedColumn<String>(
    'task_description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TriggerType, String> triggerType =
      GeneratedColumn<String>(
        'trigger_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TriggerType>($NoteTableTable.$convertertriggerType);
  @override
  late final GeneratedColumnWithTypeConverter<LocationKind?, String>
  locationKind = GeneratedColumn<String>(
    'location_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocationKind?>($NoteTableTable.$converterlocationKind);
  @override
  late final GeneratedColumnWithTypeConverter<GeofenceTransition?, String>
  geofenceTransition =
      GeneratedColumn<String>(
        'geofence_transition',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<GeofenceTransition?>(
        $NoteTableTable.$convertergeofenceTransition,
      );
  static const VerificationMeta _resolvedDatetimeMeta = const VerificationMeta(
    'resolvedDatetime',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedDatetime =
      GeneratedColumn<DateTime>(
        'resolved_datetime',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NoteStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NoteStatus>($NoteTableTable.$converterstatus);
  static const VerificationMeta _userPlaceIdMeta = const VerificationMeta(
    'userPlaceId',
  );
  @override
  late final GeneratedColumn<int> userPlaceId = GeneratedColumn<int>(
    'user_place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_places (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawText,
    taskDescription,
    triggerType,
    locationKind,
    geofenceTransition,
    resolvedDatetime,
    recurrenceRule,
    confidence,
    status,
    userPlaceId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('task_description')) {
      context.handle(
        _taskDescriptionMeta,
        taskDescription.isAcceptableOrUnknown(
          data['task_description']!,
          _taskDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taskDescriptionMeta);
    }
    if (data.containsKey('resolved_datetime')) {
      context.handle(
        _resolvedDatetimeMeta,
        resolvedDatetime.isAcceptableOrUnknown(
          data['resolved_datetime']!,
          _resolvedDatetimeMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('user_place_id')) {
      context.handle(
        _userPlaceIdMeta,
        userPlaceId.isAcceptableOrUnknown(
          data['user_place_id']!,
          _userPlaceIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      taskDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_description'],
      )!,
      triggerType: $NoteTableTable.$convertertriggerType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}trigger_type'],
        )!,
      ),
      locationKind: $NoteTableTable.$converterlocationKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}location_kind'],
        ),
      ),
      geofenceTransition: $NoteTableTable.$convertergeofenceTransition.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}geofence_transition'],
        ),
      ),
      resolvedDatetime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_datetime'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      status: $NoteTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      userPlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_place_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NoteTableTable createAlias(String alias) {
    return $NoteTableTable(attachedDatabase, alias);
  }

  static TypeConverter<TriggerType, String> $convertertriggerType =
      const TriggerTypeConverter();
  static TypeConverter<LocationKind?, String?> $converterlocationKind =
      const LocationKindConverter();
  static TypeConverter<GeofenceTransition?, String?>
  $convertergeofenceTransition = const GeofenceTransitionConverter();
  static TypeConverter<NoteStatus, String> $converterstatus =
      const NoteStatusConverter();
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;

  /// What the user typed.
  final String rawText;

  /// Phase 1 mirrors [rawText] unless edited; Phase 2 replaces it with the
  /// AI-parsed task text.
  final String taskDescription;
  final TriggerType triggerType;

  /// Null in Phase 1 — no location triggers yet.
  final LocationKind? locationKind;

  /// Null in Phase 1.
  final GeofenceTransition? geofenceTransition;

  /// Set when [triggerType] resolves to a time.
  final DateTime? resolvedDatetime;

  /// RRULE string. No UI in Phase 1.
  final String? recurrenceRule;

  /// From the AI parse; null for manually-entered notes.
  final double? confidence;
  final NoteStatus status;

  /// FK to [UserPlaceTable]. Unused until Phase 3.
  final int? userPlaceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteRow({
    required this.id,
    required this.rawText,
    required this.taskDescription,
    required this.triggerType,
    this.locationKind,
    this.geofenceTransition,
    this.resolvedDatetime,
    this.recurrenceRule,
    this.confidence,
    required this.status,
    this.userPlaceId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['task_description'] = Variable<String>(taskDescription);
    {
      map['trigger_type'] = Variable<String>(
        $NoteTableTable.$convertertriggerType.toSql(triggerType),
      );
    }
    if (!nullToAbsent || locationKind != null) {
      map['location_kind'] = Variable<String>(
        $NoteTableTable.$converterlocationKind.toSql(locationKind),
      );
    }
    if (!nullToAbsent || geofenceTransition != null) {
      map['geofence_transition'] = Variable<String>(
        $NoteTableTable.$convertergeofenceTransition.toSql(geofenceTransition),
      );
    }
    if (!nullToAbsent || resolvedDatetime != null) {
      map['resolved_datetime'] = Variable<DateTime>(resolvedDatetime);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    {
      map['status'] = Variable<String>(
        $NoteTableTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || userPlaceId != null) {
      map['user_place_id'] = Variable<int>(userPlaceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NoteTableCompanion toCompanion(bool nullToAbsent) {
    return NoteTableCompanion(
      id: Value(id),
      rawText: Value(rawText),
      taskDescription: Value(taskDescription),
      triggerType: Value(triggerType),
      locationKind: locationKind == null && nullToAbsent
          ? const Value.absent()
          : Value(locationKind),
      geofenceTransition: geofenceTransition == null && nullToAbsent
          ? const Value.absent()
          : Value(geofenceTransition),
      resolvedDatetime: resolvedDatetime == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedDatetime),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      status: Value(status),
      userPlaceId: userPlaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(userPlaceId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      taskDescription: serializer.fromJson<String>(json['taskDescription']),
      triggerType: serializer.fromJson<TriggerType>(json['triggerType']),
      locationKind: serializer.fromJson<LocationKind?>(json['locationKind']),
      geofenceTransition: serializer.fromJson<GeofenceTransition?>(
        json['geofenceTransition'],
      ),
      resolvedDatetime: serializer.fromJson<DateTime?>(
        json['resolvedDatetime'],
      ),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      status: serializer.fromJson<NoteStatus>(json['status']),
      userPlaceId: serializer.fromJson<int?>(json['userPlaceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rawText': serializer.toJson<String>(rawText),
      'taskDescription': serializer.toJson<String>(taskDescription),
      'triggerType': serializer.toJson<TriggerType>(triggerType),
      'locationKind': serializer.toJson<LocationKind?>(locationKind),
      'geofenceTransition': serializer.toJson<GeofenceTransition?>(
        geofenceTransition,
      ),
      'resolvedDatetime': serializer.toJson<DateTime?>(resolvedDatetime),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'confidence': serializer.toJson<double?>(confidence),
      'status': serializer.toJson<NoteStatus>(status),
      'userPlaceId': serializer.toJson<int?>(userPlaceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteRow copyWith({
    int? id,
    String? rawText,
    String? taskDescription,
    TriggerType? triggerType,
    Value<LocationKind?> locationKind = const Value.absent(),
    Value<GeofenceTransition?> geofenceTransition = const Value.absent(),
    Value<DateTime?> resolvedDatetime = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    NoteStatus? status,
    Value<int?> userPlaceId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteRow(
    id: id ?? this.id,
    rawText: rawText ?? this.rawText,
    taskDescription: taskDescription ?? this.taskDescription,
    triggerType: triggerType ?? this.triggerType,
    locationKind: locationKind.present ? locationKind.value : this.locationKind,
    geofenceTransition: geofenceTransition.present
        ? geofenceTransition.value
        : this.geofenceTransition,
    resolvedDatetime: resolvedDatetime.present
        ? resolvedDatetime.value
        : this.resolvedDatetime,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    confidence: confidence.present ? confidence.value : this.confidence,
    status: status ?? this.status,
    userPlaceId: userPlaceId.present ? userPlaceId.value : this.userPlaceId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NoteRow copyWithCompanion(NoteTableCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      taskDescription: data.taskDescription.present
          ? data.taskDescription.value
          : this.taskDescription,
      triggerType: data.triggerType.present
          ? data.triggerType.value
          : this.triggerType,
      locationKind: data.locationKind.present
          ? data.locationKind.value
          : this.locationKind,
      geofenceTransition: data.geofenceTransition.present
          ? data.geofenceTransition.value
          : this.geofenceTransition,
      resolvedDatetime: data.resolvedDatetime.present
          ? data.resolvedDatetime.value
          : this.resolvedDatetime,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      status: data.status.present ? data.status.value : this.status,
      userPlaceId: data.userPlaceId.present
          ? data.userPlaceId.value
          : this.userPlaceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('taskDescription: $taskDescription, ')
          ..write('triggerType: $triggerType, ')
          ..write('locationKind: $locationKind, ')
          ..write('geofenceTransition: $geofenceTransition, ')
          ..write('resolvedDatetime: $resolvedDatetime, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('userPlaceId: $userPlaceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawText,
    taskDescription,
    triggerType,
    locationKind,
    geofenceTransition,
    resolvedDatetime,
    recurrenceRule,
    confidence,
    status,
    userPlaceId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.taskDescription == this.taskDescription &&
          other.triggerType == this.triggerType &&
          other.locationKind == this.locationKind &&
          other.geofenceTransition == this.geofenceTransition &&
          other.resolvedDatetime == this.resolvedDatetime &&
          other.recurrenceRule == this.recurrenceRule &&
          other.confidence == this.confidence &&
          other.status == this.status &&
          other.userPlaceId == this.userPlaceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NoteTableCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<String> rawText;
  final Value<String> taskDescription;
  final Value<TriggerType> triggerType;
  final Value<LocationKind?> locationKind;
  final Value<GeofenceTransition?> geofenceTransition;
  final Value<DateTime?> resolvedDatetime;
  final Value<String?> recurrenceRule;
  final Value<double?> confidence;
  final Value<NoteStatus> status;
  final Value<int?> userPlaceId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NoteTableCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.taskDescription = const Value.absent(),
    this.triggerType = const Value.absent(),
    this.locationKind = const Value.absent(),
    this.geofenceTransition = const Value.absent(),
    this.resolvedDatetime = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.confidence = const Value.absent(),
    this.status = const Value.absent(),
    this.userPlaceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NoteTableCompanion.insert({
    this.id = const Value.absent(),
    required String rawText,
    required String taskDescription,
    required TriggerType triggerType,
    this.locationKind = const Value.absent(),
    this.geofenceTransition = const Value.absent(),
    this.resolvedDatetime = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.confidence = const Value.absent(),
    required NoteStatus status,
    this.userPlaceId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : rawText = Value(rawText),
       taskDescription = Value(taskDescription),
       triggerType = Value(triggerType),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<String>? rawText,
    Expression<String>? taskDescription,
    Expression<String>? triggerType,
    Expression<String>? locationKind,
    Expression<String>? geofenceTransition,
    Expression<DateTime>? resolvedDatetime,
    Expression<String>? recurrenceRule,
    Expression<double>? confidence,
    Expression<String>? status,
    Expression<int>? userPlaceId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (taskDescription != null) 'task_description': taskDescription,
      if (triggerType != null) 'trigger_type': triggerType,
      if (locationKind != null) 'location_kind': locationKind,
      if (geofenceTransition != null) 'geofence_transition': geofenceTransition,
      if (resolvedDatetime != null) 'resolved_datetime': resolvedDatetime,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (confidence != null) 'confidence': confidence,
      if (status != null) 'status': status,
      if (userPlaceId != null) 'user_place_id': userPlaceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NoteTableCompanion copyWith({
    Value<int>? id,
    Value<String>? rawText,
    Value<String>? taskDescription,
    Value<TriggerType>? triggerType,
    Value<LocationKind?>? locationKind,
    Value<GeofenceTransition?>? geofenceTransition,
    Value<DateTime?>? resolvedDatetime,
    Value<String?>? recurrenceRule,
    Value<double?>? confidence,
    Value<NoteStatus>? status,
    Value<int?>? userPlaceId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NoteTableCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      taskDescription: taskDescription ?? this.taskDescription,
      triggerType: triggerType ?? this.triggerType,
      locationKind: locationKind ?? this.locationKind,
      geofenceTransition: geofenceTransition ?? this.geofenceTransition,
      resolvedDatetime: resolvedDatetime ?? this.resolvedDatetime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      userPlaceId: userPlaceId ?? this.userPlaceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (taskDescription.present) {
      map['task_description'] = Variable<String>(taskDescription.value);
    }
    if (triggerType.present) {
      map['trigger_type'] = Variable<String>(
        $NoteTableTable.$convertertriggerType.toSql(triggerType.value),
      );
    }
    if (locationKind.present) {
      map['location_kind'] = Variable<String>(
        $NoteTableTable.$converterlocationKind.toSql(locationKind.value),
      );
    }
    if (geofenceTransition.present) {
      map['geofence_transition'] = Variable<String>(
        $NoteTableTable.$convertergeofenceTransition.toSql(
          geofenceTransition.value,
        ),
      );
    }
    if (resolvedDatetime.present) {
      map['resolved_datetime'] = Variable<DateTime>(resolvedDatetime.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $NoteTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (userPlaceId.present) {
      map['user_place_id'] = Variable<int>(userPlaceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTableCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('taskDescription: $taskDescription, ')
          ..write('triggerType: $triggerType, ')
          ..write('locationKind: $locationKind, ')
          ..write('geofenceTransition: $geofenceTransition, ')
          ..write('resolvedDatetime: $resolvedDatetime, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('confidence: $confidence, ')
          ..write('status: $status, ')
          ..write('userPlaceId: $userPlaceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserPlaceTableTable userPlaceTable = $UserPlaceTableTable(this);
  late final $NoteTableTable noteTable = $NoteTableTable(this);
  late final NoteDao noteDao = NoteDao(this as AppDatabase);
  late final UserPlaceDao userPlaceDao = UserPlaceDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userPlaceTable,
    noteTable,
  ];
}

typedef $$UserPlaceTableTableCreateCompanionBuilder =
    UserPlaceTableCompanion Function({
      Value<int> id,
      required String label,
      Value<String?> customName,
      Value<double?> lat,
      Value<double?> lng,
      Value<int> radiusM,
      required UserPlaceSource source,
      required DateTime createdAt,
    });
typedef $$UserPlaceTableTableUpdateCompanionBuilder =
    UserPlaceTableCompanion Function({
      Value<int> id,
      Value<String> label,
      Value<String?> customName,
      Value<double?> lat,
      Value<double?> lng,
      Value<int> radiusM,
      Value<UserPlaceSource> source,
      Value<DateTime> createdAt,
    });

final class $$UserPlaceTableTableReferences
    extends BaseReferences<_$AppDatabase, $UserPlaceTableTable, UserPlaceRow> {
  $$UserPlaceTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$NoteTableTable, List<NoteRow>>
  _noteTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.noteTable,
    aliasName: 'user_places__id__notes__user_place_id',
  );

  $$NoteTableTableProcessedTableManager get noteTableRefs {
    final manager = $$NoteTableTableTableManager(
      $_db,
      $_db.noteTable,
    ).filter((f) => f.userPlaceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserPlaceTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPlaceTableTable> {
  $$UserPlaceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UserPlaceSource, UserPlaceSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> noteTableRefs(
    Expression<bool> Function($$NoteTableTableFilterComposer f) f,
  ) {
    final $$NoteTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTable,
      getReferencedColumn: (t) => t.userPlaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTableTableFilterComposer(
            $db: $db,
            $table: $db.noteTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserPlaceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPlaceTableTable> {
  $$UserPlaceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPlaceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPlaceTableTable> {
  $$UserPlaceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<int> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UserPlaceSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> noteTableRefs<T extends Object>(
    Expression<T> Function($$NoteTableTableAnnotationComposer a) f,
  ) {
    final $$NoteTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTable,
      getReferencedColumn: (t) => t.userPlaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTableTableAnnotationComposer(
            $db: $db,
            $table: $db.noteTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserPlaceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPlaceTableTable,
          UserPlaceRow,
          $$UserPlaceTableTableFilterComposer,
          $$UserPlaceTableTableOrderingComposer,
          $$UserPlaceTableTableAnnotationComposer,
          $$UserPlaceTableTableCreateCompanionBuilder,
          $$UserPlaceTableTableUpdateCompanionBuilder,
          (UserPlaceRow, $$UserPlaceTableTableReferences),
          UserPlaceRow,
          PrefetchHooks Function({bool noteTableRefs})
        > {
  $$UserPlaceTableTableTableManager(
    _$AppDatabase db,
    $UserPlaceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPlaceTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPlaceTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPlaceTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> customName = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<int> radiusM = const Value.absent(),
                Value<UserPlaceSource> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UserPlaceTableCompanion(
                id: id,
                label: label,
                customName: customName,
                lat: lat,
                lng: lng,
                radiusM: radiusM,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String label,
                Value<String?> customName = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<int> radiusM = const Value.absent(),
                required UserPlaceSource source,
                required DateTime createdAt,
              }) => UserPlaceTableCompanion.insert(
                id: id,
                label: label,
                customName: customName,
                lat: lat,
                lng: lng,
                radiusM: radiusM,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserPlaceTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (noteTableRefs) db.noteTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (noteTableRefs)
                    await $_getPrefetchedData<
                      UserPlaceRow,
                      $UserPlaceTableTable,
                      NoteRow
                    >(
                      currentTable: table,
                      referencedTable: $$UserPlaceTableTableReferences
                          ._noteTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserPlaceTableTableReferences(
                            db,
                            table,
                            p0,
                          ).noteTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.userPlaceId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserPlaceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPlaceTableTable,
      UserPlaceRow,
      $$UserPlaceTableTableFilterComposer,
      $$UserPlaceTableTableOrderingComposer,
      $$UserPlaceTableTableAnnotationComposer,
      $$UserPlaceTableTableCreateCompanionBuilder,
      $$UserPlaceTableTableUpdateCompanionBuilder,
      (UserPlaceRow, $$UserPlaceTableTableReferences),
      UserPlaceRow,
      PrefetchHooks Function({bool noteTableRefs})
    >;
typedef $$NoteTableTableCreateCompanionBuilder = NoteTableCompanion Function({
  Value<int> id,
  required String rawText,
  required String taskDescription,
  required TriggerType triggerType,
  Value<LocationKind?> locationKind,
  Value<GeofenceTransition?> geofenceTransition,
  Value<DateTime?> resolvedDatetime,
  Value<String?> recurrenceRule,
  Value<double?> confidence,
  required NoteStatus status,
  Value<int?> userPlaceId,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$NoteTableTableUpdateCompanionBuilder = NoteTableCompanion Function({
  Value<int> id,
  Value<String> rawText,
  Value<String> taskDescription,
  Value<TriggerType> triggerType,
  Value<LocationKind?> locationKind,
  Value<GeofenceTransition?> geofenceTransition,
  Value<DateTime?> resolvedDatetime,
  Value<String?> recurrenceRule,
  Value<double?> confidence,
  Value<NoteStatus> status,
  Value<int?> userPlaceId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$NoteTableTableReferences
    extends BaseReferences<_$AppDatabase, $NoteTableTable, NoteRow> {
  $$NoteTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UserPlaceTableTable _userPlaceIdTable(_$AppDatabase db) =>
      db.userPlaceTable.createAlias('notes__user_place_id__user_places__id');

  $$UserPlaceTableTableProcessedTableManager? get userPlaceId {
    final $_column = $_itemColumn<int>('user_place_id');
    if ($_column == null) return null;
    final manager = $$UserPlaceTableTableTableManager(
      $_db,
      $_db.userPlaceTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userPlaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NoteTableTableFilterComposer
    extends Composer<_$AppDatabase, $NoteTableTable> {
  $$NoteTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskDescription => $composableBuilder(
    column: $table.taskDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TriggerType, TriggerType, String>
  get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<LocationKind?, LocationKind, String>
  get locationKind => $composableBuilder(
    column: $table.locationKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    GeofenceTransition?,
    GeofenceTransition,
    String
  >
  get geofenceTransition => $composableBuilder(
    column: $table.geofenceTransition,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get resolvedDatetime => $composableBuilder(
    column: $table.resolvedDatetime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NoteStatus, NoteStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UserPlaceTableTableFilterComposer get userPlaceId {
    final $$UserPlaceTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userPlaceId,
      referencedTable: $db.userPlaceTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPlaceTableTableFilterComposer(
            $db: $db,
            $table: $db.userPlaceTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteTableTable> {
  $$NoteTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskDescription => $composableBuilder(
    column: $table.taskDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggerType => $composableBuilder(
    column: $table.triggerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationKind => $composableBuilder(
    column: $table.locationKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geofenceTransition => $composableBuilder(
    column: $table.geofenceTransition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedDatetime => $composableBuilder(
    column: $table.resolvedDatetime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserPlaceTableTableOrderingComposer get userPlaceId {
    final $$UserPlaceTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userPlaceId,
      referencedTable: $db.userPlaceTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPlaceTableTableOrderingComposer(
            $db: $db,
            $table: $db.userPlaceTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteTableTable> {
  $$NoteTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get taskDescription => $composableBuilder(
    column: $table.taskDescription,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TriggerType, String> get triggerType =>
      $composableBuilder(
        column: $table.triggerType,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<LocationKind?, String> get locationKind =>
      $composableBuilder(
        column: $table.locationKind,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<GeofenceTransition?, String>
  get geofenceTransition => $composableBuilder(
    column: $table.geofenceTransition,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedDatetime => $composableBuilder(
    column: $table.resolvedDatetime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<NoteStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UserPlaceTableTableAnnotationComposer get userPlaceId {
    final $$UserPlaceTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userPlaceId,
      referencedTable: $db.userPlaceTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPlaceTableTableAnnotationComposer(
            $db: $db,
            $table: $db.userPlaceTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteTableTable,
          NoteRow,
          $$NoteTableTableFilterComposer,
          $$NoteTableTableOrderingComposer,
          $$NoteTableTableAnnotationComposer,
          $$NoteTableTableCreateCompanionBuilder,
          $$NoteTableTableUpdateCompanionBuilder,
          (NoteRow, $$NoteTableTableReferences),
          NoteRow,
          PrefetchHooks Function({bool userPlaceId})
        > {
  $$NoteTableTableTableManager(_$AppDatabase db, $NoteTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> taskDescription = const Value.absent(),
                Value<TriggerType> triggerType = const Value.absent(),
                Value<LocationKind?> locationKind = const Value.absent(),
                Value<GeofenceTransition?> geofenceTransition =
                    const Value.absent(),
                Value<DateTime?> resolvedDatetime = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<NoteStatus> status = const Value.absent(),
                Value<int?> userPlaceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => NoteTableCompanion(
                id: id,
                rawText: rawText,
                taskDescription: taskDescription,
                triggerType: triggerType,
                locationKind: locationKind,
                geofenceTransition: geofenceTransition,
                resolvedDatetime: resolvedDatetime,
                recurrenceRule: recurrenceRule,
                confidence: confidence,
                status: status,
                userPlaceId: userPlaceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String rawText,
                required String taskDescription,
                required TriggerType triggerType,
                Value<LocationKind?> locationKind = const Value.absent(),
                Value<GeofenceTransition?> geofenceTransition =
                    const Value.absent(),
                Value<DateTime?> resolvedDatetime = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                required NoteStatus status,
                Value<int?> userPlaceId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => NoteTableCompanion.insert(
                id: id,
                rawText: rawText,
                taskDescription: taskDescription,
                triggerType: triggerType,
                locationKind: locationKind,
                geofenceTransition: geofenceTransition,
                resolvedDatetime: resolvedDatetime,
                recurrenceRule: recurrenceRule,
                confidence: confidence,
                status: status,
                userPlaceId: userPlaceId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NoteTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userPlaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userPlaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userPlaceId,
                        referencedTable: $$NoteTableTableReferences
                            ._userPlaceIdTable(db),
                        referencedColumn: $$NoteTableTableReferences
                            ._userPlaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteTableTable,
      NoteRow,
      $$NoteTableTableFilterComposer,
      $$NoteTableTableOrderingComposer,
      $$NoteTableTableAnnotationComposer,
      $$NoteTableTableCreateCompanionBuilder,
      $$NoteTableTableUpdateCompanionBuilder,
      (NoteRow, $$NoteTableTableReferences),
      NoteRow,
      PrefetchHooks Function({bool userPlaceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserPlaceTableTableTableManager get userPlaceTable =>
      $$UserPlaceTableTableTableManager(_db, _db.userPlaceTable);
  $$NoteTableTableTableManager get noteTable =>
      $$NoteTableTableTableManager(_db, _db.noteTable);
}
