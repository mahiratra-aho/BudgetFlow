import 'package:intl/date_symbol_data_local.dart';

Future<void> initialiserLocalisation() async {
  await initializeDateFormatting('fr_FR', null);
}
