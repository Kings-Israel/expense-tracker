class User {
  final int id;
  final String name;
  final String email;
  final String defaultCurrency;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.defaultCurrency,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      defaultCurrency: json['default_currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'default_currency': defaultCurrency,
    };
  }
}
