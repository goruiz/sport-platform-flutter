# Guía técnica del frontend Flutter

Referencia práctica para incorporarse al repositorio, seguir sus flujos y coordinar cambios con el panel Angular y la API Spring Boot. Describe el código presente; no sustituye a los contratos del backend ni pretende enumerar cada archivo. Se contrastaron las rutas y capacidades con `lib/`, `pubspec.yaml` y `CLAUDE.md`. Si la documentación interna contradice la implementación, comprobar primero el código y el backend.

## 1. Lugar de esta app en la plataforma

La plataforma gestiona campeonatos y eventos deportivos. Este proyecto es la aplicación Flutter para jugadores/capitanes; el panel Angular es para organizadores y la API Spring Boot/PostgreSQL es el contrato compartido.

| Proyecto | Responsabilidad | Repositorio local de referencia |
|---|---|---|
| App de usuario (este repo) | App móvil/web/escritorio; login como `MOBILE_APP`, registro, perfil y consulta/gestión de ligas según permisos. | `frontend/usuario-flutter/` |
| Panel admin | Operación de organizaciones, eventos, equipos, jugadores, partidos, canchas y configuración. | `frontend/administration-angular/` |
| Backend | API REST, autenticación, autorización por rol/organización y persistencia. | `backend/` |

La API local tiene context path `/api` (p. ej. `http://localhost:8080/api`). El documento técnico de la plataforma describe objetivos, no constituye contrato técnico: para rutas, DTO y reglas manda el backend ejecutándose y su código.

## 2. Stack y estructura

- Flutter y Dart: `pubspec.yaml` fija `sdk: ^3.11.5`; aplicación `sport_platform`, versión `1.0.0+1`, privada (`publish_to: none`).
- UI: Flutter Material, un tema visual oscuro propio y widgets compartidos. No usa Angular Material ni un kit externo de componentes.
- Estado: `provider`/`ChangeNotifier` en la parte de ligas y `StatefulWidget`/`setState` en pantallas sencillas. Aunque existen directorios `application/bloc`, `cubit` y `state`, son scaffolding, no una migración real a BLoC/Cubit.
- Inyección: `get_it` (`lib/core/di/service_locator.dart`); algunas pantallas crean directamente sus clientes/servicios, por lo que no toda dependencia está centralizada.
- Navegación: `Navigator` y `MaterialPageRoute`; no hay `go_router` ni `auto_route`. El menú del servidor enruta mediante `ModuleRegistry`.
- HTTP: `dio`, encapsulado por `DioClient`; modelos JSON se parsean manualmente, sin `json_serializable`/Freezed.
- Persistencia: `shared_preferences`; no hay base de datos local ni almacenamiento seguro de credenciales integrado.
- Idiomas: `easy_localization`, JSON en `assets/translations/`, idiomas `es`, `en`, `fr`, `de`.
- Otras dependencias de app: `image_picker`, `app_links`; `flutter_lints` configura el análisis estático.

Estructura de `lib/`:

```text
lib/
  main.dart
  core/       configuración, constantes, DI, red, rutas, sesión, tema y utilidades
  modules/    auth, events, home, matches, players, rankings, reports, teams, users
  shared/     servicios y widgets transversales, enums/extensiones/modelos/mixins
```

Los módulos siguen, cuando están desarrollados, `data/` (datasources, modelos, repositorios y mappers), `domain/` (entidades, interfaces y casos de uso) y `presentation/` (páginas/widgets); los módulos maduros pueden añadir `providers/`. La separación no es uniforme todavía: `auth` accede a `DioClient` desde las páginas y el flujo de ligas concentra servicios de jugadores y equipos dentro de `events/event_types/leagues`. `core`/`shared` tienen algunas dependencias hacia `modules`; no ampliar ese acoplamiento al crear nuevas piezas.

## 3. Arranque, composición y navegación

1. `lib/main.dart` inicializa Flutter y `EasyLocalization`, llama a `setupServiceLocator()` y `registerModules()`, y monta `SportsPlatform`.
2. `MaterialApp` usa `AppNavigator.key`, `AppTheme.sportsPlatform` y los delegates/locales de Easy Localization.
3. `_AppRouter` comprueba `AuthStorage.hasToken()`. Si hay token, restaura `UserSession` y abre `HomePage`; de lo contrario muestra `LoginPage`. No comprueba localmente la expiración del JWT.
4. `HomePage` solicita `GET /menu/for-current-user`. El backend filtra el árbol según los roles. `MenuService` clasifica elementos con `navOrder > 0` para la barra inferior y los restantes para acciones rápidas. El árbol puede incluir submenús.
5. `AppRouteFactory`/`ModuleRegistry` resuelve `menu.url` a un constructor registrado en `core/modules/modules_setup.dart`. Una ruta desconocida cae a UI genérica/placeholder, no es una ruta web declarativa.

URLs registradas en `lib/core/modules/module_urls.dart`: `/teams`, `/events`, `/rankings`, `/matches`, `/reports`, `/profile` y `/ligas`. La liga usa exactamente `/ligas`, no `/leagues`. El primer índice de la barra se usa como `HomeTab`; por eso el orden y la configuración dinámica del menú afectan qué sección ve el usuario. Los iconos de backend se asignan en `MenuItemModel`; uno desconocido cae a un icono Material genérico.

El home contiene selector carrusel/drawer de acciones rápidas, selección de idioma y logout. No representa todavía un dashboard de datos: las tarjetas de resumen son estáticas/vacías y el botón de notificaciones está deshabilitado. Si el backend devuelve un menú sin ítems de navegación, el contenido puede quedar en blanco; esto puede ser un problema de roles/configuración del menú, no necesariamente de red.

## 4. Módulos: qué está implementado realmente

| Módulo/ruta | Estado actual comprobado | Código de entrada |
|---|---|---|
| `auth` | Login y registro abierto funcionales. Las páginas hacen HTTP directamente; login pide `clientType: MOBILE_APP`. El formulario de registro lleva al completado de perfil. | `modules/auth/presentation/pages/login_page.dart`, `register_page.dart` |
| `users` | `CompleteProfilePage` permite completar/actualizar perfil; la pantalla de perfil del menú es placeholder. | `modules/users/presentation/pages/complete_profile_page.dart`, `profile_page.dart`; `data/datasource/user_profile_service.dart` |
| `players` | Registro con token de invitación. El grueso de la gestión de jugadores existente está bajo el módulo de ligas, no aquí. | `modules/players/presentation/pages/invite_register_page.dart`; `data/datasource/players_auth_service.dart` |
| `home` | Menú remoto y acciones rápidas reales; tarjetas de actividad/próximo evento/equipos aún vacías o de muestra. | `modules/home/presentation/pages/home_page.dart`, `data/datasource/menu_service.dart` |
| `events/shared` | Base reutilizable para listar/crear/editar eventos por tipo y mantener estado/caché. | `modules/events/shared/data/datasource/event_service.dart`, `data/providers/events_notifier.dart`, `presentation/pages/event_type_page.dart` |
| `events/event_types/leagues` | Único módulo de negocio maduro. Lista «Mis ligas / Todas», CRUD según creador, detalle con información, equipos, partidos y posiciones consumidas del servidor; alta/gestión de equipos y jugadores, programación y gestión de partidos. | `modules/events/event_types/leagues/`; guía de apoyo `LEAGUES.md` (contrastar con código, puede estar desactualizada) |
| `events` raíz, `teams`, `matches`, `rankings`, `reports` | Pantallas `PlaceholderTab` («Próximamente»); las capas restantes son sobre todo `.gitkeep`. Las constantes de endpoint o una ruta en el menú no significan que el flujo esté construido. | `modules/{events,teams,matches,rankings,reports}/presentation/pages/` |

Bajo la madurez ya descrita no debe confundirse «hay módulo/ruta/endpoint declarado» con «hay una experiencia de usuario implementada». El registro por invitación sí es real, pero no equivale a CRUD general de jugadores. El cargador de logo permite elegir una imagen, pero el almacenamiento/subida (`TeamLogoStorageService`) está incompleto y el flujo actual no publica el archivo.

## 5. Flujo de datos de ligas

`LeaguesPage` proporciona el `EventsNotifier` registrado con `instanceName: 'leagues'`. La pantalla de evento usa `EventTypePage` y `EventFormSheet`; la vista de detalle crea notifiers de pantalla y obtiene repositorios desde `getIt`. El patrón de una petición es:

```text
Widget / ChangeNotifier
  -> contrato de repositorio (cuando existe)
  -> servicio datasource (DioClient)
  -> API Spring Boot
  -> modelo manual fromJson / ResponseParser
  -> entidad/estado -> UI
```

`EventService` es la base por tipo: recibe el `eventTypeId`, lista por tipo, consulta ids propios por usuario y agrega el id del tipo en el alta. Los servicios de detalle leen equipos, inscripciones, jugadores, partidos, canchas, clasificación y configuración de calendario. El notifier de lista conserva caché temporal (tres minutos según su implementación/documentación) y admite recarga forzada/silenciosa. Los notifiers de detalle se liberan con la pantalla; al cerrar sesión se reinicia el notifier de ligas para no exponer estado en memoria del usuario anterior.

Las fechas de API deben formatearse con `lib/core/utils/date_formatters.dart` (`yyyy-MM-dd` y fecha/hora local sin offset), no construirse de forma ad hoc. El DTO de partido usa fechas sin zona según el contrato actual; no suponer UTC.

## 6. HTTP, respuestas y errores

### Cliente común

`lib/core/config/app_config.dart` elige la URL con `--dart-define=APP_ENV=dev|staging|prod` (por defecto `dev`) y permite reemplazo completo con `API_BASE_URL`. En desarrollo local usa puerto `8080` y `/api`; en emulador Android usa `10.0.2.2`, en navegador/escritorio usa `localhost`. Para dispositivo físico se requiere la IP LAN del ordenador o `adb reverse`.

`DioClient` fija timeout de conexión/recepción de 20 segundos y agrega, en este orden:

1. `AuthTokenInterceptor`: adjunta `Authorization: Bearer <token>` si hay token local.
2. `UnauthorizedInterceptor`: ante HTTP 401 con token notifica expiración de sesión, excepto login/logout. El error original continúa al llamador.
3. `KeyFormatInterceptor`: transforma claves de respuesta si `AppConfig.apiKeyFormat` se configura como `snakeCase`; por defecto está en `camelCase` y no transforma.

`ResponseParser` admite respuesta directa y objeto `{data: ...}` para mapas/listas. Varios flujos leen la envoltura manualmente; hay formatos inconsistentes que conviene normalizar al cambiar APIs.

### Contrato habitual del backend

La respuesta común es `ApiResponse<T>`: `{success, status, message, data, timestamp}`. Un error de validación puede llevar mapa de campos en `data`. Flutter no tiene un traductor global de errores HTTP: cada pantalla/servicio maneja sus excepciones y algunas convierten errores a mensajes genéricos. En particular, el login muestra «credenciales inválidas» para cualquier excepción (también ante falta de conectividad); la invitación y el generador de calendario reconocen algunos errores buscando texto inglés, una integración frágil.

El backend emite JWT de 24 horas y no ofrece refresh de token en el contrato común actual. La app no refresca token; al primer endpoint protegido que devuelva 401 elimina sesión y vuelve a login. Un 403 no equivale a expiración: el interceptor solo reacciona a 401.

## 7. Rutas de API: consumidas vs declaradas

La fuente de rutas Flutter es `lib/core/network/api_endpoints.dart`; el uso real se encuentra en servicios/páginas. Ejemplos de flujos actualmente conectados:

| Caso | Operaciones que usa el código | Evidencia |
|---|---|---|
| Login | `POST /users/auth/login`, cuerpo `email`, `password`, `clientType: MOBILE_APP`; lee `data.token`. | `auth/presentation/pages/login_page.dart` |
| Registro abierto | `POST /users/auth/register`; envía `email`, `password`, `confirm_password`. | `auth/presentation/pages/register_page.dart` |
| Perfil | `PUT /users/auth/update-profile` con nombres/username; los opcionales vacíos se omiten. | `users/data/datasource/user_profile_service.dart` |
| Menú | `GET /menu/for-current-user`; recibe lista directa o `data` y árbol con `submenus`/`children`. | `home/data/datasource/menu_service.dart` |
| Eventos/ligas | `GET /events/by-event-type/{typeId}`, `GET /events/by-event-type/{typeId}/by-user/{userId}`, `POST /events`, `PUT|DELETE /events/{id}`. | `events/shared/data/datasource/event_service.dart` |
| Equipos e inscripciones | `GET|POST /teams`, `GET /teams-events/by-event/{eventId}`, `POST /teams-events`, `DELETE /teams-events/{id}/hard`. | Servicios bajo `events/event_types/leagues/data/datasource/` |
| Jugadores | `GET /players/by-team/{teamId}`, búsqueda por email, invitaciones y alta por invitación. | `leagues/data/datasource/players_service.dart`, `players/data/datasource/players_auth_service.dart` |
| Partidos/calendario | `GET /matches/by-event/{eventId}`, altas/ediciones/bajas, cambios de estado y programación; `GET|POST /events/{id}/schedule-config`, generación. | `leagues/data/datasource/league_matches_service.dart`, `league_schedule_service.dart` |
| Clasificación | `GET /events/{id}/standings`. | `leagues/data/datasource/standings_service.dart` |
| Logout | `POST /users/auth/logout` si es posible, después limpieza local siempre. | `shared/widgets/logout_button.dart` |
| Invitación a jugador | `POST /players/auth/register` con `inviteToken`, nombre, email y password. | `players/data/datasource/players_auth_service.dart` |

La lista anterior es una muestra práctica, no garantía de que un endpoint siga vigente en backend. `ApiEndpoints` también declara rutas no usadas o parciales (`refreshToken`, colecciones de ranking/reportes, `sportComplexes`, algunas rutas por id, entre otras); no implementar contra una constante sin revisar quién la llama y verificar el contrato del servidor. Algunas rutas que aparecen en el cliente —por ejemplo `DELETE /teams-events/{id}/hard` o `/matches/by-event/{id}/reschedule-date`— deben contrastarse en backend antes de cambiar su semántica.

## 8. Integración entre proyectos: qué sincronizar

Un cambio de contrato o navegación puede requerir cambios en más de un repositorio. Revisar explícitamente:

| Cambio | Sincronización necesaria |
|---|---|
| Ruta, método, parámetros, paginación, nombre/forma de DTO o envoltura `ApiResponse` | Backend + servicio/modelo Flutter + servicio/modelo Angular si el panel consume el mismo recurso. Revisar también `ResponseParser` y `KeyFormatInterceptor`. |
| Login, tipo de cliente, claims JWT, errores 401/403, refresh o logout | Backend + `auth`/`AuthStorage`/`UserSession` e interceptores Flutter + `AuthService`/guard/interceptor del panel. Hoy Flutter envía `MOBILE_APP`; Angular envía `ADMIN_PANEL`. |
| `menu.url`, permisos/roles, árbol, `translationKey`, `navOrder` o icono | Migración Flyway/backend (menú y asignaciones `roles_menu`) + `ModuleUrls`/registro de `ModuleRegistry` y mapa de iconos Flutter; Angular debe tener su ruta cuando aplique y ambos diccionarios deben contener las traducciones. El grupo sin permisos no llega al cliente. |
| Tipo/formato de evento y UUIDs | Backend y Flutter (`core/constants/event_type_ids.dart`, `EventTypeIds`) + panel. No sustituir el tipo por el formato sin cambiar el contrato: el backend mantiene ambos conceptos. |
| Reglas/estado de partido, programación, fecha y clasificación | Backend + parsers/modelos/reglas de Flutter y módulo `events` del panel; verificar nombres exactos de estados y momento en que se puede registrar marcador. |
| Alta/invitación de jugadores | Backend (ruta, DTO, token y correo/deep link) + Flutter (registro e invitación) + Angular (alta/invitación desde equipo). El link que configura backend apunta al frontend Flutter web. |
| Texto o validación visible | Actualizar `assets/translations/{es,en,fr,de}.json`; si proviene de un código de error, coordinar el código backend y tratamiento en Angular/Flutter. |
| Cambios de organización/rol | Confirmar filtros y claims del backend, concesiones del menú y comportamiento de ambos clientes. El backend aplica el aislamiento por organización; no duplicar filtros como supuesto de autorización en UI. |

### Diferencias y cautelas de configuración

- `AppConfig` hoy apunta a staging y producción con sufijo `/v1`, mientras que el backend local descrito por los proyectos expone `/api`; el propio `CLAUDE.md` del repo califica esas URL `/v1` como placeholders no validados. Confirmar host y context path antes de publicar/probar esos entornos. No cambiarlo por suposición.
- `ApiEndpoints.refreshToken` existe como constante, pero no se usa; el contrato común del backend indica que no hay refresh.
- El login tiene valores de prueba precargados en `login_page.dart` (`// DEV:`). Son deuda de desarrollo, no comportamiento que deba copiarse ni aceptar en una publicación.
- La pantalla de registro contiene controlador de nombre, pero el request observado solo envía email/password/`confirm_password`; verificar DTO y requisitos del backend antes de dar por persistido ese nombre.
- La configuración URL del manifest Android para invitaciones incluye un dominio de ejemplo (`yourdomain.com`); el backend envía un enlace HTTP(S), de modo que dominio, path `/register` y `inviteToken` deben coincidir con el despliegue real.

## 9. Sesión, roles y deep links

`AuthStorage` conserva token bajo `auth_token` (memoria + `SharedPreferences`). `UserSession` decodifica localmente claims del payload JWT (`id`/`sub`, rol, nombres, correo) y serializa el usuario bajo `user_session`. La decodificación local no valida firma ni expiración; la autoridad de acceso sigue siendo backend. `SessionService.clear()` borra ambos y reinicia estado de sesión registrado en DI.

`SessionExpiredHandler` coordina 401 concurrentes, borra sesión, vuelve a login y muestra mensaje. Logout intenta llamar al backend, pero el cierre local continúa aunque esa llamada falle. Si se agrega un `ChangeNotifier` con datos por usuario, incluir su reset en `_resetSessionScopedServices` (`core/di/service_locator.dart`). El almacenamiento de token actual usa `SharedPreferences`, no secure storage.

Deep links usan `app_links` y admiten registro con `?inviteToken=...`. En Web se lee `Uri.base`, pues `app_links` no intercepta la URL del navegador. En móvil se procesa enlace inicial y enlaces recibidos con la app abierta. `_extractToken` solo acepta `uri.path == '/register'`; un esquema `sportplatform://register?...` típico puede interpretarse con host `register` y path vacío y no ser reconocido. Verificar `android/app/src/main/AndroidManifest.xml`, configuración iOS y URL de correo del backend cuando se prueben invitaciones.

## 10. Localización y presentación

`main.dart` declara `es`, `en`, `fr`, `de`, fallback `es`, y `startLocale: es`. Con la configuración actual el idioma elegido no se persiste entre inicios. Los JSON que tienen que mantenerse parejos son `assets/translations/es.json`, `en.json`, `fr.json`, `de.json`. La documentación del repo registra que francés y alemán no tenían 45 claves de ligas al verificarse; las pantallas afectadas pueden caer a español. Confirmar estado actual al agregar traducciones.

Las pantallas de ligas usan varias claves literales `.tr()`; otros módulos mantienen clases de constantes en `core/constants/strings_constants/`. Seguir el estilo local del módulo, pero no agregar texto nuevo solo en un idioma. `PlaceholderTab` y pantallas aún no maduras tienen texto fijo. `AppTheme` define tema oscuro único y paleta verde en `core/theme/app_colors.dart`; el diseño usa con frecuencia colores explícitos, no un modo claro/oscuro dinámico.

## 11. Plataformas y recursos

El repositorio contiene proyectos de plataforma para Android, iOS, Web, Windows, Linux y macOS; `CLAUDE.md` indica que el uso práctico es Android, Web y Windows, no certificación equivalente de los seis. Confirmar SDKs/configuración y construir para el target concreto.

No se observan imágenes ni fuentes propias bajo `assets/`, aparte de las traducciones. `image_picker` se usa en selección de logo, pero persistencia/subida sigue pendiente. La documentación interna advierte que iOS no declara textos de uso de cámara/fototeca necesarios para ese plugin, macOS tiene permisos de red incompletos y el release Android usa firma debug y applicationId/namespace de ejemplo (`com.example.sport_platform`). No asumir que esos targets están listos para publicar.

## 12. Puesta en marcha, pruebas y diagnóstico

Desde la raíz de este repositorio (`frontend/usuario-flutter/`):

```powershell
flutter pub get
flutter analyze
flutter test
flutter run                         # dev local / dispositivo predeterminado
flutter run -d chrome --web-port 5021
flutter run -d windows
flutter run --dart-define=API_BASE_URL=http://<ip-de-la-PC>:8080/api
flutter run --dart-define=APP_ENV=staging
```

Para emulador Android dev el código usa `10.0.2.2`; en Web/escritorio usa `localhost`. En teléfono físico se puede usar IP LAN o `adb reverse tcp:8080 tcp:8080` junto a `API_BASE_URL=http://localhost:8080/api`. Flutter Web necesita que el backend permita CORS. Para compilación, Flutter usa `flutter build apk`, `flutter build web`, `flutter build windows`, etc.; verificar previamente el SDK/entorno de cada target. No hay flavors ni scripts npm del proyecto.

`flutter analyze` y `flutter test` son los chequeos de rutina. La documentación del repo registra 6 archivos/14 pruebas (login sin sesión, config, interceptor 401, sesión, expiración y servicio de perfil); la lista de test actual está bajo `test/`. La cobertura de login/registro, menú, notifiers y flujos de ligas es limitada o inexistente; no confundir `flutter test` en verde con validación integral de backend o de todos los dispositivos.

Diagnóstico rápido:

- **Login muestra credenciales inválidas incluso con red caída:** revisar DevTools/log de Dio; el widget traduce cualquier excepción como credencial incorrecta.
- **Home no ofrece módulos o queda en blanco:** inspeccionar status/respuesta de `/menu/for-current-user`, `roleId`, concesiones `roles_menu`, `navOrder`, `menu.url`; verificar salida `debugPrint` del menú. Confirmar URL exacta registrada en `modules_setup.dart`.
- **401 devuelve al login:** esperado con token en endpoint protegido; revisar expiración/reloj/token, y que el server responda ApiResponse. 403 no activa este flujo.
- **No conecta en Android:** distinguir emulador (`10.0.2.2`) de teléfono físico (IP LAN/adb reverse); revisar backend, HTTP claro de debug/profile y CORS si es Web.
- **Invitación no abre registro:** validar `/register`, `inviteToken`, asociación Android/iOS/web y que el esquema/path parseado corresponda al correo real.
- **Campos no se mapean:** comparar camelCase/snake_case y envoltura JSON con el modelo; formato de clave del cliente está en `AppConfig.apiKeyFormat`.
- **Error tras cambiar el contrato:** rastrear el flujo completo desde widget → notifier/usecase → repositorio → datasource → `ApiEndpoints` y revisar el DTO real en backend, no basarse solo en una constante o guía antigua.

## 13. Guía para implementar cambios

1. Identificar si la capacidad existe de verdad o solo tiene ruta/placeholder. Para estructura completa, usar `modules/events/event_types/leagues` como referencia; para pantallas sencillas, seguir el patrón local sin llenar por defecto carpetas BLoC vacías.
2. Leer `core/network/api_endpoints.dart`, el servicio que lo invoca y el modelo `fromJson`/`toJson`; contrastar endpoint y reglas del backend.
3. Separar lógica de UI cuando haya reglas; inyectar dependencias para permitir pruebas. Reutilizar `DioClient`, `ResponseParser`, `DateFormatters`, `AppSnackbar` y componentes comunes del repo.
4. Si se agrega ruta de menú: sincronizar URL en Backend (migración Flyway y roles), `ModuleUrls`, registro y constructor en `modules_setup.dart`, icono, claves de traducción y eventual ruta Angular. No sembrar datos de menú a mano en base de datos.
5. Mantener traducciones en cuatro idiomas, revisar el reset de estado por sesión y probar cambios de permisos/roles con tokens reales.
6. Ejecutar `flutter analyze` y `flutter test`; cuando el cambio afecta backend, deep links, persistencia, permisos o UI dependiente de API, realizar prueba integrada en los targets relevantes además del unitario.

## 14. Referencias útiles

- Arranque/config: `lib/main.dart`, `lib/core/config/app_config.dart`, `pubspec.yaml`.
- DI/módulos/rutas: `lib/core/di/service_locator.dart`, `lib/core/modules/modules_setup.dart`, `module_urls.dart`, `module_registry.dart`, `lib/core/routes/`.
- HTTP/auth/session: `lib/core/network/`, `lib/core/services/`, `lib/shared/services/session_expired_handler.dart`.
- Módulo funcional: `lib/modules/events/event_types/leagues/` y `lib/modules/events/shared/`.
- Menú y home: `lib/modules/home/`.
- Traducciones y tema: `assets/translations/`, `lib/core/theme/`, `lib/shared/widgets/`.
- Pruebas: `test/`.
- Guías heredadas, útiles con cautela: `CLAUDE.md`, `lib/modules/events/event_types/leagues/LEAGUES.md`, `lib/modules/ARCHITECTURE_GUIDE.txt`, `lib/core/modules/MENU_GUIDE.txt`.
