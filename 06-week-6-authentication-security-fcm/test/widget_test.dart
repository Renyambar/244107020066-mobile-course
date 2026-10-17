import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('konstanta rute dipakai konsisten oleh parser deep link', () {
    expect(AppRoutes.login, '/login');
    expect(AppRoutes.home, '/');
    expect(routeFromMessage(<String, dynamic>{}), AppRoutes.home);
    expect(
      routeFromMessage(<String, dynamic>{'route': '/pengumuman/3'}),
      '/pengumuman/3',
    );
  });
}
