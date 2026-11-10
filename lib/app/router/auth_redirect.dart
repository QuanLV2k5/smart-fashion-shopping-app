/// Chỉ cho quay lại route đã triển khai, không nhận URL ngoài từ query `next`.
String authDestination(String? requested) {
  final uri = requested == null ? null : Uri.tryParse(requested);
  if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
    return '/account';
  }
  if (const {'/', '/account', '/cart'}.contains(uri.path) && !uri.hasQuery) {
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
