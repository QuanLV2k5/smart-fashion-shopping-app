import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fashion/features/profile/domain/profile.dart';

void main() {
  group('ProfileValidation', () {
    test('validateFullName yêu cầu nhập và giới hạn 100 ký tự', () {
      expect(
        ProfileValidation.validateFullName(null),
        'Vui lòng nhập họ và tên',
      );
      expect(ProfileValidation.validateFullName(''), 'Vui lòng nhập họ và tên');
      expect(
        ProfileValidation.validateFullName('   '),
        'Vui lòng nhập họ và tên',
      );
      expect(ProfileValidation.validateFullName('Trần Lê Nguyên Hải'), isNull);

      final over100Chars = 'A' * 101;
      expect(
        ProfileValidation.validateFullName(over100Chars),
        'Họ và tên không được vượt quá 100 ký tự',
      );
    });

    test(
      'validatePhone cho phép để trống hoặc kiểm tra định dạng 9-15 chữ số',
      () {
        expect(ProfileValidation.validatePhone(null), isNull);
        expect(ProfileValidation.validatePhone(''), isNull);
        expect(ProfileValidation.validatePhone('   '), isNull);

        // Hợp lệ
        expect(ProfileValidation.validatePhone('0912345678'), isNull);
        expect(ProfileValidation.validatePhone('+84912345678'), isNull);
        expect(ProfileValidation.validatePhone('02838123456'), isNull);

        // Không hợp lệ
        expect(
          ProfileValidation.validatePhone('123'),
          'Số điện thoại không hợp lệ (từ 9 đến 15 chữ số)',
        );
        expect(
          ProfileValidation.validatePhone('abcdefghij'),
          'Số điện thoại không hợp lệ (từ 9 đến 15 chữ số)',
        );
        expect(
          ProfileValidation.validatePhone('09123456789012345678901'),
          'Số điện thoại không được vượt quá 20 ký tự',
        );
      },
    );
  });

  group('UserProfile model', () {
    test('hỗ trợ copyWith, so sánh equality và hashCode nhất quán', () {
      const userA = UserProfile(
        id: 'u-1',
        email: 'hai@example.com',
        fullName: 'Nguyên Hải',
        phone: '0912345678',
      );

      final userB = userA.copyWith(phone: '0987654321');
      expect(userB.id, 'u-1');
      expect(userB.phone, '0987654321');
      expect(userB.fullName, 'Nguyên Hải');

      const userC = UserProfile(
        id: 'u-1',
        email: 'hai@example.com',
        fullName: 'Nguyên Hải',
        phone: '0912345678',
      );
      expect(userA, equals(userC));
      expect(userA.hashCode, equals(userC.hashCode));
    });
  });

  group('ProfileFailure', () {
    test('chứa thông báo lỗi thân thiện', () {
      expect(ProfileFailure.network.isNetwork, isTrue);
      expect(
        ProfileFailure.network.message,
        'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng rồi thử lại.',
      );
      expect(
        ProfileFailure.storageUpload.message,
        'Không thể tải ảnh đại diện lên máy chủ. Vui lòng thử lại sau.',
      );
    });
  });
}
