import 'package:sport_platform/core/network/json_reader.dart';
import 'package:sport_platform/shared/enums/category_eligibility_issue.dart';
import 'package:sport_platform/core/utils/birth_date_rules.dart';
import 'package:sport_platform/core/models/gender.dart';

/// Un equipo en el que juega el jugador. Un jugador puede jugar en varios, pero solo en uno por organización.
class PlayerTeam {
  final String teamId;
  final String teamName;

  /// La organización del equipo; null en los del propietario de la plataforma.
  final String? organizationId;

  /// Si es el capitán de ESTE equipo (lo designa el administrador; hay uno por equipo).
  final bool isCaptain;

  /// Falso cuando el jugador no cumple lo que pide la categoría del equipo (género, edad): sigue en la plantilla pero no
  /// puede jugar. Lo calcula el backend (la edad cambia cada día), la app solo lo muestra.
  final bool eligibleForCategory;

  /// Por qué no cumple; null cuando cumple (o cuando el backend dice un motivo que esta versión no conoce).
  final CategoryEligibilityIssue? categoryIneligibility;

  const PlayerTeam({
    required this.teamId,
    required this.teamName,
    this.organizationId,
    this.isCaptain = false,
    this.eligibleForCategory = true,
    this.categoryIneligibility,
  });

  /// El jugador está en el equipo pero la categoría no lo deja jugar.
  bool get cannotPlay => !eligibleForCategory;

  factory PlayerTeam.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'equipo del jugador');
    return PlayerTeam(
      teamId: reader.requiredString('teamId'),
      teamName: reader.requiredString('teamName'),
      organizationId: reader.optionalString('organizationId'),
      isCaptain: reader.flag('isCaptain'),
      // Un backend anterior no lo manda: sin dato, el jugador puede jugar.
      eligibleForCategory: json['eligibleForCategory'] != false,
      categoryIneligibility: CategoryEligibilityIssue.fromCode(reader.optionalString('categoryIneligibility')),
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        if (organizationId != null) 'organizationId': organizationId,
        if (isCaptain) 'isCaptain': isCaptain,
        if (!eligibleForCategory) 'eligibleForCategory': false,
        if (categoryIneligibility != null) 'categoryIneligibility': categoryIneligibility!.code,
      };
}

class PlayerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? status;

  /// Lo que las categorías pueden pedir. Null mientras el jugador no los diga.
  final Gender? gender;
  final DateTime? birthDate;

  /// El equipo que el backend da por «el suyo»: el último al que entró el jugador. Quien juega en varios los tiene todos en
  /// [teams] (úsese [allTeams], que además cubre un backend que aún no los manda).
  final String? teamId;
  final String? teamName;

  /// El capitán del equipo de [teamId] (lo designa el administrador; hay uno por equipo).
  final bool isCaptain;

  /// Todos los equipos en los que juega, el último al que entró primero. Vacío si el backend no los manda.
  final List<PlayerTeam> teams;

  const PlayerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.profilePhotoUrl,
    this.status,
    this.gender,
    this.birthDate,
    this.teamId,
    this.teamName,
    this.isCaptain = false,
    this.teams = const [],
  });

  String get fullName => '$firstName $lastName';

  /// Todos los equipos del jugador. Con un backend anterior, que solo manda `teamId`, es ese equipo; sin equipo, vacío.
  List<PlayerTeam> get allTeams {
    if (teams.isNotEmpty) return teams;
    final id = teamId;
    if (id == null || id.isEmpty) return const [];
    return [PlayerTeam(teamId: id, teamName: teamName ?? '', isCaptain: isCaptain)];
  }

  /// Los ids de todos sus equipos.
  Set<String> get teamIds => {for (final team in allTeams) team.teamId};

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, resource: 'jugador');
    return PlayerModel(
      id: reader.requiredString('id'),
      firstName: reader.requiredString('firstName'),
      lastName: reader.requiredString('lastName'),
      email: reader.requiredString('email'),
      phone: reader.optionalString('phone'),
      profilePhotoUrl: reader.optionalString('profilePhotoUrl'),
      status: reader.optionalString('status'),
      gender: Gender.fromApi(reader.optionalString('gender')),
      birthDate: parseBirthDate(json['birthDate']),
      teamId: reader.optionalString('teamId'),
      teamName: reader.optionalString('teamName'),
      isCaptain: reader.flag('isCaptain'),
      teams: reader.list('teams', PlayerTeam.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
        if (status != null) 'status': status,
        if (gender != null) 'gender': gender!.apiValue,
        if (birthDate != null) 'birthDate': formatBirthDateForApi(birthDate!),
        if (teamId != null) 'teamId': teamId,
        if (teamName != null) 'teamName': teamName,
        if (isCaptain) 'isCaptain': isCaptain,
        if (teams.isNotEmpty) 'teams': teams.map((team) => team.toJson()).toList(),
      };

  PlayerModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profilePhotoUrl,
    String? status,
    Gender? gender,
    DateTime? birthDate,
    String? teamId,
    String? teamName,
    bool? isCaptain,
    List<PlayerTeam>? teams,
  }) =>
      PlayerModel(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        status: status ?? this.status,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        teamId: teamId ?? this.teamId,
        teamName: teamName ?? this.teamName,
        isCaptain: isCaptain ?? this.isCaptain,
        teams: teams ?? this.teams,
      );
}
