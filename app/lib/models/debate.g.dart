// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debate _$DebateFromJson(Map<String, dynamic> json) => Debate(
  id: json['id'] as String,
  topic: json['topic'] as String,
  joinCode: json['join_code'] as String,
  status: $enumDecode(_$DebateStatusEnumMap, json['status']),
  currentSide: $enumDecode(_$SideEnumMap, json['current_side']),
  currentRound: (json['current_round'] as num).toInt(),
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  arguments:
      (json['arguments'] as List<dynamic>?)
          ?.map((e) => Argument.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DebateToJson(Debate instance) => <String, dynamic>{
  'id': instance.id,
  'topic': instance.topic,
  'join_code': instance.joinCode,
  'status': _$DebateStatusEnumMap[instance.status]!,
  'current_side': _$SideEnumMap[instance.currentSide]!,
  'current_round': instance.currentRound,
  'participants': instance.participants,
  'arguments': instance.arguments,
};

const _$DebateStatusEnumMap = {
  DebateStatus.lobby: 'lobby',
  DebateStatus.active: 'active',
  DebateStatus.voting: 'voting',
  DebateStatus.closed: 'closed',
};

const _$SideEnumMap = {Side.teamA: 'team_a', Side.teamB: 'team_b'};
