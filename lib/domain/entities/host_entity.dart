import '../../core/utils/parse_utils.dart';

class HostEntity {
  const HostEntity({
    required this.id,
    required this.name,
    this.age,
    this.avatarUrl,
    this.about,
    this.ratePerMinute,
    this.effectiveRatePerMinute,
    this.isOnline = false,
    this.isBusy = false,
    this.languages = const [],
  });

  final int id;
  final String name;
  final int? age;
  final String? avatarUrl;
  final String? about;
  final double? ratePerMinute;
  final double? effectiveRatePerMinute;
  final bool isOnline;
  final bool isBusy;
  final List<Map<String, dynamic>> languages;

  factory HostEntity.fromMap(Map<String, dynamic> map) {
    return HostEntity(
      id: JsonParse.toInt(map['id']),
      name: map['name']?.toString() ?? 'Host',
      age: map['age'] is int ? map['age'] as int : int.tryParse('${map['age']}'),
      avatarUrl: map['avatar_url']?.toString(),
      about: map['about']?.toString(),
      ratePerMinute: JsonParse.toDouble(map['rate_per_minute']),
      effectiveRatePerMinute: JsonParse.toDouble(
        map['effective_rate_per_minute'] ?? map['rate_per_minute'],
      ),
      isOnline: map['is_online'] == 1 || map['is_online'] == true,
      isBusy: map['is_busy'] == 1 || map['is_busy'] == true,
      languages: map['languages'] is List
          ? (map['languages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (age != null) 'age': age,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (about != null) 'about': about,
      if (ratePerMinute != null) 'rate_per_minute': ratePerMinute,
      if (effectiveRatePerMinute != null) 'effective_rate_per_minute': effectiveRatePerMinute,
      'is_online': isOnline ? 1 : 0,
      'is_busy': isBusy ? 1 : 0,
      'languages': languages,
    };
  }

  HostEntity copyWith({
    bool? isOnline,
    bool? isBusy,
  }) {
    return HostEntity(
      id: id,
      name: name,
      age: age,
      avatarUrl: avatarUrl,
      about: about,
      ratePerMinute: ratePerMinute,
      effectiveRatePerMinute: effectiveRatePerMinute,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      languages: languages,
    );
  }
}
