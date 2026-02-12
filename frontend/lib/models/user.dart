class User {
  final String id;
  final String username;
  final String email;
  final String? token;

  User({required this.id, required this.username, required this.email, this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
    );
  }
}
