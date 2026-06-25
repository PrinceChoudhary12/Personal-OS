// lib/features/admin/domain/models/admin_model.dart

class AdminModel {
  final String uid;
  final String email;
  final String role; // 'founder', 'admin'

  const AdminModel({
    required this.uid,
    required this.email,
    required this.role,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String docId) {
    return AdminModel(
      uid: docId,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
    };
  }
}
