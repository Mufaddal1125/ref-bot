// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'argument.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Argument _$ArgumentFromJson(Map<String, dynamic> json) => Argument(
  id: json['id'] as String,
  side: $enumDecode(_$SideEnumMap, json['side']),
  roundNumber: (json['round_number'] as num).toInt(),
  body: json['body'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  authorName: json['author_name'] as String?,
);

Map<String, dynamic> _$ArgumentToJson(Argument instance) => <String, dynamic>{
  'id': instance.id,
  'side': _$SideEnumMap[instance.side]!,
  'round_number': instance.roundNumber,
  'body': instance.body,
  'created_at': instance.createdAt.toIso8601String(),
  'author_name': ?instance.authorName,
};

const _$SideEnumMap = {Side.teamA: 'team_a', Side.teamB: 'team_b'};
