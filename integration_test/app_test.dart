// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:add_focus_app/main.dart' as app;

// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();

//   testWidgets('Core User Flow: Launch -> Select Apps -> Start Session', (
//     WidgetTester tester,
//   ) async {
//     try {
//       // 1. Launch App
//       print('DEBUG: Launching App...');
//       app.main();
//       await tester.pump();
//       await tester.pump(const Duration(seconds: 2));

//       // 2. Onboarding/Permissions Check
//       print('DEBUG: Checking for Onboarding/Permissions...');
//       final getStartedFinder = find.text('Get Started');
//       if (getStartedFinder.evaluate().isNotEmpty) {
//         print('DEBUG: Found Get Started button. Tapping...');
//         await tester.tap(getStartedFinder);
//         await tester.pumpAndSettle();
//       }

//       final continueFinder = find.text('Continue');
//       if (continueFinder.evaluate().isNotEmpty) {
//         print('DEBUG: Found Continue button (Permissions?). Tapping...');
//         await tester.tap(continueFinder);
//         await tester.pumpAndSettle();
//       }

//       // 3. Verify Home Screen
//       print('DEBUG: Verifying Home Screen elements...');
//       expect(find.text('FocusLock'), findsOneWidget);

//       // Check if we are already in a session
//       final viewSessionFinder = find.text('View Session');
//       if (viewSessionFinder.evaluate().isNotEmpty) {
//         print(
//           'DEBUG: Found active session (View Session). Cancelling it first...',
//         );
//         await tester.tap(viewSessionFinder);
//         await tester.pump();
//         await tester.pump(const Duration(seconds: 1));

//         // Should be on Active Screen
//         expect(find.text('Stay focused 💪'), findsOneWidget);

//         // Give Up
//         print('DEBUG: Giving up existing session...');
//         await tester.tap(find.text('Give Up'));
//         await tester.pump();
//         await tester.pump(const Duration(seconds: 1));

//         if (find.text('Stop Session?').evaluate().isNotEmpty) {
//           await tester.tap(find.text('Give Up').last);
//           await tester.pump();
//           await tester.pump(const Duration(seconds: 1));
//         }

//         // Now should be back home with "Start Focus"
//         print('DEBUG: Session cancelled. Back on Home.');
//       }

//       expect(find.text('Today\'s Overview'), findsOneWidget);

//       final startFocusFinder = find.text('Start Focus');
//       if (startFocusFinder.evaluate().isNotEmpty) {
//         print('DEBUG: Found Start Focus button.');
//       } else {
//         print('DEBUG: Start Focus button NOT found!');
//       }
//       expect(startFocusFinder, findsOneWidget);

//       // 4. Navigate to App Selection (Block Apps)
//       print('DEBUG: Tapping Start Focus to navigate to Apps...');
//       await tester.tap(startFocusFinder);
//       await tester.pumpAndSettle();

//       // Verify we are on App Block Selection screen
//       print('DEBUG: Verifying App Selection Screen...');
//       expect(find.text('Block Apps'), findsOneWidget);

//       // 5. Select Apps
//       print('DEBUG: Selecting Apps...');
//       final appTiles = find.byType(ListTile);
//       if (appTiles.evaluate().isNotEmpty) {
//         print('DEBUG: Found ${appTiles.evaluate().length} app tiles.');
//         await tester.tap(appTiles.first); // Select first app
//         await tester.pump();
//         if (appTiles.evaluate().length > 1) {
//           await tester.tap(appTiles.at(1)); // Select second app
//           await tester.pump();
//         }
//       } else {
//         print('DEBUG: No apps found in list!');
//       }

//       // 6. Navigate to Set Focus Time
//       print('DEBUG: Finding FAB to proceed...');
//       final fabFinder = find.byType(FloatingActionButton);
//       expect(fabFinder, findsOneWidget);
//       await tester.tap(fabFinder);
//       await tester.pumpAndSettle();

//       // 7. Set Time and Start
//       print('DEBUG: Verifying Set Focus Time Screen...');
//       expect(find.text('Set Focus Time'), findsOneWidget);

//       // Tap "Start Focus"
//       print('DEBUG: Tapping Start Focus (Time Screen)...');
//       await tester.tap(find.text('Start Focus'));
//       await tester.pump();
//       await tester.pump(const Duration(seconds: 1));

//       // 8. Verify Active Session
//       print('DEBUG: Verifying Active Session Screen...');
//       expect(find.text('Stay focused 💪'), findsOneWidget);

//       // 9. End Session (Give Up)
//       print('DEBUG: Giving Up session...');
//       await tester.tap(find.text('Give Up'));
//       await tester.pump();
//       await tester.pump(const Duration(seconds: 1));

//       // Confirm Give Up dialog
//       if (find.text('Stop Session?').evaluate().isNotEmpty) {
//         print('DEBUG: Found Stop Session dialog. Confirming...');
//         await tester.tap(find.text('Give Up').last);
//         await tester.pump();
//         await tester.pump(const Duration(seconds: 1));
//       } else {
//         print('DEBUG: No Stop Session dialog found. Checking if back home...');
//       }

//       // Should be back home
//       print('DEBUG: Verifying return to Home Screen...');
//       await tester.pumpAndSettle();
//       expect(find.text('FocusLock'), findsOneWidget);
//       print('DEBUG: Test Completed Successfully.');
//     } catch (e, stack) {
//       print('ERROR: Test Failed with exception: $e');
//       print(stack);
//       rethrow;
//     }
//   });
// }
