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

- **Flutter/Dart** (`sdk: ^3.11.5`). App: `sport_platform`, versión `1.0.0+1`, `publish_to: none`. Hay carpetas de plataforma para android, ios, web, windows, linux y macos; en la práctica se usan Android, web y Windows.
- **Estado**: `provider` (`ChangeNotifier`) es lo que realmente se usa (ej. `events_notifier.dart`, `league_detail_notifier.dart`, `add_players_notifier.dart`), combinado con `StatefulWidget`/`setState` en pantallas simples. Las carpetas `application/bloc`, `application/cubit` y `application/state` existen en varios módulos pero están **vacías** (scaffolding sin implementar) — no asumir Bloc/Cubit real, y no llenarlas "porque están ahí" salvo que se pida migrar a Bloc explícitamente.
- **DI**: `get_it` como service locator (`lib/core/di/service_locator.dart`), registrando servicios/repositorios/notifiers como lazy singletons.
- **Navegación**: `Navigator` clásico (`MaterialPageRoute`), sin go_router/auto_route. Rutas de módulo se arman vía `AppRouteFactory` + `ModuleRegistry`. Deep links con `app_links` (ej. invitaciones de registro).
- **HTTP**: `dio` envuelto en `DioClient` (`lib/core/network/dio_client.dart`) con tres interceptores: `AuthTokenInterceptor` (`Authorization: Bearer <token>`), `UnauthorizedInterceptor` (cierra la sesión ante un 401) y `KeyFormatInterceptor`. Endpoints centralizados en `ApiEndpoints`.
- **Persistencia**: solo `shared_preferences`. Token de sesión vía `AuthStorage` (cache en memoria + `SharedPreferences`, key `auth_token`) y usuario en `UserSession` (key `user_session`). No hay Hive/sqflite/secure storage.
- **i18n**: `easy_localization`, locales `es/en/fr/de`, fallback `es`, JSON en `assets/translations/` (la única carpeta de assets: no hay imágenes ni fuentes propias). Los textos visibles al usuario deben ir a estos archivos de traducción, no hardcodeados en el widget.
- **Otras dependencias**: `image_picker` (foto del logo de equipo), `cupertino_icons`, `flutter_localizations`. No hay Freezed ni `json_serializable`: los modelos se escriben a mano (`fromJson`/`toJson`/`copyWith`).
- **Lint**: `analysis_options.yaml` usa `flutter_lints` sin overrides — respetar esas reglas por defecto, no relajarlas.

## Arquitectura y estructura de carpetas

Patrón clean-architecture por módulo bajo `lib/modules/<feature>/`:

- `application/{bloc,cubit,state}` — scaffolding, en la práctica vacío en todos los módulos (ver nota de estado arriba).
- `data/{datasource,mapper,models,repositories}` — llamadas HTTP/fuentes de datos, mapeo a modelos, implementación de repositorios.
- `domain/{entities,repositories,usecases}` — entidades de negocio e interfaces de repositorio (contrato), independientes de Flutter/dio.
- `presentation/{pages,widgets}` — UI del módulo. Los módulos maduros agregan `providers/` con los notifiers de sus pantallas (ver `leagues`).

Módulos existentes: `auth, events, home, matches, players, rankings, reports, teams, users`. Solo `events` (con `event_types/leagues`), `home`, `auth` y, en parte, `users` y `players` tienen código real; `matches`, `rankings`, `reports` y `teams` son una página placeholder y el resto de sus capas son `.gitkeep`. Antes de implementar algo nuevo en un módulo poco maduro, mirar `events/event_types/leagues` como referencia de cómo se ve el patrón completo y maduro.

- `lib/core/` — transversal técnico: `config, constants, di, errors, modules, network, routes, services, theme, utils` (`errors` está vacío).
- `lib/shared/` — transversal de dominio/UI reutilizable: `enums, extensions, mixins, models, services, widgets`. Hoy solo `mixins`, `services` y `widgets` tienen código; `enums`, `extensions` y `models` están vacíos (ahí van los `enum`s compartidos que pide la regla de "Nada fijo").
- La intención es que `core/` y `shared/` no importen de `modules/`, pero hoy lo hacen (`service_locator`, `user_session`, `module_registry`, `logout_button`, `status_badge`). No agregues más; la forma correcta es la de `SessionExpiredListener`: la interfaz vive en `core/services` y su implementación en `shared/services`.

Un módulo nuevo debe replicar esta misma carpeta interna (`data/domain/presentation`), no inventar una organización distinta.

## Testing y linting

- `flutter analyze` queda **sin issues** (verificado el 2026-10-17): debe seguir así antes de commitear.
- Hay 6 archivos de test con 14 pruebas que **pasan** con `flutter test` (2026-10-17): `widget_test.dart` (login sin sesión guardada), `AppConfig`, `UnauthorizedInterceptor`, `SessionService`, `SessionExpiredHandler` y `UserProfileService`. Cubren sesión, red y perfil: login, registro, home, menú y todo `leagues` (notifiers, servicios, modelos) no tienen tests. No asumas que existen tests de un flujo antes de verificarlo.
- Patrón de los tests existentes: sin red, con un `DioClient` falso que hereda del real (`UserProfileService({DioClient? client})` lo recibe por constructor) o con un `HttpClientAdapter` que responde un código fijo; `SharedPreferences.setMockInitialValues` antes de `EasyLocalization.ensureInitialized()`.
- Si agregas lógica nueva, favorece que sea testeable (separar lógica de UI en notifiers/usecases y recibir las dependencias por constructor, como `UserProfileService` y `SessionService`), aunque no se exija escribir el test en el mismo cambio salvo que se pida explícitamente.

## Cosas a tener en cuenta / no replicar

- El `login_page.dart` tiene credenciales de prueba precargadas con comentario `// DEV:` — es deuda de desarrollo, no un patrón a copiar en otras pantallas.
- El resto de la deuda conocida (código muerto, strings sueltos donde debería haber `enum`, errores tragados, archivos demasiado largos) está en "Tests y deuda técnica", más abajo.
- Idioma de los comentarios: el código reciente (sesión, red, perfil) los escribe en español y el más antiguo mezcla inglés. En código nuevo sigue el español; no hace falta traducir lo existente.

---

# Contexto de la plataforma

> Sección añadida el 2026-10-12 tras analizar los 3 proyectos y la carpeta `Documentación/` del monorepo; las secciones de este proyecto se volvieron a verificar contra el código el 2026-10-17. Está verificada contra el **código**, no contra los documentos de diseño. El bloque "Visión de la plataforma" es idéntico en los 3 CLAUDE.md: si lo cambias, cámbialo en los 3.

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
| Auth, usuarios y roles | ✅ | ✅ lista, alta con contraseña temporal por email, edición, borrado y asignación de roles; el administrador ve su perfil y cambia su contraseña | Login, registro y completar perfil |
| Menú dinámico por rol | ✅ | ✅ sidebar | ✅ Home (barra inferior y acciones rápidas) |
| Eventos y ligas | ✅ | ✅ CRUD de eventos (lista con búsqueda y filtros, alta, edición y borrado lógico; **el «tipo de evento» es el formato**, con sus reglas) y, desde cada fila, los equipos inscritos (agregar y quitar), los partidos (ver "Partidos") y el **campeonato** (ver "Campeonato de un evento") | ✅ **único módulo maduro** (`leagues`) |
| Equipos, jugadores e invitaciones | ✅ | ✅ CRUD de equipos (lista con búsqueda y filtros, alta, edición, estado y borrado lógico) y jugadores de cada equipo: lista, alta por email (lo agrega o lo traslada al equipo) e invitación de registro por correo si el email no existe; sin edición ni baja de jugadores | ✅ dentro de ligas |
| Partidos, calendario automático y posiciones | ✅ | ✅ dentro de cada evento: lista, alta, edición (estado y marcador), aplazar, suspender, reprogramar y borrado lógico; **calendario automático** (generar y regenerar, omitiendo los feriados) y aviso de los partidos que caen en un feriado; y, según el formato, el modal **«Campeonato»** con tablas de posiciones, llave, jornadas, sorteo de grupos y generación fase a fase; sin detalle del partido (goles, tarjetas) | ✅ dentro de ligas |
| Canchas y complejos | ✅ CRUD | ✅ CRUD de canchas (lista con búsqueda y filtro por complejo, alta, edición y borrado lógico) más el selector del formulario de partidos; los complejos solo se leen y no tienen pantalla | solo lectura (selector al programar) |
| Categorías | ✅ CRUD | ✅ CRUD (lista con búsqueda, alta, edición y borrado lógico; solo si ningún equipo ni evento la usa) | ❌ |
| Descansos y feriados (días sin juego) | ✅ CRUD (`holidays`); cada uno dura uno o varios días y el calendario automático los omite | ✅ CRUD (pantalla «Descansos/Feriados»: lista con búsqueda y filtro, alta, edición y borrado lógico; dura uno o varios días y puede repetirse cada año) | ❌ |
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

- App del usuario final. El login envía siempre `clientType=MOBILE_APP` (el backend rechaza a los administradores). Flujos reales: login; registro abierto (email + password) que **inicia sesión solo** (guarda el token si el backend lo devuelve) y lleva a `CompleteProfilePage`, que guarda el perfil con `PUT /users/auth/update-profile` (se puede omitir); registro por invitación mediante deep link; Home dinámico; **Ligas**; cambio de idioma y logout.
- **Ligas (`/ligas`) es el único módulo de negocio funcional**:
  - Listado con pestañas "Mis ligas / Todas". Crear, editar y borrar liga solo si eres el creador (`isOwner` sale de `GET /events/by-event-type/{typeId}/by-user/{userId}`). El formulario de liga solo pide nombre y fechas.
  - Detalle (`LeagueDetailPage`) con 4 pestañas: Info (edición en línea), Equipos, Partidos y Posiciones (las calcula el backend). Solo el creador ve el botón flotante y las acciones de edición.
  - Equipos: agregar uno existente, crear uno nuevo (nombre y logo) y gestionar jugadores (buscar por email, invitar a un usuario existente, enviar enlace de registro a uno no registrado, quitar).
  - Partidos: crear, editar, borrar, aplazar, suspender, reprogramar (uno o un día completo) y auto-programación. **El resultado se registra editando el partido**: al editar aparecen el estado y el marcador (local/visitante). El selector de estado ofrece solo `scheduled`, `inProgress`, `finished`, `cancelled` y `postponed`; suspender y reprogramar van por sus propias acciones.

### Estado por módulo (`lib/modules/<m>/`)

| Módulo | Estado real | Dónde mirar |
|---|---|---|
| `events/event_types/leagues` | **Maduro**, referencia de patrón (clean-arch completa salvo `domain/entities`) | `data/{datasource,models}`, `domain/{enums,exceptions,models,repositories}`, `presentation/{pages,providers,widgets}`, guía `LEAGUES.md` |
| `events/shared` | Implementado: base reutilizable para cualquier tipo de evento | `data/{datasource,local,models,providers}` y `presentation/{pages,widgets}`: `event_service.dart`, `events_notifier.dart`, `event_type_page.dart`, `event_form_sheet.dart` |
| `events` (raíz), `teams`, `matches`, `rankings`, `reports` | **Placeholder**: una página con `PlaceholderTab` ("Próximamente") y capas `.gitkeep` | `presentation/pages/<m>_page.dart` |
| `home` | A medias: menú y acciones rápidas salen de `GET /menu/for-current-user`; `home_tab.dart` es **estático** (invitaciones, próximo evento, equipos y actividad son tarjetas vacías) | `home_page.dart`, `menu_service.dart`, `menu_item_model.dart` |
| `auth` | Solo UI. No hay datasource ni repositorio: las páginas llaman a `DioClient` directamente | `login_page.dart`, `register_page.dart` |
| `players` | Parcial y sin el layout estándar: solo el registro por invitación. Su lógica principal (`PlayersService`, `PlayerModel`) vive dentro de `leagues` | `players_auth_service.dart`, `invite_register_page.dart` |
| `users` | Parcial: `CompleteProfilePage` real (`IUserProfileRepository` → `UserProfileService`, `UserModel`, `UserProfileUpdate`) y `profile_page.dart` (placeholder) | `data/datasource/user_profile_service.dart` |

Hay 133 archivos `.dart` en `lib/` y 104 `.gitkeep`. Las carpetas `application/{bloc,cubit,state}` están vacías en todos los módulos.

### Backend: URL base y endpoints

- `AppConfig.baseUrl` (`core/config/app_config.dart`) se elige con `--dart-define=APP_ENV=dev|staging|prod` (por defecto `dev`), y `--dart-define=API_BASE_URL=...` la reemplaza por completo. Dev se arma con constantes (host, puerto `8080`, context-path `/api`); staging y prod son literales `https://…sports-platform.com/v1`. Las de staging/prod terminan en `/v1`, no en el `/api` que sirve el backend ni coinciden con las de Angular: parecen placeholders sin validar. `AppConfig.apiKeyFormat` (`camelCase` hoy) decide si `KeyFormatInterceptor` convierte las keys de la respuesta.
- **Android**: en `dev`, `AppConfig` usa `10.0.2.2` (el alias de la PC en el emulador); en web y escritorio, `localhost`. Para un dispositivo físico: `--dart-define=API_BASE_URL=http://<ip-de-la-PC>:8080/api` (o `adb reverse tcp:8080 tcp:8080` con `API_BASE_URL=http://localhost:8080/api`). El manifest principal declara `INTERNET` y el tráfico `http` (`usesCleartextTraffic`) solo se permite en los manifests de debug/profile. **No se verificó con un build real de Android.**
- `DioClient` (`core/network/dio_client.dart`): timeout de 20 s e interceptores en este orden: `AuthTokenInterceptor`, `UnauthorizedInterceptor`, `KeyFormatInterceptor`. Cada servicio crea su propio `DioClient()` (un `Dio` nuevo por servicio). `ResponseParser` acepta el valor directo o envuelto en `{"data": …}`.
- Endpoints consumidos (rutas en `ApiEndpoints`, `core/network/api_endpoints.dart`):
  - Auth: `POST /users/auth/login`, `/register` (envía `email`, `password` y `confirm_password`, en snake_case), `/logout`; `PUT /users/auth/update-profile` (completar perfil); `POST /players/auth/register` (invitación).
  - Menú: `GET /menu/for-current-user`.
  - Eventos: `GET /events/by-event-type/{typeId}` y `.../by-user/{userId}`, `POST /events` (agrega `idEventType` al cuerpo), `PUT|DELETE /events/{id}`, `GET /events/{id}/standings`, `GET|POST /events/{id}/schedule-config`, `POST /events/{id}/schedule-config/generate`.
  - Equipos: `GET|POST /teams` (el alta envía `name` y `logoUrl` solo si hay), `GET /teams-events/by-event/{eventId}`, `POST /teams-events` (`teamId`, `eventId`), `DELETE /teams-events/{id}/hard`.
  - Partidos: `GET /matches/by-event/{eventId}`, `POST /matches`, `PUT|DELETE /matches/{id}`, `PATCH /matches/{id}/postpone|suspend|reschedule`, `PATCH /matches/by-event/{eventId}/reschedule-date`.
  - Jugadores: `GET /players/by-team/{teamId}`, `GET /players/search?email=` (un 404 significa "no existe"), `POST /players/invite`, `POST /players/invite-register`, `PATCH /players/{id}/remove-from-team`.
  - Canchas: `GET /courts`.
- Definidos en `ApiEndpoints` pero sin uso: `refreshToken`, `users`, `userById`, `teamById`, `teamsEventsById`, `sportComplexes`, `rankings`, `reports`, `leagues` y `leagueById` (estos dos son la ruta de pantalla `/ligas`, no un endpoint).
- Fechas hacia el backend: `DateFormatters` (`core/utils`) arma `yyyy-MM-dd` (`apiDate`) y `yyyy-MM-ddTHH:mm:00` (`apiDateTime`, hora local sin zona); para mostrar usa `date` y `dateTime` (`dd/MM/yyyy`). No formatees fechas a mano.

### Navegación y módulos dinámicos

- `Navigator` clásico (`MaterialPageRoute`). `main.dart` decide entre `HomePage` y `LoginPage` según `AuthStorage.hasToken()` (y carga `UserSession` desde disco si hay token).
- Cada pantalla de módulo se conecta así: la `url` del ítem de menú (columna `menu.url` del backend) se busca en `ModuleRegistry` (`core/modules/modules_setup.dart`, una línea `register` por módulo, con las URLs en `module_urls.dart`; la URL se normaliza a minúsculas y con `/` inicial). `AppRouteFactory` abre la página (`buildPage`, con `Scaffold` propio) o la pestaña de la barra inferior (`buildTab`, sin `Scaffold`). Una `url` no registrada cae en un placeholder genérico.
- La URL real de ligas es **`/ligas`** (no `/leagues`).
- El menú se pide a `GET /menu/for-current-user`, filtrado por rol igual que en Angular. `MenuService` reparte los ítems en dos listas: `navOrder > 0` van a la barra inferior (ordenados por `navOrder`) y el resto a las acciones rápidas (ordenados por `order`). **Un usuario sin rol o sin filas visibles en `roles_menu` recibe el menú vacío**: el registro no asigna ningún rol, así que hay que dárselo y concederle los ítems en `roles_menu`.
- `HomePage`: la barra inferior (se oculta con menos de 2 ítems) y las acciones rápidas salen del menú; el índice 0 de la barra es **siempre** `HomeTab`, aunque `navItems[0].url` apunte a otra cosa. Las acciones rápidas se muestran como carrusel o como drawer (`HomeMenuStyle`, se alterna con un botón de la barra superior; arranca en carrusel). Los ítems con hijos abren un `ChildrenSheet`. El botón de notificaciones está deshabilitado. Con `navItems` vacío (cargando, con error o sin permisos) el cuerpo queda **en blanco**: ni se construye `HomeTab`, así que el spinner y el botón de reintentar del carrusel nunca se ven (solo el drawer los muestra).
- Iconos: `MenuItemModel` traduce el nombre del icono del backend a un `IconData` de Material con `_filledIcons`/`_outlinedIcons`; un nombre desconocido se muestra como `Icons.sports`. Los colores de las tarjetas de acción salen de `kMenuColors`, que se recorre por posición.

### Auth, sesión y deep links

- Token en `AuthStorage` (memoria + `SharedPreferences`, clave `auth_token`). La sesión (`UserSession`) decodifica a mano el payload del JWT (`id`/`sub`, `idRole`/`role`, nombres, `username`, `email`) y se guarda en `user_session`; `UserSession.update` la reemplaza tras editar el perfil. `AuthStorage` y `UserSession` son clases estáticas con estado global: difíciles de testear.
- **Sesión vencida**: `UnauthorizedInterceptor` (red) detecta un 401 en una petición que llevaba token (excepto login y logout) y avisa a `SessionExpiredListener` (interfaz en `core/services`), que implementa `SessionExpiredHandler` (`shared/services`): limpia la sesión, lleva al login con `AppNavigator.key` y muestra el aviso `session.expired`; varios 401 simultáneos cierran la sesión una sola vez. No hay refresh de token. El login muestra "credenciales inválidas" ante cualquier excepción (también si no hay red).
- Logout (`shared/widgets/logout_button.dart`): confirma, llama a `POST /users/auth/logout` (ignora el fallo) y limpia con `SessionService.clear()`, igual que la sesión vencida: borra token y usuario y descarta el estado en memoria del usuario (`_resetSessionScopedServices` en `service_locator.dart`; hoy solo reinicia el `EventsNotifier` de ligas: **si agregas un notifier con datos del usuario, resetéalo ahí**). Luego vuelve al login.
- Deep link de invitación (`app_links`): `…/register?inviteToken=<token>`, el único soportado. En web se lee `Uri.base` (la librería no intercepta la URL del navegador). Android declara `http://localhost:5021/register`, `https://yourdomain.com/register` (**placeholder sin reemplazar**) y el esquema `sportplatform://`; iOS solo el esquema `sportplatform://` (sin Universal Links). Tras registrarse, la invitación lleva al login: no inicia sesión sola.
- **`_extractToken` solo reconoce `uri.path == '/register'`**: `sportplatform://register?inviteToken=…` se parsea con `host=register` y `path` vacío, así que **no se reconoce**; el esquema propio solo funciona como `sportplatform:///register?…`. El correo que manda el backend usa `http(s)`, por lo que hoy el esquema `sportplatform://` solo sirve para pruebas manuales.

### Tema y convenciones de UI

- `core/theme/app_theme.dart`: un único tema **oscuro** (sin tema claro ni `themeMode`; `fontFamily: 'sans-serif'`, sin fuentes en assets). Paleta verde en `AppColors` (`primary 2E7D32`, fondos degradados, translúcidos para inputs, colores semánticos y de podio). Casi todos los widgets fijan colores a mano con `AppColors.*` en vez de `Theme.of(context)`. `AppInputDecoration.standard(label)` es el estilo común de los campos (esquinas de 10).
- Widgets compartidos en `lib/shared/widgets/`: `GradientBackground`, `SportTextField`, `SocialButton`, `AppSnackbar` (`success`/`error`/`warning`/`info`), `showConfirmationDialog`, `EmptyState`, `ErrorRetry`, `StatusBadge`, `SheetHandle`, `LanguageSelector`, `LogoutButton`; mixin `SnackMixin`.
- Convenciones observables: cada página de módulo recibe `MenuItemModel item` y usa `Scaffold(backgroundColor: backgroundEnd)` + `AppBar(backgroundColor: primaryDark)`; formularios y acciones en bottom sheets con `static show(...)`, fondo `sheetBackground`, esquinas de 20 y `SheetHandle`; listas con `RefreshIndicator`, padding inferior de 100 por el FAB y estados de carga, error y vacío; la UI se parte en métodos `_buildX()`; imports absolutos `package:sport_platform/...`; los widgets con texto traducido leen `context.locale;` en `build` para reaccionar al cambio de idioma.
- Los pickers de fecha toman el rango de `AppConstants.minPickerDate`/`maxPickerDate`.

### Patrón de estado en `leagues` (referencia)

- El **único notifier registrado en GetIt** es `EventsNotifier` (uno por tipo de evento, `instanceName: 'leagues'`): lista y "mis eventos", con caché de 3 minutos (`load()` la respeta, `load(force: true)` la ignora) y `silentReload()` tras crear. La página de entrada lo entrega con `ChangeNotifierProvider.value`.
- Los notifiers de pantalla (`LeagueDetailNotifier`, `AddPlayersNotifier`) **se crean en el `State`** del widget que los usa, reciben los repositorios resueltos con `getIt<I…Repository>()` y se liberan en `dispose`. Todos los notifiers exponen listas inmutables (`List.unmodifiable`); los de pantalla guardan los errores como **clave de traducción** (`'leagues.error_load_teams'`), no como texto.
- Los sheets de formulario (`MatchFormSheet`, `AddTeamSheet`, `CreateTeamSheet`, `AutoScheduleSheet`, `AddPlayersSheet`) resuelven sus servicios con `getIt` y avisan con `SnackMixin` o `AppSnackbar`.

### i18n (estado)

- `easy_localization`: `es` (por defecto), `en`, `fr`, `de`, en `assets/translations/{es,en,fr,de}.json`. `startLocale: es` en `main.dart` fuerza el español en cada arranque: **el idioma elegido no se conserva**.
- `es` y `en` tienen 349 claves; **`fr` y `de` tienen 304: les faltan las 45 de `leagues.*`** (auto-programación, días, estados) y esas pantallas caen al español. Al agregar claves, agrégalas en los 4 archivos. Prefijos en uso: `app`, `common`, `events`, `home`, `invite_register`, `leagues`, `login`, `logout`, `menu`, `players`, `profile`, `register`, `session`, `settings`.
- Conviven dos estilos: clases de constantes en `core/constants/strings_constants/` (auth, home, perfil, logout, sesión) y literales `'leagues.xxx'.tr()` (ligas e invitación; son la mayoría). Para código nuevo sigue el estilo del módulo donde trabajas.
- `EventTypePage` y `EventFormSheet` son genéricos y reciben un `translationPrefix`: **un tipo de evento nuevo necesita su bloque completo de claves bajo su propio prefijo**. Las que usan hoy son `tab_mine`, `tab_all`, `new_item`, `edit_item`, `name`, `start_date`, `end_date`, `save`, `cancel`, `delete`, `delete_item`, `confirm_delete`, `retry`, `error_load`, `error_delete`, `success_created`, `success_updated`, `success_deleted`, `no_items`, `no_items_subtitle`, `no_items_mine`, `no_items_mine_subtitle`, `name_required`, `start_date_required`, `end_date_required` y `date_order_error` (copiar el bloque de `leagues` es lo más seguro).
- `StatusBadge.forEvent` traduce solo `ACTIVE`, `UPCOMING`, `FINISHED` y `CANCELLED` (con `events.status_*`, los mismos cuatro que el panel Angular); cualquier otro estado se muestra tal cual y en gris.

### Cómo agregar un tipo de evento nuevo (replica `leagues`)

1. UUID del tipo en `core/constants/event_type_ids.dart` (es el id del tipo en la BD).
2. Carpeta `lib/modules/events/event_types/<tipo>/` con `data/{datasource,models}`, `domain/{enums,repositories}` y `presentation/{pages,providers,widgets}`. (`ARCHITECTURE_GUIDE.txt` propone `events/tournaments/`, que no coincide con la estructura real.)
3. `<Tipo>Service extends EventService` con `super(eventTypeId: EventTypeIds.<tipo>)` (ver `league_service.dart`).
4. Registrar en `core/di/service_locator.dart` un `EventsNotifier` con `instanceName: '<tipo>'` y los repositorios de detalle que necesite (`abstract interface class I<…>Repository`). **Agregarlo también a `_resetSessionScopedServices`**, o el siguiente usuario que inicie sesión verá las listas del anterior.
5. Página de entrada: `ChangeNotifierProvider.value(getIt<EventsNotifier>(instanceName: '<tipo>'))` + `EventTypePage(...)`.
6. `core/modules/module_urls.dart` y una línea en `core/modules/modules_setup.dart`.
7. Endpoints nuevos en `ApiEndpoints` y bloque de traducciones en los 4 JSON.
8. Insertar el ítem en la tabla `menu` del backend con la misma `url` (si el icono es nuevo, agregarlo a `_filledIcons`/`_outlinedIcons` en `menu_item_model.dart`).
9. Correr `flutter analyze` y `flutter test`.

### Comandos

Desde `frontend/usuario-flutter/`: `flutter pub get`, `flutter run` (entorno `dev`), `flutter run -d chrome --web-port 5021` (coincide con `app.frontend.url` del backend, necesario para probar invitaciones), `flutter run -d windows`, `flutter run --dart-define=API_BASE_URL=http://<ip-de-la-PC>:8080/api` (dispositivo físico), `flutter run --dart-define=APP_ENV=staging`, `flutter analyze` (debe quedar sin issues antes de commitear), `flutter test`. No hay flavors ni scripts.

### Tests y deuda técnica (no replicar)

- Tests: ver "Testing y linting". **Sin tests**: notifiers, servicios y modelos de ligas, login, registro y menú.
- Código de prueba o sin terminar: `login_page.dart` con credenciales precargadas (`// DEV:`); subida del logo de equipo sin implementar (el usuario puede elegir la imagen con `image_picker`, pero `TeamLogoStorageService` es un esqueleto comentado y `logoUrl` siempre se envía `null`); firma release de Android con la de debug y `applicationId`/`namespace` `com.example.sport_platform`; `README.md`, `pubspec.yaml` y los metadatos web (`web/index.html`, `manifest.json`: "A new Flutter project.", color `#0175C2`) son los de la plantilla; `.claude/settings.json` y `.vscode/settings.json` están commiteados (el primero con rutas de otra máquina).
- Falta de permisos de plataforma: iOS sin `NSPhotoLibraryUsageDescription`/`NSCameraUsageDescription` (que `image_picker` necesita) y macOS sin `network.client` (solo `network.server` en debug/profile).
- Tres implementaciones de snackbar conviven: `AppSnackbar` (la correcta), `SnackMixin` (cinco sheets de ligas) y un `_showSnack` duplicado en `LeagueDetailPage` y `EventTypePage`. Usa `AppSnackbar`.
- Strings sueltos donde debería haber `enum`: `EventModel.format/status`, `TeamModel.status`, `PlayerModel.status`, `playDays`, y la lista fija `_statuses` de `MatchFormSheet`. Valores fijos que deberían salir de constantes: `DateTime(2020)`/`DateTime(2035)` en `EventFormSheet` (el resto de pickers ya usa `AppConstants`), los defaults `'90'`, `'15'`, `'30'` en `AutoScheduleSheet` y el rango 1–30 jugadores de `AddPlayersNotifier`. `PlaceholderTab` tiene "Próximamente" fijo y las seis páginas placeholder (`events`, `teams`, `matches`, `rankings`, `reports`, `profile`) muestran `item.name` en vez de `item.displayName.tr()`.
- Archivos que ya exceden lo razonable: `add_players_sheet.dart` (789 líneas) y `auto_schedule_sheet.dart` (532). Al tocarlos, extrae sub-widgets y métodos en vez de seguir creciendo.
- Errores que no llegan al usuario: `EventFormSheet._submit` traga la excepción y `EventTypePage` no captura la de crear/editar, así que **crear o editar una liga que falla no muestra ningún mensaje** (el sheet solo se queda abierto). Hay además `catch (_) {}` vacíos en `main.dart` (deep links), `UserSession.loadFromStorage` y `EventsNotifier.silentReload`, y `LeagueScheduleService.getConfig` traga cualquier excepción y devuelve `null`.
- Detección de errores por el texto en inglés del mensaje del backend (frágil): invitaciones (`already been used`, `expired`, `invalid invitation token` en `InviteRegisterPage`) y programación automática (`date range`, `play days` en `LeagueScheduleService.generate`).
- `_AppRouter` (en `main.dart`) crea el `Future` de la sesión dentro de `build`: cualquier `setState` (p. ej. al llegar un deep link en frío) lo repite y vuelve a mostrar el spinner.
- `shared/widgets/status_badge.dart` importa `MatchStatus` desde el módulo de ligas (dependencia de `shared` hacia un módulo).
- Código muerto: `LeagueStanding` (y su `compute`), `LeagueDetailService`, `MyEventsStore`, `StandingsService.getAll`, `PlayersService.create/updatePlayer`, `TeamLogoStorageService`; constantes `EventsStringsConstants`, `SocialStringsConstants`, `AppConstants.appName/appVersion` y `LoginStringsConstants.appName/appTagline`.

### Documentación interna desactualizada (el código manda)

- `lib/modules/events/event_types/leagues/LEAGUES.md`: dice que la tabla de posiciones se calcula en local con `LeagueStanding.compute`, pero hoy la pide al backend; lista endpoints y `playDays` distintos a los reales y su árbol de carpetas omite `standings_service`, `team_logo_storage_service`, `standing_model`, `domain/enums` y `domain/exceptions`.
- `lib/modules/ARCHITECTURE_GUIDE.txt`: usa `AuthStorage.deleteToken()` (real: `clearToken()`), propone `events/tournaments/`, dice que `core/` no importa módulos y describe `DioClient` con un `InterceptorsWrapper` en línea, sin `AuthTokenInterceptor` ni `UnauthorizedInterceptor`.
- `lib/core/modules/MENU_GUIDE.txt`: usa `/leagues` en los ejemplos (real: `/ligas`) y `GET /menu` (real: `GET /menu/for-current-user`).
