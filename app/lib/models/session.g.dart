// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  debate: Debate.fromJson(json['debate'] as Map<String, dynamic>),
  participant: Participant.fromJson(
    json['participant'] as Map<String, dynamic>,
  ),
  token: json['token'] as String,
);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'debate': instance.debate,
  'participant': instance.participant,
  'token': instance.token,
};
