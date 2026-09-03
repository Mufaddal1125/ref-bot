// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  authorName: json['author_name'] as String,
  authorRole: $enumDecode(_$RoleEnumMap, json['author_role']),
  body: json['body'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_name': instance.authorName,
      'author_role': _$RoleEnumMap[instance.authorRole]!,
      'body': instance.body,
      'created_at': instance.createdAt.toIso8601String(),
      'is_deleted': instance.isDeleted,
    };

const _$RoleEnumMap = {
  Role.moderator: 'moderator',
  Role.teamA: 'team_a',
  Role.teamB: 'team_b',
  Role.audience: 'audience',
};
