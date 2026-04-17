import '../models/auth_models.dart';

class AdminUserListResponse {
  final bool success;
  final AdminUserPageData data;

  AdminUserListResponse({required this.success, required this.data});

  factory AdminUserListResponse.fromJson(Map<String, dynamic> json) {
    return AdminUserListResponse(
      success: json['success'] ?? false,
      data: AdminUserPageData.fromJson(json['data']),
    );
  }
}

class AdminUserPageData {
  final List<User> users;
  final int totalPages;
  final int totalElements;
  final int currentPage;

  AdminUserPageData({
    required this.users,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
  });

  factory AdminUserPageData.fromJson(Map<String, dynamic> json) {
    return AdminUserPageData(
      users: (json['users'] as List).map((u) => User.fromJson(u)).toList(),
      totalPages: json['totalPages'] ?? 0,
      totalElements: (json['totalElements'] as num).toInt(),
      currentPage: json['currentPage'] ?? 0,
    );
  }
}

class AdminUserProfileResponse {
  final bool success;
  final AdminUserProfileData data;

  AdminUserProfileResponse({required this.success, required this.data});

  factory AdminUserProfileResponse.fromJson(Map<String, dynamic> json) {
    return AdminUserProfileResponse(
      success: json['success'] ?? false,
      data: AdminUserProfileData.fromJson(json['data']),
    );
  }
}

class AdminUserProfileData {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final double walletBalance;
  final int linkedCards;
  final DateTime createdAt;

  AdminUserProfileData({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.walletBalance,
    required this.linkedCards,
    required this.createdAt,
  });

  factory AdminUserProfileData.fromJson(Map<String, dynamic> json) {
    return AdminUserProfileData(
      userId: json['userId'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      isActive: json['isActive'] ?? true,
      walletBalance: (json['walletBalance'] as num).toDouble(),
      linkedCards: json['linkedCards'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
