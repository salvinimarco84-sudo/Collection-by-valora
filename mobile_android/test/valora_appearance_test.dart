import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valora_mobile/src/theme/valora_appearance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('all ten TEST1 themes are available in TEST2', () {
    expect(ValoraAppearance.presets.map((p) => p.id).toList(), [
      'black_gold','midnight_blue','emerald','silver_light','dark_red',
      'royal_purple','comic','minimal_zen','industrial','pastel',
    ]);
  });

  test('theme choice is persisted and restored', () async {
    final appearance = ValoraAppearance.instance;
    await appearance.load();
    await appearance.setTheme('fire_red');
    expect(appearance.selectedThemeId, 'black_gold'); // unknown identifiers are ignored
    await appearance.setTheme('dark_red');
    expect(appearance.selectedThemeId, 'dark_red');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('valora_selected_theme'), 'dark_red');
    await appearance.load();
    expect(appearance.selected.id, 'dark_red');
  });

  test('unknown saved theme safely falls back to Black & Gold', () async {
    SharedPreferences.setMockInitialValues({'valora_selected_theme':'not-a-theme'});
    await ValoraAppearance.instance.load();
    expect(ValoraAppearance.instance.selected.id, 'black_gold');
  });
}
