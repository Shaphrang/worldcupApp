class MatchPrizePoolModel {
  final String id;
  final String matchId;
  final String title;
  final String? description;

  final String? prize1;
  final String? prize2;
  final String? prize3;

  final String? sponsorName;
  final String? bannerImageUrl;
  final String? terms;

  final bool isActive;

  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MatchPrizePoolModel({
    required this.id,
    required this.matchId,
    required this.title,
    required this.description,
    required this.prize1,
    required this.prize2,
    required this.prize3,
    required this.sponsorName,
    required this.bannerImageUrl,
    required this.terms,
    required this.isActive,
    required this.startsAt,
    required this.endsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchPrizePoolModel.fromMap(Map<String, dynamic> map) {
    return MatchPrizePoolModel(
      id: '${map['id'] ?? ''}',
      matchId: '${map['match_id'] ?? ''}',
      title: _readText(map['title'], fallback: 'Today\'s Prize Pool'),
      description: _nullableText(map['description']),
      prize1: _nullableText(map['prize_1']),
      prize2: _nullableText(map['prize_2']),
      prize3: _nullableText(map['prize_3']),
      sponsorName: _nullableText(map['sponsor_name']),
      bannerImageUrl: _nullableText(map['banner_image_url']),
      terms: _nullableText(map['terms']),
      isActive: _readBool(map['is_active']),
      startsAt: _readDate(map['starts_at']),
      endsAt: _readDate(map['ends_at']),
      createdAt: _readDate(map['created_at']),
      updatedAt: _readDate(map['updated_at']),
    );
  }

  bool get hasAnyPrize {
    return prize1 != null || prize2 != null || prize3 != null;
  }

  List<String> get prizes {
    return [
      if (prize1 != null) prize1!,
      if (prize2 != null) prize2!,
      if (prize3 != null) prize3!,
    ];
  }

  static String _readText(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _readBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;

    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}