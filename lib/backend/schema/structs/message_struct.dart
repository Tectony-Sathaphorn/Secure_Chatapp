class MessageStruct {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final bool isRead;

  MessageStruct({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageStruct.fromJson(Map<String, dynamic> json) {
    return MessageStruct(
      id: json['id'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
} 