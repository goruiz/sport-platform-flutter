# Instrucciones para Claude en este proyecto

## Cómo trabajar (siempre)

### Mentalidad

- Pensar siempre como un **desarrollador senior** y un **diseñador UX/UI senior** al mismo tiempo: no basta con que el código funcione, la experiencia de usuario resultante también debe tener sentido.

### Coherencia con lo existente

- **Siempre seguir los patrones, la arquitectura y la estructura de carpetas ya implementados.** No introducir un patrón, una convención ni una forma de organizar el código distinta a la existente sin que se pida explícitamente.
- Antes de crear archivos nuevos, revisar cómo está resuelto en un módulo ya maduro (ej. `events/event_types/leagues`) y seguir ese mismo patrón.

### Legibilidad

- El código debe ser **muy fácil de entender para cualquier persona**, no solo para quien lo escribió.
- Los nombres de clases, variables, funciones, widgets, archivos, etc. deben dejar **muy claro qué hacen**, sin miedo a que sean largos.
  - **Excepción:** el nombre del **archivo** debe ser claro pero **no demasiado largo** — nombres de archivo muy largos rompen la subida de cambios (límite de longitud de ruta en Windows). Si un nombre de archivo se vuelve muy largo, acortarlo sin perder claridad (abreviar palabras obvias, quitar redundancia con la carpeta contenedora, etc.).
- Los comentarios deben ser **precisos, claros y concretos**, nunca exhaustivos: explican el *porqué* de lo que no es evidente, no repiten lo que el código ya dice.

### Estructura y calidad

- El código debe ser siempre **ordenado, eficiente y escalable**.
- Los métodos/funciones **no deben ser demasiado largos**: cuando crezcan, dividirlos en submétodos con nombres descriptivos, cada uno con una única responsabilidad. En la UI, extraer sub-widgets en lugar de anidar `build` gigantes.
- Los métodos/funciones/widgets deben ser **reutilizables**: evitar duplicar lógica y extraerla a un método o widget común cuando aplique.

### Nada fijo en el código

- **Nada debe estar fijo ("hardcodeado"): todo debe ser dinámico** (textos, rutas, URLs, ids, límites, colores, etc. vienen de configuración, datos, traducciones o del tema).
- Si algo **necesariamente** debe ser fijo (estados, tipos, roles, etc.), modelarlo con un **`enum`** en lugar de strings o números mágicos. Ubicarlo en el módulo al que pertenece, o en `lib/shared/enums/` si lo usan varios módulos.

## Proyectos relacionados (monorepo lógico "Plataforma deportiva")

- Frontend usuario (este proyecto, Flutter): `C:\Users\WALDO\Documents\Proyectos\Plataforma deportiva\frontend\usuario-flutter`
- Frontend admin (Angular): `C:\Users\WALDO\Documents\Proyectos\Plataforma deportiva\frontend\administration-angular`
- Backend (Spring Boot): `C:\Users\WALDO\Documents\Proyectos\Plataforma deportiva\backend`

## Stack del proyecto

- **Flutter/Dart** (`sdk: ^3.11.5`). App: `sport_platform`.
- **Estado**: `provider` (`ChangeNotifier`) es lo que realmente se usa (ej. `events_notifier.dart`, `league_detail_notifier.dart`), combinado con `StatefulWidget`/`setState` en pantallas simples. Las carpetas `application/bloc` y `application/cubit` existen en varios módulos pero están **vacías** (scaffolding sin implementar) — no asumir Bloc/Cubit real, y no llenarlas "porque están ahí" salvo que se pida migrar a Bloc explícitamente.
- **DI**: `get_it` como service locator (`lib/core/di/service_locator.dart`), registrando servicios/repositorios/notifiers como lazy singletons.
- **Navegación**: `Navigator` clásico (`MaterialPageRoute`), sin go_router/auto_route. Rutas de módulo se arman vía `AppRouteFactory` + `ModuleRegistry`. Deep links con `app_links` (ej. invitaciones de registro).
- **HTTP**: `dio` envuelto en `DioClient` (`lib/core/network/dio_client.dart`) con interceptor de auth (`Authorization: Bearer <token>`) y `KeyFormatInterceptor`. Endpoints centralizados en `ApiEndpoints`.
- **Persistencia**: solo `shared_preferences`. Token de sesión vía `AuthStorage` (cache en memoria + `SharedPreferences`, key `auth_token`). No hay Hive/sqflite/secure storage.
- **i18n**: `easy_localization`, locales `es/en/fr/de`, fallback `es`, JSON en `assets/translations/`. Los textos visibles al usuario deben ir a estos archivos de traducción, no hardcodeados en el widget.
- **Lint**: `analysis_options.yaml` usa `flutter_lints` sin overrides — respetar esas reglas por defecto, no relajarlas.

## Arquitectura y estructura de carpetas

Patrón clean-architecture por módulo bajo `lib/modules/<feature>/`:

- `application/{bloc,cubit,state}` — scaffolding, en la práctica mayormente vacío (ver nota de estado arriba).
- `data/{datasource,mapper,models,repositories}` — llamadas HTTP/fuentes de datos, mapeo a modelos, implementación de repositorios.
- `domain/{entities,repositories,usecases}` — entidades de negocio e interfaces de repositorio (contrato), independientes de Flutter/dio.
- `presentation/{pages,widgets}` — UI del módulo.

Módulos existentes: `auth, events, home, matches, players, rankings, reports, teams, users`. Muchos tienen solo `.gitkeep` en varias capas (scaffolding pendiente) — antes de implementar algo nuevo en un módulo poco maduro, mirar `events/event_types/leagues` como referencia de cómo se ve el patrón completo y maduro.

- `lib/core/` — transversal técnico: `config, constants, di, errors, modules, network, routes, services, theme, utils`.
- `lib/shared/` — transversal de dominio/UI reutilizable: `enums, extensions, mixins, models, services, widgets`.

Un módulo nuevo debe replicar esta misma carpeta interna (`data/domain/presentation`), no inventar una organización distinta.

## Testing

- Prácticamente no hay cobertura real: solo `test/widget_test.dart` con un smoke test del login. No asumas que existen tests de un flujo antes de verificarlo.
- Si agregas lógica nueva, favorece que sea testeable (separar lógica de UI en notifiers/usecases), aunque no se exija escribir el test en el mismo cambio salvo que se pida explícitamente.

## Cosas a tener en cuenta / no replicar

- El `login_page.dart` tiene credenciales de prueba precargadas con comentario `// DEV:` — es deuda de desarrollo, no un patrón a copiar en otras pantallas.
