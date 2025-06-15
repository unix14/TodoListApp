// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/common/encryption_helper.dart'; // For EncryptionHelper
import 'package:flutter_example/main.dart'; // Ensure MyApp is in scope
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock HomeWidget
class MockHomeWidget {
  Future<void> updateWidget({String? name, String? iOSName}) async {
    print('MockHomeWidget.updateWidget called with name: $name, iOSName: $iOSName');
    // You can add more logic here, e.g., counting calls or checking arguments
    mockUpdateWidgetCalled = true;
    mockUpdateWidgetName = name;
  }
}
bool mockUpdateWidgetCalled = false;
String? mockUpdateWidgetName;

void main() {
  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(MyApp(isAlreadyEnteredTodos: true,));

  //   // Verify that our counter starts at 0.
  //   // expect(find.text('0'), findsOneWidget); // This test is not relevant anymore
  //   // expect(find.text('1'), findsNothing);

  //   // Tap the '+' icon and trigger a frame.
  //   // await tester.tap(find.byIcon(Icons.add)); // This test is not relevant anymore
  //   // await tester.pump();

  //   // Verify that our counter has incremented.
  //   // expect(find.text('0'), findsNothing);
  //   // expect(find.text('1'), findsOneWidget);
  // });

  group('HomePage Widget Tests', () {
    late MockHomeWidget mockHomeWidget;

    setUp(() async {
      mockHomeWidget = MockHomeWidget();
      mockUpdateWidgetCalled = false;
      mockUpdateWidgetName = null;

      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({
        // Initialize with empty list or some default if your app expects it
        'flutter.$kAllListSavedPrefs': '[]', // Assuming kAllListSavedPrefs is used as part of the key
        'flutter.categories': '[]' // Using empty list for simplicity
      });

      TestWidgetsFlutterBinding.ensureInitialized();
      // Mock for rootBundle asset loading for EncryptionHelper
      ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
        // The filename is part of the message key.
        // For "assets/config/encryption_config.json"
        // This check might need to be more robust if other assets are loaded.
        // For now, assuming this is the only asset call we care about mocking here.
        // if (message?.key == "assets/config/encryption_config.json") { // This is not how message key works for assets.
                                                                    // Instead, the argument to rootBundle.loadString is the key.
                                                                    // We check the method call argument in loadString itself or trust the path.
          final String mockConfig = '{"key":"your_mock_key_for_testing_123", "iv":"your_mock_iv_for_testing_123"}';
          return ByteData.view(Uint8List.fromList(mockConfig.codeUnits).buffer);
        // }
        // return null; // Return null if other assets are requested and not mocked
      });
      // It's important that EncryptionHelper.initialize() is called *after* the mock message handler is set.
      // If MyApp or HomePage initializes it, ensure this setup is before pumpWidget.
      // If it's initialized in main.dart before runApp, this mock setup might be too late unless main_test.dart is used.
      // For this test structure, we call it directly here.
      await EncryptionHelper.initialize();

      // Mock for HomeWidget platform channel
      const MethodChannel('home_widget').setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'updateWidget') {
          mockHomeWidget.updateWidget(
            name: methodCall.arguments['android'],
            iOSName: methodCall.arguments['ios'],
          );
          return true;
        }
        if (methodCall.method == 'registerBackgroundCallback') {
          return true; // Mock success
        }
        // Add other methods if your app calls them during init
        return null;
      });
    });

    tearDown(() {
       const MethodChannel('home_widget').setMockMethodCallHandler(null);
       ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
    });

    testWidgets('Adding a todo calls HomeWidget.updateWidget', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      // MyApp initializes AppInitializer which might call EncryptionHelper.initialize()
      // Ensure our mock setup for assets is effective.
      await tester.pumpWidget(MyApp(isAlreadyEnteredTodos: true)); // Set to true to land on HomePage

      // Wait for HomePage to load its data (FutureBuilder, etc.)
      // This might involve SharedPreferences reads and other async operations.
      await tester.pumpAndSettle();

      // Find the TextField for adding a todo
      // HomePage has a RoundedTextInputField which wraps a TextField.
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      // Enter text into the TextField
      await tester.enterText(textFieldFinder, 'New Test Todo');
      await tester.pump(); // Update state for FAB visibility/opacity

      // Tap the FloatingActionButton to add the todo
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle(); // Process the tap and subsequent UI updates

      // Verify that HomeWidget.updateWidget was called
      expect(mockUpdateWidgetCalled, isTrue, reason: "HomeWidget.updateWidget was not called");
      expect(mockUpdateWidgetName, 'com.eyalya94.tools.todoLater.TodoWidgetProvider', reason: "HomeWidget.updateWidget was called with incorrect name");
    });
  });
}
