class AiCoachAskRequest {
  final String prompt;

  AiCoachAskRequest({required this.prompt});

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
      };
}

class AiCoachResponse {
  final String answer;
  final String provider;
  final DateTime? createdAt;

  AiCoachResponse({
    required this.answer,
    required this.provider,
    this.createdAt,
  });

  factory AiCoachResponse.fromJson(Map<String, dynamic> json) {
    return AiCoachResponse(
      answer: json['answer']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
