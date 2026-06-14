import 'package:flutter/foundation.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/datasource/players_service.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_invitation_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/player_model.dart';

class AddPlayersNotifier extends ChangeNotifier {
  static const int minPlayers = 1;
  static const int maxPlayers = 30;

  final PlayersService _service;
  final String teamId;
  final bool isEditMode;

  List<PlayerModel> _existingPlayers = [];
  List<PlayerInvitation> _addedPlayers = [];
  bool _loadingExisting = false;
  String? _loadError;
  bool _searching = false;
  bool _sendingInvitation = false;
  PlayerModel? _foundUser;
  bool _searchPerformed = false;
  String? _searchError;
  String? _inviteError;

  AddPlayersNotifier({
    required PlayersService service,
    required this.teamId,
    required this.isEditMode,
  }) : _service = service;

  List<PlayerModel> get existingPlayers => List.unmodifiable(_existingPlayers);
  List<PlayerInvitation> get addedPlayers => List.unmodifiable(_addedPlayers);
  bool get loadingExisting => _loadingExisting;
  String? get loadError => _loadError;
  bool get searching => _searching;
  bool get sendingInvitation => _sendingInvitation;
  PlayerModel? get foundUser => _foundUser;
  bool get searchPerformed => _searchPerformed;
  String? get searchError => _searchError;
  String? get inviteError => _inviteError;
  int get totalCount => _existingPlayers.length + _addedPlayers.length;
  bool get atMax => totalCount >= maxPlayers;
  bool get canFinish => _addedPlayers.length >= minPlayers;

  Future<void> load() async {
    _loadingExisting = true;
    _loadError = null;
    notifyListeners();
    try {
      _existingPlayers = await _service.getByTeamId(teamId);
    } catch (_) {
      _loadError = 'players.error_load';
    } finally {
      _loadingExisting = false;
      notifyListeners();
    }
  }

  Future<void> searchUser(String email) async {
    final normalized = email.toLowerCase();
    if (_addedPlayers.any((p) => p.email.toLowerCase() == normalized) ||
        _existingPlayers.any((p) => p.email.toLowerCase() == normalized)) {
      _searchError = 'players.already_added';
      notifyListeners();
      return;
    }
    _searching = true;
    _searchError = null;
    _inviteError = null;
    _searchPerformed = false;
    _foundUser = null;
    notifyListeners();
    try {
      _foundUser = await _service.searchByEmail(email);
      _searchPerformed = true;
    } catch (_) {
      _searchError = 'players.error_search';
    } finally {
      _searching = false;
      notifyListeners();
    }
  }

  /// Returns true on success; on failure sets [inviteError] and returns false.
  Future<bool> inviteExistingUser(String email) async {
    _sendingInvitation = true;
    _inviteError = null;
    notifyListeners();
    try {
      await _service.inviteExistingUser(email: email, teamId: teamId);
      _addedPlayers = [
        ..._addedPlayers,
        PlayerInvitation(
          email: email,
          firstName: _foundUser?.firstName,
          lastName: _foundUser?.lastName,
          isExisting: true,
        ),
      ];
      return true;
    } catch (_) {
      _inviteError = 'players.error_invite';
      return false;
    } finally {
      _sendingInvitation = false;
      notifyListeners();
    }
  }

  /// Returns true on success; on failure sets [inviteError] and returns false.
  Future<bool> sendRegistrationLink(String email) async {
    _sendingInvitation = true;
    _inviteError = null;
    notifyListeners();
    try {
      await _service.inviteNewUser(email: email, teamId: teamId);
      _addedPlayers = [
        ..._addedPlayers,
        PlayerInvitation(
          email: email,
          firstName: null,
          lastName: null,
          isExisting: false,
        ),
      ];
      return true;
    } catch (_) {
      _inviteError = 'players.error_invite';
      return false;
    } finally {
      _sendingInvitation = false;
      notifyListeners();
    }
  }

  /// Returns true on success.
  Future<bool> removePlayer(String playerId) async {
    try {
      await _service.removeFromTeam(playerId);
      _existingPlayers =
          _existingPlayers.where((p) => p.id != playerId).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearSearch() {
    _foundUser = null;
    _searchPerformed = false;
    _searchError = null;
    _inviteError = null;
    notifyListeners();
  }
}
