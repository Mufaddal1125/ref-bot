// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote_tally.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoteTally _$VoteTallyFromJson(Map<String, dynamic> json) => VoteTally(
  teamA: (json['team_a'] as num?)?.toInt() ?? 0,
  teamB: (json['team_b'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$VoteTallyToJson(VoteTally instance) => <String, dynamic>{
  'team_a': instance.teamA,
  'team_b': instance.teamB,
  'total': instance.total,
};
