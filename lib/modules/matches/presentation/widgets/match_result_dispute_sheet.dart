import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_input_decoration.dart';
import 'package:sport_platform/core/theme/app_text_styles.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/matches/domain/match_dispute_rules.dart';
import 'package:sport_platform/shared/widgets/sheet_handle.dart';

/// Envía el aviso. Devuelve la clave de traducción de lo que salió mal, o null si se envió.
typedef SendDispute = Future<String?> Function({
  required String reason,
  int? proposedHomeScore,
  int? proposedAwayScore,
});

/// El formulario del aviso: qué está mal y, si se sabe, cuál es el marcador correcto. Se cierra con `true` cuando el
/// aviso se envió.
class MatchResultDisputeSheet extends StatefulWidget {
  final MatchModel match;
  final String homeName;
  final String awayName;
  final SendDispute onSend;

  const MatchResultDisputeSheet({
    super.key,
    required this.match,
    required this.homeName,
    required this.awayName,
    required this.onSend,
  });

  static Future<bool?> show({
    required BuildContext context,
    required MatchModel match,
    required String homeName,
    required String awayName,
    required SendDispute onSend,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchResultDisputeSheet(match: match, homeName: homeName, awayName: awayName, onSend: onSend),
    );
  }

  @override
  State<MatchResultDisputeSheet> createState() => _MatchResultDisputeSheetState();
}

class _MatchResultDisputeSheetState extends State<MatchResultDisputeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _homeScoreController = TextEditingController();
  final _awayScoreController = TextEditingController();

  bool _isSending = false;

  /// Lo que el marcador propuesto tiene mal, o lo que el backend rechazó; null si nada.
  String? _problemKey;

  @override
  void dispose() {
    _reasonController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  String? _validateReason(String? value) =>
      (value == null || value.trim().isEmpty) ? 'match_detail.dispute.errors.REASON_REQUIRED'.tr() : null;

  String? _scoreProblemKey(ProposedScoreInput score) => switch (score.problem) {
        ProposedScoreProblem.incomplete => 'match_detail.dispute.errors.SCORE_INCOMPLETE',
        ProposedScoreProblem.invalid => 'match_detail.dispute.errors.INVALID_SCORE',
        null => null,
      };

  Future<void> _send() async {
    final score = readProposedScore(_homeScoreController.text, _awayScoreController.text);
    final scoreProblem = _scoreProblemKey(score);
    final isFormValid = _formKey.currentState!.validate();
    setState(() => _problemKey = scoreProblem);
    if (!isFormValid || scoreProblem != null) return;

    setState(() => _isSending = true);
    final backendProblem = await widget.onSend(
      reason: _reasonController.text.trim(),
      proposedHomeScore: score.homeScore,
      proposedAwayScore: score.awayScore,
    );
    if (!mounted) return;
    if (backendProblem == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSending = false;
      _problemKey = backendProblem;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final match = widget.match;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 20),
              Text('match_detail.dispute.sheet_title'.tr(), style: AppTextStyles.sectionTitle),
              const SizedBox(height: 6),
              Text(
                'match_detail.dispute.current_result'.tr(
                  namedArgs: {
                    'home': widget.homeName,
                    'homeScore': '${match.homeScore}',
                    'awayScore': '${match.awayScore}',
                    'away': widget.awayName,
                  },
                ),
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                autofocus: true,
                enabled: !_isSending,
                minLines: 3,
                maxLines: 5,
                maxLength: disputeReasonMaxLength,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.white),
                decoration: AppInputDecoration.standard('match_detail.dispute.reason_label'.tr()).copyWith(
                  hintText: 'match_detail.dispute.reason_hint'.tr(),
                  hintStyle: const TextStyle(color: AppColors.whiteSubtle),
                  alignLabelWithHint: true,
                ),
                validator: _validateReason,
              ),
              const SizedBox(height: 8),
              Text('match_detail.dispute.score_title'.tr(), style: AppTextStyles.caption),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _scoreField(_homeScoreController, widget.homeName)),
                  const SizedBox(width: 12),
                  Expanded(child: _scoreField(_awayScoreController, widget.awayName)),
                ],
              ),
              if (_problemKey != null) ...[
                const SizedBox(height: 12),
                Text(_problemKey!.tr(), style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSending ? null : _send,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : Text('match_detail.dispute.send'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreField(TextEditingController controller, String teamName) {
    return TextFormField(
      controller: controller,
      enabled: !_isSending,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
      style: const TextStyle(color: AppColors.white),
      decoration: AppInputDecoration.standard(teamName),
    );
  }
}
