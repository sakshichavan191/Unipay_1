class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final String? businessName;
  final String? phone;
  final double? walletBalance;
  final int? linkedCards;
  final bool? isActive;
  final bool? isBlocked;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.businessName,
    this.phone,
    this.walletBalance,
    this.linkedCards,
    this.isActive,
    this.isBlocked,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? (json['userId']),
      name: json['name'] ?? json['fullName'],
      email: json['email'],
      role: json['role'],
      studentId: json['studentId'],
      businessName: json['businessName'],
      phone: json['phone'],
      walletBalance: (json['walletBalance'] as num?)?.toDouble(),
      linkedCards: json['linkedCards'],
      isActive: json['isActive'] ?? json['active'],
      isBlocked: json['isBlocked'] ?? json['blocked'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'studentId': studentId,
      'businessName': businessName,
      'phone': phone,
      'walletBalance': walletBalance,
      'linkedCards': linkedCards,
      'isActive': isActive,
      'isBlocked': isBlocked,
      'createdAt': createdAt,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      user: User.fromJson(json['user']),
    );
  }
}
