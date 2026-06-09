import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isRead;
  final bool showStatus;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? Colors.white : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            _buildTimestampRow(formattedTime),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampRow(String formattedTime) {
    final timeColor =
        isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formattedTime,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            color: timeColor,
          ),
        ),
        if (showStatus) ...[
          const SizedBox(width: 3),
          _buildCheckIcon(),
        ],
      ],
    );
  }

  Widget _buildCheckIcon() {
    if (isRead) {
      // Double check — read
      return Icon(
        Icons.done_all,
        size: 14,
        color: isMe
            ? Colors.white
            : const Color(0xFF4FC3F7), // light blue for read
      );
    } else {
      // Single check — sent
      return Icon(
        Icons.done,
        size: 14,
        color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.outline,
      );
    }
  }
}
