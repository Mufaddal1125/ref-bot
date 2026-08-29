import 'package:json_annotation/json_annotation.dart';

part 'vote_tally.g.dart';

@JsonSerializable()
class VoteTally {
  const VoteTally({this.teamA = 0, this.teamB = 0, this.total = 0});

  final int teamA;
  final int teamB;
  final int total;

  /// Half each before anyone votes, so the bar opens even rather than empty.
  double get shareA => total == 0 ? 0.5 : teamA / total;

  double get shareB => 1 - shareA;

  factory VoteTally.fromJson(Map<String, dynamic> json) =>
      _$VoteTallyFromJson(json);

  Map<String, dynamic> toJson() => _$VoteTallyToJson(this);
}
