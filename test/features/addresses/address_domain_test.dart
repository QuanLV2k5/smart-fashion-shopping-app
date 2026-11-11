import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/addresses/domain/address.dart';
import 'package:smart_fashion/features/addresses/data/supabase_address_repository.dart';

import 'address_fixtures.dart';

void main() {
  test('trim các trường, payload chỉ gồm cột chỉnh sửa được', () {
    expect(draft.validate(), isEmpty);
    expect(draft.fields['recipient_name'], 'Phúc');
    expect(
      draft.fields.keys,
      unorderedEquals([
        'recipient_name',
        'phone',
        'address_line',
        'ward',
        'district',
        'city',
      ]),
    );
  });
  test('validation đúng biên schema kể cả Unicode ngoài BMP', () {
    AddressDraft value(String name, String phone, String line) => AddressDraft(
      recipientName: name,
      phone: phone,
      addressLine: line,
      ward: 'X',
      district: 'Y',
      city: 'Z',
    );
    expect(value('😀' * 100, '+123456789', 'x' * 250).validate(), isEmpty);
    expect(
      value('x' * 101, '12345678', 'x' * 251).validate().keys,
      unorderedEquals(['recipient_name', 'phone', 'address_line']),
    );
    for (final phone in [
      '+1234567890123456',
      '090 123 4567',
      'abc123456789',
      '123456789\nX',
    ]) {
      expect(value('A', phone, 'B').validate(), contains('phone'));
    }
    expect(
      value('   ', '123456789012345', 'B').validate(),
      contains('recipient_name'),
    );
    expect(
      const AddressDraft(
        recipientName: '',
        phone: '',
        addressLine: '',
        ward: '',
        district: '',
        city: '',
      ).validate(),
      hasLength(6),
    );
  });
  test('mapping từ chối chủ sở hữu khác, thiếu trường và ngày sai', () {
    final row = <String, dynamic>{
      'id': 'a',
      'user_id': 'u',
      ...draft.fields,
      'created_at': '2026-11-11T00:00:00Z',
      'updated_at': '2026-11-11T00:00:00Z',
    };
    expect(addressFromJson(row, 'u').details.city, 'Đà Nẵng');
    expect(() => addressFromJson(row, 'other'), throwsFormatException);
    expect(
      () => addressFromJson({...row, 'ward': null}, 'u'),
      throwsFormatException,
    );
    expect(
      () => addressFromJson({...row, 'updated_at': 'invalid'}, 'u'),
      throwsFormatException,
    );
  });
}
