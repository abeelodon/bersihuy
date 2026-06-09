import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get existing room by orderId or create a new one.
  Future<ChatRoom> getOrCreateRoom({
    required String orderId,
    required String customerId,
    required String staffId,
  }) async {
    try {
      debugPrint('ChatService.getOrCreateRoom INIT: orderId=$orderId, customerId=$customerId, staffId=$staffId');

      // Attempt to get the room first
      final existingRoom = await _supabase
          .from('chat_rooms')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      if (existingRoom != null) {
        debugPrint('ChatService.getOrCreateRoom: Room already exists -> ${existingRoom['id']}');
        return ChatRoom.fromJson(existingRoom);
      }

      debugPrint('ChatService.getOrCreateRoom: Room not found. Inserting new room...');
      final newRoom = await _supabase.from('chat_rooms').insert({
        'order_id': orderId,
        'customer_id': customerId,
        'staff_id': staffId,
      }).select().single();

      debugPrint('ChatService.getOrCreateRoom: Room created successfully -> ${newRoom['id']}');
      return ChatRoom.fromJson(newRoom);
    } on PostgrestException catch (e) {
      debugPrint('ChatService.getOrCreateRoom PostgrestException: code=${e.code}, message=${e.message}, details=${e.details}, hint=${e.hint}');
      if (e.code == '23505' || e.message.contains('duplicate key value')) {
        debugPrint('ChatService.getOrCreateRoom: Duplicate key error. Retrying fetch...');
        try {
          final fallbackRoom = await _supabase
              .from('chat_rooms')
              .select()
              .eq('order_id', orderId)
              .maybeSingle();

          if (fallbackRoom != null) {
            debugPrint('ChatService.getOrCreateRoom: Found room after duplicate error -> ${fallbackRoom['id']}');
            return ChatRoom.fromJson(fallbackRoom);
          }
        } catch (innerE) {
          debugPrint('ChatService.getOrCreateRoom inner error on fallback fetch: $innerE');
        }
      }
      throw Exception('Database Error: ${e.message}');
    } catch (e) {
      debugPrint('ChatService.getOrCreateRoom Generic Error: $e');
      throw Exception('Terjadi kesalahan sistem: $e');
    }
  }

  /// Get messages for a specific room, ordered by created_at ascending.
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final response = await _supabase
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Send a text message. Returns the inserted message row.
  Future<ChatMessage> sendTextMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    final response = await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'message_type': 'text',
      'message_text': text,
    }).select().single();

    _updateLastMessageAt(roomId);
    return ChatMessage.fromJson(response);
  }

  /// Upload image to storage and send an image message.
  Future<ChatMessage> sendImageMessage({
    required String roomId,
    required String senderId,
    required Uint8List imageBytes,
    required String mimeType,
    String? caption,
  }) async {
    final ext = mimeType.split('/').last;
    final normalizedExt = ext == 'jpeg' ? 'jpg' : ext;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$senderId.$normalizedExt';
    final filePath = '$roomId/$fileName';

    // Upload to bucket
    await _supabase.storage.from('chat-attachments').uploadBinary(
          filePath,
          imageBytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    final publicUrl = _supabase.storage
        .from('chat-attachments')
        .getPublicUrl(filePath);

    // Send message
    final response = await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'message_type': 'image',
      'message_text': caption,
      'attachment_url': publicUrl,
    }).select().single();

    _updateLastMessageAt(roomId);
    return ChatMessage.fromJson(response);
  }

  /// Send a location message.
  Future<ChatMessage> sendLocationMessage({
    required String roomId,
    required String senderId,
    required String locationUrl,
  }) async {
    final response = await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'message_type': 'location',
      'location_url': locationUrl,
    }).select().single();

    _updateLastMessageAt(roomId);
    return ChatMessage.fromJson(response);
  }

  /// Mark all unread messages from the other user as read.
  /// Sets read_at = now() where sender_id != currentUserId and read_at is null.
  Future<void> markMessagesAsRead({
    required String roomId,
    required String currentUserId,
  }) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .neq('sender_id', currentUserId)
          .isFilter('read_at', null);
      debugPrint('ChatService.markMessagesAsRead: done for room=$roomId');
    } catch (e) {
      debugPrint('ChatService.markMessagesAsRead ERROR: $e');
      // Non-critical, don't crash chat
    }
  }

  /// Subscribe to Supabase Realtime channel for chat_messages in a room.
  /// Returns a [RealtimeChannel] that should be unsubscribed on dispose.
  ///
  /// [onInsert] — called when a new message is inserted.
  /// [onUpdate] — called when a message is updated (e.g. read_at set).
  RealtimeChannel subscribeToRoom({
    required String roomId,
    required void Function(ChatMessage message) onInsert,
    required void Function(ChatMessage message) onUpdate,
  }) {
    final channel = _supabase.channel('chat_room_$roomId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            debugPrint('Realtime INSERT: ${payload.newRecord}');
            try {
              final msg = ChatMessage.fromJson(payload.newRecord);
              onInsert(msg);
            } catch (e) {
              debugPrint('Realtime INSERT parse error: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            debugPrint('Realtime UPDATE: ${payload.newRecord}');
            try {
              final msg = ChatMessage.fromJson(payload.newRecord);
              onUpdate(msg);
            } catch (e) {
              debugPrint('Realtime UPDATE parse error: $e');
            }
          },
        )
        .subscribe((status, [error]) {
      debugPrint('Realtime channel status: $status, error: $error');
    });

    return channel;
  }

  /// Unsubscribe from a realtime channel.
  Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    try {
      await _supabase.removeChannel(channel);
    } catch (e) {
      debugPrint('ChatService.unsubscribeChannel ERROR: $e');
    }
  }

  /// Update the last_message_at timestamp in the chat_rooms table.
  Future<void> _updateLastMessageAt(String roomId) async {
    try {
      await _supabase.from('chat_rooms').update({
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);
    } catch (e) {
      // Non-critical, ignore if fails
    }
  }
}
