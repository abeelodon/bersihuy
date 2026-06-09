import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../data/chat_service.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_image_bubble.dart';
import '../widgets/chat_location_bubble.dart';
import '../widgets/chat_input_bar.dart';

class OrderChatScreen extends StatefulWidget {
  final String orderId;
  final String currentUserId;
  final String customerId;
  final String staffId;
  final String? orderNumber;
  final String? receiverName;
  final String? serviceAddress;
  final String title;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.currentUserId,
    required this.customerId,
    required this.staffId,
    this.orderNumber,
    this.receiverName,
    this.serviceAddress,
    required this.title,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _chatService = ChatService();
  final _scrollController = ScrollController();

  ChatRoom? _room;
  bool _isLoading = true;
  String? _error;

  List<ChatMessage> _messages = [];
  RealtimeChannel? _realtimeChannel;

  final _imagePicker = ImagePicker();
  bool _isSendingAttachment = false;

  /// Set of message IDs we already have locally, for dedup.
  final Set<String> _messageIds = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      _chatService.unsubscribeChannel(_realtimeChannel!);
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    debugPrint('OrderChatScreen._initializeChat: START');
    debugPrint('Params -> orderId: ${widget.orderId}');
    debugPrint('Params -> currentUserId: ${widget.currentUserId}');
    debugPrint('Params -> customerId: ${widget.customerId}');
    debugPrint('Params -> staffId: ${widget.staffId}');
    debugPrint('Params -> orderNumber: ${widget.orderNumber}');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.staffId.trim().isEmpty || widget.staffId == '-') {
        throw Exception('Chat tersedia setelah petugas ditugaskan.');
      }

      if (widget.currentUserId != widget.customerId &&
          widget.currentUserId != widget.staffId) {
        throw Exception('Anda tidak memiliki akses ke chat ini.');
      }

      _room = await _chatService.getOrCreateRoom(
        orderId: widget.orderId,
        customerId: widget.customerId,
        staffId: widget.staffId,
      );

      debugPrint('OrderChatScreen: Room OK, ID=${_room!.id}');

      // Load initial messages
      final messages = await _chatService.getMessages(_room!.id);
      debugPrint('OrderChatScreen: Loaded ${messages.length} messages.');

      _messages = messages;
      _messageIds.clear();
      for (final m in _messages) {
        _messageIds.add(m.id);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Mark incoming messages as read
      await _chatService.markMessagesAsRead(
        roomId: _room!.id,
        currentUserId: widget.currentUserId,
      );

      // After marking as read, refresh to get updated read_at values
      await _refreshMessages();

      // Subscribe to realtime updates
      _subscribeRealtime();
    } catch (e) {
      debugPrint('Chat Init Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _subscribeRealtime() {
    if (_room == null) return;

    _realtimeChannel = _chatService.subscribeToRoom(
      roomId: _room!.id,
      onInsert: (message) {
        if (!mounted) return;
        // Dedup: skip if we already have this message (from optimistic add)
        if (_messageIds.contains(message.id)) {
          debugPrint('Realtime INSERT skipped (dedup): ${message.id}');
          return;
        }
        setState(() {
          _messageIds.add(message.id);
          _messages.add(message);
        });
        _scrollToBottom();

        // If message is from the other user, mark it as read immediately
        if (message.senderId != widget.currentUserId) {
          _chatService.markMessagesAsRead(
            roomId: _room!.id,
            currentUserId: widget.currentUserId,
          );
        }
      },
      onUpdate: (updatedMessage) {
        if (!mounted) return;
        // Update existing message in-place (e.g. read_at changed)
        setState(() {
          final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
      },
    );
  }

  Future<void> _refreshMessages() async {
    if (_room == null) return;
    try {
      final messages = await _chatService.getMessages(_room!.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _messageIds.clear();
          for (final m in _messages) {
            _messageIds.add(m.id);
          }
        });
      }
    } catch (e) {
      debugPrint('Chat refresh error: $e');
    }
  }

  /// Optimistically add a message to local state.
  void _addMessageOptimistic(ChatMessage message) {
    if (_messageIds.contains(message.id)) return;
    setState(() {
      _messageIds.add(message.id);
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Use addPostFrameCallback to ensure list is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendText(String text) async {
    if (_room == null) return;
    try {
      final sentMessage = await _chatService.sendTextMessage(
        roomId: _room!.id,
        senderId: widget.currentUserId,
        text: text,
      );
      _addMessageOptimistic(sentMessage);
    } catch (e) {
      debugPrint('Chat send text error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pesan')),
        );
      }
    }
  }

  Future<void> _handleSendImage() async {
    if (_room == null) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (picked == null) return;

      setState(() {
        _isSendingAttachment = true;
      });

      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';

      final sentMessage = await _chatService.sendImageMessage(
        roomId: _room!.id,
        senderId: widget.currentUserId,
        imageBytes: bytes,
        mimeType: mimeType,
      );
      _addMessageOptimistic(sentMessage);
    } catch (e) {
      debugPrint('Chat send image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim gambar')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingAttachment = false;
        });
      }
    }
  }

  Future<void> _handleSendLocation(String url) async {
    if (_room == null || url.trim().isEmpty) return;
    try {
      final sentMessage = await _chatService.sendLocationMessage(
        roomId: _room!.id,
        senderId: widget.currentUserId,
        locationUrl: url.trim(),
      );
      _addMessageOptimistic(sentMessage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim lokasi')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primary),
                title: const Text('Kirim Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _handleSendImage();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('Kirim Link Maps'),
                onTap: () {
                  Navigator.pop(context);
                  _showLocationDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim Link Maps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Paste Google Maps URL...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (widget.serviceAddress != null &&
                widget.serviceAddress!.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  final encodedAddress =
                      Uri.encodeComponent(widget.serviceAddress!);
                  final generatedUrl =
                      'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
                  controller.text = generatedUrl;
                },
                child: const Text('Gunakan alamat pesanan',
                    textAlign: TextAlign.center),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _handleSendLocation(url);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            if (widget.receiverName != null || widget.orderNumber != null)
              Text(
                '${widget.receiverName ?? ''} ${widget.orderNumber != null ? '(${widget.orderNumber})' : ''}'
                    .trim(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeChat,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isSendingAttachment) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.outline.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Tulis pesan pertama untuk mulai chat.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe =
                        message.senderId == widget.currentUserId;

                    if (message.isText) {
                      return ChatBubble(
                        text: message.messageText ?? '',
                        isMe: isMe,
                        time: message.createdAt.toLocal(),
                        isRead: message.readAt != null,
                        showStatus: isMe,
                      );
                    } else if (message.isImage &&
                        message.attachmentUrl != null &&
                        message.attachmentUrl!.isNotEmpty) {
                      return ChatImageBubble(
                        imageUrl: message.attachmentUrl!,
                        isMe: isMe,
                        time: message.createdAt.toLocal(),
                        isRead: message.readAt != null,
                        showStatus: isMe,
                      );
                    } else if (message.isLocation &&
                        message.locationUrl != null &&
                        message.locationUrl!.isNotEmpty) {
                      return ChatLocationBubble(
                        locationUrl: message.locationUrl!,
                        isMe: isMe,
                        time: message.createdAt.toLocal(),
                        isRead: message.readAt != null,
                        showStatus: isMe,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
        ),
        ChatInputBar(
          onSendText: _handleSendText,
          onAttachmentPressed: _showAttachmentOptions,
        ),
      ],
    );
  }
}
