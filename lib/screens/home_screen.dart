import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/city_storage.dart';
import '../services/cptec_service.dart';
import '../widgets/forecast_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = CptecService();
  final _storage = CityStorage();
  final _search = TextEditingController();
  City? _city;
  Forecast? _forecast;
  List<City> _results = [];
  bool _searching = false, _loading = false, _showSearch = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreCity();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _restoreCity() async {
    final saved = await _storage.read();
    if (!mounted || saved == null) return;
    setState(() => _city = saved);
    await _loadForecast();
  }

  Future<void> _searchCities() async {
    final query = _search.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = 'Digite o nome de uma cidade.';
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    try {
      final cities = await _service.searchCities(query);
      if (!mounted) return;
      setState(() {
        _results = cities;
        if (cities.isEmpty) {
          _error = 'Nenhuma cidade encontrada. Tente outro nome.';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Falha ao buscar cidades. Verifique sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectCity(City city) async {
    setState(() {
      _city = city;
      _forecast = null;
      _results = [];
      _showSearch = false;
      _error = null;
    });
    await _storage.save(city);
    await _loadForecast();
  }

  Future<void> _loadForecast() async {
    final city = _city;
    if (city == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forecast = await _service.getForecast(city);
      if (mounted) setState(() => _forecast = forecast);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecast = _forecast;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Tempo por aqui',
              style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            if (_city != null)
              IconButton(
                  tooltip: 'Atualizar previsão',
                  onPressed: _loading ? null : _loadForecast,
                  icon: const Icon(Icons.refresh_rounded)),
          ]),
      body: SafeArea(
          child: RefreshIndicator(
              onRefresh: _loadForecast,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    if (!_showSearch && _city == null) _startCard(),
                    if (_showSearch) _searchPanel(),
                    if (_loading)
                      const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator())),
                    if (_error != null && !_showSearch)
                      _message(_error!,
                          retry: _city != null ? _loadForecast : null),
                    if (forecast != null && !_loading) ...[
                      _citySummary(forecast),
                      const SizedBox(height: 16),
                      ForecastChart(days: forecast.days),
                      const SizedBox(height: 18),
                      const Text('Próximos dias',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF102A43))),
                      const SizedBox(height: 8),
                      ...forecast.days.map(_dayCard),
                      const SizedBox(height: 12),
                      Text(
                          'Fonte: CPTEC/INPE  •  Atualizado em ${forecast.updatedAt.isEmpty ? 'data não informada' : forecast.updatedAt}',
                          style: const TextStyle(
                              color: Color(0xFF627D98), fontSize: 12)),
                    ],
                  ]))),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => setState(() {
                _showSearch = !_showSearch;
                _error = null;
              }),
          icon: Icon(_showSearch ? Icons.close : Icons.location_on_outlined),
          label: Text(_showSearch ? 'Fechar busca' : 'Buscar cidade')),
    );
  }

  Widget _header() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('O céu da sua cidade,',
            style: TextStyle(
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43))),
        Text(_city == null ? 'em um só lugar.' : 'em ${_city!.name}.',
            style: const TextStyle(
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF167D8D))),
        const SizedBox(height: 7),
        const Text('Previsão local para os próximos dias',
            style: TextStyle(color: Color(0xFF627D98))),
      ]);

  Widget _startCard() => Card(
      child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const Icon(Icons.wb_cloudy_outlined,
                size: 58, color: Color(0xFF167D8D)),
            const SizedBox(height: 12),
            const Text('Vamos consultar o tempo?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
                'Busque uma cidade brasileira para ver a previsão completa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF627D98))),
          ])));

  Widget _searchPanel() => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchCities(),
                      decoration: const InputDecoration(
                          hintText: 'Ex.: São Paulo',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true))),
              const SizedBox(width: 8),
              IconButton.filled(
                  onPressed: _searching ? null : _searchCities,
                  icon: const Icon(Icons.arrow_forward))
            ]),
            if (_searching)
              const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFB42318)))),
            ..._results.map((city) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.location_city)),
                title: Text(city.name),
                subtitle: Text(city.state),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectCity(city))),
          ])));

  Widget _citySummary(Forecast f) => Card(
      color: const Color(0xFF102A43),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            const Icon(Icons.location_on, color: Color(0xFF7DE2D1), size: 30),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(f.city.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  Text(f.city.state,
                      style: const TextStyle(color: Color(0xFFBCCCDC)))
                ])),
            const Icon(Icons.wb_sunny_rounded,
                color: Color(0xFFFFD166), size: 36),
          ])));

  Widget _dayCard(ForecastDay day) {
    final icon = _weatherIcon(day.condition);
    return Card(
        margin: const EdgeInsets.only(top: 8),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F3),
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: const Color(0xFF167D8D))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_formatDate(day.date),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(day.condition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF627D98), fontSize: 13))
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${day.max.isEmpty ? '—' : day.max}°',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text('mín ${day.min.isEmpty ? '—' : day.min}°',
                    style: const TextStyle(
                        color: Color(0xFF627D98), fontSize: 12)),
                if (day.uv != null)
                  Text('UV ${day.uv}',
                      style: const TextStyle(
                          color: Color(0xFF167D8D),
                          fontSize: 11,
                          fontWeight: FontWeight.w700))
              ]),
            ])));
  }

  Widget _message(String text, {Future<void> Function()? retry}) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Text(text, textAlign: TextAlign.center),
            if (retry != null)
              TextButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'))
          ])));
  String _formatDate(String value) {
    try {
      final d = DateTime.parse(value);
      const weekdays = ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.', 'dom.'];
      const months = [
        'jan.',
        'fev.',
        'mar.',
        'abr.',
        'mai.',
        'jun.',
        'jul.',
        'ago.',
        'set.',
        'out.',
        'nov.',
        'dez.'
      ];
      return '${weekdays[d.weekday - 1]} • ${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return value.isEmpty ? 'Data não informada' : value;
    }
  }

  IconData _weatherIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('tempest') || v.contains('instável')) {
      return Icons.thunderstorm_rounded;
    }
    if (v.contains('chuva') ||
        v.contains('chuvisco') ||
        v.contains('pancada')) {
      return Icons.water_drop_rounded;
    }
    if (v.contains('nubl') || v.contains('encoberto')) {
      return Icons.cloud_rounded;
    }
    return Icons.wb_sunny_rounded;
  }
}
