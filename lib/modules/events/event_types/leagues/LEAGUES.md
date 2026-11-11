# Módulo de Ligas (`event_types/leagues`)

La liga es el tipo de evento de la app. Este módulo es **solo de lectura**: el organizador crea y gestiona eventos,
equipos, partidos y resultados desde el panel Angular; el jugador los consulta aquí. (Hasta el 2026-11-11 el módulo
traía también formularios de gestión —crear liga, equipos, partidos, calendario automático, jugadores— que ninguna
pantalla alcanzaba; se borraron. Si alguna vez hace falta gestionar desde la app, se reconstruye desde el historial
de git y con el contrato actual del backend.)

## Flujo de pantallas

```
LeaguesPage (`/ligas`, hoy sin entrada en el menú)      EventsPage (`/events`, «Eventos»)
  └─ EventTypePage: pestañas «Mis eventos» / «Todos»      └─ lista de eventos (buscador y filtros)
          └──────────────────────┬──────────────────────────────┘
                                 ▼
                     LeagueDetailPage (4 pestañas)
   Información │ Equipos │ Partidos │ Posiciones (o Campeonato si el formato tiene fases)
        │            │          │
        │            │          └─ MatchDetailPage (módulo `matches`: marcador y cronología)
        │            └─ TeamInEventPage: balance, partidos, goleadores y plantilla del equipo en ese evento
        └─ LeagueInfoCard + EventRulesCard (reglas del formato)
```

## Estructura de carpetas

```
leagues/
├── data/
│   ├── datasource/   league_service, league_teams_event_service, league_matches_service, standings_service,
│   │                 players_service, teams_service, courts_service
│   └── models/       match_model, team_model, team_event_model, player_model, court_model, standing_model
├── domain/
│   ├── enums/        match_status
│   ├── repositories/ i_league_teams_repository, i_league_matches_repository   (solo `getByEvent`)
│   └── team_in_event.dart   (reglas puras: partidos próximos y jugados de un equipo)
└── presentation/
    ├── pages/        leagues_page, league_detail_page, team_in_event_page
    ├── providers/    league_detail_notifier, team_in_event_notifier
    └── widgets/      league_info_card, league_teams_tab, team_event_card, league_matches_tab,
                      match_day_section, match_card, standings_tab, team_in_event_sections
```

Lo que comparten todos los tipos de evento vive en `events/shared/` (`EventModel`, `EventService`, `EventsNotifier`,
`EventTypePage`, `EventCard`, el campeonato y las reglas del formato).

## Estado

- `EventsNotifier` (GetIt, `instanceName: 'leagues'`): la lista de eventos y «mis eventos», con caché de 3 minutos.
  Se reinicia al cerrar la sesión o cuando la organización de la cuenta cambia.
- `LeagueDetailNotifier` (se crea en el `State` de `LeagueDetailPage`): equipos y partidos del evento, cada uno con su
  carga, su error (como clave de traducción) y los partidos agrupados por día.
- `TeamInEventNotifier` (se crea en `TeamInEventPage`): partidos, estadísticas y plantilla del equipo, cada lectura por
  su cuenta para que una que falla no tape a las demás.

## Endpoints que lee

| Pantalla o servicio | Endpoint |
|---|---|
| Lista de eventos (`EventService.getAll`) | `GET /events/by-event-type/{typeId}` |
| «Mis eventos» (`EventService.getMyIds`) | `GET /events/by-event-type/{typeId}/by-user/{userId}` |
| Equipos inscritos (`LeagueTeamsEventService`) | `GET /teams-events/by-event/{eventId}` |
| Partidos del evento (`LeagueMatchesService`) | `GET /matches/by-event/{eventId}` |
| Posiciones (`StandingsService.getById`) | `GET /events/{id}/standings` |
| Campeonato (`ChampionshipService`) | `GET /events/{id}/championship` |
| Un equipo (`TeamsService.getById`) | `GET /teams/{id}` |
| Plantilla (`PlayersService.getByTeamId`) y jugador en sesión (`getCurrent`) | `GET /players/by-team/{teamId}`, `GET /players/me` |

Qué ve el jugador (su organización y los eventos públicos) lo decide el backend: la app no filtra nada.

## Cómo agregar otro tipo de evento

Los pasos están en el `CLAUDE.md` del proyecto («Cómo agregar un tipo de evento nuevo»).
