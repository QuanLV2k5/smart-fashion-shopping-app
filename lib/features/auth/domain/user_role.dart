/// Vai trò người dùng trong hệ thống theo bảng public.user_roles.
enum UserRole {
  customer,
  admin;

  static UserRole fromString(String? value) {
    if (value == 'admin') return UserRole.admin;
    return UserRole.customer;
  }
}
