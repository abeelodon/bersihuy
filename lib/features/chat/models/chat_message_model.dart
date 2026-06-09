class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String messageType; // text, image, location
  final String? messageText;
  final String? attachmentUrl;
  final String? locationUrl;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageType,
    this.messageText,
    this.attachmentUrl,
    this.locationUrl,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      messageText: json['message_text'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      locationUrl: json['location_url'] as String?,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      readAt: _parseDateTime(json['read_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'message_type': messageType,
      'message_text': messageText,
      'attachment_url': attachmentUrl,
      'location_url': locationUrl,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isLocation => messageType == 'location';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
