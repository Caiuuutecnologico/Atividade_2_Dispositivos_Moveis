import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';

class CityStorage {
  static const _key = 'selected_city';
  Future<void> save(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [city.id, city.name, city.state]);
  }

  Future<City?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key);
    if (values == null || values.length < 3) return null;
    return City(id: values[0], name: values[1], state: values[2]);
  }
}
