class AppNotification {
  final String message;
  final DateTime timestamp;

  AppNotification({required this.message, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
