import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'chat_message.g.dart';

/// One line of room chat. The name and role are copied onto the message by the
/// server, so a message stays attributed even after its sender has gone.
@JsonSerializable()
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.body,
    required this.createdAt,
    this.isDeleted = false,
  });

  final String id;
  final String authorName;
  final Role authorRole;
  final String body;
  final DateTime createdAt;

  /// Removed by the moderator. The row stays, so the gap is explained.
  final bool isDeleted;

  /// What this message becomes when `chat.deleted` arrives for it.
  ChatMessage removed() => ChatMessage(
    id: id,
    authorName: authorName,
    authorRole: authorRole,
    body: '',
    createdAt: createdAt,
    isDeleted: true,
  );

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
