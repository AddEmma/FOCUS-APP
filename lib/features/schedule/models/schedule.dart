class FocusSchedule {
  final String id;
  final String title;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final List<int> days; // 1-7 (Mon-Sun)
  final List<String> blockedApps;
  final bool isEnabled;

  const FocusSchedule({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.blockedApps,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'days': days,
      'blockedApps': blockedApps,
      'isEnabled': isEnabled,
    };
  }

  factory FocusSchedule.fromMap(Map<String, dynamic> map) {
    return FocusSchedule(
      id: map['id'],
      title: map['title'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      days: List<int>.from(map['days']),
      blockedApps: List<String>.from(map['blockedApps']),
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  FocusSchedule copyWith({
    String? title,
    String? startTime,
    String? endTime,
    List<int>? days,
    List<String>? blockedApps,
    bool? isEnabled,
  }) {
    return FocusSchedule(
      id: this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      days: days ?? this.days,
      blockedApps: blockedApps ?? this.blockedApps,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
