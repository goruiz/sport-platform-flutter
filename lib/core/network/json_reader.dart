/// El backend rompió su contrato: faltó un campo que siempre manda o trajo uno con otro formato. Se avisa con el recurso
/// y el campo para poder corregirlo, en vez de enseñar un dato inventado (una fecha de «hoy», un id vacío).
class MalformedResponseException implements Exception {
  final String resource;
  final String field;
  final String problem;

  const MalformedResponseException({required this.resource, required this.field, required this.problem});

  @override
  String toString() => 'MalformedResponseException: $resource.$field $problem';
}

/// Lee los campos de un objeto JSON del backend. Hay tres formas de pedir un campo y cada una dice qué pasa si falta:
///
///  - `required…`: lo que el backend siempre manda (la clave primaria, una columna `NOT NULL`, lo que sus formularios
///    exigen). Si falta o viene mal es un [MalformedResponseException]; nunca se inventa un valor.
///  - `optional…`: lo que puede no estar. Si falta es `null` y quien lo usa decide qué mostrar.
///  - [textOrEmpty] y [flag]: un texto de pantalla opcional («sin descripción») y un marcador que solo es verdadero si el
///    backend lo manda verdadero.
class JsonReader {
  final Map<String, dynamic> _json;

  /// El recurso que se lee («partido», «equipo»…), para el mensaje de error.
  final String resource;

  const JsonReader(this._json, {required this.resource});

  String requiredString(String field) => _required(field).toString();

  String? optionalString(String field) => _json[field]?.toString();

  /// Un texto que se muestra tal cual y que, si falta, se deja en blanco.
  String textOrEmpty(String field) => _json[field]?.toString() ?? '';

  int requiredInt(String field) => _asInt(field, _required(field))!;

  int? optionalInt(String field) => _asInt(field, _json[field]);

  double? optionalDouble(String field) {
    final value = _json[field];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw _problem(field, 'no es un número: «$value»');
  }

  DateTime requiredDateTime(String field) => _asDateTime(field, _required(field))!;

  DateTime? optionalDateTime(String field) => _asDateTime(field, _json[field]);

  /// Verdadero solo si el backend manda `true`.
  bool flag(String field) => _json[field] == true;

  /// Una lista de objetos. Si falta se toma como vacía (un backend que no manda las listas vacías no inventa nada) y lo
  /// que [parse] no sepa leer —devuelve null— se descarta, como las etapas que esta versión de la app no conoce.
  List<T> list<T>(String field, T? Function(Map<String, dynamic> json) parse) {
    final value = _json[field];
    if (value == null) return const [];
    if (value is! List) throw _problem(field, 'no es una lista');
    return value.whereType<Map<String, dynamic>>().map(parse).whereType<T>().toList();
  }

  /// Un objeto anidado, o null si falta.
  JsonReader? optionalObject(String field, {String? resource}) {
    final value = _json[field];
    if (value == null) return null;
    if (value is! Map<String, dynamic>) throw _problem(field, 'no es un objeto');
    return JsonReader(value, resource: resource ?? '${this.resource}.$field');
  }

  dynamic _required(String field) {
    final value = _json[field];
    if (value == null) throw _problem(field, 'falta');
    return value;
  }

  int? _asInt(String field, dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    throw _problem(field, 'no es un número: «$value»');
  }

  DateTime? _asDateTime(String field, dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) throw _problem(field, 'no es una fecha: «$value»');
    return parsed;
  }

  MalformedResponseException _problem(String field, String problem) =>
      MalformedResponseException(resource: resource, field: field, problem: problem);
}
