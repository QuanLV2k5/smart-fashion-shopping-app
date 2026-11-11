import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/address.dart';

class SupabaseAddressRepository implements AddressRepository {
  const SupabaseAddressRepository(this.client);
  final SupabaseClient? client;
  SupabaseClient _backend(String userId) {
    final backend = client;
    if (backend == null) {
      throw const AddressFailure(
        'Địa chỉ chưa kết nối được. Vui lòng thử lại sau.',
      );
    }
    if (backend.auth.currentUser?.id != userId) {
      throw const AddressFailure(
        'Phiên đăng nhập đã thay đổi. Vui lòng tải lại.',
      );
    }
    return backend;
  }

  Future<T> _request<T>(
    Future<T> Function() action, {
    bool writing = false,
  }) async {
    try {
      return await action().timeout(const Duration(seconds: 25));
    } on AddressFailure {
      rethrow;
    } on PostgrestException catch (error) {
      if (error.code == '42501' || error.code == 'PGRST301') {
        throw const AddressFailure(
          'Bạn không có quyền thao tác địa chỉ này. Vui lòng đăng nhập lại.',
        );
      }
      if (error.code == '23514' || error.code == '23502') {
        throw const AddressFailure(
          'Thông tin địa chỉ chưa hợp lệ. Vui lòng kiểm tra lại.',
        );
      }
      if (error.code == '23505') {
        throw const AddressFailure(
          'Địa chỉ này đã được gửi. Hãy tải lại danh sách để kiểm tra.',
        );
      }
      throw AddressFailure(
        writing
            ? 'Chưa xác nhận được thay đổi. Hãy tải lại danh sách trước khi tiếp tục.'
            : 'Chưa tải được địa chỉ. Kiểm tra kết nối rồi thử lại.',
        uncertain: writing,
      );
    } catch (_) {
      throw AddressFailure(
        writing
            ? 'Chưa xác nhận được thay đổi. Hãy tải lại danh sách trước khi tiếp tục.'
            : 'Chưa tải được địa chỉ. Kiểm tra kết nối rồi thử lại.',
        uncertain: writing,
      );
    }
  }

  void _validate(AddressDraft draft) {
    if (draft.validate().isNotEmpty) {
      throw const AddressFailure('Thông tin địa chỉ chưa hợp lệ.');
    }
  }

  @override
  Future<List<Address>> load(String userId) => _request(() async {
    final backend = _backend(userId);
    final result = <Address>[];
    // Không cắt mất địa chỉ khi Data API áp giới hạn số dòng mỗi trang.
    const pageSize = 100;
    for (var offset = 0; ; offset += pageSize) {
      final rows = await backend
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);
      result.addAll(rows.map((row) => addressFromJson(row, userId)));
      if (rows.length < pageSize) break;
      _backend(userId);
    }
    return List.unmodifiable(result);
  });

  @override
  Future<Address> create(String userId, String id, AddressDraft draft) =>
      _request(() async {
        _validate(draft);
        final row = await _backend(userId)
            .from('addresses')
            .insert({'id': id, ...draft.fields})
            .select()
            .retry(enabled: false)
            .single();
        return addressFromJson(row, userId);
      }, writing: true);

  @override
  Future<Address> update(String userId, String id, AddressDraft draft) =>
      _request(() async {
        _validate(draft);
        final row = await _backend(userId)
            .from('addresses')
            .update(draft.fields)
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .retry(enabled: false)
            .maybeSingle();
        if (row == null) {
          throw const AddressFailure(
            'Địa chỉ không còn tồn tại hoặc không thuộc tài khoản này. Hãy tải lại.',
          );
        }
        return addressFromJson(row, userId);
      }, writing: true);

  @override
  Future<void> delete(String userId, String id) => _request(() async {
    final rows = await _backend(userId)
        .from('addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', userId)
        .select('id')
        .retry(enabled: false);
    if (rows.isEmpty) {
      throw const AddressFailure(
        'Địa chỉ không còn tồn tại hoặc không thuộc tài khoản này. Hãy tải lại.',
      );
    }
  }, writing: true);
}

Address addressFromJson(Map<String, dynamic> row, String userId) {
  String field(String key) {
    final value = row[key];
    if (value is! String || value.isEmpty) {
      throw const FormatException('Invalid address');
    }
    return value;
  }

  if (field('user_id') != userId) throw const FormatException('Invalid owner');
  final details = AddressDraft(
    recipientName: field('recipient_name'),
    phone: field('phone'),
    addressLine: field('address_line'),
    ward: field('ward'),
    district: field('district'),
    city: field('city'),
  );
  if (details.validate().isNotEmpty) {
    throw const FormatException('Invalid fields');
  }
  return Address(
    id: field('id'),
    userId: userId,
    details: details,
    createdAt: DateTime.parse(field('created_at')),
    updatedAt: DateTime.parse(field('updated_at')),
  );
}
