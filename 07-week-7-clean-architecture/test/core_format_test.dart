import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/format.dart';
import 'package:campus_notify/routes.dart';

void main() {
  group('routeFromMessage', () {
    test('mengizinkan rute pada allow-list dan menambahkan slash', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/login'}), '/login');
    });

    test('menolak rute di luar allow-list (mencegah payload nakal)', () {
      expect(routeFromMessage({'route': '/admin/rahasia'}), AppRoutes.home);
      expect(routeFromMessage({'route': '   '}), AppRoutes.home);
      expect(routeFromMessage(const {}), AppRoutes.home);
    });
  });

  group('hasNotificationPayload', () {
    test('payload berisi judul/isi dianggap notifikasi', () {
      expect(hasNotificationPayload(title: 'Judul', body: 'Isi'), isTrue);
      expect(hasNotificationPayload(title: 'Judul'), isTrue);
    });

    test('payload data-only tidak menampilkan banner', () {
      expect(hasNotificationPayload(), isFalse);
    });
  });

  group('format & token', () {
    test('formatDate memakai bulan Indonesia', () {
      expect(formatDate(DateTime(2026, 9, 27)), '27 Sep 2026');
    });

    test('shortToken memotong token panjang menjadi 12 karakter + elipsis', () {
      expect(shortToken('fcm_sim_abcdefghijk'), 'fcm_sim_abcd…');
      expect(shortToken('pendek'), 'pendek');
    });
  });
}
