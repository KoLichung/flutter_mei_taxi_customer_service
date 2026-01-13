import 'package:flutter/material.dart';
import 'message_detail_screen.dart';
import '../services/api_service.dart';
import '../models/message_model.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPolling = false; // 輪詢標誌

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 [MessageList] 開始載入對話列表 (使用 recent-conversations API)...');
      
      // 1. 獲取對話列表
      final drivers = await ApiService.getRecentDriverConversations();
      print('✅ [MessageList] recent-conversations API 返回 ${drivers.length} 個對話');
      
      // 2. 解析對話列表（直接使用 recent-conversations 返回的 unread_count）
      final conversations = drivers
          .map((json) => ConversationModel.fromJson(json))
          .toList();
      
      print('✅ [MessageList] 載入完成，共 ${conversations.length} 個對話');
      for (var i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        print('  💬 [$i] ${conv.driverName}: unreadCount = ${conv.unreadCount}');
      }
      
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [MessageList] 載入失敗: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    if (!_isPolling) {
      _isPolling = true;
      print('🔄 [MessageList] 開始輪詢');
    }
    _poll();
  }

  void _poll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPolling) {
        _loadConversations();
        _poll();
      } else {
        print('⏸️ [MessageList] 輪詢已暫停');
      }
    });
  }

  void _stopPolling() {
    if (_isPolling) {
      _isPolling = false;
      print('⏸️ [MessageList] 停止輪詢');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '錯誤: $_errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Text('暫無對話記錄'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      conversation.driverName.isNotEmpty
                          ? conversation.driverName[0]
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (conversation.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                conversation.driverName,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(conversation.driverPhone),
                  if (conversation.latestMessageContent != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      conversation.latestMessageContent!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: conversation.unreadCount > 0
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (conversation.latestMessageCreatedAt != null)
                    Text(
                      _formatTime(conversation.latestMessageCreatedAt!),
                      style: TextStyle(
                        color: conversation.unreadCount > 0
                            ? Colors.blue
                            : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              onTap: () {
                // 暫停輪詢
                _stopPolling();
                print('⏸️ [MessageList] 進入詳情頁，暫停輪詢');
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageDetailScreen(
                      driverId: conversation.driverId,
                      driverName: conversation.driverName,
                      driverPhone: conversation.driverPhone,
                      initialBalance: conversation.driverLeftMoney,
                    ),
                  ),
                ).then((_) {
                  // 返回時恢復輪詢
                  print('▶️ [MessageList] 返回列表頁，恢復輪詢');
                  _loadConversations(); // 立即載入一次最新數據
                  _startPolling();
                });
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
