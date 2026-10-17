import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allow-list rute deep link konsisten dengan parser', () {
    expect(AppRoutes.announcement('3'), '/pengumuman/3');
    expect(AppRoutes.isAnnouncement('/pengumuman/3'), isTrue);
    expect(AppRoutes.isAnnouncement('/pengumuman/'), isFalse);
    expect(AppRoutes.isAllowed(AppRoutes.login), isTrue);
    expect(AppRoutes.isAllowed('/pengumuman/abc'), isFalse);
  });

  test('routeFromMessage menghasilkan rute yang selalu boleh dilalui router', () {
    const samples = <Map<String, dynamic>>[
      {},
      {'route': 'pengumuman/3'},
      {'route': '/pengumuman/3'},
      {'route': 'https://evil.example'},
    ];
    for (final data in samples) {
      final route = routeFromMessage(data);
      expect(
        AppRoutes.isAllowed(route),
        isTrue,
        reason: 'rute "$route" dari $data harus lolos allow-list',
      );
    }
  });
}
