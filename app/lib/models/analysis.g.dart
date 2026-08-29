// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Claim _$ClaimFromJson(Map<String, dynamic> json) => Claim(
  text: json['text'] as String,
  assessment: $enumDecode(_$ClaimAssessmentEnumMap, json['assessment']),
  note: json['note'] as String,
);

Map<String, dynamic> _$ClaimToJson(Claim instance) => <String, dynamic>{
  'text': instance.text,
  'assessment': _$ClaimAssessmentEnumMap[instance.assessment]!,
  'note': instance.note,
};

const _$ClaimAssessmentEnumMap = {
  ClaimAssessment.supported: 'supported',
  ClaimAssessment.unsupported: 'unsupported',
  ClaimAssessment.unverifiable: 'unverifiable',
};

MissingContext _$MissingContextFromJson(Map<String, dynamic> json) =>
    MissingContext(text: json['text'] as String);

Map<String, dynamic> _$MissingContextToJson(MissingContext instance) =>
    <String, dynamic>{'text': instance.text};

Fallacy _$FallacyFromJson(Map<String, dynamic> json) => Fallacy(
  name: json['name'] as String,
  explanation: json['explanation'] as String,
);

Map<String, dynamic> _$FallacyToJson(Fallacy instance) => <String, dynamic>{
  'name': instance.name,
  'explanation': instance.explanation,
};

RefereeAnalysis _$RefereeAnalysisFromJson(Map<String, dynamic> json) =>
    RefereeAnalysis(
      claims:
          (json['claims'] as List<dynamic>?)
              ?.map((e) => Claim.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      missingContext:
          (json['missing_context'] as List<dynamic>?)
              ?.map((e) => MissingContext.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      fallacies:
          (json['fallacies'] as List<dynamic>?)
              ?.map((e) => Fallacy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RefereeAnalysisToJson(RefereeAnalysis instance) =>
    <String, dynamic>{
      'claims': instance.claims,
      'missing_context': instance.missingContext,
      'fallacies': instance.fallacies,
    };

Analysis _$AnalysisFromJson(Map<String, dynamic> json) => Analysis(
  status: $enumDecode(_$AnalysisStatusEnumMap, json['status']),
  result: json['result'] == null
      ? null
      : RefereeAnalysis.fromJson(json['result'] as Map<String, dynamic>),
  model: json['model'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$AnalysisToJson(Analysis instance) => <String, dynamic>{
  'status': _$AnalysisStatusEnumMap[instance.status]!,
  'result': ?instance.result,
  'model': ?instance.model,
  'error': ?instance.error,
};

const _$AnalysisStatusEnumMap = {
  AnalysisStatus.pending: 'pending',
  AnalysisStatus.running: 'running',
  AnalysisStatus.complete: 'complete',
  AnalysisStatus.failed: 'failed',
};
