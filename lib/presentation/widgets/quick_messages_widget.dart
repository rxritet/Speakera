import 'package:flutter/material.dart';
import '../../domain/entities/social.dart';

/// Панель быстрых сообщений для чата дуэли.
class QuickMessagesPanel extends StatelessWidget {
  const QuickMessagesPanel({
    super.key,
    required this.onMessageSelected,
  });

  final Function(QuickMessage) onMessageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = QuickMessageCategory.values;

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.outline,
            indicatorColor: theme.colorScheme.primary,
            tabs: categories.map((cat) => Tab(text: cat.label)).toList(),
          ),
          SizedBox(
            height: 120,
            child: TabBarView(
              children: categories.map((category) {
                final messages = QuickMessage.presets
                    .where((m) => m.category == category)
                    .toList();
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _QuickMessageButton(
                      message: msg,
                      onTap: () => onMessageSelected(msg),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMessageButton extends StatelessWidget {
  const _QuickMessageButton({
    required this.message,
    required this.onTap,
  });

  final QuickMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Виджет чата дуэли.
class DuelChatWidget extends StatefulWidget {
  const DuelChatWidget({
    super.key,
    required this.duelId,
    required this.senderId,
    required this.senderName,
  });

  final String duelId;
  final String senderId;
  final String senderName;

  @override
  State<DuelChatWidget> createState() => _DuelChatWidgetState();
}

class _DuelChatWidgetState extends State<DuelChatWidget> {
  final _textController = TextEditingController();
  bool _showQuickMessages = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Сообщения (заглушка)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5, // Заглушка
            itemBuilder: (context, index) {
              return _ChatMessageBubble(
                text: 'Сообщение $index',
                isMe: index % 2 == 0,
                senderName: index % 2 == 0 ? 'Вы' : 'Соперник',
              );
            },
          ),
        ),
        // Быстрые сообщения
        if (_showQuickMessages)
          QuickMessagesPanel(
            onMessageSelected: (msg) {
              // Отправить сообщение
              setState(() => _showQuickMessages = false);
            },
          ),
        // Поле ввода
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () => setState(() => _showQuickMessages = !_showQuickMessages),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    // Отправить сообщение
    _textController.clear();
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.text,
    required this.isMe,
    required this.senderName,
  });

  final String text;
  final bool isMe;
  final String senderName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(
              senderName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
