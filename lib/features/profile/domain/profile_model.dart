class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.whatsappNumber,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String whatsappNumber;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? 'Pengguna TemuBarang',
      whatsappNumber: (json['whatsapp_number'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
