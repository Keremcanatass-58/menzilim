class AuthResponse {
  final String token;
  final String userId;
  final String email;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'].toString(),
      userId: json['userId'].toString(),
      email: json['email'].toString(),
    );
  }
}