# Módulo de Ligas (`event_types/leagues`)

Este documento describe la arquitectura, el flujo de datos y el comportamiento de la pantalla de detalle de una liga dentro de la plataforma deportiva.

---

## Tabla de contenidos

1. [Visión general](#1-visión-general)
2. [Estructura de carpetas](#2-estructura-de-carpetas)
3. [Arquitectura en capas](#3-arquitectura-en-capas)
4. [Modelos de datos](#4-modelos-de-datos)
5. [Capa de dominio — interfaces de repositorio](#5-capa-de-dominio--interfaces-de-repositorio)
6. [Capa de datos — servicios](#6-capa-de-datos--servicios)
7. [Inyección de dependencias](#7-inyección-de-dependencias)
8. [Gestión de estado — Notifiers](#8-gestión-de-estado--notifiers)
9. [Pantalla principal — `LeagueDetailPage`](#9-pantalla-principal--leaguedetailpage)
10. [Pestañas y widgets](#10-pestañas-y-widgets)
11. [Flujos de usuario](#11-flujos-de-usuario)
12. [FAB dinámico — `LeagueFab`](#12-fab-dinámico--leaguefab)
13. [Tabla de posiciones — lógica de cómputo](#13-tabla-de-posiciones--lógica-de-cómputo)

---

## 1. Visión general

El módulo de ligas permite a los usuarios (dueños y participantes) gestionar un evento de tipo **liga deportiva**. Una liga agrupa equipos que se enfrentan en partidos programados con fechas, canchas y resultados, y de los que se deriva automáticamente una **tabla de posiciones** en tiempo real.

Las operaciones principales son:

| Rol       | Operaciones disponibles |
|-----------|------------------------|
| **Owner** | Editar info de la liga, agregar/quitar equipos, crear/editar/eliminar partidos, programar automáticamente, gestionar jugadores |
| **Usuario** | Ver info, ver equipos, ver partidos, ver tabla de posiciones |

---

## 2. Estructura de carpetas

```
leagues/
├── data/
│   ├── datasource/
│   │   ├── courts_service.dart            # Obtiene canchas disponibles
│   │   ├── league_detail_service.dart     # Facade que agrupa los 3 servicios principales
│   │   ├── league_matches_service.dart    # CRUD de partidos
│   │   ├── league_schedule_service.dart   # Config y generación de horarios
│   │   ├── league_service.dart            # Servicio de eventos tipo liga
│   │   ├── league_teams_event_service.dart# Equipos inscritos al evento
│   │   ├── players_service.dart           # Jugadores por equipo
│   │   └── teams_service.dart             # Equipos globales (búsqueda/creación)
│   └── models/
│       ├── court_model.dart
│       ├── event_schedule_config_model.dart
│       ├── match_model.dart
│       ├── player_invitation_model.dart
│       ├── player_model.dart
│       ├── team_event_model.dart
│       └── team_model.dart
├── domain/
│   ├── models/
│   │   └── league_standing.dart           # Lógica de posiciones (pura, sin Flutter)
│   └── repositories/
│       ├── i_league_matches_repository.dart
│       ├── i_league_schedule_repository.dart
│       └── i_league_teams_repository.dart
└── presentation/
    ├── pages/
    │   ├── league_detail_page.dart        # Pantalla principal de detalle
    │   └── leagues_page.dart              # Lista de ligas disponibles
    ├── providers/
    │   ├── add_players_notifier.dart      # Estado del sheet de jugadores
    │   └── league_detail_notifier.dart    # Estado principal de la pantalla de detalle
    └── widgets/
        ├── add_players_sheet.dart
        ├── add_team_sheet.dart
        ├── auto_schedule_sheet.dart
        ├── create_team_sheet.dart
        ├── league_fab.dart
        ├── league_info_card.dart
        ├── league_matches_tab.dart
        ├── league_teams_tab.dart
        ├── match_card.dart
        ├── match_day_section.dart
        ├── match_form_sheet.dart
        ├── standings_tab.dart
        └── team_event_card.dart
```

---

## 3. Arquitectura en capas

El módulo sigue **Clean Architecture** con tres capas claramente separadas:

```
┌─────────────────────────────────────────┐
│           PRESENTATION                  │
│  Pages · Notifiers · Widgets            │
│  (Flutter / ChangeNotifier)             │
└───────────────┬─────────────────────────┘
                │ depende de interfaces
┌───────────────▼─────────────────────────┐
│              DOMAIN                     │
│  ILeagueTeamsRepository                 │
│  ILeagueMatchesRepository               │
│  ILeagueScheduleRepository              │
│  LeagueStanding (lógica pura)           │
└───────────────┬─────────────────────────┘
                │ implementa interfaces
┌───────────────▼─────────────────────────┐
│               DATA                      │
│  *Service (HTTP) · Models (JSON ↔ obj)  │
└─────────────────────────────────────────┘
```

La capa de presentación **nunca importa** una clase de datos directamente; siempre trabaja a través de las interfaces de dominio. Los servicios concretos son registrados en `service_locator.dart` y resueltos en tiempo de ejecución vía **GetIt**.

---

## 4. Modelos de datos

### `TeamModel`
Representa un equipo global (no ligado a ningún evento).

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | Identificador único |
| `name` | String | Nombre del equipo |
| `logoUrl` | String? | URL del logo |
| `categoryId` | String? | Categoría deportiva |
| `status` | String? | Estado del equipo |

### `TeamEventModel`
Relación entre un equipo y un evento de liga. Es la entidad que se agrega/elimina al inscribir un equipo.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | ID de la relación (se usa para eliminar) |
| `teamId` | String | ID del equipo global |
| `teamName` | String | Nombre del equipo |
| `eventId` | String | ID del evento/liga |
| `createdAt` | DateTime | Fecha de inscripción |

### `MatchModel`
Partido entre dos equipos dentro del evento.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | String | Identificador único |
| `homeTeamId` / `awayTeamId` | String | IDs de los equipos |
| `matchDate` | DateTime | Fecha y hora del partido |
| `location` | String? | Lugar (cancha/dirección) |
| `status` | String | `SCHEDULED`, `IN_PROGRESS`, `FINISHED`, `CANCELLED`, `POSTPONED` |
| `homeScore` / `awayScore` | int? | Marcador (nulo si no se ha jugado) |
| `courtId` | String? | ID de la cancha asignada |
| `eventId` | String | ID del evento |

### `EventScheduleConfigModel`
Configuración para la generación automática de partidos.

| Campo | Tipo | Default |
|-------|------|---------|
| `playDays` | List\<int\> | [] (0=Dom … 6=Sáb) |
| `startTime` | TimeOfDay? | — |
| `matchDurationMinutes` | int | 90 |
| `breakBetweenHalvesMinutes` | int | 15 |
| `breakBetweenMatchesMinutes` | int | 30 |
| `courtId` | String? | — |

### `PlayerModel`
Jugador perteneciente a un equipo.

| Campo | Tipo |
|-------|------|
| `id` | String |
| `firstName` / `lastName` | String |
| `email` | String |
| `phone` | String? |
| `profilePhotoUrl` | String? |
| `status` | String |
| `teamId` / `teamName` | String |

Propiedad calculada: `fullName` → `"$firstName $lastName"`.

### `LeagueStanding` (dominio)
Estructura mutable de estadísticas por equipo. No viene del API; se **computa en cliente**.

| Campo | Calculado? | Descripción |
|-------|-----------|-------------|
| `mp` | no | Partidos jugados |
| `w` / `d` / `l` | no | Ganados / Empatados / Perdidos |
| `gf` / `ga` | no | Goles a favor / en contra |
| `pts` | **sí** | `w×3 + d` |
| `gd` | **sí** | `gf - ga` |

---

## 5. Capa de dominio — interfaces de repositorio

Las tres interfaces definen el contrato que los servicios deben cumplir:

```dart
// Equipos inscritos
abstract class ILeagueTeamsRepository {
  Future<List<TeamEventModel>> getByEvent(String eventId);
  Future<TeamEventModel> add(String teamId, String eventId);
  Future<void> remove(String teamsEventsId);
}

// Partidos
abstract class ILeagueMatchesRepository {
  Future<List<MatchModel>> getByEvent(String eventId);
  Future<MatchModel> create(Map<String, dynamic> data);
  Future<MatchModel> update(String id, Map<String, dynamic> data);
  Future<void> delete(String id);
  Future<List<MatchModel>> rescheduleDate(String eventId, DateTime from, {DateTime? to});
}

// Configuración y generación de horarios
abstract class ILeagueScheduleRepository {
  Future<EventScheduleConfigModel?> getConfig(String eventId);
  Future<EventScheduleConfigModel> saveConfig(String eventId, Map<String, dynamic> data);
  Future<List<MatchModel>> generate(String eventId);
}
```

---

## 6. Capa de datos — servicios

### `LeagueDetailService` (facade)
Agrega los tres repositorios en un único punto. Se usa directamente en contextos donde se necesitan las tres fuentes (p. ej., pantallas administrativas que no usan `LeagueDetailNotifier`).

### `LeagueMatchesService`
Implementa `ILeagueMatchesRepository`. Cada método hace una llamada HTTP:
- `getByEvent` → `GET /matches?eventId=…`
- `create` → `POST /matches`
- `update` → `PUT /matches/{id}`
- `delete` → `DELETE /matches/{id}`
- `rescheduleDate` → `PATCH /matches/reschedule`

### `LeagueTeamsEventService`
Implementa `ILeagueTeamsRepository`.
- `getByEvent` → `GET /teams-events?eventId=…`
- `add` → `POST /teams-events`
- `remove` → `DELETE /teams-events/{id}`

### `LeagueScheduleService`
Implementa `ILeagueScheduleRepository`.
- `getConfig` → `GET /schedule-config?eventId=…`
- `saveConfig` → `POST /schedule-config`
- `generate` → `POST /schedule-config/generate`

### `PlayersService`
Gestión de jugadores con dos rutas de invitación:
- **Usuario existente** → `POST /players/invite` (por email)
- **Usuario nuevo** → `POST /players/invite-new` (envía link de registro)
- `removeFromTeam` → `DELETE /players/{id}`

### `TeamsService`
- `getAll` → lista todos los equipos de la plataforma
- `create` → crea un nuevo equipo

### `CourtsService`
- `getAll` → lista canchas disponibles

---

## 7. Inyección de dependencias

Todos los servicios se registran como **lazy singletons** en `service_locator.dart`:

```
GetIt
├── ILeagueTeamsRepository    → LeagueTeamsEventService
├── ILeagueMatchesRepository  → LeagueMatchesService
├── ILeagueScheduleRepository → LeagueScheduleService
├── LeagueDetailService       (facade, usa las 3 anteriores)
├── TeamsService
├── PlayersService
├── CourtsService
└── EventsNotifier (instanceName: 'leagues')
```

`LeagueDetailPage` resuelve `ILeagueTeamsRepository` e `ILeagueMatchesRepository` al crear el notifier:

```dart
_notifier = LeagueDetailNotifier(
  teamsRepo: getIt<ILeagueTeamsRepository>(),
  matchesRepo: getIt<ILeagueMatchesRepository>(),
  eventId: _event.id,
);
```

---

## 8. Gestión de estado — Notifiers

### `LeagueDetailNotifier` (`ChangeNotifier`)

Es el **estado central** de toda la pantalla de detalle. Mantiene sincronizados equipos y partidos.

**Estado expuesto:**

| Getter | Tipo | Descripción |
|--------|------|-------------|
| `teams` | `List<TeamEventModel>` | Equipos inscritos (inmutable) |
| `matches` | `List<MatchModel>` | Partidos planos |
| `groupedMatches` | `List<(DateTime, List<MatchModel>)>` | Partidos agrupados por día |
| `loadingTeams` | bool | Carga inicial de equipos |
| `loadingMatches` | bool | Carga inicial de partidos |
| `teamsError` | String? | Clave i18n del error |
| `matchesError` | String? | Clave i18n del error |

**Métodos y efecto sobre el estado:**

```
loadTeams()           → _teams, _loadingTeams, _teamsError
loadMatches()         → _matches, _groupedMatches, _loadingMatches, _matchesError
addTeam(teamId)       → prepend a _teams
removeTeam(id)        → filtra _teams
createMatch(data)     → prepend a _matches + reagrupa
updateMatch(id, data) → reemplaza en _matches + reagrupa
deleteMatch(id)       → filtra _matches + reagrupa
addGeneratedMatches   → append a _matches + reagrupa
rescheduleDateMatches → actualiza partidos afectados + reagrupa
```

**Agrupación por fecha (`_groupByDate`):**
Los partidos se ordenan por `matchDate` y se agrupan por clave `"YYYY-MM-DD"`. El resultado es una lista de tuplas `(DateTime, List<MatchModel>)` usadas por `LeagueMatchesTab`.

---

### `AddPlayersNotifier` (`ChangeNotifier`)

Estado del modal de gestión de jugadores de un equipo. Se crea al abrir `AddPlayersSheet`.

| Estado | Descripción |
|--------|-------------|
| `players` | Jugadores actuales del equipo |
| `loadingExisting` | Carga inicial de la lista |
| `searching` | Búsqueda de usuario por email |
| `searchResult` | `PlayerInvitationModel?` encontrado |
| `sendingInvitation` | Envío en curso |

Límites: mínimo **1** jugador, máximo **30** por equipo.

---

## 9. Pantalla principal — `LeagueDetailPage`

### Entrada

```dart
LeagueDetailPage(event: EventModel, isOwner: bool)
```

- `event`: datos del evento (nombre, fechas, descripción).
- `isOwner`: controla visibilidad de acciones de edición y FAB.

### Ciclo de vida

```
initState()
  ├── crea TabController (4 tabs)
  ├── crea LeagueDetailNotifier con repos del DI
  ├── _notifier.loadTeams()   ← llamada paralela
  └── _notifier.loadMatches() ← llamada paralela

dispose()
  ├── _tabController.dispose()
  └── _notifier.dispose()
```

### Estructura del Scaffold

```
Scaffold
├── AppBar
│   ├── Título: event.name
│   └── TabBar (4 tabs)
│       ├── [0] Info
│       ├── [1] Equipos
│       ├── [2] Partidos
│       └── [3] Posiciones
├── Body: TabBarView
│   ├── [0] _buildInfoTab()
│   ├── [1] _buildTeamsTab()
│   ├── [2] _buildMatchesTab()
│   └── [3] _buildStandingsTab()
└── FAB: LeagueFab (solo si isOwner)
```

Todo el body está envuelto en `ListenableBuilder(listenable: _notifier)`, de modo que cualquier cambio en el notifier reconstruye únicamente la parte afectada.

### Helper `_confirmAndExecute`

Patrón reutilizable para operaciones destructivas. Evita duplicar el código de confirmación + try/catch en toda la pantalla:

```
_confirmAndExecute(title, content?, confirmLabel, cancelLabel, action, successMsg, errorMsg)
  1. Muestra ConfirmationDialog
  2. Si el usuario cancela → retorna sin hacer nada
  3. Ejecuta action()
  4. Muestra snackbar de éxito
  5. Si action() lanza → muestra snackbar de error
```

Lo usan: `_confirmRemoveTeam` y `_confirmDeleteMatch`.

---

## 10. Pestañas y widgets

### Tab 0 — Info (`_buildInfoTab`)

```
SingleChildScrollView
└── LeagueInfoCard(event, isOwner, onSave, onError)
```

`LeagueInfoCard` muestra nombre, fechas inicio/fin y descripción. Si `isOwner = true`, habilita edición en línea. Al guardar:
1. Llama a `EventsNotifier(instanceName: 'leagues').update(id, data)`
2. Actualiza `_event` localmente con `setState`
3. Muestra snackbar de éxito

---

### Tab 1 — Equipos (`_buildTeamsTab`)

```
LeagueTeamsTab
├── Estado de carga / error / vacío
└── ListView de TeamEventCard
    ├── Nombre del equipo
    ├── [owner] Botón "Gestionar jugadores" → AddPlayersSheet
    └── [owner] Botón "Remover" → _confirmRemoveTeam
```

**Flujo agregar equipo (FAB en tab 1):**

```
_openAddTeam()
  ├── Calcula enrolledIds (equipos ya inscritos)
  └── AddTeamSheet.show()
      ├── Lista todos los equipos de la plataforma
      ├── Filtra los ya inscritos
      ├── [sin resultado] Botón "Crear nuevo" → CreateTeamSheet
      └── Al seleccionar → _notifier.addTeam(teamId)
```

**Flujo gestionar jugadores:**

```
AddPlayersSheet.show(team, isEditMode: true)
  ├── Tab "Jugadores actuales"
  │   ├── Lista playerModels del equipo
  │   └── [owner] Botón remover por jugador
  └── Tab "Agregar jugador"
      ├── Campo búsqueda por email
      ├── Si usuario existe → "Invitar" (POST /players/invite)
      └── Si no existe → "Enviar link de registro" (POST /players/invite-new)
```

---

### Tab 2 — Partidos (`_buildMatchesTab`)

```
LeagueMatchesTab
├── RefreshIndicator → _notifier.loadMatches()
├── Estado de carga / error / vacío
└── ListView de MatchDaySection (agrupados por día)
    ├── Header: "Lun 12 Jun" + [owner] menu popup
    │   ├── "Reprogramar día" → DatePicker → _onRescheduleDay(from, to)
    │   └── "Aplazar día"    → _onRescheduleDay(from, null)
    └── Lista de MatchCard
        ├── Equipos local vs visitante
        ├── Marcador (si status ≠ SCHEDULED)
        ├── Fecha, hora, cancha
        ├── [owner] Icono editar → _openEditMatch(match)
        └── [owner] Icono eliminar → _confirmDeleteMatch(match)
```

---

### Tab 3 — Posiciones (`_buildStandingsTab`)

Muestra un spinner mientras `loadingTeams || loadingMatches`. Una vez cargados ambos:

```
StandingsTab(teams, matches)
  └── LeagueStanding.compute(teams, matches)
      ├── Itera todos los partidos con status FINISHED
      ├── Acumula mp, w, d, l, gf, ga por equipo
      └── Ordena: pts → gd → gf → nombre
```

La tabla muestra columnas: **Pos, Equipo, PJ, G, E, P, Pts** con badges dorado/plata/bronce para el top 3.

> La tabla de posiciones es **100% local**: no requiere llamada al API; se deriva de los datos ya cargados en el notifier.

---

## 11. Flujos de usuario

### Crear partido manualmente

```
[FAB tab 2] → menú expandido → "Nuevo partido"
  └── MatchFormSheet.show(enrolledTeams, eventId)
      ├── Selector equipo local (dropdown de equipos inscritos)
      ├── Selector equipo visitante (excluye el local)
      ├── DatePicker + TimePicker
      ├── Selector de cancha (CourtsService.getAll)
      └── [Guardar] → _notifier.createMatch(data)
                      → SnackBar "Partido creado"
```

### Editar partido

```
[MatchCard icono editar]
  └── MatchFormSheet.show(..., match: existente)
      ├── Mismos campos, pre-rellenos con datos del partido
      ├── Selector de estado: SCHEDULED | IN_PROGRESS | FINISHED | CANCELLED | POSTPONED
      ├── [si estado ≠ SCHEDULED] Campos de score local/visitante
      └── [Guardar] → _notifier.updateMatch(id, data)
                      → SnackBar "Partido actualizado"
```

### Auto-programar partidos

```
[FAB tab 2] → menú expandido → "Auto-programar"
  └── AutoScheduleSheet.show(eventId)
      ├── Carga configuración existente (ILeagueScheduleRepository.getConfig)
      ├── Días de juego (multi-select: L M X J V S D)
      ├── Hora de inicio (TimePicker)
      ├── Duración del partido, descanso de mitades, descanso entre partidos
      ├── Selección de cancha
      ├── [Guardar config] → ILeagueScheduleRepository.saveConfig
      └── [Generar] → ILeagueScheduleRepository.generate
                      → _notifier.addGeneratedMatches(resultado)
                      → SnackBar "Partidos generados"
```

### Reprogramar día completo

```
[MatchDaySection menú popup] → "Reprogramar día"
  └── DatePicker (nueva fecha)
      └── _onRescheduleDay(fromDate, toDate)
          → _notifier.rescheduleDateMatches(from, toDate: to)
          → API actualiza todos los partidos de ese día
          → Notifier reemplaza los registros afectados
          → Reagrupa partidos por fecha
          → SnackBar "Día reprogramado"

[MatchDaySection menú popup] → "Aplazar día"
  └── _onRescheduleDay(fromDate, null)
      → API marca partidos como POSTPONED
      → SnackBar "Día aplazado"
```

### Crear equipo desde cero

```
[AddTeamSheet] → "Crear nuevo equipo"
  └── CreateTeamSheet.show()
      ├── Campo nombre
      ├── Selector de imagen (logo) — TODO: cloud storage pendiente
      └── [Crear] → TeamsService.create(nombre, logo?)
                    → AddPlayersSheet.show() (encadenado automáticamente)
                    → agrega el nuevo equipo al evento
```

---

## 12. FAB dinámico — `LeagueFab`

El FAB se adapta según la pestaña activa mediante `AnimatedBuilder` sobre el `TabController`:

| Tab activa | FAB renderizado |
|-----------|----------------|
| 0 — Info | `SizedBox.shrink()` (oculto) |
| 1 — Equipos | `FloatingActionButton` → agregar equipo |
| 2 — Partidos | `_MatchFabMenu` (expandible) |
| 3 — Posiciones | `SizedBox.shrink()` (oculto) |

**`_MatchFabMenu`** muestra un FAB principal con ícono `+` que rota 45° al expandirse. Al expandir aparecen dos `_MiniActionButton`:
1. **Auto-programar** (ícono `auto_awesome`)
2. **Nuevo partido** (ícono `edit_calendar_outlined`)

Al cambiar de tab, el FAB colapsa automáticamente mediante un listener registrado en `initState` y removido en `dispose`.

---

## 13. Tabla de posiciones — lógica de cómputo

`LeagueStanding.compute(teams, matches)` es un método estático puro (sin dependencias de Flutter):

```
1. Inicializa un Map<teamId, LeagueStanding> con cada equipo inscrito
2. Filtra partidos con status == 'FINISHED'
3. Para cada partido con scores definidos:
   a. Determina ganador (homeScore > awayScore, viceversa, o empate)
   b. Acumula mp +1 en ambos equipos
   c. Acumula w / d / l según resultado
   d. Acumula gf y ga para cada lado
4. Convierte el mapa a lista
5. Ordena descendente por: pts → gd → gf → nombre (alfabético ascendente)
6. Retorna List<(String teamName, LeagueStanding)>
```

La tabla se recalcula en cada rebuild cuando el notifier notifica cambios. No se cachea porque el costo de cómputo es lineal en el número de partidos (típicamente < 200 en una liga).
