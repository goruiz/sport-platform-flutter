import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las reglas de quién puede importar a quién en `lib/`. Se leen los `import` y `export` de cada archivo, así que el test
/// falla en cuanto alguien rompe la estructura, con la lista exacta de imports que lo causan:
///
///  1. `core/` no importa `shared/` ni `modules/` (solo el ensamblaje, que conoce todo, puede importar módulos).
///  2. `shared/` no importa `modules/`.
///  3. Lo que no es presentación de un módulo (`data/`, `domain/`) nunca importa la presentación de otro.
///  4. Los módulos no se importan en círculo. Cada módulo cuenta como dos nodos —su presentación y todo lo demás—, de modo
///     que una pantalla puede usar widgets de otro módulo, pero el otro módulo no puede volver a usar los suyos.
///
/// Si necesitas algo de otro módulo y la regla te lo impide, la salida es subirlo a `shared/` (o a `core/`, si lo usa el
/// ensamblaje) o pedirlo por `AppPages` (`core/routes`) cuando es solo navegar a una pantalla.
void main() {
  final imports = _readImports();

  test('core/ no importa shared/ ni modules/ (salvo el ensamblaje)', () {
    final offenders = imports.where((i) =>
        i.fromArea == _Area.core &&
        !_assemblyFiles.contains(i.from) &&
        (i.toArea == _Area.shared || i.toArea == _Area.modules));

    expect(offenders, isEmpty, reason: _explain('core/ solo puede apoyarse en core/', offenders));
  });

  test('shared/ no importa modules/', () {
    final offenders = imports.where((i) => i.fromArea == _Area.shared && i.toArea == _Area.modules);

    expect(offenders, isEmpty, reason: _explain('shared/ no puede conocer a ningún módulo', offenders));
  });

  test('data/ y domain/ nunca importan la presentación de otro módulo', () {
    final offenders = imports.where((i) =>
        i.fromArea == _Area.modules &&
        i.toArea == _Area.modules &&
        i.fromModule != i.toModule &&
        !i.fromNode.isPresentation &&
        i.toNode.isPresentation);

    expect(offenders, isEmpty, reason: _explain('el estado que otros consumen va en data/, no en presentation/', offenders));
  });

  test('los módulos no se importan en círculo', () {
    final cycles = _findCycles(imports);

    expect(cycles, isEmpty, reason: _explainCycles(cycles, imports));
  });
}

/// Los dos archivos que arman la app y por eso conocen todos los módulos: registrar servicios y registrar pantallas.
const _assemblyFiles = {'core/di/service_locator.dart', 'core/modules/modules_setup.dart'};

enum _Area { core, shared, modules, other }

/// Una pieza del grafo: un módulo y su capa. La presentación va aparte porque es lo único que puede depender de otras
/// presentaciones sin que eso arrastre a las capas de datos.
class _Node {
  final String module;
  final bool isPresentation;

  const _Node(this.module, this.isPresentation);

  @override
  bool operator ==(Object other) => other is _Node && other.module == module && other.isPresentation == isPresentation;

  @override
  int get hashCode => Object.hash(module, isPresentation);

  @override
  String toString() => '$module (${isPresentation ? 'presentation' : 'data/domain'})';
}

class _Import {
  final String from;
  final String to;

  const _Import(this.from, this.to);

  _Area get fromArea => _areaOf(from);
  _Area get toArea => _areaOf(to);
  String get fromModule => _moduleOf(from);
  String get toModule => _moduleOf(to);
  _Node get fromNode => _nodeOf(from);
  _Node get toNode => _nodeOf(to);

  @override
  String toString() => '$from -> $to';
}

_Area _areaOf(String path) {
  if (path.startsWith('core/')) return _Area.core;
  if (path.startsWith('shared/')) return _Area.shared;
  if (path.startsWith('modules/')) return _Area.modules;
  return _Area.other;
}

String _moduleOf(String path) {
  final parts = path.split('/');
  return parts.length > 2 && parts[0] == 'modules' ? parts[1] : '';
}

_Node _nodeOf(String path) {
  final parts = path.split('/');
  return _Node(_moduleOf(path), parts.skip(2).contains('presentation'));
}

/// Todos los `import` y `export` de `lib/` que apuntan a otro archivo del proyecto, con rutas relativas a `lib/`.
List<_Import> _readImports() {
  final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);
  const packagePrefix = 'package:sport_platform/';
  final imports = <_Import>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final from = entity.path.replaceAll('\\', '/').substring('lib/'.length);

    for (final match in directive.allMatches(entity.readAsStringSync())) {
      final target = match.group(1)!;
      if (target.startsWith(packagePrefix)) {
        imports.add(_Import(from, target.substring(packagePrefix.length)));
      } else if (!target.contains(':')) {
        // Un import relativo: se resuelve contra la carpeta del archivo que lo escribe.
        final resolved = Uri.parse('lib/$from').resolve(target).path;
        imports.add(_Import(from, resolved.substring('lib/'.length)));
      }
    }
  }
  return imports;
}

/// Los grupos de nodos que se alcanzan unos a otros (componentes fuertemente conexos de más de un nodo).
List<List<_Node>> _findCycles(List<_Import> imports) {
  final graph = <_Node, Set<_Node>>{};
  for (final i in imports) {
    if (i.fromArea != _Area.modules || i.toArea != _Area.modules || i.fromNode == i.toNode) continue;
    graph.putIfAbsent(i.fromNode, () => {}).add(i.toNode);
    graph.putIfAbsent(i.toNode, () => {});
  }

  final index = <_Node, int>{};
  final lowLink = <_Node, int>{};
  final stack = <_Node>[];
  final onStack = <_Node>{};
  final cycles = <List<_Node>>[];
  var counter = 0;

  void visit(_Node node) {
    index[node] = lowLink[node] = counter++;
    stack.add(node);
    onStack.add(node);
    for (final next in graph[node]!) {
      if (!index.containsKey(next)) {
        visit(next);
        lowLink[node] = lowLink[node]! < lowLink[next]! ? lowLink[node]! : lowLink[next]!;
      } else if (onStack.contains(next)) {
        lowLink[node] = lowLink[node]! < index[next]! ? lowLink[node]! : index[next]!;
      }
    }
    if (lowLink[node] == index[node]) {
      final group = <_Node>[];
      late _Node member;
      do {
        member = stack.removeLast();
        onStack.remove(member);
        group.add(member);
      } while (member != node);
      if (group.length > 1) cycles.add(group);
    }
  }

  for (final node in graph.keys) {
    if (!index.containsKey(node)) visit(node);
  }
  return cycles;
}

String _explain(String rule, Iterable<_Import> offenders) =>
    '$rule. Imports que la rompen:\n${offenders.map((i) => '  $i').join('\n')}';

String _explainCycles(List<List<_Node>> cycles, List<_Import> imports) {
  final lines = <String>['Estos módulos se importan en círculo:'];
  for (final cycle in cycles) {
    lines.add('  ${cycle.join(' <-> ')}');
    final members = cycle.toSet();
    for (final i in imports) {
      if (i.fromArea == _Area.modules && i.toArea == _Area.modules && members.contains(i.fromNode) && members.contains(i.toNode) && i.fromNode != i.toNode) {
        lines.add('    $i');
      }
    }
  }
  return lines.join('\n');
}
