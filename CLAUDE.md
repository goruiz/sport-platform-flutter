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

---

# Contexto de la plataforma

> Sección añadida el 2026-10-12 tras analizar los 3 proyectos y la carpeta `Documentación/` del monorepo. Está verificada contra el **código**, no contra los documentos de diseño. **Si algo de aquí contradice una sección anterior de este archivo, prevalece esto**: varias secciones previas quedaron desactualizadas (se señalan en "Estado real" de cada proyecto). El bloque "Visión de la plataforma" es idéntico en los 3 CLAUDE.md: si lo cambias, cámbialo en los 3.

## Visión de la plataforma (bloque común a los 3 proyectos)

### Qué es y para quién

- Plataforma **a medida para gestionar campeonatos deportivos** (ligas, torneos): varios campeonatos y eventos a la vez, categorías/divisiones y proyección a nivel nacional. El partido se modela con goles, asistencias, tarjetas y faltas.
- Dos tipos de usuario, una app para cada uno:
  - **Organizador / administrador** → panel web Angular, solo para administradores. Gestiona usuarios, categorías, equipos, jugadores, eventos, canchas, partidos, resultados, reportes y configuración.
  - **Usuario final (jugador, capitán)** → app Flutter. Perfil, equipos, partidos, eventos y ligas, tablas de posiciones, canchas, estadísticas y reportes de su equipo.
- Idioma por defecto: español. Ambos frontends traducen además a `en`, `fr` y `de`.

### Las 3 piezas

| Pieza | Carpeta | Stack | Rol |
|---|---|---|---|
| Backend | `backend` | Java 25, Spring Boot 4, PostgreSQL | API REST única para los dos frontends (`http://localhost:8080/api`, Swagger en `/api/swagger-ui.html`) |
| Admin web | `frontend/administration-angular` | Angular 21 + CoreUI | Panel de organizadores |
| App usuario | `frontend/usuario-flutter` | Flutter | App de jugadores (en la práctica Android, web y Windows) |

Los 3 son repos git independientes. La carpeta `Documentación/` (en la raíz del monorepo, fuera de los repos) guarda la propuesta y el plan de trabajo acordados con el cliente, `documentacion_tecnica.docx` y dumps SQL antiguos.

- **El documento técnico es un borrador (v1.0, abril 2026) y describe una intención, no la realidad**: habla de Java 21 / Spring Boot 3, base `/api/v1`, JWT con refresh token, BLoC/Riverpod en Flutter, roles PLAYER/CAPTAIN/TEAM_ADMIN/SYSTEM_ADMIN con matriz de permisos y módulos de auditoría, rankings, reportes y configuración. Nada de eso existe tal cual en el código. Úsalo para entender qué quiere el negocio, nunca como contrato técnico.
- El plan acordado (24 ago – 20 sep 2026) ordena la entrega: 1) acceso de administradores y usuarios, 2) categorías, equipos y jugadores, 3) eventos y canchas, 4) partidos, resultados, dashboard, reportes y configuración.

### Estado de implementación (oct 2026)

| Dominio | Backend | Admin (Angular) | App usuario (Flutter) |
|---|---|---|---|
| Auth, usuarios y roles | ✅ | ✅ lista, alta con contraseña temporal por email, edición, borrado y asignación de roles | Login, registro y completar perfil |
| Menú dinámico por rol | ✅ | ✅ sidebar | ✅ Home (barra inferior y acciones rápidas) |
| Eventos y ligas | ✅ | ✅ CRUD de eventos (lista con búsqueda y filtros, alta, edición y borrado lógico); sin equipos, partidos ni calendario | ✅ **único módulo maduro** (`leagues`) |
| Equipos, jugadores e invitaciones | ✅ | ✅ CRUD de equipos (lista con búsqueda y filtros, alta, edición, estado y borrado lógico) y lista de jugadores de cada equipo (solo lectura); sin alta de jugadores ni invitaciones | ✅ dentro de ligas |
| Partidos, calendario automático y posiciones | ✅ | ❌ | ✅ dentro de ligas |
| Canchas y complejos | ✅ CRUD | ❌ | solo lectura (selector al programar) |
| Categorías | ✅ CRUD | ✅ CRUD (lista con búsqueda, alta, edición y borrado lógico; solo si ningún equipo ni evento la usa) | ❌ |
| Rankings, estadísticas, reportes, auditoría, configuración global | ❌ no existen (solo el CRUD crudo de eventos de partido) | ❌ | placeholders "Próximamente" |
| Dashboard | n/a | demo de la plantilla con datos falsos | Home con tarjetas vacías |

### Contrato común backend ↔ frontends (no romper sin avisar)

- Toda respuesta va en `ApiResponse<T> = {success, status, message, data, timestamp}`. Un 400 de validación trae en `data` un mapa `campo → motivo`. Los dos frontends desenvuelven `data` a mano: no hay cliente generado ni librería compartida, así que **un cambio de endpoint o DTO hay que reflejarlo a mano en el servicio de Angular y en el de Flutter**.
- Base `/api` (context-path). Autenticación: `Authorization: Bearer <JWT>`. El JWT dura 24 h y **no hay refresh**. Un token ausente, vencido o inválido en un endpoint protegido responde **401** con `ApiResponse` (antes 403 o un error 500); los dos frontends lo usan para cerrar la sesión (Angular en `authInterceptor`, Flutter en `UnauthorizedInterceptor`).
- **Login**: `POST /users/auth/login` con `email`, `password` y `clientType`. `ADMIN_PANEL` solo admite administradores y `MOBILE_APP` rechaza administradores; si no corresponde, el backend responde 403. Es el único control de "quién entra a qué app".
- **La API no autoriza por rol**: solo exige un JWT válido. Que un endpoint sea "de admin" es hoy una convención de qué app lo llama, no una protección. No asumas que el backend bloquea a un usuario de la app móvil.
- **Admin** = el usuario tiene una fila activa en `users_roles` con el UUID de `app.security.admin-role-id` (backend). Angular repite ese UUID en `environment*.ts` (`adminRoleId`) y **los dos deben coincidir**. Los nombres de rol son editables: nunca comparar por nombre.
- **Menú dinámico**: la navegación de ambos frontends sale de la tabla `menu` del backend. Cada ítem trae `url`, `icon` y `translationKey`. Ambos frontends llaman `GET /menu/for-current-user` (filtrado por los roles del usuario). **Un usuario sin rol, o con un rol sin filas visibles en `roles_menu`, recibe el menú vacío**: hoy el registro no asigna ningún rol, así que a los usuarios de la app hay que darles uno con sus ítems de menú. Para agregar una pantalla: (1) ruta/página en el frontend, (2) ítem en `menu` con esa misma `url`, (3) claves de traducción. Si el frontend no conoce la `url`, el ítem cae a un fallback (Angular redirige a `/dashboard`; Flutter muestra un placeholder).
- **i18n**: claves `modulo.snake_case`, resueltas como `translationKey ?? name`. El `TranslationService` de Angular está calcado de `easy_localization` de Flutter.
- **Invitaciones a equipos**: el backend envía un correo con `<app.frontend.url>/register?inviteToken=<token>`, que abre el registro por invitación de la app Flutter (deep link; en dev `app.frontend.url` apunta a Flutter web en el puerto 5021).

## Contexto de este proyecto: app de usuario Flutter (estado real)

### Qué hace hoy

- App del usuario final. El login envía siempre `clientType=MOBILE_APP` (el backend rechaza a los administradores). Flujos reales: login; registro abierto (email + password) que lleva a `CompleteProfilePage`, que guarda el perfil con `PUT /users/auth/update-profile` (se puede omitir); registro por invitación mediante deep link; Home dinámico; **Ligas**; cambio de idioma y logout.
- **Ligas (`/ligas`) es el único módulo de negocio funcional**:
  - Listado con pestañas "Mis ligas / Todas". Crear, editar y borrar liga solo si eres el creador (`isOwner` sale de `GET /events/by-event-type/{typeId}/by-user/{userId}`).
  - Detalle con 4 pestañas: Info (edición en línea), Equipos, Partidos y Posiciones (las calcula el backend).
  - Equipos: agregar uno existente, crear uno nuevo y gestionar jugadores (buscar por email, invitar a un usuario existente, enviar enlace de registro a uno no registrado, quitar).
  - Partidos: CRUD, aplazar, suspender, reprogramar (uno o un día completo) y auto-programación.

### Estado por módulo (`lib/modules/<m>/`)

| Módulo | Estado real | Dónde mirar |
|---|---|---|
| `events/event_types/leagues` | **Maduro**, referencia de patrón (clean-arch completa salvo `domain/entities`) | `data/datasource/*_service.dart`, `data/models/`, `domain/{enums,repositories}`, `presentation/{pages,providers,widgets}`, guía `LEAGUES.md` |
| `events/shared` | Implementado: base reutilizable para cualquier tipo de evento | `event_service.dart`, `events_notifier.dart`, `event_type_page.dart`, `event_form_sheet.dart` |
| `events` (raíz), `teams`, `matches`, `rankings`, `reports` | **Placeholder**: una página con `PlaceholderTab` ("Próximamente") y capas `.gitkeep` | `presentation/pages/<m>_page.dart` |
| `home` | A medias: menú y acciones rápidas salen de `GET /menu/for-current-user`; `home_tab.dart` es **estático** (invitaciones, próximo evento, equipos y actividad son tarjetas vacías) | `home_page.dart`, `menu_service.dart`, `menu_item_model.dart` |
| `auth` | Solo UI. No hay datasource ni repositorio: las páginas llaman a `DioClient` directamente | `login_page.dart`, `register_page.dart` |
| `players` | Parcial y sin el layout estándar: solo el registro por invitación. Su lógica principal (`PlayersService`, `PlayerModel`) vive dentro de `leagues` | `players_auth_service.dart`, `invite_register_page.dart` |
| `users` | Parcial: `CompleteProfilePage` real (`IUserProfileRepository` → `UserProfileService`, `UserModel`, `UserProfileUpdate`) y `profile_page.dart` (placeholder) | `data/datasource/user_profile_service.dart` |

Hay 122 archivos `.dart` y 104 `.gitkeep`. Las carpetas `application/{bloc,cubit,state}` están vacías en todos los módulos.

### Backend: URL base y endpoints

- `AppConfig.baseUrl` (`core/config/app_config.dart`) se elige con `--dart-define=APP_ENV=dev|staging|prod` (por defecto `dev`), y `--dart-define=API_BASE_URL=...` la reemplaza por completo. Las URLs están fijas en el código: dev `http://localhost:8080/api`; staging y prod `https://…sports-platform.com/v1`. Las de staging/prod terminan en `/v1`, no en el `/api` que sirve el backend ni coinciden con las de Angular: parecen placeholders sin validar.
- **Android**: en `dev`, `AppConfig` usa `10.0.2.2` (el alias de la PC en el emulador); en web y escritorio, `localhost`. Para un dispositivo físico: `--dart-define=API_BASE_URL=http://<ip-de-la-PC>:8080/api` (o `adb reverse tcp:8080 tcp:8080` con `API_BASE_URL=http://localhost:8080/api`). El manifest principal declara `INTERNET` y el tráfico `http` (`usesCleartextTraffic`) solo se permite en los manifests de debug/profile. **No se verificó con un build real de Android** (la máquina donde se hizo no tiene el SDK).
- `DioClient` (`core/network/dio_client.dart`): timeout de 20 s, `Authorization: Bearer` y `KeyFormatInterceptor` (solo convierte si se cambia `AppConfig.apiKeyFormat`). Cada servicio crea su propio `DioClient()`. `ResponseParser` acepta el valor directo o envuelto en `{"data": …}`.
- Endpoints consumidos (rutas en `ApiEndpoints`, `core/network/api_endpoints.dart`):
  - Auth: `POST /users/auth/login`, `/register`, `/logout`; `PUT /users/auth/update-profile` (completar perfil); `POST /players/auth/register` (invitación).
  - Menú: `GET /menu/for-current-user`.
  - Eventos: `GET /events/by-event-type/{typeId}` y `.../by-user/{userId}`, `POST /events`, `PUT|DELETE /events/{id}`, `GET /events/{id}/standings`, `GET|POST /events/{id}/schedule-config`, `POST /events/{id}/schedule-config/generate`.
  - Equipos: `GET|POST /teams`, `GET /teams-events/by-event/{eventId}`, `POST /teams-events`, `DELETE /teams-events/{id}/hard`.
  - Partidos: `GET /matches/by-event/{eventId}`, `POST /matches`, `PUT|DELETE /matches/{id}`, `PATCH /matches/{id}/postpone|suspend|reschedule`, `PATCH /matches/by-event/{eventId}/reschedule-date`.
  - Jugadores: `GET /players/by-team/{teamId}`, `GET /players/search?email=` (un 404 significa "no existe"), `POST /players/invite`, `POST /players/invite-register`, `PATCH /players/{id}/remove-from-team`.
  - Canchas: `GET /courts`.
- Definidos en `ApiEndpoints` pero sin uso: `refreshToken`, `users`, `sportComplexes`, `rankings`, `reports` y otros.

### Navegación y módulos dinámicos

- `Navigator` clásico (`MaterialPageRoute`). `main.dart` decide entre `HomePage` y `LoginPage` según `AuthStorage.hasToken()`.
- Cada pantalla de módulo se conecta así: la `url` del ítem de menú (columna `menu.url` del backend) se busca en `ModuleRegistry` (`core/modules/modules_setup.dart`, una línea `register` por módulo, con las URLs en `module_urls.dart`). `AppRouteFactory` abre la página o la pestaña. Una `url` no registrada cae en un placeholder genérico.
- La URL real de ligas es **`/ligas`** (no `/leagues`).
- El menú se pide a `GET /menu/for-current-user`, filtrado por rol igual que en Angular. **Un usuario sin rol o sin filas visibles en `roles_menu` ve el menú vacío** (sin barra inferior ni acciones rápidas): el registro no asigna ningún rol, así que hay que dárselo y concederle los ítems en `roles_menu`.
- `HomePage`: la barra inferior (se oculta con menos de 2 ítems) y las acciones rápidas salen del menú; el índice 0 de la barra es **siempre** `HomeTab`, aunque `navItems[0].url` apunte a otra cosa. Los ítems con hijos abren un `ChildrenSheet`.

### Auth, sesión y deep links

- Token en `AuthStorage` (memoria + `SharedPreferences`, clave `auth_token`). La sesión (`UserSession`) decodifica el JWT a mano y se guarda en `user_session`. `AuthStorage` y `UserSession` son clases estáticas con estado global: difíciles de testear.
- **Sesión vencida**: `UnauthorizedInterceptor` (red) detecta un 401 en una petición que llevaba token (excepto login y logout) y avisa a `SessionExpiredListener` (interfaz en `core/services`), que implementa `SessionExpiredHandler` (`shared/services`): limpia la sesión, lleva al login con `AppNavigator.key` y muestra el aviso `session.expired`; varios 401 simultáneos cierran la sesión una sola vez. No hay refresh de token. El login muestra "credenciales inválidas" ante cualquier excepción.
- Logout (`shared/widgets/logout_button.dart`): confirma, llama a `POST /users/auth/logout` (ignora el fallo) y limpia con `SessionService.clear()`, igual que la sesión vencida: borra token y usuario y descarta el estado en memoria del usuario (`_resetSessionScopedServices` en `service_locator.dart`; **si agregas un notifier con datos del usuario, resetéalo ahí**). Luego vuelve al login.
- Deep link de invitación (`app_links`): `…/register?inviteToken=<token>`, el único soportado. Android declara `http://localhost:5021/register`, `https://yourdomain.com/register` (**placeholder sin reemplazar**) y el esquema `sportplatform://`; iOS solo el esquema `sportplatform://` (sin Universal Links). Tras registrarse, la invitación lleva al login: no inicia sesión sola.

### Tema y convenciones de UI

- `core/theme/app_theme.dart`: un único tema **oscuro** (sin tema claro ni `themeMode`). Paleta verde en `AppColors` (`primary 2E7D32`, fondos degradados, translúcidos para inputs, colores semánticos y de podio). Casi todos los widgets fijan colores a mano con `AppColors.*` en vez de `Theme.of(context)`.
- Widgets compartidos en `lib/shared/widgets/`: `GradientBackground`, `SportTextField`, `AppSnackbar`, `showConfirmationDialog`, `EmptyState`, `ErrorRetry`, `StatusBadge`, `SheetHandle`, `LanguageSelector`, `LogoutButton`; mixin `SnackMixin`.
- Convenciones observables: cada página de módulo recibe `MenuItemModel item` y usa `Scaffold(backgroundColor: backgroundEnd)` + `AppBar(backgroundColor: primaryDark)`; formularios y acciones en bottom sheets con `static show(...)`, fondo `sheetBackground`, esquinas de 20 y `SheetHandle`; listas con `RefreshIndicator`, padding inferior de 100 por el FAB y estados de carga, error y vacío; la UI se parte en métodos `_buildX()`; imports absolutos `package:sport_platform/...`; los widgets con texto traducido leen `context.locale;` en `build` para reaccionar al cambio de idioma.

### i18n (estado)

- `easy_localization`: `es` (por defecto, siempre arranca en español), `en`, `fr`, `de`, en `assets/translations/{es,en,fr,de}.json`. El idioma elegido **no se persiste**.
- **`fr` y `de` tienen 45 claves menos que `es` y `en`**: faltan las de `leagues.*` (auto-programación, días, estados) y esas pantallas caen al español. Al agregar claves, agrégalas en los 4 archivos.
- Conviven dos estilos: clases de constantes en `core/constants/strings_constants/` (auth, home, perfil, logout) y literales `'leagues.xxx'.tr()` (ligas e invitación). Para código nuevo sigue el estilo del módulo donde trabajas.
- `EventTypePage` es genérico y recibe un `translationPrefix`: **un tipo de evento nuevo necesita su bloque completo de claves bajo su propio prefijo**.

### Cómo agregar un tipo de evento nuevo (replica `leagues`)

1. UUID del tipo en `core/constants/event_type_ids.dart` (es el id del tipo en la BD).
2. Carpeta `lib/modules/events/event_types/<tipo>/` con `data/{datasource,models}`, `domain/{enums,repositories}` y `presentation/{pages,providers,widgets}`. (`ARCHITECTURE_GUIDE.txt` propone `events/tournaments/`, que no coincide con la estructura real.)
3. `<Tipo>Service extends EventService` con `super(eventTypeId: EventTypeIds.<tipo>)` (ver `league_service.dart`).
4. Registrar en `core/di/service_locator.dart` un `EventsNotifier` con `instanceName: '<tipo>'` y los repositorios de detalle que necesite (`abstract interface class I<…>Repository`).
5. Página de entrada: `ChangeNotifierProvider.value(getIt<EventsNotifier>(instanceName: '<tipo>'))` + `EventTypePage(...)`.
6. `core/modules/module_urls.dart` y una línea en `core/modules/modules_setup.dart`.
7. Endpoints nuevos en `ApiEndpoints` y bloque de traducciones en los 4 JSON.
8. Insertar el ítem en la tabla `menu` del backend con la misma `url` (si el icono es nuevo, agregarlo a `_filledIcons`/`_outlinedIcons` en `menu_item_model.dart`).
9. Correr `flutter analyze`.

### Comandos

Desde `frontend/usuario-flutter/`: `flutter pub get`, `flutter run` (entorno `dev`), `flutter run -d chrome --web-port 5021` (coincide con `app.frontend.url` del backend, necesario para probar invitaciones), `flutter run -d windows`, `flutter run --dart-define=API_BASE_URL=http://<ip-de-la-PC>:8080/api` (dispositivo físico), `flutter run --dart-define=APP_ENV=staging`, `flutter analyze` (debe quedar sin issues antes de commitear), `flutter test`. No hay flavors ni scripts.

### Tests y deuda técnica (no replicar)

- Hay tests de: el login (`test/widget_test.dart`, con `EasyLocalization` y `SharedPreferences` simulados; el `setUpAll` simula primero las preferencias porque `EasyLocalization.ensureInitialized()` las lee), `AppConfig`, `UnauthorizedInterceptor`, `SessionService`, `SessionExpiredHandler` y `UserProfileService`. **Sin tests**: notifiers, servicios y modelos de ligas.
- Código de prueba o sin terminar: `login_page.dart` con credenciales precargadas (`// DEV:`); subida del logo de equipo sin implementar (`logoUrl` siempre se envía `null`); firma release de Android con la de debug y `applicationId` `com.example.sport_platform`; `README.md` es la plantilla de Flutter; `.claude/settings.json` commiteado con rutas de otra máquina.
- Falta de permisos de plataforma: iOS sin `NSPhotoLibraryUsageDescription`/`NSCameraUsageDescription` (que `image_picker` necesita) y macOS sin `network.client`.
- Tres implementaciones de snackbar conviven (`AppSnackbar`, `SnackMixin` y `_showSnack` duplicado). Usa `AppSnackbar`.
- Strings sueltos donde debería haber `enum`: `EventModel.format/status`, `TeamModel.status`, `PlayerModel.status`, `playDays`. Valores fijos que deberían salir de constantes: `DateTime(2020)`/`DateTime(2035)` en `EventFormSheet` y los defaults `'90'`, `'15'`, `'30'` en `AutoScheduleSheet`. `PlaceholderTab` tiene "Próximamente" fijo y los placeholders muestran `item.name` en vez de `item.displayName.tr()`.
- `shared/widgets/status_badge.dart` importa `MatchStatus` desde el módulo de ligas (dependencia de `shared` hacia un módulo).
- Hay `catch (_) {}` vacíos y `LeagueScheduleService.getConfig` traga cualquier excepción y devuelve `null`. La detección de errores de invitación compara texto en inglés del mensaje del backend (frágil).
- Código muerto: `LeagueStanding`, `LeagueDetailService`, `MyEventsStore`, `StandingsService.getAll`, `PlayersService.create/updatePlayer`.

### Documentación interna desactualizada (el código manda)

- `lib/modules/events/event_types/leagues/LEAGUES.md`: dice que la tabla de posiciones se calcula en local con `LeagueStanding.compute`, pero hoy la pide al backend; además lista endpoints y `playDays` distintos a los reales.
- `lib/modules/ARCHITECTURE_GUIDE.txt`: usa `AuthStorage.deleteToken()` (real: `clearToken()`) y propone `events/tournaments/`.
- `lib/core/modules/MENU_GUIDE.txt`: usa `/leagues` en los ejemplos (real: `/ligas`).
