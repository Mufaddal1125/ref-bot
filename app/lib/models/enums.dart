import 'package:json_annotation/json_annotation.dart';
import 'package:refbot_core/refbot_core.dart';

/// `wire` is the value Django sends and expects.
@JsonEnum(valueField: 'wire')
enum Side with Wire {
  teamA('team_a', 'Team A'),
  teamB('team_b', 'Team B');

  const Side(this.wire, this.label);

  @override
  final String wire;
  final String label;
}

@JsonEnum(valueField: 'wire')
enum Role with Wire {
  moderator('moderator', 'Moderator'),
  teamA('team_a', 'Team A'),
  teamB('team_b', 'Team B'),
  audience('audience', 'Audience');

  const Role(this.wire, this.label);

  @override
  final String wire;
  final String label;

  /// Which side this role argues for, or null for watchers.
  Side? get side => switch (this) {
    Role.teamA => Side.teamA,
    Role.teamB => Side.teamB,
    _ => null,
  };
}

@JsonEnum(valueField: 'wire')
enum AnalysisStatus with Wire {
  pending('pending'),
  running('running'),
  complete('complete'),
  failed('failed');

  const AnalysisStatus(this.wire);

  @override
  final String wire;

  bool get isWaiting => this == pending || this == running;
}

@JsonEnum(valueField: 'wire')
enum ClaimAssessment with Wire {
  supported('supported', 'Supported'),
  unsupported('unsupported', 'Unsupported'),
  unverifiable('unverifiable', 'Unverifiable');

  const ClaimAssessment(this.wire, this.label);

  @override
  final String wire;
  final String label;
}

@JsonEnum(valueField: 'wire')
enum DebateStatus with Wire {
  lobby('lobby'),
  active('active'),
  voting('voting'),
  closed('closed');

  const DebateStatus(this.wire);

  @override
  final String wire;
}
