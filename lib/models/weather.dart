class City {
  const City({required this.id, required this.name, required this.state});
  final String id;
  final String name;
  final String state;
  String get label => '$name, $state';
}

class ForecastDay {
  const ForecastDay(
      {required this.date,
      required this.condition,
      required this.min,
      required this.max,
      this.uv});
  final String date;
  final String condition;
  final String min;
  final String max;
  final String? uv;
}

class Forecast {
  const Forecast(
      {required this.city, required this.updatedAt, required this.days});
  final City city;
  final String updatedAt;
  final List<ForecastDay> days;
}
