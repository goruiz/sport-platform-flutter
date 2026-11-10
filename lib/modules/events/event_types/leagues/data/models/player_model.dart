/// Un equipo en el que juega el jugador. Un jugador puede jugar en varios, pero solo en uno por organización.
class PlayerTeam {
  final String teamId;
  final String teamName;

  /// La organización del equipo; null en los del propietario de la plataforma.
  final String? organizationId;

  /// Si es el capitán de ESTE equipo (lo designa el administrador; hay uno por equipo).
  final bool isCaptain;

  const PlayerTeam({
    required this.teamId,
    required this.teamName,
    this.organizationId,
    this.isCaptain = false,
  });

  factory PlayerTeam.fromJson(Map<String, dynamic> json) {
    return PlayerTeam(
      teamId: json['teamId']?.toString() ?? '',
      teamName: json['teamName']?.toString() ?? '',
      organizationId: json['organizationId']?.toString(),
      isCaptain: json['isCaptain'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        if (organizationId != null) 'organizationId': organizationId,
        if (isCaptain) 'isCaptain': isCaptain,
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
    final rawTeams = json['teams'];
    return PlayerModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      profilePhotoUrl: json['profilePhotoUrl']?.toString(),
      status: json['status']?.toString(),
      teamId: json['teamId']?.toString(),
      teamName: json['teamName']?.toString(),
      isCaptain: json['isCaptain'] == true,
      teams: rawTeams is List
          ? rawTeams.whereType<Map<String, dynamic>>().map(PlayerTeam.fromJson).toList()
          : const [],
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
        teamId: teamId ?? this.teamId,
        teamName: teamName ?? this.teamName,
        isCaptain: isCaptain ?? this.isCaptain,
        teams: teams ?? this.teams,
      );
}
