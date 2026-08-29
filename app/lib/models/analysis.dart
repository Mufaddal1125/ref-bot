import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'analysis.g.dart';

@JsonSerializable()
class Claim {
  const Claim({
    required this.text,
    required this.assessment,
    required this.note,
  });

  final String text;
  final ClaimAssessment assessment;
  final String note;

  factory Claim.fromJson(Map<String, dynamic> json) => _$ClaimFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimToJson(this);
}

@JsonSerializable()
class MissingContext {
  const MissingContext({required this.text});

  final String text;

  factory MissingContext.fromJson(Map<String, dynamic> json) =>
      _$MissingContextFromJson(json);

  Map<String, dynamic> toJson() => _$MissingContextToJson(this);
}

@JsonSerializable()
class Fallacy {
  const Fallacy({required this.name, required this.explanation});

  final String name;
  final String explanation;

  factory Fallacy.fromJson(Map<String, dynamic> json) => _$FallacyFromJson(json);

  Map<String, dynamic> toJson() => _$FallacyToJson(this);
}

/// What the referee found. The same shape the Pydantic schema defines.
@JsonSerializable()
class RefereeAnalysis {
  const RefereeAnalysis({
    this.claims = const [],
    this.missingContext = const [],
    this.fallacies = const [],
  });

  final List<Claim> claims;
  final List<MissingContext> missingContext;
  final List<Fallacy> fallacies;

  int get findings => claims.length + missingContext.length + fallacies.length;

  factory RefereeAnalysis.fromJson(Map<String, dynamic> json) =>
      _$RefereeAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$RefereeAnalysisToJson(this);
}

/// The referee's work on one argument: how it went, and what it found.
@JsonSerializable()
class Analysis {
  const Analysis({required this.status, this.result, this.model, this.error});

  final AnalysisStatus status;
  final RefereeAnalysis? result;
  final String? model;
  final String? error;

  factory Analysis.fromJson(Map<String, dynamic> json) =>
      _$AnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisToJson(this);
}
