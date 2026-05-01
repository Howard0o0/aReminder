import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ireminder/models/reminder.dart';
import 'package:ireminder/providers/settings_provider.dart';
import 'package:ireminder/widgets/reminder_details_sheet.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  testWidgets('date picker allows reminders more than 30 days ahead',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: SettingsProvider(),
        child: CupertinoApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          home: CupertinoPageScaffold(
            child: ReminderDetailsSheet(
              reminder: Reminder(title: 'Test reminder'),
              onUpdate: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CupertinoSwitch).first);
    await tester.pumpAndSettle();

    final calendar = tester.widget<TableCalendar<dynamic>>(
      find.byType(TableCalendar),
    );
    final thirtyOneDaysFromNow = DateTime.now().add(const Duration(days: 31));

    expect(calendar.lastDay.isAfter(thirtyOneDaysFromNow), isTrue);
  });
}
