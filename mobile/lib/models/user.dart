class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final String? address;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.address,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone_number': phoneNumber,
      'address': address,
      'profile_image': profileImage,
    };
  }
}
