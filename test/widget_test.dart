import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop_sync_app/core/theme/theme_provider.dart';
import 'package:shop_sync_app/main.dart';
import 'package:shop_sync_app/shared/providers/app_state_provider.dart';

void main() {
  testWidgets('ShopSyncApp desktop viewport render test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider(initialAuth: true, shopName: 'My Retail Store')),
        ],
        child: const ShopSyncApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('My Retail Store'), findsWidgets);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Total Revenue'), findsWidgets);
  });

  testWidgets('ShopSyncApp mobile viewport render test without overflows', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider(initialAuth: true, shopName: 'My Retail Store')),
        ],
        child: const ShopSyncApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ShopSync'), findsWidgets);
    expect(find.text('My Retail Store'), findsWidgets);
  });
}
