/// Normalizes a Supabase join result for a replay row so that it can be parsed
/// by [ReplayModel.fromJson].
Map<String, dynamic> normalizeReplayRow(Map<String, dynamic> map) {
  final normalized = Map<String, dynamic>.from(map);

  final arena = normalized.remove('arenas') as Map<String, dynamic>?;
  if (arena != null) {
    normalized['arena_name'] = arena['name'];
  }

  final court = normalized.remove('courts') as Map<String, dynamic>?;
  if (court != null) {
    normalized['court_name'] = court['name'];
  }

  normalized['visibility'] ??= 'public';
  normalized['recorded_at'] ??=
      normalized['created_at'] ?? DateTime.now().toIso8601String();
  normalized['created_at'] ??= DateTime.now().toIso8601String();
  normalized['updated_at'] ??= normalized['created_at'];
  normalized['duration_seconds'] ??= 0;

  return normalized;
}
