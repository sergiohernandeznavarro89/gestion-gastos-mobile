class User {
  final int userId;
  final String userName;
  final String userLastName;
  final String userEmail;

  User({
    required this.userId,
    required this.userName,
    required this.userLastName,
    required this.userEmail,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      userName: json['userName'],
      userLastName: json['userLastName'],
      userEmail: json['userEmail'],
    );
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: User.fromJson(json['user']),
    );
  }
}
