class ChatRoom {
  final String id;
  final String orderId;
  final String customerId;
  final String staffId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  ChatRoom({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.staffId,
    this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      lastMessageAt: _parseDateTime(json['last_message_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'staff_id': staffId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
