import 'package:json_annotation/json_annotation.dart';

import 'argument.dart';
import 'enums.dart';
import 'participant.dart';

part 'debate.g.dart';

@JsonSerializable()
class Debate {
  const Debate({
    required this.id,
    required this.topic,
    required this.joinCode,
    required this.status,
    required this.currentSide,
    required this.currentRound,
    this.participants = const [],
    this.arguments = const [],
  });

  final String id;
  final String topic;
  final String joinCode;
  final DebateStatus status;
  final Side currentSide;
  final int currentRound;
  final List<Participant> participants;
  final List<Argument> arguments;

  /// Whether somebody in this role may submit right now.
  bool isTurnOf(Role role) =>
      status == DebateStatus.active && role.side == currentSide;

  factory Debate.fromJson(Map<String, dynamic> json) => _$DebateFromJson(json);

  Map<String, dynamic> toJson() => _$DebateToJson(this);
}
