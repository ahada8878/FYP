class UserDetails {
  final String name;

  UserDetails({required this.name});

  Map<String, dynamic> toJson() => {
    'email': name,
  };

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      name: json['email'] as String,
    );
  }
}
