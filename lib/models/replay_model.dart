enum ReplayVisibility { public, expired }

class ReplayModel {
  const ReplayModel({
    required this.title,
    required this.courtName,
    required this.duration,
    required this.timeAgo,
    required this.visibility,
  });

  final String title;
  final String courtName;
  final String duration;
  final String timeAgo;
  final ReplayVisibility visibility;
}
