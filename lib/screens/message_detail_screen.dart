import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/message_model.dart';
import 'recharge_form_screen.dart';

class MessageDetailScreen extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String driverPhone;
  final double initialBalance;

  const MessageDetailScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.initialBalance,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  double _currentBalance = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSending = false;
  String? _errorMessage;

  int _currentPage = 1;
  bool _hasMore = true;
  PaginationModel? _pagination;

  // 臨時訊息（發送後等待輪詢）
  final List<MessageModel> _tempMessages = [];

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.initialBalance;
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
      // 載入更多時，先增加頁碼
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final response = await ApiService.getDriverSystemMessages(
        driverId: widget.driverId,
        viewType: 'system',
        page: _currentPage,
        pageSize: 20,
      );

      final messagesJson = response['messages'] as List;
      final newMessages = messagesJson
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // API 返回的順序是最新的在前（-created_at），保持不變
      // 使用 ListView reverse: true 讓最新的顯示在底部

      // 更新餘額
      if (response['driver_left_money'] != null) {
        _currentBalance = (response['driver_left_money'] as num).toDouble();
      }

      // 更新分頁資訊
      if (response['pagination'] != null) {
        _pagination = PaginationModel.fromJson(
          response['pagination'] as Map<String, dynamic>,
        );
        _hasMore = _pagination!.hasNext;
      }

      setState(() {
        if (loadMore) {
          // 載入更多時，新訊息（更舊的）添加到列表末尾
          // 因為 reverse: true，會顯示在頂部
          _messages.addAll(newMessages);
        } else {
          // 首次載入，最新的在列表開頭（因為 API 返回順序）
          _messages = newMessages;
          // 如果還有更多頁面，設置下一頁為第 2 頁
          if (_pagination != null && _pagination!.hasNext) {
            _currentPage = 1; // 保持為 1，下次載入更多時會變成 2
          }
        }
        _isLoading = false;
        _isLoadingMore = false;

        // 清除已確認的臨時訊息
        _tempMessages.clear();
      });

      // 滾動到底部（僅首次載入，reverse: true 時底部是最新訊息）
      if (!loadMore && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.minScrollExtent);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _loadMessages();
        _startPolling();
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // 創建臨時訊息（時間已經是本地時間，不需要再加 8 小時）
    final tempMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch, // 臨時 ID
      driver: widget.driverId,
      driverName: widget.driverName,
      driverPhone: widget.driverPhone,
      content: content,
      isFromSystem: false,
      createdAt: DateTime.now(), // 本地時間
    );

    setState(() {
      _tempMessages.add(tempMessage);
      _isSending = true;
    });

    try {
      await ApiService.createDriverSystemMessage(
        driverId: widget.driverId,
        content: content,
      );

      // 等待輪詢更新，不立即更新 UI
      setState(() {
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _tempMessages.remove(tempMessage);
        _isSending = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('發送失敗: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRecharge() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RechargeFormScreen(
          driverId: widget.driverId,
          driverName: widget.driverName,
          currentBalance: _currentBalance,
        ),
      ),
    );

    if (result != null && result is double) {
      setState(() {
        _currentBalance = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 合併顯示訊息（臨時訊息 + 實際訊息）
    // API 返回順序：最新的在前
    // 使用 reverse: true，所以最新的會顯示在底部
    // 臨時訊息應該在列表開頭（因為 reverse，會顯示在底部）
    final displayMessages = [..._tempMessages, ..._messages];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.driverName),
            Text(
              widget.driverPhone,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 司機餘額卡片
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '司機餘額',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NT\$ ${_currentBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _navigateToRecharge,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('儲值'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 訊息列表
          Expanded(
            child: _isLoading && displayMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && displayMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '錯誤: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadMessages(),
                              child: const Text('重試'),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification notification) {
                          if (notification is ScrollUpdateNotification) {
                            // reverse: true 時，頂部是 maxScrollExtent（列表末尾，最舊的訊息）
                            // 向上滑動到頂部時載入更多（更舊的訊息）
                            if (_scrollController.position.pixels >=
                                    _scrollController.position.maxScrollExtent -
                                        100 &&
                                _hasMore &&
                                !_isLoadingMore) {
                              _loadMessages(loadMore: true);
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true, // 使用 reverse，最新的在底部
                          padding: const EdgeInsets.all(16),
                          itemCount: displayMessages.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // 載入更多指示器顯示在列表末尾（reverse 時顯示在頂部）
                            if (_isLoadingMore && index == displayMessages.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final message = displayMessages[index];
                            final isTemp = _tempMessages.contains(message);

                            return Opacity(
                              opacity: isTemp ? 0.6 : 1.0,
                              child: Align(
                                alignment: message.isFromSystem
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: message.isFromSystem
                                        ? Colors.grey[200]
                                        : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.content,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isTemp)
                                            const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          if (isTemp) const SizedBox(width: 4),
                                          Text(
                                            _formatTime(message.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          // 輸入框
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 58), // 底部 50px + 原本 8px = 58px
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: _isSending ? '發送中...' : '輸入訊息...',
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
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: Colors.blue,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
