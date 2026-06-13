import '../core/utils/validators.dart';

class ParticipantModel {
  final String name;
  final int? teamAScore, teamBScore;
  ParticipantModel({required this.name, this.teamAScore, this.teamBScore});
  factory ParticipantModel.fromMap(Map<String, dynamic> m) {
    final display = (m['display_name'] ?? m['full_name'] ?? '').toString();
    final mobile = Validators.maskMobile(m['mobile_number']?.toString());
    return ParticipantModel(
      name: display.isNotEmpty ? display : (mobile.isNotEmpty ? mobile : 'Player'),
      teamAScore: int.tryParse('${m['team_a_score'] ?? ''}'),
      teamBScore: int.tryParse('${m['team_b_score'] ?? ''}'),
    );
  }
}
