class MessageModel {
  final int id;
  final int? conversationId;
  final int driver;
  final String driverName;
  final String driverPhone;
  final double? driverLeftMoney;
  final String content;
  final bool isFromSystem;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    this.conversationId,
    required this.driver,
    required this.driverName,
    required this.driverPhone,
    this.driverLeftMoney,
    required this.content,
    required this.isFromSystem,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // 解析時間並加 8 小時（UTC+8）
    final utcTime = DateTime.parse(json['created_at'] as String);
    final localTime = utcTime.add(const Duration(hours: 8));
    
    return MessageModel(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int?,
      driver: json['driver'] as int,
      driverName: json['driver_name'] as String,
      driverPhone: json['driver_phone'] as String,
      driverLeftMoney: json['driver_left_money'] != null
          ? (json['driver_left_money'] as num).toDouble()
          : null,
      content: json['content'] as String,
      isFromSystem: json['is_from_system'] as bool,
      createdAt: localTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'driver': driver,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_left_money': driverLeftMoney,
      'content': content,
      'is_from_system': isFromSystem,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ConversationModel {
  final int driverId;
  final String driverName;
  final String driverPhone;
  final double driverLeftMoney;
  final int? latestMessageId;
  final String? latestMessageContent;
  final bool? latestMessageIsFromSystem;
  final DateTime? latestMessageCreatedAt;

  ConversationModel({
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverLeftMoney,
    this.latestMessageId,
    this.latestMessageContent,
    this.latestMessageIsFromSystem,
    this.latestMessageCreatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      driverId: json['driver_id'] as int,
      driverName: json['driver_name'] as String,
      driverPhone: json['driver_phone'] as String,
      driverLeftMoney: (json['driver_left_money'] as num).toDouble(),
      latestMessageId: json['latest_message_id'] as int?,
      latestMessageContent: json['latest_message_content'] as String?,
      latestMessageIsFromSystem: json['latest_message_is_from_system'] as bool?,
      latestMessageCreatedAt: json['latest_message_created_at'] != null
          ? DateTime.parse(json['latest_message_created_at'] as String)
              .add(const Duration(hours: 8))
          : null,
    );
  }
}

class PaginationModel {
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationModel({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalCount: json['total_count'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrevious: json['has_previous'] as bool,
    );
  }
}

