import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/weather.dart';

class CptecService {
  static const _base = 'http://servicos.cptec.inpe.br/XML';
  static const _conditions = <String, String>{
    'ec': 'Encoberto com chuvas isoladas',
    'ci': 'Chuvas isoladas',
    'c': 'Chuva',
    'in': 'Instável',
    'pp': 'Possibilidade de pancadas de chuva',
    'cm': 'Chuva pela manhã',
    'cn': 'Chuva à noite',
    'pt': 'Pancadas de chuva à tarde',
    'pm': 'Pancadas de chuva pela manhã',
    'np': 'Nublado e com possibilidade de chuva',
    'pc': 'Pancadas de chuva',
    'pn': 'Parcialmente nublado',
    'cv': 'Chuvisco',
    'ch': 'Chuvoso',
    't': 'Tempestade',
    'ps': 'Predomínio de sol',
    'e': 'Encoberto',
    'n': 'Nublado',
    'cl': 'Céu limpo',
    'nv': 'Nevoeiro',
    'g': 'Geada',
    'ne': 'Neve',
    'nd': 'Não definido',
    'pnt': 'Pancadas de chuva à noite',
    'ncn': 'Nublado com possibilidade de chuva à noite',
    'psc': 'Possibilidade de chuva',
    'pcm': 'Possibilidade de chuva pela manhã',
    'pct': 'Possibilidade de chuva à tarde',
    'pcn': 'Possibilidade de chuva à noite',
    'npt': 'Nublado com pancadas à tarde',
    'npn': 'Nublado com pancadas à noite',
    'nct': 'Nublado com possibilidade de chuva à tarde',
    'ncm': 'Nublado com possibilidade de chuva pela manhã',
    'npm': 'Nublado com pancadas pela manhã',
    'npp': 'Nublado com possibilidade de chuva',
    'vn': 'Variação de nebulosidade',
    'ppt': 'Possibilidade de pancadas de chuva à tarde',
  };

  Future<List<City>> searchCities(String query) async {
    final response = await http
        .get(Uri.parse(
            '$_base/listaCidades?city=${Uri.encodeQueryComponent(query)}'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Serviço CPTEC indisponível (${response.statusCode}).');
    }
    final doc = XmlDocument.parse(response.body);
    return doc
        .findAllElements('cidade')
        .map((e) {
          final id = _text(e, 'id');
          final name = _text(e, 'nome');
          final state = _text(e, 'uf');
          if (id.isEmpty || name.isEmpty) return null;
          return City(id: id, name: name, state: state.isEmpty ? 'BR' : state);
        })
        .whereType<City>()
        .toList();
  }

  Future<Forecast> getForecast(City city) async {
    final response = await http
        .get(Uri.parse('$_base/cidade/${city.id}/previsao.xml'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
          'Não foi possível carregar a previsão (${response.statusCode}).');
    }
    final doc = XmlDocument.parse(response.body);
    final root = doc.rootElement;
    final days = root.findElements('previsao').map((e) {
      final raw = _text(e, 'tempo').toLowerCase().trim();
      return ForecastDay(
        date: _text(e, 'dia'),
        condition:
            _conditions[raw] ?? (raw.isEmpty ? 'Condição não informada' : raw),
        min: _text(e, 'minima'),
        max: _text(e, 'maxima'),
        uv: _text(e, 'iuv').isEmpty ? null : _text(e, 'iuv'),
      );
    }).toList();
    if (days.isEmpty) {
      throw Exception('Não há previsão disponível para ${city.name}.');
    }
    return Forecast(
        city: city, updatedAt: _text(root, 'atualizacao'), days: days);
  }

  static String _text(XmlElement element, String name) {
    final values = element.findElements(name);
    return values.isEmpty ? '' : values.first.innerText.trim();
  }
}
