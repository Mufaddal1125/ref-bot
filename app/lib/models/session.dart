import 'package:json_annotation/json_annotation.dart';

import 'debate.dart';
import 'participant.dart';

part 'session.g.dart';

/// What create and join hand back: who you are, and the key to come back with.
@JsonSerializable()
class Session {
  const Session({
    required this.debate,
    required this.participant,
    required this.token,
  });

  final Debate debate;
  final Participant participant;
  final String token;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  Map<String, dynamic> toJson() => _$SessionToJson(this);
}
