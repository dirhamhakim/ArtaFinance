import 'package:material_ui/material_ui.dart';

import '../controllers/finance_controller.dart';
import '../models/ledger.dart';
import '../screens/account_form.dart';
import '../screens/transaction_form.dart';
import '../screens/occurrence_form.dart';
import '../screens/schedules_screen.dart';
import '../models/schedule.dart';
import '../services/schedule_engine.dart';

abstract final class AppRoutes {
  static Future<void> schedules(
    BuildContext context,
    FinanceController controller,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => SchedulesScreen(controller: controller)),
  );
  static Future<void> scheduleDetail(
    BuildContext context,
    FinanceController controller,
    String id,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ScheduleDetailScreen(controller: controller, id: id),
    ),
  );
  static Future<void> schedule(
    BuildContext context,
    FinanceController controller, {
    EntryMode mode = EntryMode.repeat,
    ScheduleRule? replaces,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TransactionForm(
        controller: controller,
        initialMode: mode,
        replaces: replaces,
      ),
    ),
  );
  static Future<void> occurrence(
    BuildContext context,
    FinanceController controller,
    PendingOccurrence item,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => OccurrenceForm(controller: controller, item: item),
    ),
  );
  static Future<void> account(
    BuildContext context,
    FinanceController controller,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => AccountForm(controller: controller)),
  );
  static Future<void> transaction(
    BuildContext context,
    FinanceController controller, {
    LedgerTransaction? existing,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          TransactionForm(controller: controller, existing: existing),
    ),
  );
}
