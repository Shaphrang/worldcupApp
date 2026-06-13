//lib/models/winner_model.dart

class WinnerModel {
  final String id;
  final String winnerName;
  final String matchTitle;
  final String? prize;
  final String? rewardDescription;
  final String? winnerType;
  final int? rankNo;
  final int? points;
  final DateTime? publishedAt;
  final String? sponsorImageUrl;

  const WinnerModel({
    required this.id,
    required this.winnerName,
    required this.matchTitle,
    this.prize,
    this.rewardDescription,
    this.winnerType,
    this.rankNo,
    this.points,
    this.publishedAt,
    this.sponsorImageUrl,
  });

  factory WinnerModel.fromMap(Map<String, dynamic> map) {
    return WinnerModel(
      id: _text(map['id']),
      winnerName: _text(
        map['winner_name'] ??
            map['full_name'] ??
            map['display_name'] ??
            'Winner',
      ),
      matchTitle: _text(
        map['match_title'] ??
            map['fixture_title'] ??
            'World Cup Winner',
      ),
      prize: _nullableText(
        map['prize'] ??
            map['reward_title'],
      ),
      rewardDescription: _nullableText(
        map['reward_description'],
      ),
      winnerType: _nullableText(
        map['winner_type'],
      ),
      rankNo: _nullableInt(
        map['rank_no'],
      ),
      points: _nullableInt(
        map['points'] ??
            map['total_points'],
      ),
      publishedAt: _toDateTime(
        map['published_at'] ??
            map['created_at'],
      ),
      sponsorImageUrl: _nullableText(
        map['sponsor_image_url'],
      ),
    );
  }

  static String _text(dynamic value) {
    if (value == null) return '';
    return '$value'.trim();
  }

  static String? _nullableText(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = '$value'.trim();
    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    final text = '$value'.trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text)?.toLocal();
  }
}