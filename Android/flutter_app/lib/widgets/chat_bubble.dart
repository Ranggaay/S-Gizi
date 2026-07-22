import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromNutritionist
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.fromNutritionist ? SgColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SgColors.border),
        ),
        child: Text(
          message.message,
          style: AppTypography.body.copyWith(
            color: message.fromNutritionist
                ? Colors.white
                : SgColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
