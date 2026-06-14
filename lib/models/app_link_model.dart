class AppLinkModel {
  final String id;
  final String linkKey;
  final String title;
  final String? subtitle;
  final String buttonText;
  final String url;
  final bool isActive;

  const AppLinkModel({
    required this.id,
    required this.linkKey,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.url,
    required this.isActive,
  });

  factory AppLinkModel.fromMap(Map<String, dynamic> map) {
    return AppLinkModel(
      id: '${map['id'] ?? ''}',
      linkKey: '${map['link_key'] ?? ''}',
      title: _text(map['title']) ?? 'Join our Community',
      subtitle: _text(map['subtitle']),
      buttonText: _text(map['button_text']) ?? 'Join Group',
      url: '${map['url'] ?? ''}',
      isActive: map['is_active'] == true,
    );
  }

  static String? _text(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}