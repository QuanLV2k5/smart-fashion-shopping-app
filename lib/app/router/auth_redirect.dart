/// Chỉ cho quay lại route đã triển khai, không nhận URL ngoài từ query `next`.
String authDestination(String? requested) {
  final uri = requested == null ? null : Uri.tryParse(requested);
  if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
    return '/account';
  }
  if (const {
        '/',
        '/ai',
        '/ai/photo',
        '/favorites',
        '/admin/users',
        '/account',
        '/account/profile',
        '/account/orders',
        '/admin/orders',
        '/cart',
        '/checkout',
        '/addresses',
        '/addresses/select',
        '/admin',
        '/admin/categories',
        '/admin/categories/new',
        '/admin/products',
        '/admin/products/new',
      }.contains(uri.path) &&
      !uri.hasQuery) {
    return uri.path;
  }
  if (!uri.hasQuery &&
      (RegExp(r'^/products/[a-zA-Z0-9_-]{1,80}/reviews?$').hasMatch(uri.path) ||
          RegExp(r'^/admin/users/[a-zA-Z0-9_-]{1,80}$').hasMatch(uri.path) ||
          RegExp(
            r'^/admin/(products|categories)/[a-zA-Z0-9_-]{1,80}/edit$',
          ).hasMatch(uri.path))) {
    return uri.path;
  }
  if (RegExp(r'^/products/[a-zA-Z0-9_-]{1,80}$').hasMatch(uri.path) &&
      uri.queryParametersAll.entries.every(
        (entry) =>
            entry.key == 'variant' &&
            entry.value.length == 1 &&
            RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(entry.value.single),
      )) {
    return uri.toString();
  }
  return '/account';
}
