import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'participant.g.dart';

@JsonSerializable()
class Participant {
  const Participant({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final Role role;

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
}
