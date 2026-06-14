class SponsorBannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final String placement;
  final String slot;
  final int sortOrder;
  final DateTime? createdAt;

  const SponsorBannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.linkUrl,
    required this.placement,
    required this.slot,
    required this.sortOrder,
    required this.createdAt,
  });

  factory SponsorBannerModel.fromMap(Map<String, dynamic> map) {
    return SponsorBannerModel(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? ''}',
      imageUrl: '${map['image_url'] ?? ''}',
      linkUrl: _nullableText(map['link_url']),
      placement: '${map['placement'] ?? ''}',
      slot: '${map['slot'] ?? 'top'}',
      sortOrder: _readInt(map['sort_order']),
      createdAt: _readDate(map['created_at']),
    );
  }

  static int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _nullableText(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

class SponsorBannerPlacement {
  static const global = 'global';
  static const home = 'home';
  static const fixtures = 'fixtures';
  static const prediction = 'prediction';
  static const myPredictions = 'my_predictions';
  static const rules = 'rules';
  static const profile = 'profile';
  static const winner = 'winner';
  static const winners = 'winners';
  static const leaderboard = 'leaderboard';
  static const matchDetail = 'match_detail';
}

class SponsorBannerSlot {
  static const top = 'top';
  static const middle = 'middle';
  static const bottom = 'bottom';

  static const afterHeader = 'after_header';
  static const afterMatches = 'after_matches';
  static const afterResults = 'after_results';
  static const afterPredictions = 'after_predictions';
  static const afterPopularPicks = 'after_popular_picks';
  static const beforeList = 'before_list';
  static const afterList = 'after_list';
}