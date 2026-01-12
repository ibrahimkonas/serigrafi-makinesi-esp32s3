class MachineEvent {
  final DateTime time;
  final String type; // 'ariza' veya 'duruş'
  final String reason;
  MachineEvent({required this.time, required this.type, required this.reason});
  String get timeString => '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
