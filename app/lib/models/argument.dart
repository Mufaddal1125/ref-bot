import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'argument.g.dart';

@JsonSerializable()
class Argument {
  const Argument({
    required this.id,
    required this.side,
    required this.roundNumber,
    required this.body,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final Side side;
  final int roundNumber;
  final String body;
  final DateTime createdAt;
  final String? authorName;

  factory Argument.fromJson(Map<String, dynamic> json) =>
      _$ArgumentFromJson(json);

  Map<String, dynamic> toJson() => _$ArgumentToJson(this);
}
